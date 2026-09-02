# ⚠⚠⚠ SEALED 2026-09-02 — THE setGroup COPY WAS PART OF THE CARRIER DEFECT; SIX
# FIXITS OPENED AND FOUR CLOSED IN ONE DAY; AND THE ASKING STILL ANSWERS NO, WITH
# A NEW SIGNATURE.
#
#   ⚠ DATE CHECK, run before the mark: `date` reads 2026-09-02 15:31 and
#   `git log -1 --date=iso` stamps 2026-09-02 15:02. They agree.
#
#   ## THE ONE-LINE STATE: **`setGroup` never copies, `embedRule` owns the one
#   legitimate copy, the argument channel goes through `setGroup` on BOTH roads,
#   and node-valued operations — deref, assign, print — go through runtime helpers
#   sharing ONE spelling with the interpreter.** Fleet **176 green / 1 parked / 3
#   pinned red**, frontier **exit 0, 10 PASS**, canary **332**, `gNoUnwrap` **0**,
#   bare binary verified live. Both repos 0 dirty / 0 unpushed but for `parser`.
#
#   ## ⚠⚠ THE SIX THINGS A FRESH READER MUST NOT RE-DERIVE
#
#   **1. `setGroup`'s COPY WAS PART OF THE CARRIER DEFECT, AND TWO FIXTURES HAD
#   PINNED IT FOR DAYS WITHOUT KNOWING.** `holderT` row 3 (`argument` → `htWindow`)
#   and `anyOrNum`'s ANSWER (`1` → the label) both moved when the copy went, and
#   **both were fixes.** ⚠ `holderT`'s pin predicted the FLIP would fix it and
#   named the wrong cause; it arrived at `gNoUnwrap` **0**. **A pin can hold its
#   VALUE correctly while its stated TRIGGER is wrong, and nothing in the row can
#   catch that.**
#
#   **2. THE BOOTSTRAPPER USED `setGroup`'s COPY AS ITS ONLY COPY PRIMITIVE (F-44).**
#   `GroupMain.twk` hand-builds the grammar in C++ and never passes through
#   `aCTionDefinE`, so six sites did copy-then-modify with no copy of their own.
#   Cured by `GroupItem::embedRule` — copy when the source is a rule, store it
#   otherwise — called at seven sites. ⚠ **`:218` is NOT one of them**: `new("tik")`
#   is unparented and not a rule, so it never had a copy to borrow.
#
#   **3. PRINT DOES NOT FOLLOW. LAW 1 IS RETIRED (F-49).** `getText`'s `isGROUP`
#   case yields `group.tag`; cyclic group chains are legal data and **the overflow
#   is UNREACHABLE rather than guarded**. Five other transitive followers —
#   `getCount`, `getDataType`, `getItem`, `getNumber`, `getObject` — stopped
#   following in their own stroke, with **zero moved rows**.
#   ⚠ **"one level, no follow" is not a one-line answer for all five**: `getText`'s
#   answer was the TAG because a tag is text, and **a holder has no count of its
#   own.**
#
#   **4. NODE-VALUED OPERATIONS GO THROUGH RUNTIME HELPERS — ONE SPELLING.**
#   `jitDerefRT`, `assignFieldCore` (called by BOTH roads), `jitPrintNodeRT`
#   (delegating to `appendGroup`, the interpreted walk's own call). ⚠ **The emit-time
#   marking keys on the `groupBody`, NOT the node** — two failed attempts earned
#   that: **the print's operand and the assign's target are different nodes over one
#   body**, C18's finding at a third site.
#
#   **5. ⚠⚠ THE ASKING ANSWERS NO, WITH A NEW SIGNATURE, AND `carrierNode` IS NOT
#   DISCHARGED.** Under the flip `parser(Start)` reports `PARSE argument <- ruleText`
#   and `setParse: ERROR field passed in argument has no rStuff`. **Previously the
#   callee got a COPY SHARING Start's body; now it gets THE HOLDER ITSELF**, named
#   `argument`, carrying no `rStuff`.
#   ⚠ **THE RULED RESPELL IS STAR EVERY USE — `<-` MINTS A COPY AND IS NOT AN
#   ALIAS.** Measured: `pArg <- *argument` reports the capture's own name. Law 4's
#   *name-it-then-star-it* does not reach Start.
#
#   **6. THE TRY-AND-BUY IS OPEN ON `tryAndBuy-gNoUnwrap`. 176 → 116, and THE 61
#   RED ROWS ARE TEN MECHANISMS, NOT 61 FINDINGS.**
#   ```
#   kant8T HANGS (90s) -- K7a/b/c, K6c, K2x x3, sentinel are ITS truncation   8  (d)
#   countPop truncates                                                        3  (d)
#   spacingT                                                                 14  (a)
#   pointerT (one row a by-design tripwire)                                   8  (a)
#   holderT 3 - nestT 3 - starT 2 (pre-registered) - faceT/ADDROF 3 - argWriteT 1
#   UNCLASSIFIED, need a look                                               ~14
#   ```
#   ⚠⚠ **`spacingT` IS THE LINE THAT A BUCKET IS NOT A DIRECTION.** Its pins
#   expected the **tag** and under the flip it prints the **value**; every other
#   (a) row moved tag-ward. **A re-pin sweep assuming one direction would have got
#   those four backwards.**
#
#   ## ⚠ DOCTRINE BANKED TODAY
#
#   **DEGRADE 0 IS NOT A CERTIFICATE ROW; A CERTIFICATE NAMES THE DEGRADES IT
#   ALLOWS.** A certificate asked for zero on a fixture where **14 of 25 degrades
#   were an unemitted `cerr`** — unreachable by anything that stroke could do. Same
#   family as pinning a certificate to a ROAD instead of to the LAW, and both were
#   paid for in one week.
#
#   **Bear-traps #41–#45 minted:** `=` captures nothing where `:=` captures (#41,
#   and it makes #35's own stated remedy usable); an inserted block re-points every
#   bare field BELOW it (#42); a probe must be a minimal DELTA, never a rewrite
#   (#43); a generated body's run-time `taG` reads `BlocK`, not the rule (#44); an
#   unresolved bare name in a tok condition becomes a STRING LITERAL, always true,
#   **with the canary green throughout** (#45).
#
#   ## THE ORDER FOR TOMORROW
#   1. **`minionWork/kant8Tstar.candidate` is step 1** — the `*argument` respell,
#      byte-identical under the flip and hanging bare, so it RIDES WITH the flip.
#   2. The ~14 unclassified reds, then `kant8T`'s hang.
#   3. The runtime-set item: **`noUnwrap;` on `debug;`'s mechanism, explicit set,
#      NEW NAME** — `unWrap` has three callers and keeps its meaning. **Recon of
#      `gNoUnwrap` reads FIRST.**
#   4. F-51 (`Token` print part) and F-52 (`cerr` unemitted) are Tony's, jitter
#      campaign, interpreted road correct, not chased.
#
#   ## ⚠ HOUSEKEEPING A FRESH SESSION SHOULD KNOW
#   - **Fixit queue is 1** — `carrierNode`, since 2026-08-31, and the asking above
#     is why it is still open. **Nothing earlier discharges it.**
#   - **`gNoUnwrap` is 0 on main and 1 on the branch.** Every retok this session was
#     BARE; no directives build was measured except one one-entry instrument,
#     unwound and md5-verified.
#   - **Tony flip-build-test-unflip-builds tonight, sealed on both sides, NO
#     MEASUREMENT BETWEEN.**
#   - `IncantForms/WorkingOn/parser` is the only dirty file and it is Tony's WIP.
#
# ⚠⚠⚠ SEALED 2026-09-01f — THE CHANNEL CARRIES. `*argument` IS THE SOURCE FIELD BY
# ADDRESS, AND THE FOUR-ASKING MYSTERY IS CLOSED BY ADDRESS TOO. THE ASKING IS
# TOMORROW'S FIRST STROKE.
#
#   ⚠ DATE CHECK, run before the mark: `date` reads 2026-09-01 17:56 and
#   `git log -1 --date=iso` stamps 2026-09-01 17:53. They agree. THIRD seal of the
#   day — 2f0e0dc covers C1–C17, 1f0a82b covers C18–C19, this one covers C20–C26.
#   ⚠⚠ AND THE CHECK CAUGHT ITS FIRST REAL ERROR, WHICH IS THE POINT OF RUNNING IT:
#   this session stamped **2026-09-02** on 35 lines across 8 files before the mark
#   was typed. Corrected to 09-01 in every line this session added.
#   ⚠ AND A FINDING FELL OUT OF THE CORRECTION, LEFT UNTOUCHED BECAUSE IT IS NOT
#   CLOD'S TO REWRITE: **the tree already carried `2026-09-02` prose in nine files,
#   including `CLAUDE.md` (committed 2026-09-01) and `docs/groupBodySplit.md`
#   (committed 2026-08-31).** So the registers disagree with the clock and with each
#   other about what day it is. The seals use the clock; the prose does not always.
#   **Tony's to rule.** Recorded here rather than fixed.
#
#   ⚠ VOCABULARY: **field** and **copy of a field**. "Frame" is retired (SEQ 114) —
#   where an older ruling says frame, read the argument channel. The peas-pass and
#   the loaded-gun pair are retired with it.
#
#   ## THE ONE-LINE STATE: **The channel carries. `*argument` reaches the SOURCE
#   FIELD — same pointer, not merely the same body — and the four-asking mystery is
#   closed by address: the bind repointed the ORIGINAL's body while every named read
#   went through a COPY still holding the pre-bind body.** Flip-gated at 0 and inert;
#   fleet **171 green / 1 parked / 3 red (the pinned set), byte-identical** to C24;
#   canary **326**; frontier **exit 0, 10 PASS**; `jitBindArgRT` **deliberately not
#   yet touched**. Both repos 0 dirty / 0 unpushed.
#
#   ## ⚠⚠ THE FIVE THINGS A FRESH READER MUST NOT RE-DERIVE
#
#   **1. THE CHANNEL CARRIES, BY ADDRESS.** In `runAction` under `gNoUnwrap`: set the
#   argument attribute BODY's `gGroup` to the source field and mark it isGROUP — the
#   `+*` link — saving the previous pair and restoring after `processAction`. The
#   parse road is untouched.
#   ```
#   the callee's `argument`     field #6  body #4  isCopy=1   as pre-registered
#   addrOf(*argument) DIRECT    field #5  body #2  tag s4Src  THE SOURCE FIELD
#   ```
#   **Field #5 is the same field the bind saw as its source, same raw pointer, same
#   run.** Not merely the same body — the same FIELD.
#
#   **2. THE FOUR-ASKING MYSTERY IS CLOSED, AND THE ANSWER IS AN ADDRESS.** The bind's
#   target and the callee's read are **different fields over one body**: target field
#   #3 / body #4, callee field #6 / body #4. The bind repoints the ORIGINAL's body
#   pointer to #2; the copy still points at #4. That is why four askings failed, and
#   the comment above the bind had been saying it, unmeasured, the whole time.
#
#   **3. ⚠⚠ THE SPELLING NEARLY COST A WORKING BUILD ITS VERDICT, and Clod's words
#   are kept: THE VALUE READ SAID SOMETHING ARRIVED, THE DIRECT READ SAID WHAT, AND
#   ONLY IDENTITY DISCRIMINATES.** `s4Star <- *argument; addrOf(s4Star)` reads body #8
#   — a FRESH node — and would have been reported as the channel failing. It is
#   bear-trap #35's ruled copy-on-rebind. ⚠ And the value witness alone could never
#   have saved it: **bare `argument` also prints ORIG**, because print follows (law 1).
#
#   **4. STEP 4 IS DEAD, AND SO IS WIDENING IT.** The sweep at `ruleActions.rtn:459`
#   was built twice — unscoped, then scoped to the attributes of CODED definitions —
#   and **the second one FIRED** (`coded=1` on `s4Callee`, `POINTER installed for
#   argument` ×17) while the callee's read **did not move a byte**. So the sweep is
#   not the road: changing what the definition HOLDS does not change what the call
#   HANDS OVER. Members widening dies for the same reason. Both patches are in
#   `minionWork/`.
#   ⚠ **AND THE HEAD-VS-COUNT LESSON, IN CLOD'S WORDS: the trace's first twenty lines
#   all read `coded=0`, because every early definition in the corpus is a command with
#   no code body. A `head` said the gate never fired. A COUNT said 43.** Reported off
#   the head, step 4 would have gone into the record as never engaging — a different
#   and false finding, and one that would have sent the next stroke after a phantom.
#
#   **5. LAW 2 IS CERTIFIED BY IDENTITY (C20), AND ITS GATE HAD BEEN OPEN FOR A DAY.**
#   `pointerT` row L4: the subscript result is a DIFFERENT BODY from the source (#7 vs
#   #2) and the same capture STARRED is the source (#2). Law 2 is the difference, law
#   4 is the match, each the other's control. The blocker was identity — `addrOf` —
#   which landed in the SAME stroke that wrote the note saying law 2 was blocked.
#
#   ## ⚠⚠⚠ ONE RULING IS BLOCKED ON A MEASUREMENT, AND IT IS THE FIRST THING TOMORROW
#
#   **TONY ASKED, BEFORE THE MARK: did C25 write `gGroup` DIRECTLY or through `setGroup`?**
#   **ANSWER: DIRECTLY — AND WITH `flags.data = 6` SET ALONGSIDE IT.** So the premise the
#   ruling rested on does not hold: the union is **not** left undiscriminated, isGROUP **is**
#   set, and nothing of the prior contents stays readable as data. The direct write set both
#   halves, copied from `opAddPointer`'s own generated form.
#
#   **THE RULING WAS THEN BUILT ANYWAY AND MEASURED, AND IT COSTS THE CHANNEL ITS WHOLE POINT.**
#   `setGroup` (`GroupItem.mm`) stores the field ITSELF only when the target body is `isLocal`
#   or `isLabel`, or the source is `byRef`, or **the source has no parent**. Otherwise it stores
#   **`new GroupItem(g)` — a copy.** An action's argument attribute is neither local nor label,
#   and a define-block field HAS a parent, so the copy branch is the one taken:
#   ```
#   CHANCAM  the SOURCE handed to setGroup            field #3  body #2
#   CHANCAM  what gGroup ACTUALLY HOLDS after it      field #4  body #2
#   CHANCAM  same field?  NO -- A COPY   (source parent=0x1049e7300, isLocal=0, isLabel=0)
#   then     addrOf(*argument)                        field #4  body #2   <- THE COPY
#   ```
#   **So through `setGroup`, `*argument` reaches a COPY OF THE SOURCE, not the source** — which
#   is precisely the disease this campaign exists to cure. Direct reaches the FIELD.
#   ⚠ **AND THE BODY COLUMN CANNOT TELL THEM APART**, which is why this needed asking: the copy
#   SHARES the source's body (C18), so both spellings read `body #2`. Only the field column
#   separates them, and only with the camera at the bind.
#
#   **AND THE OTHER HALF OF TONY'S QUESTION — what does `setGroup` do when the body already
#   holds data? NOTHING. It never inspects the prior union**; it overwrites `gGroup`, sets
#   `data = 6` and `isInitialized`, and only zeroes when handed null. **So `setGroup` is not a
#   union guard, and the `0x4` is not the method's own problem — the tripwire is still the only
#   thing standing between the channel and a clobbered union.**
#
#   ⚠ **HELD AT DIRECT, NOT SHIPPED THROUGH setGroup, AND THE HOLD IS THE REPORT.** The ruling
#   said change it tonight so `jitBindArgRT` lifts the right lines tomorrow — but the lines it
#   would lift are lines that lose the field. **Tony's re-ruling is the first thing tomorrow,
#   ahead of `jitBindArgRT`**, because it decides WHAT jitBindArgRT lifts. The code carries the
#   fork in a comment at the site.
#   ⚠ **A third option nobody has priced: `setGroup` takes the field itself when the source is
#   `byRef`.** Not measured, not recommended, and named only so the re-ruling has the full menu.
#
#   ## ⚠ TWO RULINGS TAKEN THIS SESSION (Tony, SEQ 120)
#
#   **THE UNION — A CONSTRAINT WITH A TRIPWIRE, NOT A FIX. BUILT.** `gGroup` shares
#   storage with `gCount`, `gNumber`, `gBuffer` and six others (`GroupBody.h:119-131`),
#   so the channel's write CLOBBERS whatever else that union holds. It is safe today
#   only because an action's argument attribute body holds nothing. So the channel
#   **writes `gGroup` only when that union reads 0x0, and refuses BY NAME otherwise**
#   (`ARGCHANNEL REFUSED on <action>`). Certified under the flip: the channel still
#   carries and **zero refusals fired**. ⚠ **The refusal has NO NEGATIVE CONTROL — it
#   has never been made to fire, so "it stays silent" is not yet evidence that it CAN
#   speak.** Named, not implied.
#   ⚠ The `0x4` on the source's body stays an **undiagnosed identification**: `s4Src`
#   holds "ORIG", four characters, so it is probably `gCount` read as a pointer. The
#   union is structural; the 4 is not diagnosed.
#
#   **THE ORDER FOR TOMORROW, AND NOTHING SHIPS BETWEEN.**
#   0. **THE setGroup RE-RULING FIRST** — see the blocked ruling above. It decides what
#      `jitBindArgRT` is supposed to lift, so it cannot come after it.
#   1. **`jitBindArgRT`** (`GroupActions.rtn:382`) — JIT-first, and Clod's own
#      finding is that **the two roads now differ**, which they were built never to do:
#      it lifts `runAction`'s binding lines VERBATIM and its comment says so.
#   2. `nestT` f(g(x)) — the inner bind must not clobber the outer setup.
#   3. The A→B→A recursion fixture, through the bracket.
#   4. **FLEET ROWS**, so the channel is certified by something that runs every day
#      and not by one probe in `minionWork/`.
#   5. **The asking: `parser(Start)` receives Start.**
#   ⚠ **A ONE-ROAD CHANNEL IS EXACTLY THE INTERMEDIATE STATE THE TWO-HALF LAW FORBIDS.**
#
#   ## WHAT ELSE LANDED — C20 THROUGH C26
#
#   ```
#   C20  law 2 certified by identity; L3's attribution measured; pointerT's header
#        corrected -- it still carried the falsified account
#   C21  the isCopy column gets rows (L5); faceT's options row held on a SPELLING,
#        not on an instrument -- a falsified reason is not a cleared gate
#   C22  the results table; roundTripT JOINS THE FLEET and its ARM 0 control, failing
#        since birth, is pinned at MISMATCH; `<-` pinned as carrier-stable
#   C23  step 4 built unscoped, measured, reverted -- stop clause; F-43 banked
#   C24  F-43 fixed and certified by DRIVING the arm; step 4 re-aimed, FIRED, and the
#        callee's read did not move
#   C25  the bind is the lever -- probe confirmed both clauses; the channel carries
#   C26  the union tripwire; the date correction; the seal
#   ```
#
#   **F-43 (the guard that crashes) — CLOSED.** `opAddPointer`'s null-refusal arm, added
#   by F-41 so a refused operand would be named instead of crashing, **contained the
#   crash**: bare `tag` resolved to the still-null `ptr`. Exit 139 → exit 0, certified by
#   driving it. ⚠ **It survived because nothing could reach it** — `pointerT`'s F1 uses an
#   undeclared name, which bear-trap #39 mints as a local, so it never yielded a null.
#   Row **F2** exists to be the refusal test F1 never was.
#
#   ## ⚠ HOUSEKEEPING A FRESH SESSION SHOULD KNOW
#
#   - **`gNoUnwrap` is 0 and the shipped binary is bare.** Every retok this session was
#     BARE; no directives build was ever measured. The flip was raised and lowered four
#     times, with a rebuild each way, and only probes were run on a flipped build.
#   - **The fixit queue is 1** — `carrierNode`, since 2026-08-31 — and it is still the
#     gate. It does NOT discharge on the channel carrying: discharge is `parser(Start)`
#     receiving Start, at the asking, after step 5. Nothing earlier (SEQ 114).
#   - **Off-repo, 2026-09-01:** iCloud's "Desktop & Documents Folders" was still ON after
#     the 08-31 twin scrub; Tony switched it off and Finder found `Documents` again. The
#     scrub was MEASURED, the setting's prior ON state is REPORTED and was never measured,
#     the aftermath was MEASURED (`~/Documents` real, 15 items, 1.6 GB; iCloud `Desktop/`
#     8 KB and empty; the 458 MB retired copy intact). See `docs/fixIts.md` F-42.
#
# ⚠⚠⚠ SEALED 2026-09-01e — REBOOT SEAL. C18 AND C19, AND THE DAY'S BEST RESULT IS A
# SUSPICION THAT DIED: THE STAR HAS NO FIXPOINT AND NO COMPOSITION EITHER — IT HAS ONE STAR.
#
#   ⚠ DATE CHECK, run before the mark: `date` reads 2026-09-01 15:45, `git log -1 --date=iso`
#   stamps 2026-09-01 15:31. They agree. This is the second seal of the day — the earlier one
#   (2f0e0dc) covers C1–C17 and STANDS; this one covers only what landed after it.
#
#   ⚠ VOCABULARY: **field** and **copy of a field**, per Tony's SEQ 112 ruling, and now with
#   his SEQ 113 definition — *a copy of a field is a field with `isCopy` true whose body is
#   SHARED with the original. A copy knows it is a copy; the original does not know it has any.*
#
#   ## THE ONE-LINE STATE: **Two strokes. Step 3 answered (the sweep makes the copy, 317/317),
#   and SEQ 113's first three items landed — the follow-through laws re-pinned, `addrOf` minted
#   as an identity instrument, and `starT` S3a GRADED AGAINST ITSELF.** Fleet **149 green / 1
#   parked**, expected-red **3** (unchanged all day). Canary **326**. Frontier **exit 0, nine
#   stations, 10 PASS**. decodePop 22/82 · ddPop 6 · countPop 39/39 · formsPop 14. Both repos
#   **0 dirty / 0 unpushed**. `gNoUnwrap` **verified back at 0**, bare binary verified live.
#
#   ## ⚠⚠ THE FOUR THINGS A FRESH READER MUST NOT RE-DERIVE
#
#   **1. STEP 3: THE COPY UNDER THE TOKEN IS SWEEP-MADE (C18).** `addGroup` copies only
#   `if ( group->parent )` (`GroupItem.mm:239`), the parse-made field always arrives with a
#   parent, and the camera read **`adopted=0` on 317 of 317 firings**. No sweep edit was made.
#   ⚠ **AND THE COPY SHARES THE BODY** — `copyBody == itemBody` in every row, because the copy
#   constructor is `groupBody = grup->groupBody` outright. **TWO FIELDS OVER ONE BODY**, and
#   what crosses between them is enumerable: contents, flags, `groupList`, `gMethod`, `gGroup`
#   are **shared**; `parent`, sibling links, `rStuff` (freshly allocated) and `jitData` are
#   **not**.
#
#   **2. ⚠⚠ `starT` S3a IS GRADED AND ITS OWN SUSPICION IS FALSIFIED. THERE IS NO FIXPOINT AND
#   NO COMPOSITION — ONLY ONE STAR IS EVER APPLIED. N stars behave as exactly one.** Measured
#   under `gNoUnwrap=1`, identity by `addrOf`'s **body** column:
#   ```
#   baselines   s3Leaf #2    s3One #4    s3Two #6
#   *s3One   -> #2 LEAF      **s3One  -> #2 LEAF
#   *s3Two   -> #4 MIDDLE    **s3Two  -> #4 MIDDLE   <- THE DISCRIMINATOR
#   * *s3Two -> #4 MIDDLE    ***s3Two -> #4 MIDDLE
#   ```
#   **R4 decides and R2 alone never could:** a fixpoint AND a working composition both predict
#   `**s3Two` reaches the LEAF. It reaches the MIDDLE. Only *"the second star does nothing"*
#   predicts that — and it also explains R2 with no fixpoint anywhere, because one star on a
#   ONE-deep pointer reaches the leaf by itself. **THE READING THAT LOOKED LIKE A FIXPOINT WAS
#   A ONE-DEEP COINCIDENCE.**
#   ⚠ **THE ABSENCE IS EVIDENCE HERE:** not one `ERROR unary *` line in the flip-ON run. F-41
#   made every operator refuse **by name**, so a second star that ran and refused would have
#   said so. Nothing refused; nothing second ever ran.
#   ⚠ **R5 KILLS THE OBVIOUS MECHANISM** — spaced `* *x` reads identically, so this is NOT
#   longest-match merging two stars into one token. **WHERE they are dropped is NOT DIAGNOSED
#   and is not guessed at**, per the standing split: reproduction proves the symptom, never the
#   cause.
#   ⚠⚠ **THIS CONTRADICTS C16/C17's "`**x` is now `*` twice"** — that claim was read from the
#   operator table; this is measured. **And it relocates the row that matters to S2b**, which
#   must go RED at the flip and stay red until composition works.
#
#   **3. `addrOf` EXISTS, AND WHY IT IS NOT `showBody`.** Canary 325 → 326. `showBody` already
#   printed node and body addresses — the right question in the wrong currency, because a raw
#   `%p` **moves every run** and rule H3 forbids pinning what moves for correctness-unrelated
#   reasons. `addrOf` prints a **per-run sequence number** instead: first distinct pointer is
#   `#1`, a pointer already seen reads back its own number. **Identity becomes a small stable
#   integer a `pop.sh` row can pin.** Certified: identical across three consecutive runs while
#   the raw addresses moved between them.
#   ⚠ **ITS BODY COLUMN IS CARRIER-PROOF AND THAT IS THE USEFUL PROPERTY.** The argument carrier
#   mints a fresh FIELD on every call — `apSrc` read `field=#1`, `#3`, `#8` across three asks —
#   but the BODY survived at `#2` throughout. So a body-column comparison can ask an identity
#   question **through** the carrier defect instead of being voided by it. **That is what
#   unblocked S3a, and it is offered to the step-5 asking for the same reason.**
#
#   **4. THE FOLLOW-THROUGH LAWS ARE RULED, AND TWO ROWS WERE PINNED AGAINST THE WRONG
#   MECHANISM.** Law 1 *print follows* · law 2 *subscript stops at the element* · law 3 *unary
#   binds tightest, `*a[0]` is `(*a)[0]`* · law 4 *name it, then star it*. `pointerT`'s L1 was
#   credited to the subscript and belongs to **print**; X was credited to *"one level too many"*
#   and is really the star **binding to the bag**.
#   ⚠ **THE VALUES NEVER MOVED — ONLY THE ACCOUNT OF THEM WAS WRONG, WHICH IS EXACTLY WHAT A
#   VALUE-PINNED ROW CANNOT CATCH.** X's witness had been in the output all along, unread:
#   `ERROR unary * on ptBagP -- it holds no group`. `pop.sh` now asserts that line **by its
#   text** (H4), because a row pinned only at 0 goes green the day the star binds the other way.
#   ⚠ **LAW 4's SPELLING IS `<-`, NOT `=`** — measured: rebind-then-star **follows**,
#   assign-then-star **refuses**. Rows L2/L3 are that pair, and L3 exists so the next reader who
#   writes the natural `=` does not conclude the law is broken.
#   ⚠ **LAW 2 IS NOT CERTIFIED** and `pointerT` says so rather than implying it.
#
#   ## `faceT` — THE PAIR FIXTURE, AND THE QUESTION IT ANSWERED FOR CLAY
#
#   **`noPrinT` lives in `GroupBody`'s `flags` — THE SHARED COLUMN.** `GroupItem`'s `options`
#   struct holds only `affiliation:2` and `isCopy:1`. So the charter's conditional resolves the
#   **other** way: `roundTripT` ARM B2 was **already a body-half arm**, never the field-half arm.
#   `faceT` adds the identity proof, the FORWARD direction (B2 only did reverse), and the column
#   census. **Flags round-trip both ways, 1/1.**
#   ⚠ **F1 IS LOAD-BEARING FOR EVERY OTHER ROW** — without it, *"the write round-tripped"* could
#   simply mean both names were one field, and the fixture would be a confident tautology. It
#   pins `field=#1` vs `#3` with `body=#2` both.
#   ⚠ **F4 IS RECORDED AS UNREADABLE, NOT AS A VERDICT.** `parent` is per-field and the charter
#   predicted it would not round-trip; **it cannot be read at all** — the capture yields a
#   data-less field, which returns its own tag (#26). **A PREDICTION THAT CANNOT BE MEASURED IS
#   NOT CONFIRMED BY FAILING TO MEASURE IT.**
#   ⚠ **The `options` and `rStuff` columns are ABSENT DELIBERATELY**: `isCopy` is visible only
#   through `addrOf`, which reports the **carrier** (every subject reads `isCopy=1`, originals
#   included), and an `rStuff` counter has no readable spelling today. Two more tag-echo rows
#   would have been green and asserted nothing.
#
#   ## THE CHANNEL RULE THIS DAY BOUGHT — WT-15, IN `docs/walkieTalkie.md`
#
#   **SCRIBE AT PICKUP, NOT AT LEISURE.** A dispatch is transcribed into `ipc/` **before** the
#   work it orders begins. SEQ 106–111 were each dictated, each acted on, and **not one was
#   scribed**; SEQ 106–110's words are gone and the channel carries a reconstruction NOTICE in
#   their place. SEQ 111 survived **by three minutes** — read out of the untracked, gitignored
#   `incant++` at 14:26, overwritten at 14:29.
#   ⚠ **SEQ 113 WAS SCRIBED AT PICKUP**, before any work started. The practice is live.
#
#   ## WHAT IS NEXT — SEQ 113's REMAINING ITEMS
#
#   **STEP 4, NOT STARTED.** `+*` at the sweep behind `gNoUnwrap` for bare mentions of the
#   action's own fields; the body reads `*argument`. **The step-3 finding is its argument** —
#   `+*` hands the callee the field, not a copy of it.
#   Then **step 5 and the asking** (`kant8T` K2x row 1 / K6c / `nestT`, pre-registered), then
#   the **try-and-buy**: flip `gNoUnwrap` on a branch, fleet + unitTests, `incant/utilities`
#   first, **classify reds by mechanism** — that pass IS the unitTests and `pop.sh` revision.
#   ⚠ **CLAY'S GRADED CANDIDATE STANDS, UNDRIVEN:** the callee's fresh, zeroed `rStuff` as the
#   account of `parser(Start)` not receiving Start — it received Start's body wearing a copy's
#   rule state. **`addrOf`'s body column is the witness that candidate did not have.**
#   ⚠ **OWED BY CLAY, NOT CLOD:** the Ruling A re-read against Tony's copy-of-a-field
#   definition, before step 5 is graded; and the SEQ 108 recon re-read after Finding 1.
#
#   ## ⚠ HOUSEKEEPING A FRESH SESSION SHOULD KNOW
#
#   - **`gNoUnwrap` is 0** and the bare binary is verified live — it was flipped to 1 to grade
#     S3a and flipped back, with a rebuild each way. **Never measure anything else on a flipped
#     or directives build.**
#   - **The fixit queue is 1** — `carrierNode`, since 2026-08-31. **It is the gate, and step 3
#     was its work.** There is no separate step-one errand.
#   - **Off-repo, this session only:** the iCloud `Documents` twin was scrubbed after a verified
#     458 MB copy to `~/iCloudDocs-retired-2026-09-01`; three unique files were rescued into
#     `~/Documents` first. CG's wiki draft lives in `~/Documents/Wiki` with a browsable HTML
#     pair regenerated by `makeWikiHtml.py` beside it. **None of this is repo material.**
#
# ⚠⚠⚠ SEALED 2026-09-01 — SEVENTEEN STROKES, AND THE ONE THING THAT DID NOT LAND WAS A
# MESSAGE. THE OPERATOR TABLE IS RE-RULED; THE CHANNEL LOST FIVE DISPATCHES AND NEARLY LOST
# A SIXTH BY THREE MINUTES.
#
#   ⚠ DATE DISCIPLINE, RUN BEFORE THIS MARK WAS TYPED, per the standing check the seal
#   below minted: `date` reads **Tue Sep  1 14:34 EDT 2026** and `git log -1 --date=iso`
#   stamps **2026-09-01 14:33**. They agree. This seal's date is MEASURED, and it is the
#   first one that can say so.
#
#   ⚠ VOCABULARY, TONY'S RULING (SEQ 112): this seal is written in **field** and **copy of a
#   field**. Not "node", not "frame". Where a commit message says "frame bind", read **the
#   argument channel**; the old word is kept only in the commit trail it was written into.
#
#   ## THE ONE-LINE STATE: **Seventeen strokes plus a WIP commit. `+*` became a real pointer
#   operator, `**` stopped being an operator at all, seven operators learned to refuse a null
#   operand by name, and two premises the campaign was resting on fell out. The session was
#   stopped by a usage wall at 11:15, one word short of step 3 — so the machine is clean and
#   the CONVERSATION is what broke.** Fleet **138 green / 1 parked**, expected-red **3**
#   (unchanged). Canary **325**. Frontier **exit 0, nine stations, 10 PASS**. decodePop 22/82 ·
#   ddPop 6 · countPop 39/39 · formsPop 14. Both repos **0 dirty / 0 unpushed**. Every retok
#   BARE. Binary **11:06**, newest source **11:05** — current, not stale.
#
#   ## ⚠⚠ THE SIX THINGS A FRESH READER MUST NOT RE-DERIVE
#
#   **1. `+*` IS `opAddPointer` AND `**` IS NOT AN OPERATOR (C16, C17).** `a +% b` adds a
#   **copy of a field**; `a +* b` adds a **pointer to** that field, read back with a subscript,
#   which already follows it. `**` left BOTH the operator table AND the `UnaryOPS` bin — it was
#   in two places, which is why one removal was not enough — so `**x` is now `*` twice.
#   `opCopyList` and `opDerefAll` retired at **zero call sites each**, censused before removal.
#   `copyListTo` is frozen substrate and did not move. Canary **326 → 325**, fully accounted:
#   −2 retired, +1 added.
#   ⚠ **`+*` WAS NEVER MINTED.** It had been bound in `incant/setup` since before this charter,
#   meaning "copy the argument's list", with **no users anywhere in the corpus**. So the spacing
#   law was certified against an operator that already existed, and nothing was added to the
#   tokenizer to ask the question.
#
#   **2. ⚠⚠ `+%` DOES NOT ISOLATE — AND A PLAN WAS RESTING ON IT.** `pointerT`'s anti-vacuity
#   twin expected a **copy of a field** not to see later writes to its source. **It sees them**,
#   measured identically with the flip ON and OFF, so this is not the flip: `+%` already shares
#   the source's `GroupBody` (`Bytecode.twk:77` says so outright). **The copy-versus-pointer
#   difference is THE LINK, not the contents.** The SEQ 108 recon's framing — *can `+%` hand the
#   body a reference instead of a copy?* — is answered *it already does, at the body level*, and
#   **the re-read is Clay's; nothing is owed from Clod** (SEQ 112).
#
#   **3. ⚠⚠ `starT` S3a IS UNGRADED, AND SEQ 112 SUPPLIES THE MISSING WITNESS.** Under the flip,
#   `**x` on a one-deep pointer READ where the law says the second star must refuse. Both
#   witnesses were void: **printing a pointer follows the chain**, so a value witness cannot
#   separate one-level from to-the-leaf; and the identity witness — pass it to an action, print
#   `argument.taG` — returns `argument`, because **a tag read through an action-argument holder
#   yields the holder**. The instrument needed to certify the star law was blocked by the very
#   defect this campaign exists to fix. It was reported unmeasured rather than graded, per the
#   refusal to grade a voided control. ⚠ **SEQ 112 ORDERS AN `addrOf` EXTERN — instrument,
#   canary-declared — so S3a separates the two by IDENTITY with no holder and no print. S3a is
#   gradeable and is owed.**
#
#   **4. F-41 — SEVEN OPERATORS REFUSE A NULL OPERAND BY NAME (C14).** `opPlus`, `opMinus`,
#   `opGT`, `opLT`, `opEQ`, `opGE`, `opLE` each gained `opMultiply`'s guard. A refusing unary
#   returns null, that null arrives as the next operator's right operand, and every
#   `argument.` read below it was a latent 139. **Certified by DRIVING each one** — eight rows
#   in `spacingT`, each asserted BY ITS TEXT (H4).
#   ⚠ **THE EIGHT ROWS ARE ONLY MEANINGFUL WHILE ROW A IS GREEN**, and that dependency is
#   written into `pop.sh` beside them: row A is the unary still refusing cleanly, and if it ever
#   starts succeeding there is no null, and all eight go green while asserting nothing.
#   ⚠ **GRADE KEPT HONEST:** the crash was MEASURED on `opMultiply` only (F-36). The other six
#   were censused **structurally** — zero guards against 3–6 dereferences each — and guarded on
#   that basis, not on six separate crashes.
#
#   **5. THE FOLLOW-THROUGH LAWS ARE RULED AND TWO ROWS ARE PINNED AGAINST THE WRONG READING.**
#   Tony, 2026-09-01: **print follows** — a field holding a pointer prints its group;
#   **subscript stops at the element**; **unary binds tightest**, so `*a[0]` is `(*a)[0]` and
#   refuses on a `+*` list; **the read of a pointer out of a list is name it, then star it.**
#   ⚠ These arrived in the dispatch that never landed, so `pointerT` rows **L and X are pinned
#   against Clod's own reading, not against these laws.** Two green rows are currently asserting
#   something Tony did not rule. **They re-pin as part of step 3's stroke.**
#
#   **6. ⚠⚠ THE CHANNEL IS WHAT FAILED, NOT THE MACHINE — FIVE DISPATCHES LOST, A SIXTH SAVED BY
#   THREE MINUTES.** SEQ 106 through SEQ 111 were dictated in chat and acted on; **not one was
#   scribed into `ipc/clay-to-clod.md` at the time.** SEQ 106–110's words are **gone** — the
#   channel now carries a **reconstruction NOTICE** in their place, built from the commits that
#   cite them, and it says in terms that it is evidence about what was DONE and never about what
#   was SAID. **None of it may be cited as Clay's.**
#   ⚠ **SEQ 111 SURVIVES ONLY BECAUSE OF A COINCIDENCE OF THREE MINUTES.** Its body was read out
#   of `IncantForms/WorkingOn/incant++` at **14:26** on the restart; Tony overwrote that section
#   at **14:29**. `incant++` is untracked and gitignored, so **there was no second copy anywhere
#   on disk** — the whole operator-table ruling, the star law, and both fixture charters would
#   have gone with it. It is transcribed verbatim now, with that provenance stated in the entry.
#   **THE RULE THIS BUYS: SCRIBE AT PICKUP, NOT AT LEISURE.** The channel's own doctrine already
#   said a finding recorded only in a commit message is recorded and simultaneously lost; this
#   is the same failure one register over, and it cost five dispatches before anybody counted.
#
#   ## ⚠ WHERE THE SESSION ACTUALLY STOPPED, so nobody reconstructs it twice
#
#   The 09-01 session ran **08:45 → 11:15** and was ended by a **usage wall**, not by a decision.
#   The last thing written was Clod's report at the foot of `incant++`, and it ends:
#   *"Step 3 is next and unstarted — the mint-site capture: is the copy under the Token made by
#   the sweep at `ruleActions.rtn:459`, or already present from parse and merely copied again?
#   One capture, address reported before any sweep edit. **Say go.**"*
#   **Nothing was in flight** — no half-edit, no uncommitted build, no running agent, no staged
#   index, no merge or rebase state in either repo. The wall caught the conversation, not the
#   tree. **The go arrived in a dispatch that never reached disk**, which is why the restart cost
#   a reconstruction instead of a resume.
#
#   ## THE NUMBERS, MEASURED AT 14:34 ON THE RESTART — NOT CARRIED FORWARD FROM C17
#
#   ```
#   pop.sh          138 green / 1 parked / 3 red      exit 1   (the pinned red set, unchanged)
#                     parseClass.target · oneTest baseline · jsonTest baseline
#   decodePop        22 checks, 82 terms                       PASSED
#   ddPop             6 green                                  PASSED
#   countPop         39 compiled clean of 39 attempted         SENTINEL reached
#   formsPop         14 checks                                 PASSED
#   frontier          9 stations RAN and PASSED, 10 PASS lines exit 0
#   canary           grep -c '^extern' GroupRules.h = 325
#   binary           11:06, 1427584 bytes; newest source 11:05 — CURRENT
#   Groups           0 dirty, 0 unpushed         (jit-unified-emit-wip)
#   support          0 dirty, 0 unpushed         (main; groups.ext committed at 4a4d61d)
#   fixit queue      1 — carrierNode, since 2026-08-31, lane parser, blast OVERLAPS
#   ```
#   ⚠ **THE THREE REDS ARE THE PINNED SET AND DID NOT MOVE ALL SESSION.** Read `parseClass.target`
#   past its first six lines, per the standing warning that a red row absorbs new breakage
#   silently.
#
#   ## ⚠ THE FIXIT LINE, AND IT IS NOT A SEPARATE ERRAND
#
#   **`carrierNode` is THE GATE, and step 3 is its work** (SEQ 112). There is no step-one-first
#   question to ask this session: the queue's single citizen and the campaign's next stroke are
#   the same stroke. Queue **1**, oldest **2026-08-31**.
#
#   ## WHAT HAPPENS NEXT — SEQ 112'S ORDER, (a) AND (b) NOW DONE
#
#   **(c) STEP 3, THE MINT-SITE CAPTURE.** At `ruleActions.rtn:459`: is the **copy of the field**
#   under the Token made by the sweep, or already present from the parse and merely copied again?
#   **One capture. The address is reported BEFORE any sweep edit.**
#   Then, in order: **steps 4–5** (`+*` at the sweep behind `gNoUnwrap` for bare mentions of the
#   action's own fields; the body reads `*argument`; the asking pre-registered with `kant8T` K2x
#   row 1, K6c and `nestT`), and **after step 5 the try-and-buy**: flip `gNoUnwrap` on a branch,
#   run fleet + unitTests, `incant/utilities` first, **classify reds by mechanism** — and that
#   pass IS the unitTests and `pop.sh` revision, done against the real red set rather than a
#   guessed one.
#   ⚠ **THE PRE-STEP-4 CHECK ALREADY PASSED** and does not need re-running: with `gNoUnwrap` ON,
#   `spacingT` G2 (`a + *b`) reads **12** and G (`a + **b`) reads **12**. A single `*` IS wired
#   to the flip.
#
#   ## ⚠ ONE PROCESS FAILURE, BANKED WHERE IT HAPPENED
#
#   **C16 carried only the `derefAllT` rename while its message described the whole stroke.** Its
#   `git add` listed a path that no longer existed, **the add aborted, and `2>/dev/null` hid it**;
#   the commit took what was staged. C16 was already pushed, so it was not rewritten — **C17 is
#   the body its message describes, and the two are one stroke.** Same family as the 08-08
#   sweep-up note: a commit that describes work it does not contain.
#   **The lesson, and it was applied to every commit after it:** read `git diff --cached
#   --name-only` BEFORE typing the commit, not after.
#
#   ## THE SEVENTEEN STROKES, IN ORDER
#
#   ```
#   C1   SEQ 103 transcribed; the seal date was never the clock
#   C2   Tony's fixit verdicts — four of goldenDrift's six discharge
#   C3   K2 could not answer the question K2 asks — the asymmetry is void
#   C4   the argument trample has a pointable one-statement cause, and it is NOT the carrier
#   C5   SEQ 98 to Clay — Part 1 done, Part 2 stopped on a measurement
#   C6   THE FIXIT CULL — queue 9 → 1, and two rules that stop it growing back
#   C7   R4 + carrierNode's new form; Part 2 stops at the scoping gate
#   C8   the argument channel binds — certificates 2 and 3 green, the trample fixed
#   C9   the fourth asking failed; the camera says the slot was never written
#   C10  frameArg stripped; the copy census answers the fork — ONE copy, not one per mention
#   C11  the copy bind fails its own control — arm 1's save/restore clause does not hold
#   C12  SEQ 108 recon items 1–2 — and item 2 CORRECTS Clod's own C10 census
#   C13  F-36 CLOSED — and the star was a red herring
#   C14  F-41 — all seven operators refuse a null operand by name
#   C15  step 2 — `+*` ALREADY EXISTED, so the law was certified without minting it
#   C16  +* IS opAddPointer, ** IS NOT AN OPERATOR — and two premises fell out
#   C17  SEQ 111's body — the operator table, both fixtures, and the re-pins
#   +    WIP (Tony): compileRules recursion → compileRules, not walkRules   [parser:68]
#   ```
#   ⚠ **`parser:68` WAS ADJUDICATED, NOT INHERITED.** It was found dirty at the restart, mtime
#   09:30, and it is Tony's hunk: `compileRules` was recursing into `walkRules` on a
#   list-bearing field, so the deeper levels took the other walker. Ruled **commit as-is, not a
#   revert under any reading**. `parser` stays TRACKED — it is WIP with an end date, waiting on
#   the flip, which is the line that separates it from `incant++` and `tester`.
#
#   ⚠ **THIS SUPERSEDES THE SEAL BELOW (2026-08-31), WHICH IS INTACT AND TRUE AS OF ITS OWN
#   MARK.** Its "clean with no exception clause" state held through all seventeen strokes.
#
# ⚠⚠⚠ SEALED 2026-08-31 — THE THIRD ASKING FAILED INFORMATIVELY, AND THAT IS THE DAY'S
# HEADLINE. THE BIND IS EXONERATED ON CAMERA; ONE MECHANISM NOW EXPLAINS THREE MEASUREMENTS.
#
#   ⚠⚠ **DATE CORRECTED 2026-09-01 (SEQ 103 housekeeping). THIS SEAL WAS MARKED `2026-09-02`,
#   WRONG BY TWO DAYS — AND IT WAS *NOT* THE CLOCK. THE CLOCK IS THE ONE INSTRUMENT THAT HAS
#   BEEN RIGHT ALL ALONG.** The seal prose has been running AHEAD of the machine, and two
#   earlier seals diagnosed that backwards.
#
#   **THE PROOF, for this seal, independent of any earlier claim:** every commit this seal
#   describes is machine-stamped **2026-08-31 08:19–12:49 EDT** (`R1`…`R20`, the seal commit
#   `8fb096a`, and `2a947d2`); the machine now reads **2026-09-01**; and **Tony's own calendar
#   agrees at 09-01**. That timeline is monotonic and ~20h wide, so a clock two days *behind*
#   on 08-31 would put today at 09-03, which Tony says it is not.
#
#   **THE DRIFT LEDGER — each seal's claimed date against the machine stamp on its own commit:**
#   ```
#   claimed 2026-09-02   commit 08-31   +2      <- this seal
#   claimed 2026-08-31   commit 08-30   +1      <- the seal below; ALSO mis-stamped
#   claimed 2026-08-29e  commit 08-29    0
#   claimed 2026-08-29   commit 08-28   +1
#   claimed 2026-08-28   commit 08-27   +1
#   claimed 2026-08-27   commit 08-26   +1
#   claimed 2026-08-25   commit 08-25    0      <- and 08-23, -22, -21, -20, -19 all 0
#   ```
#   ⚠ **SO THE SEAL BELOW IS MIS-STAMPED TOO — its true date is 2026-08-30 — and the two seals
#   do NOT both belong to one day.** It is left as written rather than rewritten, per the
#   standing rule that a dated record is not restated to match a later finding; **read it as
#   08-30.** Same for `ipc/clay-to-clod.md`'s **SEQ 100** (`2026-09-01`) and **SEQ 101 /
#   SEQ 102** (`2026-09-02`): all three were transcribed in the **08-31** session. Read them
#   as 08-31.
#
#   ⚠⚠ **AND THE FINDING WORTH MORE THAN THE DATES: THE 08-27 AND 08-28 SEALS' "the machine
#   clock read a day behind" NOTES WERE POINTING AT THE WRONG INSTRUMENT.** Both sit in the +1
#   band above, and the note "retired" on 08-29 exactly when the drift happened to fall to zero
#   — which reads as the clock correcting itself and is equally consistent with the prose
#   landing on the right day by accident. **The unreliable instrument is the seat's inherited
#   sense of the date, not the machine** — and the machine is the only one of the two that
#   leaves a checkable stamp on every commit.
#   ⚠ **GRADE, stated because this file's own doctrine demands it: the top row is MEASURED
#   against Tony's calendar. The older rows are a CONSISTENT PATTERN, not independently
#   confirmed** — nobody has a calendar witness for 08-26, and none is now obtainable.
#   ⚠ **The standing check is one command, and it is owed before any seal mark is typed:
#   `date` beside `git log -1 --date=iso`.** A seal date is a measurement like any other; this
#   one was being written from memory for six seals running.
#
#   ⚠ **THIS SUPERSEDES THE SEAL BELOW (marked 2026-08-31, truly 08-30), WHICH IS INTACT AND
#   TRUE AS OF ITS OWN MARK.**
#
#   ## THE ONE-LINE STATE: **Twenty-two commits of little steps that compounded — the flip's
#   blocker is now a filmed mechanism instead of a hypothesis, two getters lost their side
#   effects, `tokenize` retired in full, the audit gate stopped demanding the impossible, and
#   the tree is CLEAN WITH NO EXCEPTION CLAUSE for the first time since mid-August.** Fleet
#   **88 green / 1 parked**, expected-red set **3** (was 4). Canary **326**. Frontier **exit 0,
#   10 PASS**. decodePop 22/82 · ddPop 6 · countPop 39/39 · formsPop green. Both repos
#   **0 dirty / 0 unpushed**. Every retok BARE.
#
#   ## ⚠⚠ THE SIX THINGS A FRESH READER MUST NOT RE-DERIVE
#
#   **1. THE THIRD ASKING FAILED, AND THE CAMERA CHANGED THE QUESTION.** `parser(Start)` still
#   receives a carrier — but the bind is **exonerated on film**:
#   ```
#   CARRIERCAM bind   ruleArg=0x100651780 ruleArgBody=0x100652960 -> resultBody=0x100652cd0
#   CARRIERCAM after  ruleArgBody=0x100652cd0        THE BIND WORKED
#   BODY  argument    node=0x100657540  body=0x100652960   THE CALLEE READS ANOTHER NODE
#   ```
#   One unwrap of the carrier yields **nothing** — "holds no group". Legacy's else-arm sets
#   `setGroup`; the flip skips it and the body adoption lands elsewhere, so the read node ends up
#   with **neither**. ⚠ **NEITHER PRE-REGISTERED CANDIDATE SURVIVED.** The replacement question
#   is narrower: *which road mints the node the callee reads, and when.*
#
#   **2. PART 1 ANSWERED IT: MINT → BIND → READ, and the mint and bind are ALREADY different
#   nodes** (0x100ced8c0 vs 0x100ced780, one body). **THREE nodes in play**, so the multi-node
#   problem starts earlier than the bind — which is the measured argument for moving the channel
#   to the FRAME rather than chasing identity across three roads.
#
#   **3. ⚠ IT IS ONE MECHANISM, MEASURED THREE TIMES ON THREE DAYS.** `roundTripT` (flag write vs
#   read), `broadcastT` (twin vs original), and now the argument bind: **a named read does not
#   reach a written node.** A fix aimed only at the argument road leaves the other two standing.
#
#   **4. THE GATE READS "AUDIT AT PIN", NEVER "AUDIT CLEAN".** The audit counts `isRule &&
#   !rStuff`, which Ruling D makes the lawful signature of a bare master, and SEQ 100's C3 table
#   showed **no reader needs rStuff off those ten**. Pinned **10/4** as a tripwire: 11 means a new
#   route is marking masters, 9 means an attachment road started constructing. `literalMasterIsRule`
#   discharged and retired on it.
#
#   **5. `tokenize` IS GONE — method, extern, mirror, GroupMain construction, every term.** Zero
#   firings measured; the succession is `tokened` → `captureSpan`, named in the code's own
#   comments. ⚠ **The H11 gap was closed by the DELETION, not waived** — a removal is the positive
#   control a counter cannot be. Odometer re-pinned 18/45/63; `tokenize` was one of the nineteen
#   genParse-GREEN rules.
#
#   **6. TWO GETTERS STOPPED BEING SETTERS.** `getRStuff` and `getGuard` are pure; `ensureRStuff`
#   and `ensureGuard` carry the construction by name. ⚠ **The `getRStuff` census was wrong by 133
#   sites** — tok's `#autoGetSet` binds every bare `.rStuff` read to it, and **the blast radius is
#   set by the out-of-repo mirror, not by the getter**: 8 sites before one `groups.ext` line, 137
#   after. `pop.sh` now pins the raw-read count as a drift tripwire.
#
#   ## WHAT MOVED
#   **RETIRED:** `tokenize` (in full) · `literalMasterIsRule` (by mapping) · the seal's
#   "but for Tony's two named files" clause · the 08-08 sweep-up trap (structurally).
#   **BORN:** `carrierNode` (the campaign's last citizen, evidence not hypotheses) ·
#   `roundTripT` · `sixShapeT` · `derefAllT` · `litToK` · `opDerefAll`.
#   **CLOSED:** F-35 (codegen drift from one out-of-repo line) · F-37.
#   **OPEN:** F-34 (kant/C++ literal text) · F-36 (`* *x` crashes at 139).
#
#   ## ⚠ THE NEXT SEAT OPENS WITH ONE OF THESE, NEVER BOTH
#   **A — THE FRAME BIND (SEQ 102 Part 2).** Revert boundary is **R19**. The shape is
#   `parentLabel`'s, transplanted: slot on the frame beside `parentLabel`; caller evaluates args,
#   writes the slot, then calls (**write-last is load-bearing**); callee **lifts into a stack local
#   at entry, first line**. No save/restore — a handoff window, not storage. Certificates
#   pre-registered in `carrierNode`'s RULED block: the asking on camera, an A→B→A recursion
#   fixture, an f(g(x)) nesting fixture, and `parseRule`'s owed lift. ⚠ **It is a `RuleStuff`
#   LAYOUT change — bear-trap #10: `groups.ext` sync AND `tokall`, or it fails silently.**
#   **B — THE COMMENT SWEEP of `ruleActions.rtn`** (1,714 lines, 37 externs, ~35 blocks).
#   ⚠ **RECONCILE FIRST: `docs/commentMinion.md` is SIGNED with schema v2 and Tony's own
#   METHOD-SCOPED-NOT-FILE-SCOPED amendment; tonight's exemplar uses `TokFiles`. TWO CONVENTIONS,
#   ONE JOB** — and the two-line question from `opDot` is unruled. Ten-minute ruling, then a
#   minion can run it mechanically.
#
#   ## NON-GOALS, so they do not creep
#   The flag-write and addGroup-twin roads stay as ruled. The operand-pickup unwrap (#35's arms,
#   `derefT`'s non-motion) is **the second gate, separately chartered.** `opDebug`'s unwrap strip
#   re-rides whichever stroke carries the flip.
#
#   ## ⚠ THREE PROCESS FAILURES, RECORDED BECAUSE THEY WERE MECHANICAL AND MINE
#   `git add -u` swept Tony's WIP into a commit that then described work it did not contain
#   (fixed structurally — both files untracked). A fleet run **chained into the commit command**,
#   so an 85 scrolled past above an already-made commit. And an instrument reverted in **source
#   but not binary**, which is what produced that 85. **The rule earned: the fleet run is its own
#   step, read before the commit is typed.**
#
#   Tony's fixit incantations waiting: 8 (oldest: kantGenPath, since 2026-08-24)

# ---

# ⚠⚠⚠ SEALED 2026-08-31 — THE ACCEPTANCE LINE WAS NOT ASKED A THIRD TIME. THE SPLIT IS
# BLOCKED ON A FLAG THAT WILL NOT ROUND-TRIP, AND THAT IS UPSTREAM OF EVERYTHING TRIED.
#
#   ## THE ONE-LINE STATE: **Three split attempts, three reverts, and today the instrument
#   finally named something upstream of the search space — under the split a node cannot read
#   a flag it just had set.** Fleet **86 green / 1 parked**, red set byte-identical to
#   stroke-open. Canary **325**. Frontier **exit 0, 10 PASS**. decodePop **22 checks / 82
#   terms**. ddPop **6 green / 31 records**. countPop **39/39**. Switch at **0**, probes
#   **zero**, every retok BARE. Both repos clean and pushed but for Tony's two named files.
#
#   ## ⚠⚠ THE FIVE THINGS A FRESH READER MUST NOT RE-DERIVE
#
#   **1. THE ACCEPTANCE LINE'S VERDICT IS "NOT ASKED".** It was asked twice before and failed
#   both times on `parser(Start)` receiving a carrier. Today it was never reached: certification
#   is gated on the audit number and the audit never came clean, so the flip did not re-arm and
#   `acceptStartT` stayed parked. **Not asked is not the same as failed, and the seal says so
#   rather than implying a third failure.**
#
#   **2. THE MECHANISM IS ONE LEVEL ABOVE WHERE THREE STROKES LOOKED.** `broadcastT`'s ARM 3 —
#   its anti-vacuity control, *did the write land on the original at all* — **FAILS under the
#   split**. `x :. noPrinT` then `x.noPrinT` does not round-trip on the same node. Every other
#   arm is downstream of that, so the columns, the stamp, the roads and the writers were all
#   being measured through a void control. **A three-line round-trip fixture is the next
#   stroke's first build.**
#
#   **3. THE WRITER FIX WAS A NO-OP, AND THAT IS THE PER-SITE CHECK'S ANSWER.** All three late
#   writes are already at the earliest moment their inputs exist — the bin write sits inside
#   `aCTionDefinE`'s attachment walk, and `setRuleStuff`'s two arms derive from `registry` and
#   `parent`, both set at attachment. Nothing to relocate. **A derivation cannot be asked before
#   its answer exists**, and these are asked exactly when it does.
#
#   **4. `isVirtual` AT STAY IS RIGHT AND WAS NOT THE HANG.** Re-homing it was the standing
#   hypothesis; the hang survives with it firmly in the body and the `copyOf` rider reverted.
#   **`kant8T` times out at 90s.** The ruling is correct on its own terms — it is a mechanism
#   flag — and that hypothesis is dead. Do not re-run it.
#
#   **5. THE BROADCAST IS REAL AND MEASURED, AND THE LAW OUTLAWS IT.** ARM 2b read 1 on the
#   legacy binary: a late write to a shared body reaches every node sharing it. Ruled the same
#   day — identity set at definition, post-definition writes user-beware with a squawk — so
#   **post-mint silence is the law working, not a regression.** `incant/broadcastT` ships as a
#   tripwire pinned to the pre-law answer; it goes red when the fix lands, which is when
#   somebody should be looking.
#
#   ## WHAT MOVED
#   **BORN:** `probePlacementInheritsConclusion` (a probe downstream of its predicate sees one
#   outcome) and `parentStampOnRealNode` — decoder lines, problem records, rendered.
#   **RETIRED:** `parentStamp`, unreproduced, queue 9 → 8. 33 measured arrivals at opDot's
#   substituting cases, dangerous event zero. **Its coupling claim was STRUCK, not archived.**
#   **DOCTRINE:** two rows in `hookRules.md` — probe placement, and `!` exonerated a second time
#   with the capture convicted twice.
#   **BUILT AND KEPT:** `incant/broadcastT`, the timing oracle — one second where the fleet took
#   ten minutes and hung.
#
#   ## THE NEXT STATIONS
#   1. **The three-line round-trip fixture.** Set a flag, read it back, same node, under the
#      split. Upstream of every other question.
#   2. The split re-attempt, unchanged in shape, once round-trip holds.
#   3. The flip, and the acceptance line's third asking.
#   4. **Fixit queue: 8 — the pledged hour ran today; parentStamp retired out of it.**
#
#   ## PARKED, WITH GRADES
#   `gMethod` (own ruling, against #34 and methodSlotFourReaders) · `lastREF` channel redesign
#   (named ledger row, outside the charter) · the J-arm · `goldenDrift` clusters 2/3/4 (cluster
#   1 REMEDY; 3 narrowed to 08-02, four unbuildable commits, hand-read not bisect) ·
#   `parseSelfRecursion` retest-post-flip · `literalMasterIsRule` on its four-node remainder ·
#   `*` quarantined to fixtures until the flip certifies · the closing stroke's sweep list
#   (switch obituary, dead-flag census, `isPointer`'s whole-organism retirement).
#
#   ## TRIPWIRES ARMED
#   `incant/broadcastT` — pinned pre-law, goes RED when the propagation-writer fix lands.
#   `incant/acceptStartT` — parked, un-parks at the flip. `incant/derefT` — parked, re-pins to
#   R1 ≠ R2 at the flip.
#
#   Tony's fixit incantations waiting: 8 (oldest: kantGenPath, since 2026-08-24)
  lanes: parser 5 . genParse campaign 3   |   blast: OVERLAPS 4 . DISJOINT 4
  routing: OVERLAPS lands before the recon or rides the migration ledger; DISJOINT holds for the pledged hour

# ---

# ⚠⚠⚠ SEALED 2026-08-29, SECOND SESSION (EVENING) — THE GENERATED PARSE DISPATCHES AND CARRIES
# A TRUE FRAME. XPRESS IS ONE HUNG DOOR FROM WALKING. READ THIS FIRST.
#
#   ⚠ **TWO SEALS CARRY THE DATE 2026-08-29.** This is the SECOND. The one below it is the
#   isGROUP-poison session and is intact and true as of its own mark. ⚠ **AND THE CLOCK NOTE
#   RETIRES: the machine clock read correctly today.** Two consecutive seals carried a
#   clock-a-day-behind warning; this one does not, and commits are stamped 2026-08-29 truthfully.
#
#   ## THE ONE-LINE STATE: **Dispatch is proven four-deep on camera; the frame channel carries
#   four distinct true parents as dataflow; the 4364 verdict is honest — frame and attachment are
#   SEPARATE duties; Xpress is one unbuilt door from walking.** Fleet **75 green / 1 parked**, red
#   set byte-identical to yesterday's four. Canary **322**. Frontier **exit 0, 10 PASS**.
#   decodePop **22 checks / 80 terms**. ddPop **6 green / 29 records**. countPop **39/39 clean**.
#   Nine commits G1–G9, both repos pushed. **Fixit queue: 8 (oldest kantGenPath, 08-24) —
#   FOUR sessions unmoved, and it gets the first hour next session.**
#
#   ## ⚠⚠ THE SIX THINGS A FRESH READER MUST NOT RE-DERIVE
#
#   **1. THE EVICTION IS THE MECHANISM, AND IT WORKS.** Step 3 of the original brief — install the
#   parse INTO `gMethod` — is DEAD, killed by the `parseAction` finding. The replacement is
#   bear-trap #34's retirement clause: **vacate `gMethod`, install nothing.** With the slot empty
#   and `isMethod` retracted by the now-symmetric `setMethod`, `runOP` arm two stops claiming
#   rules, and a bare `QuotE()` falls through to the `isRule` arm → `runRule` → `builtinParsE`.
#   **The new parse wins by having no competitor.** Proof is a stack, not an absence:
#   ```
#   runOP -> runRule -> parseRule -> aCTionBlocK -> aCTionIF -> runShortCircuit
#         -> runOP -> runRule -> parseRule -> ...      (four levels deep)
#   ```
#   That chain cannot exist while `gMethod` holds the action, because arm two claims the call first.
#
#   **2. ⚠ THE PARK HAD TO REACH THE MASTER, AND THE REFUSAL FOUND IT.** `rStuff` is PER NODE,
#   `groupBody` is SHARED. `setParse` parked `actionMethod` on whatever FACE it was handed; the
#   walk calls it on member TERMS; the eviction sweep reaches the MASTER. So the verified copy and
#   the slot to be nulled sat on **different nodes**, and `evictAction` refused **nine of ten**
#   cohort rules rather than destroy an action nothing was holding. `parkOnMaster` (resolving
#   `definingRule()`) took it to **10 of 10**. **Additive, not a move** — the actor gate reads
#   `actionMethod` off the face, so parking only on the master would silently stop hanging
#   `builtinActoR` at all.
#
#   **3. ⚠⚠ A SINGLETON IS NOT A CHANNEL — AND THE CONTROL IS PRESERVED IN-ROW.** The frame's
#   first implementation resolved the parent from `ruler->ruleSTUFF`. It printed **ONE pointer for
#   all four invocations** (the driver's own `BlocK`, stale) where four distinct were
#   pre-registered. Reading the holder's own `rStuff.label` — `runRule`'s existing argument —
#   prints four distinct labels, **on the same line as the stale singleton pointer**, which is why
#   `frameProbe` was KEPT rather than deleted as scaffolding. **A doctrine row whose control has
#   been thrown away is a claim nobody can re-check.**
#   ```
#   PARENTPROBE Xpress      parentLabel=0x103536c00  ruleText     <- the argument holder
#   PARENTPROBE ExpressioN  parentLabel=0x103560b00  InvokeArg
#   PARENTPROBE Token       parentLabel=0x103563700  InvokeArg
#   PARENTPROBE QuotE       parentLabel=0x103565340  InvokeArg
#   ```
#   Morning: all four `0x0`. Mid-evening: all four one stale `BlocK`. Now: four distinct, correct.
#
#   **4. THE FRAME-BYPASS MECHANISM, WITH ITS ADDRESS.** `parse()` documents `rStuff.parentLabel`
#   as FRAME and its fork carries the comment *"THIS LINE IS ITS SINGLE WRITER"*. The new-parse
#   road dispatches `newParse.method(rule)` **straight at `builtinParsE` and never calls
#   `rule.parse()`**, so it never crossed the writing line. The channel existed; the road did not
#   write it. Fixed by EXTRACTION, not duplication: `GroupItem::establishFrame` is one BODY with
#   two call sites, and the fork's comment now says exactly that so it cannot decay into a lie.
#   ⚠ **THE DISCIPLINE IS NOT SAVE/RESTORE.** There is none, and the incumbent had none — a bare
#   write immediately before the call. **Recursion safety lives in the CALLEE**, which lifts
#   `parentLabel` into a stack local at entry before descending; the emitted methods do it on their
#   first line. **`parseRule` does NOT lift today**, and the lift is owed AT ENTRY when the door
#   reads the frame.
#
#   **5. ⚠ 4364's VERDICT IS HONEST NOW, AND IT IS "SEPARATE DUTIES".** `interpretXP`
#   (`GroupRules.mm`) dereferences `xpList->groupBody->groupList->listLength` unguarded and dies.
#   It **fires unchanged under a true frame**, same five frames — so the orphaned-action mechanism
#   is NOT explained by the missing frame, and frame and attachment are separate duties as
#   designed. ⚠ That verdict was refused twice off broken gauges before being taken off a good
#   one. **No guard was added there, deliberately**: a null check converts a crash into whatever
#   an expression interpreter returns next, which is the silent-wrong-answer family.
#
#   **6. ⚠ THE DOOR WAS STOPPED DELIBERATELY, AND THE REASON IS SCHEDULING, NOT DIFFICULTY.**
#   `setParentLabel` is unbuilt. What remains — Measurement 4's **walker-attach retirement in the
#   same stroke the door goes live** — is the SILENT-FAILURE class: retire it wrongly and old-road
#   rules duplicate or drop attachments with nothing going red. The session's ledger holds three
#   mechanical slips caught **only by instruments**, which is exactly the state the 2026-08-08
#   doctrine routes away from silent-failure work. **Measurements 3 and 4 are read-only and resume
#   cold with nothing lost.**
#
#   ## WHAT MOVED
#   **BORN:** `methodSlotFourReaders` (repointing method has four readers) — status **open**,
#   decoder line + problem record + census. Its H11 control pair is pre-registered: any census of
#   this class must return `parseAction` AND `aCTionStatemenT` or it is void.
#   **ATTRIBUTED:** the P1 guard, by a one-arm revert-test Tony authorised — `if actionMethod`
#   vs `if actionMethod && parseMethod` is **72 green vs 75**, and the three moved rows are the
#   isGROUP-poison detector family, which **named the disease in words** on its first independent
#   occasion.
#   **CLOSED:** the `gMethod` write side — three raw-write bypasses converted through the
#   now-symmetric setter; standing detector `grep -n "gMethod = " GroupRules.mm` reads **ZERO**.
#   **ABOLISHED:** `gNewParseInFlight`, with its obituary standing in `jitContext.h`. The capture
#   gate is now STRUCTURAL (`pMethod` — a property of the FIELD) where it was TEMPORAL (a global —
#   a property of the moment). Tony's objection to the `-%` spelling was the better instinct: **the
#   awkward spelling was the symptom of a guard asking its question about the wrong subject.**
#
#   ## MINTS
#   - **THE SINGLETON DOCTRINE ROW.** Per-invocation facts travel as **dataflow**, or as
#     write-then-lift **adjacency**. A distant read of shared state answers *"what happened last"*,
#     never *"who is asking"*. Funded by four identical pointers where four distinct were
#     pre-registered; **control preserved in-row** in `frameProbe`.
#   - **⚠⚠ BEAR-TRAP: A DECLARATION INTRODUCED INTO A tok FUNCTION RE-BINDS EVERY BARE MEMBER NAME
#     IN SCOPE — INCLUDING LINES ABOVE THE INSERTION.** tok resolves a bare field name against
#     whichever DECLARED field owns that member, later declaration winning. Adding two locals to
#     `setParse` silently re-pointed every bare `parseMethod`, `actionMethod`, `upTo` and `data` in
#     the rest of the function onto the new declarations: **the rStuff refusal began testing the
#     wrong node and the whole classification switch began writing the master's slot.** It compiled
#     clean and the fleet would have run green. Caught **only** by reading the generated `.mm`.
#     **ENFORCEMENT: cross-node work in a declared-field function goes in a SEPARATE FUNCTION — a
#     call introduces no declaration.** `parkOnMaster`, `frameParent` and `frameProbe` all exist in
#     that shape for this reason and say so in their headers.
#   - **THE MASTER/FACE SEAM ROW, FOUR SIGHTINGS:** Ruling D, bear-trap #34, `methodSlotFourReaders`,
#     `evictAction`'s nine refusals.
#   - **TWO RENT COLLECTIONS.** `percentMinusClosesPassthrough` — a `%-` width specifier inside a
#     `-%` block **is** the terminator; tok exited 139 with the extern canary at **ZERO**, and the
#     register turned an hour into one bisect. And **bt36's backward read** on the crash frame.
#   - **TWO GUARDS FIRED CORRECTLY ON FIRST CONTACT:** the fleet's poison detector on the `:300`
#     revert, and `evictAction`'s structural relocate-then-null on the nine unparked rules.
#
#   ## THE NEXT STATIONS
#   1. **`kantGenPath` — FIRST HOUR, four sessions unmoved.** Discharge staged behind the Start walk.
#   2. **The door.** `setParentLabel` reads the frame; Measurements 3 (return census, `testAction`
#      and refusal spellings named) and 4 (walker attach traced) resume as written; **walker's
#      attachment retires in the same stroke, verified against duplication on an OLD-ROAD rule**;
#      the `parseRule` entry lift lands with its reader.
#   3. **Start's walk is Tony's**, triage map standing: **keyword-name** (9 refusals — `if()`,
#      `while()`, `print()` parse as the KEYWORD, which is what Step 4's `parseR` fixes) /
#      **empty-conjunct** (18 refusals — rules with neither data nor walkable members emit `if ;`;
#      **no step on any page addresses this**) / **parseAction-cohort** (`DEFINing`, `PRINTing` —
#      the Start-only intersection) / **fourth-column unknowns, which OUTRANK all three.**
#   4. `verifyParse139` stands as its own citizen, NOT discharged as downstream.
#
#   ## THE SEAL CHECKLIST, run 2026-08-29 evening ON A BARE REBUILD
#   ⚠ **AND THE REBUILD EARNED ITS KEEP ON THE FIRST COMMAND.** A bare retok moved `GroupRules.mm`
#   by exactly one line — `frameProbe(...)` → `::frameProbe(...)`, tok emitting the global
#   qualifier once the extern was declared in `groups.ext`, which landed AFTER the previous retok.
#   No behaviour change, but **the committed artifact was not what its own sources generate**, and
#   a certify-from-memory seal would have recorded a green checklist over a stale file.
#   Bear-trap #11's family in miniature: `groups.ext` affects **codegen**, is out of repo, and can
#   never appear in a Groups `git status`. **Rebuild THEN certify.**
#
#   fleet **75 green / 1 parked**, red set byte-identical to the four (`parseClass.target`,
#   `rStuff audit`, `oneTest baseline`, `jsonTest baseline`) · frontier **exit 0, 10 PASS, first
#   failing station NONE** (⚠ still unrevised — the standing finding that it has fallen behind the
#   campaign holds) · decodePop **22 checks / 80 terms** (re-pinned +1, seventeenth, term named) ·
#   ddPop **6 green / 29 records** · countPop **39/39 clean** · canary **322** (+3: `evictAction`,
#   `parkOnMaster`, `frameProbe` — all declared in `groups.ext`) · `groups.ext` **committed, three
#   commits, per the 08-25 rule** · both repos **0 dirty / 0 unpushed** but for Tony's
#   `IncantForms/WorkingOn/incant++`, which is his status report and commits with his session ·
#   every retok BARE.
#   **Tony's fixit incantations waiting: 8 (oldest: kantGenPath, since 2026-08-24)**

# ---

# ⚠⚠⚠ SEALED 2026-08-29 — THE isGROUP POISON HAS A MECHANISM AND IS DEAD, THE INSTRUMENT THAT
# WAS ITS BIGGEST VICTIM IS RESTORED, AND THE FLEET GREW A DISEASE-CLASS DETECTOR. READ THIS FIRST.
#
#   ⚠ **THIS SUPERSEDES THE 2026-08-28 SEAL BELOW, WHICH IS INTACT AND TRUE AS OF ITS OWN MARK.**
#
#   ## THE ONE-LINE STATE: **`parser(ANYorNum)` goes 4-refused to 0-refused on a ruled one-line
#   fix; `incant/parseClass` goes from 63 errors and a quarter of its census to zero errors and all
#   of it; the fleet is 75 green / 1 parked (was 67, +8 rows, no row changed state); one id was
#   born and discharged inside the session; and SEQ 2 is off `working` after 25 days.** Canary
#   **319**. Frontier **10 PASS, first failing station NONE**. decodePop **22 checks / 79 terms**.
#   ddPop 6. countPop **39/39 clean**. All repos clean and pushed. **Fixit queue: 8 (oldest
#   kantGenPath, 08-24) — and it did NOT move today, see item 6.**
#
#   ⚠ **CLOCK NOTE, SECOND SESSION RUNNING: the machine clock read 2026-08-28 all day while the
#   work was dated 08-29.** Every commit from this session is stamped Aug 28. Do not read that as
#   the previous seal's day.
#
#   ## ⚠⚠ THE SIX THINGS A FRESH READER MUST NOT RE-DERIVE
#
#   **1. THE POISON WAS ONE ARM, ATTRIBUTED BY A THREE-ARM PROBE, AND IT IS FIXED.** `setParse`
#   takes `actionMethod = method` ABOVE its data switch, and the switch's isGROUP case sets
#   `parseMethod = null` — so an isGROUP alias came away with an ACTOR AND NO EXECUTOR, and that
#   half-installed executor broke every later parse of any grammar the alias could be reached from.
#   Three aliases carry it: **ANYtoken, NewGroup, ShortcuT**, and `ANYtoken` sits under
#   `TokenXP → ANYorNum`, which every expression parse crosses. One rebuild per arm:
#   ```
#   arm 1  suppress the builtinActoR attachment, keep the assignment   4 -> 0 refused   THE POISON
#   arm 2  keep the attachment, null the persisted actionMethod        4 -> 4 refused
#   arm 3  suppress updateContentFlags                                 4 -> 4 refused
#   ```
#   **EXACTLY ONE ARM CLEARS IT**, which is what makes it attribution and not correlation. Clay
#   pre-registered arm 3 or arm 1 with arm 2 harmless: arm 1 confirmed, **arm 3 falsified**, arm 2
#   harmless as predicted. Fix is `if actionMethod && parseMethod {` — the parked pointer STAYS
#   (arm 2 says it is harmless and it is wanted the day an alias gains a real executor).
#   ⚠ **ARM 2 NEEDED A CONSTRUCTION THE BRIEF DID NOT DESCRIBE:** suppressing the assignment
#   outright also suppresses the attachment, which is gated on it, so the two arms would have been
#   confounded. Arm 2 keeps both and nulls `rStuff->actionMethod` after.
#
#   **2. ⚠⚠ THE INSTRUMENT WAS THE DISEASE'S LARGEST VICTIM AND NOTHING SAID SO.**
#   `incant/parseClass` had been emitting **63 `reached end of input` errors every run** and walking
#   **66 of its 239 census rows** — three quarters gone, at exit 0, with its sentinel printing.
#   After the fix: **0 errors, 237 rows, 118 distinct tags against 66.** Its "poisons the loader"
#   header folklore now carries the address. **DOUBT THE INSTRUMENT HARDEST WHEN IT IS THE ONE
#   INSTRUMENT POINTED AT THE THING YOU ARE HUNTING.**
#
#   **3. ⚠ `parseClass.target` IS STILL RED AND WAS DELIBERATELY NOT RE-PINNED.** Its remaining
#   ~60-line diff is entirely Tony's punctuation rename plus parked `HeX` — literals to
#   `leftParen`/`rightBrace`, `e`→`exponent`, `CodE`→`CodeBody`, and `followedBy`/`SemI`/`Modifier`/
#   `nameSet`/`numberSet`/`while` moving off `parseSet`/`parseString` onto `parseRule`. Re-pinning
#   would ALSO assert the six punctuation `NO-rSTUFF` rows are correct, which is the exact thing
#   under ruling in `literalMasterIsRule`. **B3/B4 unlocks it; do not re-pin it before then.**
#   ⚠ **AND THE ROW HAD BEEN READ AS ITS FIRST SIX LINES FOR WEEKS** while the census fell 239→66
#   underneath them. **A red row absorbs new breakage silently, because nobody diffs a diff.**
#
#   **4. THE ACTION-PARKED CENSUS — TONY'S RECON ANSWER, ON THE COMPLETE WALK.** `setParse` parks
#   `actionMethod` for EVERY rule it claims, not only `parseRule` ones. Of 237 rows: parseRule 65
#   parked / 74 none, parseAction 8 / 0, **isGROUP-none 7 parked**, and **ZERO parked on every
#   label-work executor** (parseString 37, parseSet 16, parseContainer 4, parseUpTo 2,
#   parseCharacter 1, parseAny 1). **So none of them is owed a `runRuleAction` tail today** —
#   `BrancheS` is `parseContainer`, `act=none`, exactly as Tony read it. ⚠ The safety is MEASURED,
#   not structural, which is why P2 pins it.
#   ⚠ **AN EARLIER REPORT OF THIS CENSUS SAID 66 ROWS AND IS CORRECTED HERE** — it was taken on the
#   truncated run. **The conclusion is unchanged; only the magnitudes moved.**
#
#   **5. BEAR-TRAP CANDIDATE, MEASURED WITH CONTROLS: A `(…#)` LITERAL WHOSE OPENING LINE ENDS
#   RIGHT AFTER THE `(` KILLS THE PARSE.** `name=(one line#);` parses · `name=(first\n second#);`
#   parses · `name=(\n second#);` **BREAKS**. It took `ddPop` 6 green → 3 with
#   `ddGate sentinel MISSING` and its H7 control going vacuous, and the symptom is bear-trap #32's
#   misdirection exactly: `RunRulE: expected a method not DisplayDesignHTML` names the FIRST entry
#   in the file, which is healthy, at exit 0. **Bisect by removing later entries.**
#
#   **6. ⚠ THE FIXIT QUEUE IS 8 AND DID NOT MOVE. A RELAY SAID 8 → 7 AND WAS READING A CITIZEN THAT
#   NEVER EXISTED.** `isGroupActorPoison` was minted as a **problem record + decoder line only** —
#   it never had a file in `incant/fixits/`, so its (correct, ruled) retirement discharges the
#   RECORD and moves the directory not at all. The queue stands at 8, oldest `kantGenPath`, and
#   `fixitNag.sh` says so. Generated, not typed — which is why the discrepancy was visible.
#
#   ## WHAT MOVED
#   **BORN AND DISCHARGED IN ONE SESSION:** `isGroupActorPoison` (half-installed executor on an
#   alias) — status **remedy**, verdict written, `reviewed` closed. ⚠ **The record KEEPS its table
#   and discharge evidence by Tony's explicit instruction: it is trimmable by the gate and is NOT
#   to be trimmed.**
#   **BORN AND ESCALATING:** `verifyParse139` — `parser(PrintXP)` and `parser(ExpressioN)` **STILL
#   exit 139 after the fix, signature identical** (PARSER SENTINEL · WITNESS compiled 1 · death).
#   So it does NOT discharge as downstream-of-poison. **It is the campaign's last orphan with no
#   mechanism.** Next measurement named and NOT taken: a backtrace under `script -q /dev/null`,
#   read one line BACKWARD from whatever it names (bt36).
#   **REGRADED:** `parentUnreachable` **BEST GUESS → OPEN**, and **nothing is owed by Tony at that
#   grade** — a change from the version that asked him for a language addition.
#   **RELAYED:** SEQ 2 Part B ruling to the support minion; `ipc/support-to-clod.md` off `working`
#   after **25 days**. Part B is unblocked and NOT started; the campaign outranks it.
#
#   ## ⚠ `parentUnreachable`: THE GUESS WAS FALSIFIED BY ONE GREP, AND THIS IS THE SHAPE TO COPY
#   It said "add a parent accessor to opDot — up is the one missing direction". **`parenT` IS
#   opDot case 2**, registered in `incant/setup` as `parenT=2`, returning the real parent; the
#   wrapper behaviour was repaired 08-24 and `minionWork/probeCanonTopo`'s "returns a WRAPPER" note
#   is **stale**. Building it would have added a second parent road beside a working one.
#   **What is actually broken, measured in one process with a control column:**
#   ```
#   accessor      kind       direct      through an action-argument holder
#   .taG          property   fpInside    fpInside          ok
#   .texT         property   --          fpInside          ok
#   .listLengtH   property   4           4                 ok
#   .parenT       NODE       fpWindow    argument          BROKEN
#   ```
#   **READ THE COLUMNS.** Direct is right for everything, so the accessor works. Through the holder
#   every PROPERTY accessor is right and the NODE accessor hands back **the holder** — `runAction`
#   binds by `ruleArg.group = argument`, so an action's `argument` is a field POINTING AT the
#   subject. **A single-unwrap asymmetry between opDot cases, not a missing direction.** Contact
#   with G5's two-faces hypothesis on a second road; noted, not chased.
#
#   ## THE NEW DOCTRINE — RULE H12, in CLAUDE.md
#   **A LANDING RUNS THE FULL SEAL CHECKLIST, NOT THE FLEET ALONE.** No exception for an
#   "obviously neutral" edit — that is the class that forced it. A comment move landed under a
#   fleet-only check: **67 green before, 67 after**, because no fleet row reads `designDocs`, while
#   `ddPop` went 6 → 3. **A GREEN FLEET IS EVIDENCE ONLY ABOUT WHAT THE FLEET READS**, and "no
#   instrument reads what I touched" is a coverage finding, not a clean bill.
#
#   ## ⚠ THE FRONTIER HAS BEEN ALL-PASS FOR TWO SEALS, WHICH MEANS IT IS NO LONGER MEASURING AN EDGE
#   `incant/frontier` is 10 PASS / first failing station NONE, unrevised, exactly as on 08-28. **A
#   red frontier is its normal, correct state**, so two green seals running is a signal that the
#   file has fallen behind the campaign rather than that the campaign is finished. **Revising it is
#   real work owed.** The candidate edge, now that a single rule's nine stations all pass, is the
#   MULTI-RULE WALK — which is what `incant/anyOrNumT` exercises and what `verifyParse139` dies in.
#
#   ## THE NEXT STATIONS, in Clay's order
#   1. **The `verifyParse139` backtrace** — cheap, and it gives the campaign's last orphan a
#      mechanism. `script -q /dev/null`, read one line backward.
#   2. **B3/B4** — teach `auditMissingRules` the category, then re-pin. Carries the bonus of
#      unlocking `parseClass.target`'s re-pin and starting the expected-red set down from four.
#   3. **The widened opDot census** — every node-returning case, twice each, direct and through a
#      holder, every row paired with its direct sibling.
#   4. SEQ 2 Part B implementation, at Clod's sequencing. A6–A8, B5 at Tony's priority.
#
#   ## THE SEAL CHECKLIST, run 2026-08-29
#   fleet **75 green / 1 parked** (was 67; +8 rows, **red/park set byte-identical — no row changed
#   state**) · frontier **exit 0, 10 PASS, FIRST FAILING STATION: NONE** (⚠ not revised, and see
#   the section above — that is now a finding, not a note) · decodePop **22 checks, 79 terms**
#   (re-pinned +2, sixteenth, both additions named) · ddPop **6 green** · countPop **39/39 clean,
#   0 missing** · canary **319** · `groups.ext` untouched (mtime predates the session) · **all
#   repos 0 dirty / 0 unpushed but for Tony's two named-WIP files** · every retok BARE, so the
#   binary is the real program and not an instrumented one.
#   **Tony's fixit incantations waiting: 8 (oldest: kantGenPath, since 2026-08-24)**

# ---

# ⚠⚠⚠ SEALED 2026-08-28 — TONY'S OFFLINE WORK RE-BASELINED, THREE CITIZENS OFF THE QUEUE,
# AND THE isRule CENSUS KILLS OPTION B'S CHEAP FLAVOUR. READ THIS FIRST.
#
#   ⚠ **THIS SUPERSEDES THE 2026-08-27 SEAL BELOW, WHICH IS INTACT AND TRUE AS OF ITS OWN MARK.**
#
#   ## THE ONE-LINE STATE: **Tony's punctuation/rename work is landed and re-baselined; the fleet
#   is 67 green / 1 parked (was 61, +9 rows added, one lost to a ruling); the fixit queue is 7
#   (was 8, with three retired and two minted); and option B for `literalMasterIsRule` is measured
#   dead in its cheap form.** Canary **319**. Frontier **10 PASS, first failing station NONE**.
#   decodePop 77 terms / 22 checks. ddPop 6. countPop **39/39 clean**. All four repos clean and
#   pushed. **Fixit queue: 7 (oldest kantGenPath, 08-24).**
#
#   ⚠ **CLOCK NOTE FOR A RESURRECTION READER: the machine clock read 2026-08-27 all session while
#   the work was dated 08-28.** Every commit from this session is stamped Aug 27. Do not read that
#   as the previous seal's day.
#
#   ## ⚠⚠ THE SIX THINGS A FRESH READER MUST NOT RE-DERIVE
#
#   **1. THE `setParse` CRASH FIX IS REAL AND INDEPENDENT OF EVERYTHING ELSE.** Its refusal arm
#   printed `field passed in %s has no rStuff` and then FELL THROUGH to `if parseMethod`, which
#   resolves against the very null it had just refused. `incant/parseClass` died at exit 139.
#   Tony's six punctuation members are the first callers ever to lack rStuff. Ruling D says a node
#   without rStuff is LAWFUL, so the refusal is right and must actually refuse. Fixed in
#   `Generate.rtn`; fleet 54 → 56.
#
#   **2. ⚠ DO NOT ADD `setRuleStuff()` TO THE SIX PUNCTUATION MASTERS. IT WAS TRIED, IT WAS GREEN,
#   AND IT IS WRONG.** Tony's ruling: rules added to Grokking do NOT carry rStuff; the rStuff
#   arrives when a literal is ATTACHED to another rule, by a `setRuleStuff` call or by a `modify`
#   call that runs it. The addition cleared two fleet rows and took genParse 19 → 25 — it bought a
#   better number by breaking an unwritten invariant. **Green was not the test.** Reverted.
#
#   **3. THE `isRule` BACK-PROPAGATION, AND ITS CENSUS.** `setRuleStuff` raises
#   `groupBody->flags.isRule`; the copy constructor SHARES groupBody (`groupBody = grup->groupBody`)
#   while rStuff is per-node. So attaching a literal marks the MASTER. Negative control: a seventh
#   master attached to NO rule does not acquire the flag — minting is clean, ATTACHMENT marks it.
#   Census banked at **`minionWork/isRuleCensus`**, pre-registration at its head. Its four findings:
#   - **the write is EIGHT sites, six outside `setRuleStuff`** (a pre-registered prediction of ONE,
#     falsified) — `GroupMain.twk:16,282`, `ruleActions.rtn:398,449,1447`, `Commands.rtn:863`;
#   - **B2 (gate the write on a copy) is REFUTED and not on cost — it does not achieve its goal.**
#     Audit stayed at 10 missing and loose went 4 → 11; countPop crashed a rule; the odometer lost
#     `Limit`'s refusal line; fleet 67 → 63. Restored, md5-verified;
#   - **`tokenize` is NOT this disease** — ABSENT from MISSRULE, so it HAS rStuff, because
#     `modify(strap,"^@")` runs on the master not a copy. `break`/`continue`/`return` ARE affected
#     but by a THIRD route, bin-member propagation at `ruleActions.rtn:449`. **Three mechanisms;**
#   - the affected population is **10**, splitting **6 / 3 / 1** across those three.
#   ⚠ **SO OPTION A (teach `auditMissingRules` the category) IS THE ONLY CHOICE WITH A KNOWN-ZERO
#   BLAST RADIUS. B1 — move `isRule` out of groupBody — is a LAYOUT CHANGE (bear-trap #10) and is
#   UNMEASURED. The ruling is still Tony's; `incant/fixits/literalMasterIsRule` holds all three.**
#
#   **4. BEAR-TRAP #35 EXTENDED — A PROPERTY READ INSIDE A COMPOUND CONDITION UNDER-FILTERS A WALK
#   AT EXIT 0.** Six shapes measured, one run each, 39 correct: bare-positive and
#   capture-then-test give 39; `!x`, `x == 0`, AND `cursor.x == 0` all give **64**. **`!` is not the
#   culprit** — `== 0` fails identically and both work once the value is in a local. **CAPTURE,
#   THEN TEST.** Worse than #38's under-walk-to-one, because 64 where 39 is right looks exactly
#   like a working walk. Provenance: Tony distrusted `!` and was right about the line, one step off
#   on the mechanism; Clod wrote the `!` and blamed `!` in prose before measuring.
#
#   **5. THE TWO REMAINING FLEET REDS ARE PRE-EXISTING AND WERE MEASURED SO.** Both were red at
#   HEAD before Tony's edits: `parseClass.target` (its diff SHRANK under his change) and
#   `jsonTest baseline`. ⚠ **`rStuff audit` and `oneTest baseline` are red BY CHOICE, not by
#   neglect** — re-pinning them 4 → 10 would assert that ten missing rules is correct, which is the
#   exact thing under ruling in item 3. **Do not re-pin them to get a green number.**
#
#   **6. THE WALKIE-TALKIE IS DOWN (Tony, 08-28).** `SEQ 92` in `ipc/clod-to-clay.md` is a RECORD,
#   NOT A DELIVERY; the paste-ready text went to Tony in chat. ⚠ And while polling,
#   `ipc/support-to-clod.md` **SEQ 2 has sat at `working` since 2026-08-03 — 25 days** — blocked on
#   a ruling from Tony on the registry archive wire format, Part A landed green, Part B at the gate.
#   Clay wants that Part B text when the channel carries it; the ruling stays his.
#
#   ## WHAT MOVED ON THE QUEUE
#   **RETIRED (3):** `dataCrash` (crash gone, mapped onto countPop's `ok DatA`; ⚠ its listLength
#   anti-vacuity control did NOT carry, said plainly) · `countInputInTmp` (population now DERIVED
#   live — no file to go stale — and `ok` scored on the compile census, so a ghost name can no
#   longer score green; ⚠ last session's "42/42 clean" was **41 real + 1 ghost**, corrected) ·
#   `trailingContinue` (promoted to `incant/trailingContinueT`, five fleet rows).
#   **MINTED (2):** `jsonListNotAList` · `literalMasterIsRule`.
#   ⚠ **`incant/jsonTest` HAD NOT BEEN RUNNING SINCE 2026-08-25** — its semicolon-less `if` became
#   illegal under the SemI- ruling, so it dropped all 17 assertions and still exited 0. Fixed; it
#   now reproduces its 07-29 baseline byte-for-byte but for one stray line, which is `jsonListNotAList`.
#
#   ## ⚠ THE MEASUREMENT THAT JUSTIFIED PROMOTING trailingContinue, because it generalises
#   With the remedy stripped and the binary rebuilt, **the fleet reported 62 green and a
#   byte-identical failure set — it was BLIND.** After promotion the same control takes it 67 → 65
#   with FOR and DO red by name. **Retiring a citizen without measuring whether the fleet covers it
#   is how coverage is lost silently.** `incant/loopBranchT` is adjacent and asserts behaviour
#   INSIDE the loop; nothing asserted what survives after it.
#
#   ## THE NEXT STATIONS, in Clay's order
#   1. **`literalMasterIsRule`'s A/B/C ruling** — Tony's, now unblocked by the census.
#   2. **The two-pattern corpus sweep** — semicolon-less `if`s (the 08-25 seal already named four
#      in `displayIfVisible`, in the file every fixture includes) and in-condition property reads.
#   3. **SEQ 2 Part B text to Clay** when the channel carries it.
#   4. Then resume the queue: `kantGenPath` and `parentUnreachable` are both BEST GUESS.
#
#   ## THE SEAL CHECKLIST, run 2026-08-28
#   fleet **67 green / 1 parked** · frontier **exit 0, 10 PASS, FIRST FAILING STATION: NONE**
#   (⚠ NOT revised this session, and that is deliberate: the campaign edge did not move — the work
#   was fixits and a census, not the parse campaign) · decodePop **77 terms, 22 checks** · ddPop
#   **6 green** · countPop **39/39 clean, 0 missing** · canary **319** · `groups.ext` untouched
#   (mtime predates the session; no flag or extern was added) · **all four repos 0 dirty /
#   0 unpushed** · every retok BARE, so the binary is the real program and not an instrumented one.
#   **Tony's fixit incantations waiting: 7 (oldest: kantGenPath, since 2026-08-24)**

# ---

# ⚠⚠⚠ SEALED 2026-08-27 — THE CONNECTIVE CLOSES, THE MIRROR'S DISEASE IS NAMED BY ADDRESS, AND
# THE GUARD IS REFUSED PENDING A RULING. READ THIS FIRST.
#
#   ⚠ **THIS SUPERSEDES THE 2026-08-25 SEAL BELOW, WHICH IS INTACT AND STILL TRUE AS OF ITS OWN
#   MARK.** That one closed the label seam. This one discharged a citizen by remedy, found the
#   recursion's actual door, and STOPPED one step short of barring it because the door was not
#   where the brief put it.
#
#   ## THE ONE-LINE STATE: **connectiveDiscriminant is DISCHARGED BY REMEDY and promoted into the
#   fleet; parseSelfRecursion's mechanism is RULED and its door is measured, but NO GUARD IS BUILT.**
#   Fleet **61 green / 1 parked** (was 57 — four rows added, none lost). Canary **319**. Frontier
#   **10 PASS, first failing station NONE**. decodePop 77 terms / 22 checks. ddPop 6. All four repos
#   clean and pushed but for Tony's own files. **Fixit queue: 8 (oldest countInputInTmp, 08-24).**
#   **THE NEXT STATION IS THE UPSTREAM PROBE, chartered below and not run.** One disease named by
#   address, one probe waiting at its door.
#
#   ## ⚠⚠ THE FIVE THINGS A FRESH READER MUST NOT RE-DERIVE
#
#   **1. THE CONNECTIVE DEFECT WAS NEVER THE DISCRIMINANT — IT WAS setParse'S DECORATION, AND THE
#   2x2 IS THE WHOLE PROOF.** `setParse` hangs `builtinParsE`/`builtinActoR` on every rule it
#   touches, both noPrint, so `hasAttributeS` — which answers *is this node marked up* — read TRUE
#   for all 36 emitted bodies and the OR branch was unreachable. `hasTraits` (a bit that counts only
#   NON-noPrint attributes) fixed it in two ruled parts. Read the COLUMNS:
#   ```
#   gate           setParse RUNS      setParse OFF
#   hasAttributeS  36 AND / 0 OR      28 AND / 8 OR     <- retired gate, PINNED, must not be "fixed"
#   hasTraitS      28 AND / 8 OR      28 AND / 8 OR     <- live gate
#   ```
#   ⚠ **THE RETIRED GATE'S ROW NOT MOVING IS THE NEGATIVE CONTROL, NOT A MISS**, and it was
#   pre-registered as a hold before the run. Old gate still wrong, new gate right, same build. A run
#   where BOTH rows moved could not attribute the change to the gate at all.
#
#   **2. A RULED ONE-LINER COST A THIRD EDIT NOBODY PLANNED, AND THAT IS NOW A REGISTRY ROW.**
#   `setParse` calling `updateContentFlags` crashed at EXC_BAD_ACCESS and took the fleet 57 → 55.
#   `updateContentFlags` read `if listLength` through an **unguarded groupList** and always had —
#   latent for exactly as long as `moveTo` was its only caller. Minted as **`firstCallerNullList`**
#   (*dead helper meets its first caller*), status remedy, and it completes the demolition-arc pair:
#   **condemned code gets READ before deletion; revived code gets DISTRUSTED before promotion.**
#   ⚠ It was identifiable as CAUSED rather than pre-existing only because the before-captures were
#   banked before the first edit. Two red rows in a fixture with nothing to do with connectives is
#   otherwise a mystery of unknown vintage.
#
#   **3. THE MIRROR'S ENTRY PATH IS NOT THE runAction RECONSTRUCTION, AND IT IS WRONG IN THREE
#   PARTICULARS.** Read outermost-inward from the stack bottom:
#   ```
#   runOP · runAction(argument=StatemenT, field=parser) · processAction · aCTionBlocK ·
#   runOP · runOP · runRule(field=ruleText, rule=StatemenT) · parseRule(field=StatemenT) ·
#   aCTionBlocK · aCTionStatemenT x74k
#   ```
#   (a) the `runOP/runAction/processAction` frames are the **verifier action `parser` running its own
#   body**, not a generated parse body; (b) the rule-name call **DID take the legal road** —
#   `runRule → parseRule`; (c) the first mirror entry is called by **`aCTionBlocK`**, and `runAction`
#   has no gMethod dispatch line to guard at all — it calls `processAction`.
#
#   **4. THE ILLEGAL THING IS THE NODE, NOT THE ROAD — AND ITS PROVENANCE IS MEASURED.** The mirror
#   node's parent is a node tagged `BlocK` whose parent is **Grokking**: it is **the grammar's own
#   `BlocK[StatemenT]` term-reference**. `aCTionBlocK` is walking a legitimately parsed `BlocK`
#   (parent StatemenT, listLength 9) and fires that grammar term as if it were a parsed statement.
#   **TWO DOORS, both named.** OUTER — `aCTionBlocK` `GroupRules.mm:84-85`, which consults
#   `isMethod(grup->groupBody->flags.instructType)` **and nothing else**; `instructType` and `gMethod`
#   both live in the COPIED `groupBody` (bear-trap #34), so `isMethod` is a SHAPE fact and never a
#   legality one. INNER — `aCTionStatemenT:1487`, where `datA 0` means the isGROUP unwrap never fires
#   and the node dispatches its own handler on itself.
#   ⚠ **`isRule` ALONE DOES NOT DISCRIMINATE:** `aCTionBlocK`'s own input — legitimate work — also
#   reads `isRule 1`, `parseMethod` bound, registry Grokking. A guard keyed on it refuses correct work.
#   ⚠ **AND A THIRD CANDIDATE SITE IS UPSTREAM OF BOTH:** whatever put the grammar term into that
#   parsed BlocK's member list is earlier than either door, and a guard at either door treats a symptom.
#   ⚠⚠ **THE THIRD-DOOR RECONSTRUCTION IS DEAD. DO NOT RE-DERIVE IT.** Killed in three measured
#   particulars by the 08-27 docket (`8118146`). **ANY BRIEF CITING "the third door" OR "guard
#   runAction" IS SUPERSEDED BY THIS SECTION** — there is no third door, there is a contaminated
#   member list with two doors downstream of it.
#
#   **5. THE DOOR'S INVENTORY, because the routing decision needs it in hand.** `isRule 1` ·
#   `isLabel 0` · `datA 0` · `actionType 1` · `hasNewParse 1` · `gMethod` = aCTionStatemenT ·
#   registry Grokking · **`rStuff` LIVE with `parseMethod` BOUND, resolving to `parseRule`.** So
#   route-to-parse **is constructable** — the rule's own parse is readable at the point of the
#   illegal fire. Graded BEST GUESS, NOT built, and its promote conditions are in the report below.
#
#   ## ⚠ WHERE I DISAGREE WITH THE TOPSIDE ACCOUNTING — flagged, not silently reconciled
#
#   **A. `censusScratch` DOES NOT EXIST, AND THIS IS THE SECOND TIME.** The trim brief's NEVER-CUT
#   list names it among the seal-checklist fixtures. It was renamed **`popScratch`** and the 08-05
#   wakeup says so; the **08-25 seal's Amendment A already recorded this exact citation failure**.
#   `pop.sh:187` drives `popScratch`. ⚠ **A NEVER-CUT LIST BUILT ON IT WOULD PROTECT A GHOST AND
#   LEAVE THE REAL FILE UNPROTECTED** — the citation-from-a-sealed-document failure, third instance.
#
#   **B. `jitLadder/ladder.sh` IS MISSING FROM THE CITATION SOURCES, AND IT PROTECTS 40 FILES.**
#   The brief's sweep names pop.sh + ladder targets, tree.sh, frontier, wakeup recipes, minionWork,
#   seal-checklist fixtures. **Measured: 40 `incant/` files are named by `jitLadder/ladder.sh` and
#   driven by NONE of `pop.sh`'s 14** — `jiquery`, `jitAttrPop`, `jitDfProbe`, `jitFalseT`,
#   `jitIterTwice`, `jitJ1`–`jitJ7`, `jitJE/JF/JP/JPd/JPl/JR/JRL/JRt1..JRt4/JU/JUi`, `jitPrintT`,
#   `jitSelfFn`, `jitSlotT`, `juiProbe` and siblings. That is a **fifth of the 190-file directory**,
#   it is exactly the jit population the brief hands to my judgment, and with jitLadder omitted every
#   one of them defaults to CUT or MAYBE. **jitLadder goes in the sweep.**
#
#   **C. THE GUARD DID NOT LAND, SO THE CENSUS'S FILL-CONDITION NEVER TRIGGERS.** The accounting has
#   the third-door brief IN FLIGHT with the trim census "optional as fill if the guard lands early".
#   Step 1's stop clause fired instead. **The census is therefore not fill — it is the only
#   available work**, because the guard is blocked on a ruling that has not been made.
#
#   **D. THE ROUTING DECISION IS THREE-WAY, NOT TWO-WAY.** The accounting frames it as
#   *route-to-parse vs refusal-only*. The **site** is open too: outer door on provenance, inner door
#   on self-dispatch (which needs no new fact at all), or the upstream site. The briefed site,
#   `runAction`, is gone.
#
#   **E. `parseSelfRecursion` HAS NO FIXIT CITIZEN — its "NEXT" is a problem-record field, not a
#   `NEXT:` block.** The accounting says "parseSelfRecursion's NEXT" as though it were a citizen in
#   the queue. It is not in `incant/fixits/`. ⚠ **So the hottest open item on the board is the one
#   thing NOT pointing at Tony's foot at shutdown**, which inverts the loaded-gun mechanism exactly
#   where it matters most. The standing rule since 08-19 is that banking an issue owed to Tony means
#   writing its fixit incantation as part of the banking.
#
#   **F. THE FIRE-DOCTRINE SENTENCE IS OWED BUT HAS NO ADDRESS.** It is to land "beside the
#   fire-count row" — and that row exists **only inside the 08-25 sealed vintage**, which is history
#   and must not be rewritten. The write needs a destination ruling: CLAUDE.md's seat ledger, or a
#   problem record of its own.
#
#   **G. `firstCallerNullList`'s `verdict` STILL READS `-- unreviewed --`/`-- awaiting Tony --`.**
#   Tony ratified it on the wire; I did not write his verdict, because `verdict` is his loud channel
#   and I have it only relayed. One line from him and it is done.
#
#   **H. THE UNTRACKED POPULATION IN `incant/` IS ZERO.** All 190 files plus the 8 fixits are
#   tracked, so phase two's "untracked files just die" clause has an empty population there and
#   **every cut is a commit**. Worth knowing before the razor comes out.
#
#   ## ⚠⚠ THE NEXT STATION ON RESURRECTION: THE UPSTREAM PROBE — THE DISEASE, NOT THE DOORS
#   **Chartered, NOT run. Both doors treat symptoms until this answers.** In the crashing parse:
#   1. **which member INDEX** of that parsed `BlocK` holds the term-reference;
#   2. **what the other eight members ARE** — the diff between minted products and the intruder is
#      the mechanism's fingerprint, and it is the whole point of the station;
#   3. **which parse step APPENDED it.**
#   ⚠ **LEDGER-ADJACENT SUSPECTS ARRIVE AS TREE-READS ONLY** — `<-` hands back copies; `copyOf` does
#   not carry `gMethod`. Neither is to be reasoned forward into a mechanism. **This week produced two
#   reconstructions that died on contact with frames, which is the proof of why.**
#
#   ## ⚠ RULINGS TEED UP FOR TONY — made in conversation, recorded nowhere else until this mark
#   **INNER-DOOR SELF-DISPATCH BACKSTOP — Clay RECOMMENDS ruling it in regardless of the upstream
#   fix.** A node dispatching its own `gMethod` on itself is detectable at `:1487`'s own site **on no
#   new fact**, refuses a state that is never legal, and **cannot false-positive the way `isRule`
#   would** — `aCTionBlocK`'s own legal input also reads `isRule 1`. It converts any future
#   contamination from 74k frames into a one-line tattle. **Awaiting Tony's word.**
#   **ROUTE-TO-PARSE — graded BEST GUESS and explicitly NOT recommended.** Kill condition on record:
#   with the term-reference still sitting in the member list, a routed parse likely re-enters by the
#   same door. **Do not build ahead of the upstream answer.**
#   **THE FIRE-DOCTRINE SENTENCE is still owed and is UNCHANGED by the docket** — the doctrine was
#   never wrong, only the map of where it was violated: *an action fires when its rule parses,
#   holding a label, once, done — zero fires on every other road.* Dated, beside the fire-count row.
#   ⚠ **AND FLAG F BELOW STILL STANDS AGAINST IT:** that row lives only inside the 08-25 SEALED
#   vintage, which is history and must not be rewritten. **The sentence has a text and no address.**
#
#   ## ⚠ WHAT TONY IS ON THE HOOK FOR — in rough order of heat
#   1. **The inner-door backstop: yes or no** (Clay recommends yes, independent of everything else).
#      The door question proper — outer/inner/upstream — waits on the upstream probe, which is the
#      next station and is chartered above. Route-vs-refuse does not get decided before it.
#   2. **Jitter sketch margin notes** — seven holes, gated on the redirect ruling. Hole 4
#      (print-redirect-to-buffer, kant can't) is the load-bearing move; hole 2 (method-cell fired
#      from kant); hole 3 answered by the opSetFlag/isSTRING type-as-data ruling; holes 1, 5, 6, 7
#      afternoon-sized seams.
#   3. **Trim lists review** — `incant/` is overdue a high-and-tight trim. **PHASE ONE IS A
#      READ-ONLY CENSUS: nothing cut, moved or renamed.** Clod produces three graded lists, Tony and
#      Clay review, cutting is phase two under its own brief. Judge-jury-barber on the grades is
#      Clod's — especially the jit population, his own build — **but the razor stays holstered.**
#      **NEVER CUT** — derived mechanically first, judgment second: every `incant/` file cited by a
#      standing instrument (pop.sh + ladder targets, tree.sh, **jitLadder — see flag B**, frontier
#      stations, wakeup run recipes, minionWork probes, seal-checklist fixtures: `oneTest`,
#      `jsonTest`, **`popScratch` — see flag A**, `walkPhase`, the decodePop/ddPop fixtures), the
#      `kant8T` family (K5/K6 chartered-but-unrun — a fixture with chartered future work is cited by
#      the charter), and `jitscratch` by name (sole exerciser of `jitRunAction`, home of the parked
#      `opPlusPlus` 139). Each row: filename + the one-line citation that protects it. ⚠ **A file
#      protected only by a STALE citation — an instrument that no longer runs — is a FINDING, not a
#      protection.** **CUT** — answered one-shot probes, superseded rungs, dead scaffolding,
#      fixtures for discharged-and-tombstoned defects. Each row: filename + what it was for + why
#      it is done. `firstCallerNullList` is the doctrinal cover: deleting dormant machinery is the
#      safe direction, no eulogies owed. **MAYBE** — probably-dead but a doubt survives: possible
#      sole exerciser of some road, questions that could recur, jit files whose future under O6 is
#      unclear. Each row: filename + what it exercises + **the specific doubt**. ⚠ **THE MAYBE LIST
#      IS THE REVIEW'S REAL AGENDA; the other two should mostly rubber-stamp.**
#      **INVERSE FINDING ALSO OWED:** instruments citing files that do not exist — trim-adjacent debt,
#      and flag A is already one of them.
#      Disposition PRE-RULED for phase two: **tracked die by commit — the repo is the archive, no
#      attic directory, no ponytail in a drawer. Untracked just die.** Note tracked/untracked per
#      file, since it picks the mechanism (⚠ but see flag H: in `incant/` that population is ZERO).
#      ⚠ **Fold flags A and B in BEFORE the census runs, or it is built on a bad source.**
#   4. **Parent text owed to me** for the two doctrine rows — the **opSetFlag contract** and the
#      **typed-valueless accessor caution**. I refused to reconstruct them from the one-line
#      summaries; a relayed amendment whose parent is unconfirmed is one clause of a convention.
#
#   ## CHARTERED, QUEUED AT TONY'S WORD, none in flight
#   **The & campaign** — four read-only pre-design stations: `&` meaning census · R-3 assign-census
#   slice · `<-` intent census (incl. the does-`<-`-ever-bind-node-fields grep that checks the
#   locals-only scoping) · **runOP recon** (two roads walked, divergence named, touch-list graded —
#   runOP the bear in waiting). Design session convenes on all four. **`byRefReview` is exhibit
#   zero**, absorbed and moved to `minionWork/byRefReview` with its gate questions preserved verbatim
#   — absorption is not an answer to them. K5/K6 clears the frame-model wall first if the recon
#   confirms it load-bearing. **Retirement by census: `<-` dies when its site count reads zero.**
#   **opSetFlag implementation** — clears-by-contract on data-flag set, population named via the
#   flag-species declarations, before-captures (blast radius: every re-type site).
#   **K5/K6** — the standing KANT-8 gate, chartered 08-05, still unrun; now has a live customer.
#
#   ## STANDING DESIGN STATE (O6, not yet open)
#   Jitter incantation = parser's structural sibling, residing in `IncantForms/WorkingOn` beside it.
#   Loader contract specced (`jitLoad(buffer, name)` → verdict, register into slot machinery,
#   three-rung tattling refusal, interpreted floor). Two-layer POP (byte-agreement round-tripped +
#   two-arm answer-agreement). Buffer = one per action, print-redirect, sink-doctrine (emission owns
#   the redirected channel; everything with a voice speaks on stderr). O6 charter questions still
#   Tony's: buttress death = loader is permanent residue; reflexive close = final POP, unscheduled.
#   ⚠ **The third-door findings may inform jitter dispatch design — both threads converge on the
#   dispatch door from opposite sides.**
#
#   ## THE DISCIPLINE EXHIBITS, because each changed an outcome
#   **A PRE-REGISTERED PREDICTION HELD, TWICE, AND ONE OF THEM WAS A NON-MOVE.** The `hasAttributeS`
#   row was called as a HOLD before the run and holding is the fix working; without the
#   pre-registration it reads as a failed promote condition.
#   **MY OWN CENSUS INSTRUMENT LIED IN THIS PASS AND I CAUGHT IT.** The first jitLadder comparison
#   returned **0 files protected only by jitLadder** — plausible, quotable and wrong, because
#   jitLadder drives fixtures through a variable rather than literals. The real figure is **40**.
#   H9's exact shape, and it is recorded because the number was going into a seal.
#   **TWO RECONSTRUCTIONS DIED ON CONTACT WITH FRAMES** — the citizen's bare-name-resolution guess,
#   and the runAction door. Both were sound reasoning on premises nobody had run.
#   **A BACKTRACE'S OFF-BY-ONE WAS CAUGHT AT ITS OWN VINTAGE.** The 08-26 docket cites `:1483` for
#   `getGroup`; at that same commit `getGroup` is `:1484` and `:1483` is the guard above it —
#   bear-trap #36. And the call is moot anyway: `datA 0`, so it never fires.
#
#   ## THE SEAL CHECKLIST, run 2026-08-27
#   `incant/frontier` **exit 0, 10 PASS, FIRST FAILING STATION: NONE** · fleet **61 green / 1 parked**,
#   rows diffed against a pre-session capture, **zero lost** · decodePop **77 terms, 22 checks** ·
#   ddPop **6 green** · canary **319** · `oneTest`/`jsonTest` md5 unmoved · `parser(NamE)` transcript
#   byte-identical · **support repo 0 uncommitted / 0 unpushed**, `groups.ext` committed per the
#   standing rule (`4d1b252`) · Parse and Tokf clean · Groups clean but for Tony's
#   `IncantForms/WorkingOn/{incant++, parser, tester, jitter}` — all his, all expected dirt, `jitter`
#   new and untracked and named-WIP.
#   **Tony's fixit incantations waiting: 8 (oldest: countInputInTmp, since 2026-08-24)**

# ---

# ⚠⚠⚠ SEALED 2026-08-25 — THE LABEL SEAM CLOSES, AND FOUR LATENT DEFECTS SURFACE. READ THIS FIRST.
#
#   ⚠ **THIS SUPERSEDES THE 2026-08-23 SEAL BELOW, WHICH IS INTACT AND STILL TRUE AS OF ITS OWN
#   MARK.** That one closed F-31. This one made new parse answer correctly, and then spent the day
#   finding what the fleet structurally cannot see.
#
#   ## THE ONE-LINE STATE: **NamE parses `foo` through the new parse and its action returns `foo`,
#   byte-identical to old parse.** Fleet **57 green / 1 parked** (was 53 — four rows added, none
#   lost). Canary **318**. Frontier **10 PASS, first failing station NONE**. decodePop 72 terms /
#   22 checks. ddPop 6. Both repos clean and pushed. **Fixit queue: 9.**
#
#   ## ⚠⚠ THE FIVE THINGS A FRESH READER MUST NOT RE-DERIVE
#
#   **1. THE LABEL FIX IS ONE SITE PLUS ONE GATE, AND THE GATE IS THE LOAD-BEARING HALF.**
#   `runRuleAction` is the ONLY seam between the terms matching and the action firing, because the
#   emitted tail is `return runRuleAction(this)` — the action fires from INSIDE the body. But that
#   function is also on the ORDINARY path (`aCTionBrancH`, `runOP`), where no parse is in flight and
#   `hereAt` is stale. `gNewParseInFlight` (jitContext.h) makes the stale-span write
#   unconstructable. Ungated it would have written a plausible span into every ordinary dispatch.
#
#   **2. A GREEN FLEET IS NOT A CORPUS CHECK, AND THIS COST TWO NEAR-MISSES IN ONE DAY.** Bodies
#   compile LAZILY AT FIRST CALL, so anything never called is invisible to `pop.sh`. The `SemI-`
#   change ran 57 green **with a live hit sitting in `incant/utilities`** — `displayIfVisible`, four
#   semicolon-less `if`s, in the file every fixture includes. And guard-1's symptom census, which
#   sweeps only code that RUNS, misses that same function's two Operator errors for the same reason.
#   **When a corpus gate reads clean, ask whether the corpus was executed.**
#
#   **3. `if field != 0;` IS NOT A SAFER `if field;` — THE TWELVE-CELL TABLE SAYS SO.** They ask
#   different questions (presence vs numeric value) and each is wrong where the other is right.
#   `!= 0` reads TRUE on an absent field and FALSE on a group; the bare test reads TRUE on a field
#   holding zero and on a valueless one. **`if listLengtH;` is the CORRECT empty-list guard and
#   `!= 0` breaks it** — nine sites would have moved under a blanket rule. Accessors disagree with
#   each other and must be checked one at a time. `minionWork/probeBareTest`.
#
#   **4. BEAR-TRAP #39 HAS TWO VICTIMS, FOUND BY TWO DIFFERENT INSTRUMENTS.** An undeclared name in
#   an action body is an action LOCAL, cleared on entry, so two actions sharing one never see each
#   other's writes. `e8e8619`'s mechanical patch gave eleven of twelve emitter copies their counter
#   declaration. `incant/bisectQ` was found by being banked as a citizen; `incant/phaseProbe` was
#   found by guard-1 sweeping for the SYMPTOM. **Neither instrument would have found the other's
#   file.** Both fixed, one line each.
#
#   **5. THE FIRE COUNT IS ONE PER ROAD, AND `parseSetLabel`'S FIRE WAS UNREACHABLE.** Tony's
#   ruling: `parseSetLabel` = label work (alive as the future glom arm), `runRuleAction` = body road,
#   `fireLabelMethod` = interpretive road. Stripping it discharged **fixIts row 1 BY RULING**. It
#   could never have starved anything: only three rules are leaf-shaped AND method-bearing
#   (`ANYtoken`, `NewGroup`, `ShortcuT`), all read `datA 6` = isGROUP, and `setParse` binds those to
#   `parseMethod = null`.
#
#   ## ⚠ WHAT TONY IS ON THE HOOK FOR
#   1. **`parentUnreachable`** — an action cannot reach its argument's parent; five of six
#      navigation directions exist and only UP is missing. Two shapes graded, choosing is his.
#   2. **`trailingContinue`** — REMEDY landed, awaiting step-and-bless, then it promotes.
#   3. **`WhilE` grammar rule** — `SemI-` STOPPED at 19 live `while ++grup` sites. A style ruling on
#      a live idiom, not a first-draft safety net. `ElseIf` and `IF` landed.
#   4. **Guard-1's proposal** — standardise the refusal tail across all 13 operator sites; a halt
#      would fire on NOTHING today, so it can be armed with no migration.
#   5. **Bear-trap #39 minted** in CLAUDE.md (the seat ledger); the user-facing document is task 4
#      and unwritten.
#
#   ## THE DISCIPLINE EXHIBITS, because each changed an outcome
#   **FIVE INSTRUMENT FAULTS, EVERY ONE CAUGHT BY A CONTROL RATHER THAN BY A WRONG-LOOKING NUMBER:**
#   unquoted globs returning 0 over a known-non-empty population; `xargs -a` (not BSD) erroring into
#   a 0; a stale corpus list making an H11 control read ABSENT; a regex anchored on `NamE$` after a
#   pointer print was appended; and `if isGROUP;` reading a constant, not a field kind.
#   **A PREDICTION DIED ON ONE COMMAND** — `notFirstTimeThru` was predicted to break rule 2 and does
#   not, because undeclared is the CORRECT spelling there. Recorded rather than dropped.
#   **AN ASSERTION'S BLIND SPOT WAS AUDITED AND FOUND EMPTY** — the earlier fire-count grep did
#   exclude `parseSetLabel`; re-run with every site counted, the figures are unchanged.
#   **A REPORTED DEFECT WAS NEARLY MINE** — `displayIfVisible`'s Operator errors were first measured
#   against a fixture whose argument had no parent. Re-measured with a properly parented specimen;
#   they reproduce. The patient is sick; the first instrument could not prove it.
#
#   ## THE SEAL CHECKLIST, run 2026-08-25
#   `incant/frontier` **exit 0, 10 PASS, FIRST FAILING STATION: NONE** · fleet **57 green / 1 parked**
#   · decodePop **72 terms, 22 checks** · ddPop **6 green** · canary **318** · generated-file check
#   **flags.tokened = 2, expected 2** · **support repo 0 uncommitted, 0 unpushed** (the standing step,
#   ruled today) · Groups clean but for Tony's `IncantForms/WorkingOn/{incant++,tester}`.
#   **Tony's fixit incantations waiting: 9 (oldest: byRefReview, since 2026-08-24)**

# ---

# ⚠⚠⚠ SEALED 2026-08-23 — THE CAMPAIGN CLOSES. READ THIS FIRST.

#   ⚠ **THIS SUPERSEDES THE 2026-08-22 SEAL BELOW, WHICH IS INTACT AND STILL TRUE AS OF ITS OWN
#   MARK.** That one proved the fix shape on a specimen. This one made the shape unnecessary.

#   ## THE ONE-LINE STATE: **F-31 is CLOSED, status remedy, and the fix that was proven end-to-end
#   was never fired in anger.** `tokenize` has **zero reads-through and zero firings**, is still in
#   the grammar, still bare, still tagged. The same-count discriminator that isolated F-31 now
#   answers **identically on both arms** — its defining measurement returns null.
#   **THE COUNT: 22 compiled clean, 19 parse-failed, 1 crashed, of 42 attempted.**
#   Fleet **52 green / 1 parked**, rows byte-identical. Decoder 72 terms.

#   ## ⚠⚠ THE FIVE THINGS A FRESH READER MUST NOT RE-DERIVE

#   **1. THE MECHANISM WAS NEVER A BODY-MISREAD.** Installing a generated parse method gave the one
#   BARE hook its **FIRST attribute**, which reclassified it from method-hook to attribute-matcher —
#   so its method stopped being fired and the reader it served starved. `Braced`, which already had
#   attributes and gained the same `CodE`, did not flip. Measured `hasAttr 0 -> 1`.

#   **2. THE JANITOR HAD A SECOND JOB, AND THAT IS THE ASYMMETRY NOBODY COULD EXPLAIN FOR A WEEK.**
#   `tokenize`'s comment advertised one thing — it "gloms parent label components together into the
#   label string". That glom **also consumed** the labels a rule's LABELED sub-terms produce.
#   `captureSpan` inherited the capture; nobody inherited the collapse.

#   **3. THE DASH IS WHY NamE WAS IMMUNE — IT IS SPELLING, NOT LUCK.** Read the two lines:
#   `NamE first-=[a-zA-Z] nameSet-^*` — both sub-terms carry the **noLabel dash**;
#   `NumbeR numberSet=[0-9]+` — **labeled**. A noLabel sub-term mints no label, so there is nothing
#   to hang. Respelling NumbeR the same way took the load census **42 → 4**. Do not go looking for
#   rule-specific weirdness; there is none.

#   **4. THE COUNT'S 19 FAILURES ARE WEATHER, NOT THE SNAKE.** Named, not absorbed: BasicElse CodE
#   DEFINing DO DelimText ElseIf FOR IF InvokE Limit MemberS PrinT RunRulE Search SetBrackets
#   TraiTdata WhilE break tokenize; plus DatA crashing at 139. The four the earlier 12-of-43 partial
#   had already named are all present, which is what makes them **pre-existing rather than caused**.
#   `tokenize` failing is expected and harmless — a bare rule generates an empty condition and
#   nothing routes through it. Each is an ordinary frontier row now.

#   **5. THE EPITAPH, because it is the whole campaign in one sentence: ABSENCE IS NOT A CHANNEL.**
#   A bare hook meant *I am live machinery*; a leaf product meant *I am a value*; an unread label
#   meant *nothing*. Uniform progress erased all three absences. **Every fix shipped was the same
#   fix: say the thing explicitly** — a flag instead of bareness, `setToken` instead of decoration,
#   a dash instead of an unread label.

#   ## THE DISCIPLINE EXHIBITS, because each changed an outcome
#   **FIVE MECHANISMS DIED ON CONTACT** and one survivor was named on bones — four cuts, every
#   outcome pre-registered, all four landing where they were aimed and neither loud miss firing.
#   **TWO PROBES WERE VOID AND SAID SO.** A hollow-capture run reported a clean 52 that meant
#   nothing, because `GroupMain.twk` was edited and never re-tok'd — the flag never reached the
#   binary. **The check is now standing: count the set site in the GENERATED file, never the source.**
#   **A KILLED CAPTURE WAS READ AS A DIFF**, against rule H5's explicit warning, and produced a
#   finding that had to be re-measured. It reproduced — but the doubt was the instrument's fault.

#   ## ⚠ WHAT IS CARRIED
#   1. **The fix-shape apparatus** — off-rule storage, explicit activation, ruled-moment bind —
#      **superseded-unexecuted**, proven on Braced, retired to doctrine.
#   2. **`DatA` crashes at 139** in the count harness — its own row, undiagnosed.
#   3. **Buffer-lifetime** — still honestly void, twice attempted.
#   4. **Queued:** `parseMethod` → `groupBody` · define liberation · the installation gap
#      (genParse never sees NamE or FormaT) · the wrap/unwrap evidence pile
#      (`canonRoadDependence`, the rebind-taG sighting). **#37 stays parked and fed.**
#   5. **HeX is parked**, reversal instructions inside its own comment. **Station 3 stays parked.**
#   6. ⚠ **`groups.ext` IS DIRTY IN THE SUPPORT REPO AND IT IS THE CAMPAIGN'S OWN WORK.** Eleven
#      insertions, mtime 2026-08-21, uncommitted: `maxLimit`, `repeatLimit`, `reportMaxLimit`,
#      `reportRepeatLimit`, `storeBody`, `storedBody`, `activateBody` and siblings. **It is EXPLAINED,
#      not a surprise diff** — it is the out-of-repo extern mirror keeping pace. **But bear-trap #11
#      applies: it lives outside the Groups repo, so it never appears in a Groups `git status` and
#      the build depends on it.** Committing it is Tony's call; a resurrection reader needs to know
#      it is there and uncommitted.

#   ## THE SEAL CHECKLIST, run 2026-08-23
#   `incant/frontier` — **RUN, exit 0, nine of nine RAN and PASSED. FIRST FAILING STATION: NONE.**
#   Its prose now records that the campaign it was built for closed *without it ever needing
#   `tokenize` as its subject*, and that the next edge is unnamed — the 19 parse failures are the
#   candidates. Fleet **52 green / 1 parked**, zero timeouts · decodePop **72 terms, 22 checks** ·
#   ddPop **6 green** · canary **315** · generated-file check **2 set sites** ·
#   **Tony's fixit incantations waiting: 1 (nodeIdentity, since 2026-08-22)** · everything pushed,
#   working tree clean except Tony's own `IncantForms/WorkingOn/{incant++,tester}`.

# ---

# ⚠⚠⚠ SEALED 2026-08-22 — KITCHEN PASS (CURRENT VINTAGE). READ THIS FIRST.
#
#   ⚠ **THIS SUPERSEDES THE 2026-08-21 SEAL BELOW, WHICH IS INTACT AND STILL TRUE AS OF ITS OWN
#   MARK.** That one had an instrument that said where the campaign was stuck. This one ran it green.
#
#   ## THE ONE-LINE STATE: **the F-31 (tokenize snake-eats-tail) fix shape is PROVEN end-to-end on a
#   specimen.** `incant/frontier` runs **nine stations, all RAN and all PASSED**, ran-census 9 of 9,
#   exit 0, reproduces. Fleet **53 green / 1 parked**, canary **315**, everything pushed.
#   **Tony's fixit incantations waiting: 1 (nodeIdentity, since 2026-08-22)**
#
#   ## ⚠⚠ THE FIVE THINGS A FRESH READER MUST NOT RE-DERIVE
#
#   **1. THE CAMPAIGN'S QUESTION IS ANSWERED, ON A SPECIMEN.** A body that did not exist when the
#   process started was generated, stored off-rule, activated on a twin, compiled, harvested onto the
#   live rule, bound into its parse path, and **executed by the ordinary parse as Braced's own parse
#   implementation** — correctly enough that the bracket it governs parsed. `tokenize` untouched.
#   Runnable: `minionWork/probeDecisiveV2`, `incant/frontier`.
#
#   **2. THREE THINGS HAD TO BE TRUE AT ONCE.** Remove any one and the run goes red or silent.
#   **Bind the real node** — `<-` hands back a reference-sharing-substance, and a reference confirms
#   every read-back of a write that changed nothing (Ruling E: bind the node, not a copy).
#   **The fork's node is the ordinary catalog node** — no carrier, no fallback, no resolution
#   function; `canonOf(Grokking["Braced"])` reports SAME NODE and equals the fork's `definer`.
#   **The return is consumed at the fire site** — a body's yield is a value, never control flow.
#
#   **3. ⚠ THE CONFOUNDER THAT ATE A WEEK, AND WHY NO INSTRUMENT CAUGHT IT.** `<-` yields a node that
#   shares the original's child list but is **not** the original. It answers every READ correctly —
#   same tag, flags, list, `definingRule` — and diverges only on MUTATION, where the write lands on
#   the copy and **the read-back off that copy confirms it**. No error, no crash, fixture green. Four
#   findings were reported and later inverted from this one root. **Identity questions are asked in
#   POINTERS, through `canonOf`** — a resolver that reports names cannot answer a question about
#   identity, because two faces of one rule share a tag by construction.
#
#   **4. #37 (artifact return unwinds caller) IS STILL STANDING — DO NOT READ THE GREEN AS ITS CURE.**
#   Containment is proven at `parseRule`'s door ONLY. The frontier is green because the truth-test
#   discipline **removed the fire**, not because the unwind was contained; the #37 path is not
#   exercised anywhere in that run. The evaluation door — `aCTionIF`'s condition fork,
#   `GroupRules.mm:857` — is parked as a named acceptance criterion on the gMethod-move batch with an
#   H7 control: **truth-test a commissioned BlocK; it must NOT fire.** Retirement fires on that
#   verified landing, not before.
#
#   **5. THE STAGING PROPERTY, DEMONSTRATED NOT ASSERTED: arming without routing is inert by
#   construction.** The artifact sat armed on the live rule across whole sessions and never fired
#   until it was routed. So the tokenize repair stages **store → arm → verify → bind**, everything
#   before the bind provably inert, the live switch at one ruled moment.
#
#   ## RULINGS BANKED BY THIS CAMPAIGN
#
#   **A** twin inertness (a `copyOf` twin is specimen, not organism) · **C** compile guards both
#   channels with distinct refusals (flag-vs-artifact disagreement is itself diagnostic) ·
#   **D** shape vs liveness vs birth — D1 `isRule`-class flags say rule-SHAPED never LIVE, liveness is
#   asked of `rStuff`; D2 `isLabel` is a birth certificate, an `rStuff`-less label is WRECKAGE and
#   refuses loud; D3 registration mints shape, reference mints life · **E** bind the node, not a copy ·
#   **containment lives at the fire site**, yields are consumed not obeyed.
#   ⚠ **DOOR TAXONOMY:** deliberate fire sites (parseRule) consume returns — landed and proven.
#   **Evaluation sites (any operand-position gMethod call) are a LANGUAGE ruling, not an edit** —
#   consuming there changes what `if` means for every method-valued condition.
#
#   ## ⚠ WHAT TONY IS ON THE HOOK FOR
#
#   1. **Arm A** — instrument the walk around install #43, confirm one concrete read into `tokenize`'s
#      overwritten body. It gates the repair and nothing this campaign did touched it.
#   2. **`nodeIdentity` fixit** — intent half RULED (pointer wanted, mechanism missing); the `parenT`
#      grep is the open half, one command, no build.
#   3. **The `<-` memory row** (`project_incant_new_operators_setflag_rebind`) describes the symptom as
#      if it were the design — wants a word now that the intent is ruled.
#   4. **Carried:** `groupDirectives` working copy · `jsonTest baseline` red, pre-existing all session ·
#      `IncantForms/WorkingOn/{incant++,tester}` are his live files.
#
#   ## THE DISCIPLINE EXHIBITS, because each changed an outcome
#   **THE TRY-AND-BUY SYSTEM SAID NO, AND WAS RIGHT.** One full cycle, criteria pre-registered before
#   the edit, criterion 2 failed on measurement, the one-commit revert floor executed clean — and the
#   no-buy turned out righter than known once the confounder surfaced.
#   **A GREEN RUN THAT NEVER ENTERS THE FAILING PATH IS NOT EVIDENCE THE PATH IS FIXED**, and the
#   frontier says so in its own prose rather than letting its banner imply otherwise.
#   **THE RAN-CENSUS EXISTS BECAUSE THE BANNER LIED ONCE:** reading v1 printed "all nine stations
#   PASSED" while station 9 sat unparsed, because `frDead` only ever rises from a station that RAN.
#   **FOUR FINDINGS WERE WITHDRAWN OR INVERTED AND NO WRONG RULING SURVIVED** — finding 1 withdrawn
#   before its ruling was acted on, finding 3's fix-vs-reorder explicitly held for mechanism, Ruling E's
#   trial refused by pre-registered criteria. The process caught what the probes could not.
#
# ---
#
# ⚠⚠⚠ SEALED 2026-08-21 — KITCHEN PASS (CURRENT VINTAGE). READ THIS FIRST.
#
#   ⚠ **THIS SUPERSEDES THE 2026-08-20 SEAL BELOW, WHICH IS INTACT AND STILL TRUE AS OF ITS OWN
#   MARK.** That one opened the campaign gate. This one spent the gate — and found the road.
#
#   ## THE ONE-LINE STATE: **the storage-and-activation machinery EXISTS, the headline number has
#   NOT moved, and the campaign now has an instrument that says exactly where it is stuck.**
#   `incant/frontier` runs and **dies at STATION 4**. Fleet **53 green / 1 parked**, canary **314**,
#   jitLadder 205, everything pushed. **Tony's fixit incantations waiting: 0**
#
#   ## ⚠⚠ THE FIVE THINGS A FRESH READER MUST NOT RE-DERIVE
#
#   **1. THE FRONTIER FILE EXISTS AND DIES AT STATION 4.** `incant/frontier`, eight stations,
#   revised in place at every seal and never forked. Stations 1-3 PASS (generate · store, census
#   pending 1 · mint twin, taG reads Braced). **STATION 4 FAILS: a `copyOf` twin REFUSES the body
#   install that the LIVE RULE accepts one station earlier** — same `frHang`, same body, different
#   target. ⚠ **That is ONE STEP UPSTREAM of the portability gate the crucible was built to answer**,
#   so the crucible is *wounded at a named line*, not dead. **The front question for the next session
#   is: what does install require that a `copyOf` twin lacks?** Steppable at `fixFrontier4Here`.
#
#   **2. THE SWEEP-RETRIEVAL SUSPECT IS DEAD.** The leading candidate for the sweep's uniform
#   `reached end of input` was *"retrieval hands compile an empty read"*. **Measured and refuted** —
#   the dump shows the body arriving IN FULL:
#   `{ if  SemI() OR BlocK() OR WardeD() OR Iterate() OR Xpress(); return runRuleAction(this); }`
#   A further cell (OR-chain on a detached entry) did **not** reproduce the sweep's text either. The
#   texture is narrowed to **subject-identity or a population/sequence effect** and is **named, not
#   chased**. Do not re-run the empty-read theory; it is closed.
#
#   **3. THE ARTIFACT'S TRUE ADDRESS IS `BlocK` + `isAction`, NOT rStuff.** Attached by `processCode`
#   at **`GroupActions.rtn:951-952`** (`result.noPrint = true; field +% result; field.isAction =
#   true`). ⚠ **The rStuff siting in the SEQ 81 charter is STRUCK AS AN ERRATUM.** Anything designed
#   against "commission into rStuff" needs re-siting before it means anything.
#   ⚠ **And its companion blocker, captured:** `:. isActioN` has **no case in `opSetFlag`** — it
#   prints `groupField isActioN has no case yet -- gCount 408` and does nothing. Station 6 will need
#   another route to the `isAction` half. **Blocker-in-waiting, not yet paid.**
#
#   **4. R1-GREEN STANDS: A DETACHED ENTRY COMPILES FINE AND RESOLVES NOTHING.** The 2x2
#   (`minionWork/probeCompileCells`, runnable) is the sharpest thing measured this session:
#   | body | terms | `runRuleAction` | result |
#   |---|---|---|---|
#   | R1 | no | no | **GREEN** |
#   | R2 | no | yes | fails at `runRuleAction(this)` |
#   | R3 | yes | no | fails at the term |
#   | R4 | yes | yes | fails at the term |
#   **A detached-entry compile fails on the FIRST UNRESOLVABLE CONSTRUCT**, and both term calls and
#   `runRuleAction(this)` are unresolvable there. ⚠ **So "entries do not compile" was WRONG — they
#   compile, and resolve nothing.** The cause is arm 2's finding, below.
#
#   **5. WHY, EXACTLY — AND IT IS A ONE-LINE MECHANISM.** `GroupItem.twk:1789`:
#   `if registry && registry.isRule  isRule = true;` — **filing a node in an `isRule` registry
#   AUTO-PROMOTES IT TO A RULE.** `GroupMain.twk:16` sets that on Grokking, and `genParse.rtn:780`
#   records it true **only** for Grokking. `GenBodies` is not `isRule`, so corpus entries **are not
#   rules**, so `runRuleAction(this)` has nothing to resolve against.
#   ⚠ **AND THE COROLLARY THAT MATTERS FOR THE CRUCIBLE:** `kantDoor`'s "NOT Grokking … the mint must
#   not be one" (`genParse.rtn:826-830`) is **NOT the substrate rejecting rule-shaped-but-not-a-rule.**
#   It exists to stop **accidental** promotion. **It says nothing against a deliberate rule-shaped
#   twin — the crucible is untouched by it.**
#
#   ## WHAT LANDED — six commits, all pushed
#
#   | commit | what |
#   |---|---|
#   | `4dcee26` | **pre-registration, committed BEFORE a line of code** — canary delta, groups.ext edits by name, f31 signature, census shape, and `56 of 56 PRE-REGISTERED AS SUSPICIOUS` |
#   | `d097772` | **the machinery is born** — five verbs, corpus in `GenBodies`, phase 1 hits its pin at 56/0/0/56 |
#   | `40864cb` | back-pointer **deleted** (audited: no second purpose), bodyless compile refuses loud, **the number taken** |
#   | `758dd32` | **Option B built and stopped by its own stop condition** — and the condition's premise falsified |
#   | `f97c4f4` | the crucible recon: arms 2 and 3 delivered, **arm 1 declared INCOMPLETE rather than reported** |
#   | `62986a5` | **`incant/frontier` born**, dies at station 4 |
#
#   ## THE MACHINERY, AS BUILT — six library verbs, canary 308 → 314
#
#   `storeBody` · `storedBody` · `activateBody` · `activateAll` · `compileStored` · `bodyCensus`.
#   Corpus is the **`GenBodies`** registry, keyed by rule tag. States on an entry: **1 pending · 3
#   compiled-green · 2 commissioned — never 0**, because a fresh node counts zero already and zero
#   must never mean a state we put it in.
#   ⚠ **`groups.ext` took SIX decls and rides in no commit here (bear-trap #11).** md5 at session
#   start `31ff1b0f7db20271e5d98f7ef0851a7b`, **at seal `96e8fc0b9f86a3dedc0b95badcb28c96`** — the six are `storeBody`, `storedBody`,
#   `activateBody`, `activateAll`, `compileStored`, `bodyCensus` in the `external GroupRules.h` block.
#
#   ## ⚠⚠ THE HEADLINE NUMBER: STILL 0 OF 56. Said plainly, because it is the point.
#
#   | | |
#   |---|---|
#   | phase 1 census | **56 / 0 / 0 / 56 — the pre-registration EXACTLY** |
#   | phase 2 | **compiled 0, rejected 56** against a pinned 0 of 56 |
#   | residue | **uniform** — all 56 `reached end of input` |
#
#   **THE INVARIANT HOLDS AND THE NUMBER DID NOT MOVE, AND BOTH HALVES ARE TRUE.** Generation writes
#   no live slot; phase 1 is clean. But **whole-population activation before any compile reproduces
#   the poisoning**, and **compile-from-store is not constructible by compiling a detached entry**.
#   ⚠ **`reached end of input` IS NOT A DISPLACEMENT DETECTOR** — under Option B displacement was
#   *impossible* (commissioned 0 at every checkpoint) and the text appeared anyway. Anything that
#   leaves a reader with no tokens produces it. **A constant failure is camouflage for a variable
#   one**, which is the trap that hid F-31's transition behind `BasicElse`.
#
#   ## THREE SUBSTRATE FINDINGS THE BUILD PAID FOR — two are now bear-traps #32 and #33
#
#   **#32 — a multi-statement indented `if`-arm followed by an `else` breaks the parse**, and the
#   error names **the first action in the file**, which is healthy. Two controls passed; only the
#   combination fails. That misdirection cost an entire bisect. Cure is the flag idiom.
#   **#33 — an incant command extern MUST return `GroupItem`.** An `int` return is read as a pointer
#   and the process dies **on the statement after the call**, so the callee's entry trace never fires
#   and it reads as *"never registered"*. Census: **zero** registered commands return `int`.
#   **Third, applied not charted:** `setGroup` **deep-copies a parented target** (`GroupItem.twk:1662`)
#   unless the node is `isLocal`/`isLabel` or the target is `byRef` — which is why `kantDoor` sets
#   `isLocal` before `group`, and why the corpus back-pointer was deleted rather than repaired.
#
#   ## ⚠ WHAT TONY IS ON THE HOOK FOR
#
#   1. **THE FRONT QUESTION, and it is answerable in the debugger before anyone writes a line:
#      what does install require that a `copyOf` twin lacks?** Break at `fixFrontier4Here`.
#   2. **F-33 — QUEUED AND LOAD-BEARING.** The termless-rule body. It is in the 56.
#   3. **Charter B — the `isLIST` recon — UNSTARTED.** Chartered in full at SEQ 78; rides after A seals.
#   4. **The 8 nested-term refusals are UNMEASURED under the new siting** — `;` `attributes` `cerr`
#      `cout` `in` `iterate` `members` `on`, all nested terms `locate()` cannot reach. They did **not**
#      reproduce under Option B, so **no fixit row is minted from them** until the siting settles.
#   5. **The ordinal is STILL FLAGGED** — four customers found and sited, fifth unrefuted.
#   6. **`IncantForms/WorkingOn/drawing` is annotated but UNCOMMITTED** — it is his working file. See
#      the Drawing-registry section in the session report; six entries confident, two flagged `"?"`,
#      `endPath` refuted by dlsym.
#   7. **Carried:** `groupDirectives` working copy · F-29's mechanism · F-32's `else()` emit ·
#      `jsonTest baseline` red, pre-existing all session.
#
#   ## THE DISCIPLINE EXHIBITS, because each one changed an outcome
#   **THE PRE-REGISTRATION DID ITS JOB TWICE.** It caught the canary at +5 not +4 (the fifth verb,
#   `storedBody`, closing a gap nobody could have reasoned out: **the direct install was doing double
#   duty as the walk's VISITED MARK**, and separating them made the walk recurse forever). And its
#   `56-of-56-is-suspicious` clause was written before any run, so it could not be rationalised after.
#   **ARM 1 WAS DECLARED INCOMPLETE RATHER THAN REPORTED.** Its control's marker body silently failed
#   to parse, so nothing ever demonstrated the artifact executing. Reporting a twin comparison on top
#   of that would have been a void control wearing green — the exact failure H7 exists to prevent.
#   **THE FRONTIER FILE CAUGHT ITSELF BEING VOID ONE RUN AFTER IT WAS WRITTEN**, and that is the best
#   argument for the practice: `if frOk;` tests existence, always true, so three stations printed PASS
#   unearned. **The structure found it, not anybody's memory.**
#   **A GRINDING THRESHOLD WAS HONOURED THREE TIMES** — activation binding, the compile site, and the
#   starvation texture were each handed back after three distinct attempts rather than ground on.
#
# ---
#
# ⚠⚠⚠ SEALED 2026-08-20 — KITCHEN PASS (CURRENT VINTAGE). READ THIS FIRST.
#
#   ⚠ **THIS SUPERSEDES THE 2026-08-19 LATE SEAL BELOW, WHICH IS INTACT AND STILL TRUE AS OF ITS
#   OWN MARK.** That one closed the day 56 problems became one. This one closes the one.
#
#   ## THE ONE-LINE STATE: **the campaign gate is OPEN.** `F-31` is **CONFIRMED and ratified**, its
#   mechanism is **measured**, and the fix is **ruled and released — but deliberately not tasked.**
#   Fleet **53 green / 1 parked**, canary **308**, everything pushed, tree clean but for Tony's three
#   working files. **Tony's fixit incantations waiting: 0**
#
#   ## ⚠⚠ THE THING A FRESH READER MUST NOT RE-DERIVE — THREE MEASUREMENTS, THEY NEST
#
#   **1. WHICH install — a SAME-COUNT SWAP.** The old 42-vs-43 A/B moved count and membership
#   together and could not settle it. Hold installs **fixed at 42** and exchange one member:
#
#   | arm | 42 installs | `tokenize` among them | compiling `BasicElse` |
#   |---|---|---|---|
#   | 0 | `BlocK` in | no | **CONTENT** — `failed at "else() AND followedBy()…"` |
#   | 1 | `BlocK` out | **yes** | **EMPTY** — `reached end of input`, line 1 |
#
#   **2. WHEN — dispatch is LIVE, not frozen at bind.** Two compiles of the same body in **one
#   process**, one install between: reads CONTENT before, EMPTY after.
#
#   **3. WHY — Arm A, and it is the promoter.** A temporary `cerr` on the C++ `tokenize`
#   (`GroupActions.rtn:1545`), counting calls, then a **bare revert and rebuild**:
#
#   | arm | `tokenize` in | whole run | **DURING the compile** |
#   |---|---|---|---|
#   | 0 | no | 1163 | **2** |
#   | 1 | yes | 1170 | **0** |
#
#   ⚠ **READ THE TWO COLUMNS TOGETHER OR NEITHER MEANS ANYTHING.** The whole-run totals are
#   effectively equal, so the tokenizer is **alive in both runs** and the install does not kill it
#   globally — that is the anti-vacuity control. **During the compile it goes 2 → 0**: a reader that
#   got tokens and choked, versus one that **never got a token.**
#
#   ## ⚠ AND THE TRACE BOUGHT A REFINEMENT — TWO CAUSES, AND THEY EXPLAIN DIFFERENT HALVES
#
#   The body installed over `tokenize` is **degenerate — `{ if  return runRuleAction(this); }`, an
#   `if` with no condition** — because `tokenize^@;` (`grammar:34`) is a **termless** rule and the
#   generator's term loop emits nothing.
#   **Do not merge the causes:** the **DUAL ROLE** explains **the collision** (a rule the reader
#   depends on gets a body installed over it mid-use); **TERMLESSNESS** explains **the degenerate
#   body**, now charted separately as **F-33**. They compound — but **a hook WITH terms is still a
#   hook**, which is exactly why the fix was ruled on the dual role and not on the body.
#
#   ## THE FIX: RULED, RELEASED, NOT TASKED — and each word was decided separately
#
#   **SELECTED: off-rule storage plus explicit activation**, fourth customer (with the napalm, the
#   `BlocK` re-poison, mid-walk `setParse` binding). **REFUTED: exempt-the-hook** — correct for
#   today's grammar, **silently wrong for tomorrow's**. Tony ruled the **hook class OPEN**: `tokenize`
#   may be the only member *now*, and self-hosting **structurally mints dual-role rules over time**.
#   ⚠ **THE CENSUS NEVER GOT TO VOTE, AND THAT IS THE POINT** — it returned **one** member, and the
#   siblings' immunity is **incidental** (they carry data; `tokenize` does not). Second time this
#   campaign a fix was chosen by asking **what the project IS** rather than what the bug does; the
#   pick-one constraint went the same way.
#   **The census survives as a standing registry: `docs/hookRules.md`**, row one `tokenize`.
#
#   ## ⚠ WHAT TONY IS ON THE HOOK FOR
#
#   1. **THE BUILD — released-and-untasked BY RULING, not by drift.** Cut it first thing on a fresh
#      session. ⚠ **STEP ONE IS PRE-REGISTRATION:** write `incant/f31`'s expected taken-signature down
#      **before touching code** — a target regenerated green is not a target. ⚠ **AND f31 ORACLES THE
#      SYMPTOM, NOT THE MECHANISM:** a green f31 says `tokenize` survives installation and says
#      **nothing** about the other three customers. **The build's verification surface is wider than
#      the fixit that gated it.**
#   2. **F-33** — ratify the shape: emit the **minimal well-formed body** for a termless rule (no
#      `if`, straight to the return). **Not** "refuse to generate" — refusal leaves termless rules
#      permanently outside self-hosting for no gain.
#   3. **F-26's five** — still his. Sites for all five are now in the docket, file:line, so he reads
#      rather than hunts. ⚠ **Items 1 and 5 are NOT mintable as fixits yet** and the reason is
#      measured: nothing drives a parse through a bound `parseRule`.
#   4. **`groupDirectives`** — his working copy; the `compile`-entry `debugAllRules` line is still not
#      regenerable from it.
#   5. **One ordinal to check:** the relay called `tokenize` the **fifth** customer of
#      off-rule-plus-activation; the tree says **fourth** and names three predecessors. **Flagged, not
#      reconciled** — a customer count is exactly the kind of cited number that gets built on.
#   6. **Carried:** DesignDocs `KantParser` authored-not-installed · `IncantForms/WorkingOn`
#      reconciliation (H8) · F-29's mechanism · F-32 the `else()` emit · `jsonTest baseline` red,
#      pre-existing all session.
#
#   ## WHAT ELSE CLOSED — `iterT1m`, and KE-4 with it
#
#   **Row 1 GRADUATED (H6):** `iterT1m.divergence` → **`iterT1m.target`**, 7 visits, each node once.
#   The re-pin sentence is a **subsequence claim**: the old 14-line pin differs by **deletions only**,
#   so today's walk *is* the old walk minus its seven duplicate visits — and it is the exact trace the
#   fixture's own header **pre-registered as correct**. ⚠ **NOT claimed:** that header's conclusion
#   that the recursion inference now covers mutual recursion. `field.recursive` is **unchanged**
#   (`ruleActions.rtn:1320`, still identity-against-`currentMETHOD`). **The target pins the answer, not
#   a mechanism.**
#   **Row 2 — cause established, then RULED AND RESTORED.** KE-4's three candidates resolved to the
#   **first**: the `cerr` was **deleted in `9c4962b` (2026-08-15)**, Tony's own offline work. Restored
#   verbatim; **provably one line** (canary 308, `.mm` diff = 1 insertion); fleet **52 → 53 with
#   exactly one row moved**. ⚠ **The pin is 4, not the old 7** — seven was the count under the *broken*
#   walk. **The number moved because the WALK moved.**
#   ⚠ **REMEDY: ASSERTABILITY** — restoring it changed **no behaviour**; the poison was intact
#   throughout. It restored the fleet's only **presence-with-value** cover for the poison.
#
#   ## THE REGISTER GREW A CHARTER TODAY — five addenda, and the queue emptied
#
#   `incant/fixits/` gained: **prose below `stop();`** (parse-dead — Tony's ruling, hostile-text probe
#   agrees); **the loaded gun** (the seal line is an *armed condition*, not a reminder — silencing it
#   is unloading someone else's gun); **the peas pass** (session open runs `fixitNag.sh` and asks
#   *step one now, or which citizen first* — **new campaign work does not open while that is
#   pending**); **REMEDY blocks** naming `BEHAVIOUR`/`ASSERTABILITY` first word; and **`NEXT:` on
#   every citizen, never absent**, graded `OPEN → BEST GUESS → RULED → REMEDY`.
#   ⚠ **`RULED` exists because the other three are EPISTEMIC and a ruling is DEONTIC** — a project
#   that rules on trajectory ahead of evidence produces *decided-but-not-yet-buildable* structurally.
#   ⚠ **AND ABSENCE-AS-SIGNAL FAILED ITS FIRST COLD READER**, which is why `NEXT:` is mandatory: a
#   grade needing a qualifying clause to be read correctly is **a failure surviving correct
#   application.**
#
#   ## ⚠ WHY THE BUILD WAS NOT CUT TONIGHT — a scheduling ruling, not a judgement call
#
#   The 2026-08-08 doctrine fired on its exact signature: **reasoning intact, mechanics degrading.**
#   Six mechanical misfires this session — a non-discriminating `eq` guard that **voided a control**, a
#   registry lookup echoing its own tag, `!listLengtH` reporting zero leaves, an ordinal skip landing
#   on `continue` **twice**, a `fixitNag` sort written wrong twice, and a control that **collapsed into
#   an arm already in hand**. ⚠ **Every one was caught — and the catch rate is NOT the metric.** The
#   ruling is *scheduling, not more care*, and the fourth-customer build is the **highest blast-radius
#   work on the board** (a ruling with three other customers, where a misfiling is charter-level and
#   gets built on).
#
#   ## THE DISCIPLINE EXHIBITS, because each cost something today
#   **TWO VOID CONTROLS IN F-31 ALONE, both caught by a PRINTED NAME and neither by reasoning:**
#   *"43 installs without `tokenize`"* is **unbuildable** (the population is exactly 43 and `tokenize`
#   is last, so the skip silently collapses to the N=42 arm and **reproduces the CONTENT read**, which
#   reads as a clean refutation); and an ordinal skip above `fbGen`'s `datA` gate skips `continue`,
#   which `fbGen` drops silently anyway. **A fixture that names what it skipped cannot lose a control
#   the way the name-skip did.**
#   **THE INSTRUMENTED BUILD WAS REVERTED AND REBUILT BARE BEFORE ANY CAPTURE** (bear-trap #23's
#   hardening) — verified by canary 308, zero `TOKZ` in the `.mm`, and the fleet returning to 53.
#   **A RELAY DROP:** an amendment arrived whose parent ruling never did. **Flagging the gap beat
#   reconstructing it** — a reconstruction would have been plausible, unmarked and wrong.
#
# ---
#
# ⚠⚠⚠ SEALED 2026-08-19 LATE — KITCHEN PASS (CURRENT VINTAGE). READ THIS FIRST.
#
#   ⚠ **THIS SUPERSEDES THE 2026-08-19 SEAL BELOW, WHICH IS INTACT AND STILL TRUE AS OF ITS OWN
#   MARK.** Same day, second pass: that one sealed the pick-one work in the morning; this one seals
#   the parse-generation afternoon.
#
#   ## THE ONE-LINE STATE: **the day the campaign went from 56 problems to ONE, and the one has an
#   address.** `F-31` bisected to a **single install** — `tokenize`, #43 — that turns a readable
#   generated body into an empty read. Fleet **51 green / 1 parked**, canary **308**, everything
#   pushed, tree clean but for Tony's three working files.
#
#   ## ⚠⚠ THE THING A FRESH READER MUST NOT RE-DERIVE — F-31 IS ONE INSTALL, NOT FIFTY-SIX
#
#   `incant/fixBisect` installs the first N bodies then compiles the FIRST one, known good alone:
#
#   | N | last installed | compiling `BasicElse` |
#   |---|---|---|
#   | 1 … 42 | … `break` | fails on **CONTENT** — `failed at "else() AND followedBy()"`, text **is read** |
#   | **43** | **`tokenize`** | fails at **`reached end of input`**, line 1 |
#
#   Same body, same compile, one install between them. **Individually perfect, collectively
#   unreadable.** Candidate mechanism, structural support only: `tokenize` is the tokenizer hook
#   (`grammar:34`), so installing a body over it plausibly displaces the method every later read
#   depends on. ⚠ **The confirming control is VOID, not negative** — two name-skip spellings both
#   matched every member and installed nothing (now bear-trap #28's fourth row). What stands is the
#   A/B, which isolates the same install without naming it.
#   ⚠ **AND THE DETECTOR HAD TO BE THE SIGNATURE, NOT THE ERROR.** `BasicElse` fails at EVERY N
#   (F-32: the generator emits `else()`, a keyword). Counting `ERROR processCode` reports failure at
#   N=1 and hides the transition completely. **A constant failure is camouflage for a variable one.**
#
#   ## WHAT LANDED — six commits, all pushed
#
#   | commit | what |
#   |---|---|
#   | `654a180` | **Generate.rtn template audit** — the `parse*` family had lost the half that MOVES: no `atRuleMark++`, no min gate, and `parseString` had lost its match guard |
#   | `acb0617` | `maxLimit` becomes a settable property, landed at the **status quo** because the default is measured |
#   | `73ae47c` | **F-27 closed** — bad writes refuse AT THE WRITE; default measured at 100000 because **100 would have truncated `phaseA`** |
#   | `fa28f71` | **`parseClass`** — the setParse classification census, and it found a third misrouting on its first run |
#   | `d34f3c1` | **maxLimit splits** (F-28), **setParse skips registries** (F-30), **the runaway is `StatemenT`** (F-29) |
#   | `c4a222b` | **F-31 bisected**, and **fixit incantations** start with `iterT1m` |
#
#   ## THE INSTRUMENTS — three new, and each answered a question the same day it was built
#
#   **`incant/parseClass`** — which `setParse` arm claims each field, 239 rows, pinned and wired into
#   `pop.sh`. ⚠ **It is the ONLY row in the fleet that exercises `setParse` at all**; before it,
#   "fleet unmoved" said nothing whatever about the generated-parse arc. It found the `ANYtoken` /
#   `NewGroup` / `ShortcuT` misrouting within minutes of existing.
#   **`reportRepeatLimit`** — named `StatemenT` as the sinkProbe runaway, with position, the first
#   time it fired. **`incant/fixBisect`** — F-31's answer above.
#
#   ## THE TWO CEILINGS, BOTH MEASURED (F-28 closed)
#
#   | knob | bounds | fleet ceiling | default | on a hit |
#   |---|---|---|---|---|
#   | `maxLimit` | characters in one match | 79 | **100** | `reportMaxLimit`, **match fails** |
#   | `repeatLimit` | times a rule repeats | 171 | **100000** | `reportRepeatLimit`, **reports only** |
#
#   The asymmetry is the ruling: a truncated TOKEN is wrong content; a rule at its repetition ceiling
#   matched everything correctly. **Anti-vacuity: 182 fixtures, exactly one citizen at either ceiling,
#   nothing near 100.**
#
#   ## NEW STANDING PRACTICE — FIXIT INCANTATIONS (CLAUDE.md, fourth register)
#
#   `incant/fixits/` holds one **runnable** file per issue owed to Tony. Prose capture rots. The seal
#   line is generated by `genLadder/fixitNag.sh`, never typed:
#   **Tony's fixit incantations waiting: 1 (oldest: iterT1m, since 2026-08-19)**
#   ⚠ `incant/fixits/` is Tony's queue and **NOT** the fleet — nothing in it runs under `pop.sh` until
#   promoted.
#
#   ## ⚠ WHAT TONY IS ON THE HOOK FOR
#
#   1. **`incant/fixits/iterT1m`** — step it, bless or investigate, re-pin BOTH baselines. The fixture
#      now walks CORRECTLY (7 visits, each node once) while both pins describe the old broken walk.
#      **One decision, not two.** This run is also the practice's acceptance test.
#   2. **F-31 confirm or refute** — one working skip plus `showBody` on the failing pair. **Everything
#      gated on "parse generation closes" sits behind this.**
#   3. **F-26's five** — still his: the rule action firing TWICE on the generated path, `setParse`'s
#      order vs `setTestMatch`'s, the four parse methods that never call `checkInput` (`parseRule` is
#      the one that matters), `parseRule`'s local-clear guard, and `*`-at-zero on the generated fork.
#   4. **`groupDirectives`** — his working copy; the `compile`-entry `debugAllRules` line is NOT
#      regenerable from it and was lost in a retok. Re-add if wanted.
#   5. **Carried:** DesignDocs `KantParser` still authored-not-installed · `IncantForms/WorkingOn`
#      reconciliation (H8) · F-29's mechanism (candidate-grade, now instrumented) · F-32 the `else()`
#      emit · star-at-zero as the named second fixit citizen.
#
#   ## ⚠ groups.ext TOOK FIVE EDITS AND IS IN NO COMMIT (bear-trap #11)
#   `maxLimit` and `repeatLimit` in the `external GroupRules` mirror · `maxRepeat` in the
#   `external RuleStuff` mirror · `reportMaxLimit` and `reportRepeatLimit` in `external GroupRules.h`.
#   md5 at seal: `31ff1b0f7db20271e5d98f7ef0851a7b`.
#
#   ## THE DISCIPLINE EXHIBITS, because three of them cost real time today
#   **`pop.sh` from inside `genLadder` reports 1 green** — its paths are repo-root-relative, and a
#   wrong-cwd run reads exactly like a catastrophic regression. **A probe that changes what it
#   measures is not a measurement** — the first high-water probe `fprintf`'d per record advance and
#   turned a 268M-iteration loop into a timeout that looked like my own regression. **Bear-trap #29
#   live**: a comment inside an `if`/`or` chain silently deleted `setParse` from the extern block,
#   307→306, tok exit 0, BUILD SUCCEEDED — the canary was the only tell.
#
# ---
#
# ⚠⚠⚠ SEALED 2026-08-19 — KITCHEN PASS (CURRENT VINTAGE). READ THIS FIRST.
#
#   ⚠ **THIS SEAL COVERS TWO DAYS.** 2026-08-18 was worked and pushed but never sealed — an API
#   failure took the session mid-brief — so everything below spans 08-18 and 08-19 together. The
#   08-17-late block beneath is intact and superseded.
#
#   ## THE ONE-LINE STATE: **the day the rules learned to pick one, and the day two owed
#   measurements both came back and both changed a plan.** The GroupMain bootstrap trio is
#   pick-one conforming; the phase-one shadow census prices the (b) pull-forward at **all of it**;
#   and the BrancheS fork's premise is **falsified by its own control.** Fleet **48 green / 1
#   parked, byte-identical to the pre-edit baseline**; jitLadder **205 ok, stderr 0, one owned red
#   (JV/F-12)**. Groups clean but for Tony's two `IncantForms/WorkingOn` files.
#
#   ## ⚠⚠ THE THING A FRESH READER MUST NOT RE-DERIVE — THE TWO VERDICTS
#
#   **PHASE ONE DAMAGES ALL OF THE GRAMMAR PHASE TWO NEEDS, AND THERE IS NO SAFE SUBSET.**
#   `incant/phaseProbe`, 79 rules read twice in one process. **11 flip shape. EIGHT of them go
#   `-M--` → `AM--`** — a members-only alternation rule acquiring an attribute, which is F-15's
#   poisoned shape exactly — and since **zero rules owned both before the walk, every one of the
#   eight is a hybrid CREATED by generation.** Then the half that prices it: **11 of 11 flipped
#   rules are reachable from `BlocK`. Zero fall outside.** So off-rule storage cannot be deferred
#   behind phase two. **This is F-15 option (b), and the measurement says FIRST, not last.**
#   ⚠ Its instrument check ran first and is why the rest is readable: the warm-up S2 block agrees
#   with S1 **row for row, 79/79**, so the two shape readers demonstrably read the same thing.
#
#   **BrancheS: THE `bin`-IS-AN-ATTRIBUTE PREMISE IS FALSIFIED, AND NO CHILD TRIPS THE CLASSIFIER.**
#   The fork was posed as *`bin` is a noPrint ATTRIBUTE the census should ignore, so the repair is a
#   classifier filter*. `incant/branchProbe` walks the attribute list and prints one line each:
#
#   | rule | columns | attributes | members |
#   |---|---|---|---|
#   | `BrancheS` | `-MD-`, `datA = 3` | **zero** | 3 — `break` `continue` `return` |
#   | `Operators` | `-MD-`, `datA = 3` | **zero** | 57 |
#   | `NumbeR` (control) | `A---`, `datA = 0` | 3 | zero |
#
#   **The control is what makes the two zeros mean anything** — the same loop printed three rows for
#   `NumbeR` in the same run, so the walk is live and the answer is genuinely empty. `bin` is
#   consumed by `processFlags` at define time and leaves nothing behind. **The `D` is on the rule
#   node itself.** And the structural replacement, measured over all 13 members-shaped rules: **the
#   `-MD-` pair is exactly the two CONTAINERS** — `BrancheS` a bin, `Operators` a registry — while
#   the other **eleven** carry no data at all. ⚠ **What that `isSET` datum IS was NOT measured and
#   is deliberately not inferred.** The live question is no longer *filter the census*; it is
#   **does pick-one apply to a container at all** — Tony's.
#
#   ## WHAT LANDED
#
#   | commit | what |
#   |---|---|
#   | `a5ca5e1` `a390f83` | F-15/F-16 — the refusals are a SHADOWING defect, measured with a control; pre-flight census NONZERO |
#   | `c13f06f` | **F-15 CLOSED** — the members arm goes first, gated on `!data`; fleet UNMOVED |
#   | `9614ea2` | **Ruling 4** — the two-phase walk lands and delivers the partition |
#   | `4ab72dd` | Tony's 2026-08-18 offline work: `compile`, the name/token guards, directives |
#   | `1f39bac` | **F-18 RULED AND LANDED** + **F-19 opened and closed** + **F-20 opened** |
#   | `7488cb5` | **PICK-ONE lands on the GroupMain trio** + both owed measurements |
#
#   ## ⚠ THE SEAL BRIEF'S SIX ITEMS, ANSWERED IN ORDER
#
#   **1. F-18 — LANDED, `1f39bac`.** `Generate.rtn`'s `parseRule` bail arm is `reportNoBody(field);`
#   — no parse call, no fallback — and the comment was rewritten in the same edit, because the old
#   one stated the opposite doctrine. `reportNoBody` is a **sibling** of `reportCodeFail`, not a
#   reuse: the two state different facts and the wrong one would print `ERROR processCode:` for a
#   rule `processCode` never touched. Externs 302 → 303.
#   ⚠ **AND ITS NAPALM CLAIM IS RETRACTED BY THE REPAIR ITSELF** — with the null deref fixed the run
#   still died and the backtrace named a different function; `parseRule` was never entered. The
#   defect was real, the mechanism story was written before it was tested.
#
#   **2. DIRECTIVES-BUILD DOCTRINE — CONFIRMED ON DISK,** `CLAUDE.md` bear-trap #23, the 2026-08-18
#   hardening block. A directives build is **semantically different**, not merely instrumented
#   (`aCTionNamE starting active` changes how a name resolves), so a capture taken on one is a
#   result about a different program. **Rebuild bare before any capture** is doctrine now. Every
#   number in this seal was taken that way: `tok GroupMain.twk`, no directives file, canary
#   `303 → 303`, rebuilt 09:09.
#
#   **3. ⚠ DesignDocs `KantParser` — NOT INSTALLED. DO NOT RECORD IT GREEN.** The five attributes
#   (`KantParser` `KantParserWhy` `KantParserHow` `KantParserFlow` `InterpretOrCompile`) exist
#   **only in `IncantForms/WorkingOn/incant++`**, which is Tony's uncommitted working file — a grep
#   of the whole tree finds them nowhere else, and `incant/designDocs` (last touched 08-15) has no
#   `KantParser` entry at all. So: **authored, not homed, not compile-verified.** The pending
#   amendment stands and is now sharper: `KantParserHow`'s constraint wording — *"only data, only
#   attributes, or only members"* — would gain an *"ignoring noPrint attributes"* clause **if** the
#   noPrint exemption is ruled; the BrancheS measurement above says that exemption **would not save
#   BrancheS**, because BrancheS has no attributes to exempt. ⚠ Note also that `KantParserHow`
#   asserts *"Incant grammar rules now fit that constraint"* — as of this seal **two do not**, and
#   they are the two containers.
#
#   **4. PICK-ONE — SCOPE WAS NOT OPEN HERE. Tony's sentence was received in session, verbatim and
#   PLURAL**, and this is the one place the brief and the room disagreed:
#   > *"Change GroupMain bootstrap rules that do not pick one; For example, NumbeR rule should be
#   > changed to: `NumbeR numberSet=[0-9]+ FloaT? tokenize;`"*
#   The census closes the set at **exactly three** — `incant/shadowCensus`'s `A-D-` class is
#   `{ FloaT NumbeR PoweR }` and `census.target` refuses all three for the identical
#   `rule-level data (§4.1)` reason. **After the edit the `A-D-` class is EMPTY, 3 → 0.**
#   ```
#   NumbeR   setGroup(numberSet)   ->  addAttribute(numberSet) "+"     <- Tony's spelling exactly
#   FloaT    setCharacter('.')     ->  attribute `point` = "."         <- NAME CHOSEN BY CLOD
#   PoweR    setCharacterSet("eE") ->  attribute `e`     = [eE]        <- NAME CHOSEN BY CLOD
#   ```
#   ⚠ **`point` and `e` want a nod, not a review** — chosen by the `HeX zero-="0" x-=[xX]` precedent
#   for a marker term. Everything else is mechanical.
#   ⚠ **THE FLEET BEING UNMOVED IS NOT THE CERTIFICATION, and this is the H7 row of the day:
#   NOTHING IN `pop.sh` PARSES A FLOAT.** The positive control is `incant/dblProbe` — `3.5` · `0.25`
#   · `1.5e2 → 150` · `3.5+1 = 4.5` · `10/4 = 2.5`, all correct after the reshape, **exponent
#   included**, plus `incant/divT` sentinel-green.
#   **THE LABELLED-LITERALS CLEANUP WAS NOT BUNDLED** — same rules, same visit, still Tony's and
#   still undecided. The bare literals (`strap += "("`, `new("{")`) are untouched.
#
#   **5. BrancheS fork — MEASURED. Verdict above.** Recorded under `docs/fixIts.md` F-17c with the
#   probe, the control, and the named non-measurement.
#
#   **6. CARRIED UNTOUCHED, verbatim from the brief:** shadowCensus probe *(⚠ **this one is now
#   DONE** — `incant/phaseProbe`, verdict above, recorded under F-15)* · Tony's offline Xcode walk,
#   row 8 · checkSkip-in-kant, parked post-jit-proof, with its loader-separation row · F-13/F-14 ·
#   **Tony's owed: the two `iterT1m` re-pins, and `docs/commentMinion.md` to Clay.**
#
#   ## THE CENSUS RE-PIN, AND WHY IT IS NOT A REGRESSION
#
#   `genLadder/census.target` moved by **six lines, all three rules, one shape**. Refusals rise
#   **24 → 27** and `PLAN` stays **30**. That is H9's corollary in its cheap direction — a refusal
#   census reports the FIRST blocker, so removing one reveals the next — and **the destination is
#   the point:** the three rules now refuse in **exactly the shape `QuotE` and `NamE` already refuse
#   in** (`inline group / structural data` → `term unclassified`). They left a private refusal class
#   and joined the shared one, so their remaining work is the work the conforming rules already
#   need, not extra work.
#
#   ## THE INSTRUMENTS — two new
#
#   **`incant/phaseProbe`** (clean-vs-post-walk shape, term graph, reachability computed in the
#   shell where it can be checked by eye; carries its own warm-up agreement check) ·
#   **`incant/branchProbe`** (attribute/member walk with a built-in vacuity control — the reason its
#   two zeros are readable).
#
#   ## ⚠ LATE ADDITION — `IncantForms/WorkingOn/parser` RUNS TO COMPLETION AGAIN, AND IT HAD NOT BEEN
#
#   Tony asked for whatever the walker needed to be runnable in Xcode. **It had not been reaching
#   its `stop()` at all, and its exit status was an accident of what followed it.** Once the walk
#   installs generated methods the loader cannot read the source that follows, so a top-level
#   `walkRules(X); stop();` dies at `checkInput: no input source`. With five dead `walkRules` lines
#   sitting BELOW the `stop()`, the poisoned loader failed to parse them and abandoned the file —
#   the documented exit-0-on-parse-failure path — so the run reported **0**. Truncate those same
#   lines and the identical run reports **139**. **Neither reached `stop()`, and neither said so.**
#
#   **THE FIX IS SHAPE, NOT CARE: the driver is now an action and its `stop()` is INSIDE it.** An
#   action body is parsed once into a cached BlocK, so it needs no loader, and stopping from in
#   there ends the process before the loader is ever asked for another statement. The sentinel
#   beside it is on **`cerr`** deliberately — stdout is block-buffered and a crash loses it, so a
#   stdout sentinel cannot report the crash it exists to detect. Measured: **TokenXP 59 lines ·
#   Braced 59 · NumbeR 19 · QuotE 7 · StringXP 7**, every one reaching the sentinel, printing
#   `stop:`, exit 0. `Start` still exits 1 at the first `ERROR processCode` — **F-17e, Tony's.**
#
#   ⚠ **AND IT CAUGHT A REGRESSION THE FLEET COULD NOT SEE** — `setParse: ERROR field passed in e
#   has no rStuff`, from the pick-one conversion's two new terms, which were added with `+%` and
#   never given rStuff (`QuotE`'s `tik` is the precedent and carries an explicit `setRuleStuff()`).
#   **48 green through the whole thing.** H7 from the other end: an instrument that does not
#   exercise a construct is silent about it, and silence is not a pass. **F-21 opened** for the
#   four `Buffer: ERROR no text passed into appendString` lines, zero on the control binary.
#
#   ⚠ **AND ONE CONSEQUENCE OF PICK-ONE THAT IS NOT A DEFECT: F-16's bare-name deref NO LONGER
#   APPLIES TO `NumbeR`.** On the pre-change control, `walkRules(NumbeR)` printed three lines and
#   walked `numberSet`; today it walks the real `NumbeR` and all six descendants. **F-16's
#   "done when" is satisfied for NumbeR — by removing the group data, not by changing the call.**
#
#   ## ⚠⚠ SECOND LATE ADDITION — THE QuotE ORDER-DEPENDENCE DISSOLVED, AND IT WAS MY INSTRUMENT
#
#   **THERE IS NO PREDECESSOR AND THERE IS NO ORDER DEPENDENCE.** `incant/bisectQ` walked TokenXP in
#   real order (QuotE is SEQ 19 of 30) and took the endpoints first: **N=0 crashes, and N=18 — every
#   compile that precedes QuotE — STILL CRASHES.** One difference between the arms was visible in one
#   look and got one run: the walk calls `compile(argument);` bare, my driver wrote
#   `bqTarget := compile(argument);`.
#
#   | run | result |
#   |---|---|
#   | N=0, driver frame, **`:=` capture** | **139** |
#   | N=18, driver frame, **`:=` capture** | **139** |
#   | N=0, **bare** `compile` | **exit 0, sentinel** |
#   | N=0, walk's own call path (bare) | **exit 0, sentinel** |
#
#   **One variable, and it is not a rule.** The walk passed because `walkRules` has always called
#   compile bare. Filed **F-22**, candidate trap, **symptoms only** — a `:=` capture of a COMMAND
#   RETURN segfaults; that is bear-trap #3's family (`:=` stamps `byRef` permanently) and no
#   mechanism is claimed.
#
#   ⚠⚠ **RETRACTED: the row-8 matrix in the block above was measuring the fixture.** It reported
#   `QuotE` 139 (2/2), `NamE` 137, `tokenize` 139, `GrouP` clean, and I read a shape split off it —
#   members-shaped compiles, attribute-shaped crashes. **Bare call: `QuotE` exit 0, `tokenize` exit
#   0, `GrouP` exit 0.** Two of the three crashes were the capture. **And the green row is what made
#   it convincing** — `GrouP` passing read as proof the instrument discriminated, when it only proved
#   the defect is not universal. **A matrix with one green row is not thereby a working instrument.**
#   ✅ **STANDING:** `NamE` still **hangs (137)** with the bare call, at a 45s cap and at 150s. Real,
#   and deliberately not chased.
#
#   ## ⚠ AND PICK-ONE NOW HOLDS WITH NO EXCEPTIONS — the classifier was wrong about the containers
#
#   A bin's or registry's data is **DERIVED, not authored**: `GroupItem::addGroup` folds each member's
#   first character into the set at **add-member time**, and nothing anywhere authors it. So
#   `BrancheS` and `Operators` were reported as hybrids **that were never written**. Both readers now
#   exempt a container by `!binType` — **the same test `addGroup` writes under, so the reader cannot
#   drift from the writer**. `-MD-` **2 → 0**; members-shaped 11 → 13.
#   **No new flag, and none was needed.** The only existing candidate, `altered`, is the
#   stak-invalidation bit that `resetStak` **clears** — a derived mark stored there would evaporate.
#   `census.target` did **not** move and no re-pin is owed: the planner's 30 PLAN rules never reach a
#   container. `pop.sh`'s partition row re-pinned — ⚠ an empty expected set is an absence check, so it
#   now also asserts the data-shaped population non-zero (**17**).
#
#   ## ⚠⚠ THIRD LATE ADDITION — F-17e CLOSED, AND THE COUNT IT WAS SUPPRESSING IS **56 OF 56**
#
#   **`compile` no longer exits on a refused parse** (`Commands.rtn`, `exit(1)` → `return null;`).
#   `processCode` had already reported through `reportCodeFail` by the time control reached that
#   line, so the exit added nothing but the end of the process — and a refusal is now a **value a
#   caller can tally**. `runParse(Start)` used to die at the first `ERROR processCode`; it now
#   reports **six** and keeps going.
#
#   **THE CAMPAIGN'S ACTUAL POSITION, and it is worse than the number everyone was quoting.**
#   `incant/walkPhase`, exit 0, sentinel:
#   ```
#   entered 139 · generated 56 · leaf 60 · refused 23     (sums, no remainder)
#   census 56  ->  compiled 0 · rejected 56
#   ```
#   **Nothing compiles. Not 53 of 54 — 56 of 56**, and this is the first time the figure was
#   *takeable*, because the exit was terminating the census that would have produced it.
#   ⚠ **The instrument was checked before the number was believed, twice:** the 56 `ERROR
#   processCode` lines name **56 distinct rules**, and that set is **identical** to the set of 56
#   `COMPILING` lines — corroboration from a channel the tally does not control — and the sweep was
#   re-run with `=` in place of its `:=` capture, returning the identical verdict.
#
#   ## ⚠ NamE IS NOT FRAME-DEPENDENT — IT IS **PHASE**-DEPENDENT, and that is the finding
#
#   | configuration | NamE |
#   |---|---|
#   | standalone, driver frame | **137 hang** |
#   | standalone, walk's own call path | **137 hang** |
#   | after an 18-rule prefix, either frame | **137 hang** |
#   | after the **full** 30-rule TokenXP prefix | **137 hang** |
#   | inside `walkPhase`'s **two-phase** run | **refuses cleanly**, run completes |
#
#   **So there is no minimal walk target to name — the minimal reproducer is STANDALONE**, and it is
#   installed as **`runNamE`** in `IncantForms/WorkingOn/parser` (swap the foot line to
#   `runNamE(NamE);`; it hangs at a labelled `cerr`, so the last line printed names the statement).
#   The discriminator is neither the frame nor the prefix: it is **whether the grammar is fully
#   generated before anything is compiled.** Two-phase turns the hang into an ordinary refusal —
#   Ruling 4's split doing real work. Filed **F-23**; Tony's, in Xcode, and the texture is a cycle to
#   interrupt rather than a frame to catch.
#
#   **`parser` is current** — driver-as-action, cerr sentinel, bare `compile`, **zero `:=`**. Two
#   things in it predated today: the post-mint prediction is **retired in place** (its
#   `CENSUS prune-noPrint` counters were removed in the 08-18 offline edit, so no run can settle it —
#   kept as provenance, marked do-not-repair-by-re-adding-the-counters), and the stale `Start` note
#   is replaced by the six-refusals-then-hang measurement.
#
#   **F-22 sweep, listed and untouched:** `enumT:53` · `walkPhase:129` · `compileProbe:65` and `:75`.
#   None crashes today. ⚠ **`:= new(...)` / `:= copyOf(...)` are NOT on it** — that is the sanctioned
#   mint idiom; the suspect shape is a **command return**. **F-24 opened** in passing: `compile`
#   returns the FIELD for an uncoded subject, so `compileProbe`'s own row C has been printing `????`
#   on every run with nobody watching. It does **not** touch the 56/56 — all 56 were `isCoded`.
#
#   ## ⚠⚠ FOURTH LATE ADDITION — THE DISCRIMINATOR IS `setParse`, AND THE PHASE STORY IS RETRACTED
#
#   The provenance exhibit was built to Clay's brief and **came back negative** — `runTokenHand`
#   and `runTokenWalked` **both compile**, so how the body was authored is not the discriminator.
#   But `Token` **does** refuse inside `walkPhase`'s sweep, same rule and same install path, so one
#   call separated those runs. It did:
#
#   | run | result |
#   |---|---|
#   | `runNamE(NamE)` — genParseTest **with** `setParse` | **137 hang** |
#   | `runNamEnoParse(NamE)` — identical, `setParse` suppressed | **exit 0, completes** |
#   | `walkPhase` as committed (**no** setParse) | 56 clean refusals, sweep finishes |
#   | `walkPhase` **with setParse added** | ⚠ **hangs on its FIRST swept item** (`StatemenT`), 0 refusals |
#
#   ⚠⚠ **F-23's phase reading, filed this morning, is RETRACTED.** I read the difference as one-phase
#   versus two-phase — *"NamE compiled against a grammar that is only partly generated"* — and the
#   two-phase arm simply **never armed the rules**. The phase split got the credit for `setParse`'s
#   absence. **Structural claims here hold, causal ones fail; this was a causal one, and it is the
#   sixth.**
#
#   ⚠ **The mechanism was in writing BEFORE it was measured**, which is the only reason a reading is
#   offered: `setParse` binds `parseMethod = parseRule` (`GroupRules.mm:12200`, one-shot behind
#   `if (!parseMethod)`), and `parseRule` reads the rule's own `CodE` (`:9949`). **F-17a** already
#   called this *"activation happening during generation"*; **F-18**'s ruling already recorded that
#   `field.parse(...)` *"trades crash for infinite recursion through the parseMethod fork"*. A hang is
#   what that predicts. **NOT measured and not claimed: the recursion itself** — that is the walk, and
#   breakpoints **B9/B10** are aimed at exactly it (`parseRule` entry, *the frame to watch repeat* —
#   the same tag recurring IS the loop).
#
#   **`IncantForms/WorkingOn/parser` is the deliverable** and carries its own crib: a four-command
#   recipe with each outcome measured, five uniquely-named inert anchors (fleet UNMOVED confirms no
#   leak), and ten breakpoints each with a re-find grep, because `GroupRules.mm` is generated and any
#   retok moves them. Filed **F-25** for the negative exhibit, kept in the file as the control.
#
#   ## FIFTH LATE ADDITION — THE MINION-DAY PILOT RAN, AND `minionWork/` NOW EXISTS
#
#   One charter, read-only, solo. **`minionWork/jitArcPhase1`** is a DesignDocs-format report on the
#   jit arc — 19 claims, **9 current · 7 superseded · 3 current-with-caveat**, each carrying the
#   command that checks it. It parses, walks, and verifies itself. **`minionWork/pilotAddendum.md`**
#   is the protocol verdict. Status **unbaked**: nothing installed, nothing measured moved.
#
#   **Three doc claims moved and they matter to anyone reading `docs/jit.md`:** *"exactly ONE gated
#   statement handler"* → **twelve**; *"42 ops, 18 gated"* → **44 and 20**, with the membership wrong
#   in two named rows (`opDot`, `opRem` are gated and sit in the not-gated list); and §3.4's
#   *"sharpest **OPEN** contradiction"* → **resolved by O4**, ratified 2026-07-31, one day after
#   §3.4's own asOf and inside the same consolidation.
#
#   ⚠ **AND A NEW AUTHORING FACT, MEASURED AND NOT YET FILED IN THE TRAP TABLE: A BLANK LINE INSIDE A
#   `define` BLOCK ENDS THE BLOCK.** Silently, at exit 0, with `RunRulE: expected a method not <next
#   entry>` on stderr — the documented truncation signature. Found by losing a cycle to it. It was
#   **not filed** because the pilot's writes were fenced to `minionWork/` and the IPC file, so it is
#   **owed a home by someone with the write** — `docs/kantCorpus.md` beside KANT-42 is the fit.
#
#   Also filed this session: **`CLAIM KANT-42`** — a brace is **inert** in a defining string body and
#   **still bites** in a `code={ }` body, both sides measured with a negative control. That is what
#   lets a minion claim carry its verification command verbatim with no escaping convention.
#
#   ## NEXT SESSION OPENS ON
#
#   1. **Tony's two rulings, both now priced by measurement:** F-15 option **(b) first** (off-rule
#      storage / explicit activation), and **does pick-one apply to a container** (BrancheS,
#      Operators).
#   2. **`KantParser` needs a home** — `incant/designDocs`, then compile-verify, then the noPrint
#      clause if it is ruled.
#   3. **F-20** — `setParse` writes `field->rStuff` while `parse()` reads `definingRule().rStuff`.
#      Graded structural-not-measured; one probe printing two pointers settles it.
#   4. **F-13/F-14**, and Tony's offline Xcode walk, row 8.
#   5. **Owed by Tony:** the two `iterT1m` re-pins, `docs/commentMinion.md` to Clay, and adjudication
#      of `IncantForms/WorkingOn/{incant++,parser}`, dirty since before this session (H8).
#
# ⚠⚠⚠ SEALED 2026-08-17 LATE — SUPERSEDED by the 2026-08-19 block above. Kept intact.
#
#   THE ONE-LINE STATE: **the day the monty ran, and the day it turned out not to have.** The walk
#   generates 54 rules and terminates; the strict jit sweep closed 10/10; and the last hours were
#   an eight-hypothesis hunt that ended with the cause NOT FOUND and the search space finally
#   narrowed by measurement. **Tony takes the parse offline from here with an Xcode walk.**
#   Fleet **40 green / 1 parked, byte-identical to this morning's baseline.** jitLadder **205 ok,
#   stderr 0, one owned red (JV/F-12)**. Both repos pushed. Tree clean but for Tony's `incant++`.
#
#   ## ⚠⚠ THE THING A FRESH READER MUST NOT RE-DERIVE: WHAT "IT WORKS" ACTUALLY COVERS
#
#   **`walkRules(Start)` terminates and emits 54 correct-looking parse bodies. NOTHING COMPILES.**
#   The 147 walk entries partition with **zero remainder** — 54 generated, 73 leaf-installed,
#   21 revisit-refused — but `processCode` refuses **53 of the generated bodies**, and that was
#   invisible until this evening because `compile` had been silently refusing every rule.
#   **So the ledger is: generation ✅ · installation ✅ · compilation ❌.**
#
#   ## ⚠ THE FALSIFICATION TABLE — EIGHT HYPOTHESES, SEVEN DEAD, ONE REPRODUCING
#
#   | # | hypothesis | died on |
#   |---|---|---|
#   | 1 | missing `this`/`tempField` | ensure block landed (prune-noPrint 34→102), still 53 |
#   | 2 | generated shape invalid | all shapes compile at define time |
#   | 3 | mint path broken | hand-built CodE → `compile SUCCEEDED` |
#   | 4 | emitter reads `.text` not tag | every leaf spells as a name; `SemI()` correct **14×** |
#   | 5 | the body content | `Token`'s **real body** compiles standalone |
#   | 6 | `clear(CodE)` | passes with and without |
#   | 7 | dedent / close-brace indent (Tony's suspect) | both indents compile |
#   | **8** | **the target is a real grammar rule** | ⚠ **REPRODUCES — 139** |
#
#   **Row 8 is the live lead and it is one line to reproduce:** an identical trivial body compiles
#   on a PLAIN FIELD and **exits 139 on a REAL GRAMMAR RULE** (`QuotE`). The variable was never the
#   text — it is **what you attach it to**. ⚠ **And note where that points: a rule carrying BOTH its
#   grammar structure and a compiled body is the two-live-paths shape R-2 forbade.**
#
#   ## WHAT LANDED — 11 commits, all pushed
#
#   | commit | what |
#   |---|---|
#   | `a2711e6` `9f1beba` | **step 2 pathfinder** — `*` then `>` emit through a `jitEmitter` slot |
#   | `1913c6a` `04df6b1` | **sweep batches 1 & 2 — STRICT BINARY/COMPARISON MIGRATED 10/10** |
#   | `2a4d97b` | `compile`'s `isCoded` guard — an uncoded field truncated a whole run at exit 0 |
#   | `533fa2e` | **F-11 census** — expected zero customers, found one |
#   | `66f5be7` | **`showBody`** — the pointer instrument, and the aliasing it found |
#   | `dfd5a23` | **`mintT`** — five spellings of "give me my own node", two correct |
#   | `95e8e19` | **Tony's mint** — every rule gets its own CodE; the walk terminates |
#   | `0874699` `5e35cab` | **`:.` SETS, all nine flags** (Tony's ruling) |
#   | `8dd7cd6` | R-4 ensure + `reportCodeFail`, **diagnosis falsified in the message** |
#
#   ## ⚠ RULINGS BANKED
#
#   **R-2 RULED — REPLACEMENT, NOT COEXISTENCE**, verbatim from `jit.md` §0. Generated parse IS the
#   parser; old `parse()` is the specification and transitional fallback. **Ruling 1 later hardened
#   it: no fallback arm at all — refuse loudly.** ⚠ **The fork-3 counter and crossing fixture were
#   STRUCK** — no second arm means nothing to count.
#   **R-3 OPEN — the assign-semantics census.** *What does a name bind to, and what does writing
#   through it touch?* Three rows from one drill, and they are ONE question answered differently per
#   operator and per position.
#   **R-4 RULED, IMPLEMENTED, AND ITS DIAGNOSIS FALSIFIED.** compile owns the preconditions; they
#   were genuinely absent; that was not the trip point.
#   **RULING 3 (cycle guard) RETIRED ON EVIDENCE** — ENTERs 130 at a 20s cap and 130 at 40s, 77
#   distinct rules, identical. The walk terminates on its own merits.
#   **`:.` SETS FOR EVERY FLAG.** Census first: zero sites relied on toggling, **five were broken by
#   it** (`isPercenT` on reused locals in `utilities`' layout loops).
#
#   ## ⚠ THE NAPALM IS REAL, AND IT HAS A CUSTOMER
#
#   **Once the generated methods install, the parser can no longer read the source that follows** —
#   after `walkRules` runs, no further statement executes, not `cerr`, not a registered action, not
#   `stop()`. Not a hang: the generated parser is live enough to **eat its own loader**. The
#   loader-separation question (generation vs activation, separable in principle, not separated
#   today) now has a paying customer and belongs on the queue as its own item.
#
#   ## THE INSTRUMENTS — four new, all born this week
#
#   `showBody` (node + groupBody addresses; incant accessors are snapshot-by-value so identity is
#   otherwise unaskable) · **`incant/flagT`** (does `:.` set a flag) · **`incant/bodyT`** (do two
#   attachments alias — ⚠ **its verdict INVERTS when the mint lands; do not "repair" it**) ·
#   **`incant/mintT`** (which spelling gives me my own node — the R-3 copy-semantics chapter,
#   pre-written and executable) · `reportCodeFail` (named home for parse-error reporting; converges
#   with `aCTionFailed` when someone makes it good).
#   Ladder rungs **JM1-JM4** carry the slot migration; `slotrung` asserts the count and fails on a
#   MISSING line.
#
#   ## ⚠ TRAPS COLLECTED, ALL PAID FOR IN ONE DAY
#
#   - a block comment **between an `if`'s closing brace and its `else`** wipes the extern block to 0
#     (bear-trap #29 — walked into while writing an error handler)
#   - `%-` inside a passthrough format string **is the close delimiter**
#   - a `:` inside a string literal collides with the `:` print terminator
#   - **literal braces inside a string in a code body close the block early** — which is why Tony's
#     `openBrace`/`closeBrace` fields exist
#   - **`+=` on a name adds an ATTRIBUTE** (via `addString`), it is not the member-add `:+`
#   - `field[CodE]` in a fresh extern killed the process; three separate bites
#   - ⚠ **`[]` runs `get(String)` and IS agnostic between attributes and members.** A claim that it
#     is not was cited from a sealed doc without re-measuring, then "confirmed" by a probe using the
#     wrong operator. **Corrected by Tony.** Re-measure before citing, then re-measure the probe.
#
#   ## NEXT SESSION OPENS ON
#
#   1. **Tony's offline Xcode walk of the parse** — row 8 is the lead.
#   2. **Bootstrap rules in `GroupMain.twk` are ARMED, not firing** — they carry bare literals
#      (`strap += "["`, `new("{")`) whose tags are the characters, and never got the
#      labelled-literals cleanup the grammar did. The walk does not reach them yet; it will.
#      Two grammar-level siblings exist: `grammar:60` (`define`) and `grammar:61` (`RunRulE`) carry
#      bare `';'`, and they are the only source of the one `;()` emitted. **`SemI=";"` is innocent.**
#   3. **F-13/F-14** — the aliasing exhibit and the walk's four silent exits (now instrumented).
#   4. **Owed by Tony:** the two `iterT1m` re-pins, and `docs/commentMinion.md` to Clay for review.
#
# ⚠⚠⚠ SEALED 2026-08-17 — earlier vintage, superseded by the block above.
#
#   THE ONE-LINE STATE: **the runway session. It opened on the 08-16 seal's own queue — F-5, the
#   landable-set declaration, the capture — and cleared all of it. F-5 is CLOSED across two foreign
#   repos, the compile/actionTypE trio is LANDED with the fleet certified UNMOVED, and STEP 2 IS
#   NOW OPEN.** Fleet **40 green / 1 parked**, reds `iterT1m` ×2 + `jsonTest baseline`, all
#   pre-existing. Three repos clean or intentionally dirty; everything pushed.
#   ⚠ **THE NAMED OMISSION, per the valve: the two `iterT1m` re-pin sentences are STILL NOT IN HAND.**
#   Sealed without them, knowingly. They remain Tony's, KE-4.
#
#   ## WHAT LANDED — 3 commits across 2 repos, all pushed
#
#   | commit | repo | what |
#   |---|---|---|
#   | `1e4c738` | **Parse** | `.act` bodies attach to their rules; `PLG.C` regenerated BARE, not committed as found |
#   | `fcb87b8` | Groups | `fixIts`: **F-5 closed**, **F-10 opened** |
#   | `62deb33` | Groups | **Tony-commit — the `compile` command and the `actionTypE` group field** |
#
#   ## ⚠ THE THINGS A FRESH READER MUST NOT RE-DERIVE
#
#   1. ⚠⚠ **BEAR-TRAP #31, AND IT IS THE DAY'S BEST FINDING BECAUSE IT ARRIVED DISGUISED AS THREE
#      REGRESSIONS.** `incant/setup` is read at **RUNTIME**, so Tony's `compile immediateAction;` was
#      live against a binary that had no such extern. The fleet read **37 green, not 40**. Four rows
#      carried `setCompiledMethod: ERROR no method found compile`; three went red on that line
#      ALONE — and all three are fixtures with **nothing to do with the new command**
#      (`manyScratch.target`, `displayForm baseline`, `oneTest baseline`), because the error prints
#      into the output a diff-based row compares. **The control is one command** —
#      `git checkout HEAD -- incant/setup`, re-run — **and it reproduced the seal exactly at 40.**
#      Order is **rebuild, then measure**. A fleet number taken between the edit and the build is a
#      number about the gap.
#   2. ⚠ **TONY'S `Generate.rtn` WIP DOES NOT TOK — IT SEGFAULTS AND WIPES THE EXTERN BLOCK.**
#      `tok GroupRules.twk` with his working `parseRule` in the chain exits **139** and takes the
#      canary **288 → 0**, which then fails the build three files away in `Bytecode.mm` with nothing
#      pointing home. Cause is the bare unbound `action` in `if result = action["BlocK"]` — the
#      fallout of removing `processCode` from `parseRule`, which **he has already diagnosed**. tok
#      says `FAIL Block at: if result = action["` / `FAIL Body3` / `Expected a semi-colon`.
#      **For the landing his file was set aside to HEAD and restored byte-exact** (md5
#      `4d31e82e55bee529c2b92f4f878313aa`). It is untouched, still dirty, still his.
#   3. **THE TRIO IS ADDITIVE AND IT WAS PROVED TWICE, NOT ASSERTED.** Extern set **288 → 289**, diff
#      exactly one line (`extern "C" GroupItem *compile(GroupItem *field);`). Fleet body
#      **BYTE-IDENTICAL** to the control, 62 lines each, zero differing check rows — the only capture
#      diffs are the harness's own H1 header and tree-state list, which move by design.
#   4. ⚠ **ONE LINE OF TONY'S CODE WAS REPAIRED AND IS NAMED, NOT BURIED.** `compile` could not
#      compile: `processCode` returns **`int`**, not `GroupItem`. Landed as
#      `if !processCode(field) return 0; return field;` — preserves the failure signal, matches
#      `cLEAR`/`cOPY` either side of it, and `walkRules` ignores the return anyway. **If Tony wanted a
#      bare success flag, that is the line.**
#   5. **`plgDirectives` IS NOT `groupDirectives` — F-10.** Some of its entries generate **flag-gated**
#      debug support (`if ( state->debugRulePLG || debug )`) and **that generated code IS the committed
#      baseline** (`GUARD-REJECTED`: PLGrule.twk **0**, PLGrule.C **1**; same in `Alternative`,
#      `Element`). So a bare retok of those files **silently deletes working debug support** — the
#      exact opposite of the correct answer for `PLG.C`, same repo, same directives file, **no marker
#      at either target saying which.** Not bear-trap #23 repeating: #23 discriminates *normal build*
#      from *hunting*; here both are normal builds and the discriminator is **which file**.
#   6. **DEAD CITATION: the 08-16 seal's "the reissued brief is in the Clay channel" IS NOT THERE.**
#      `ipc/clay-to-clod.md` ends at **SEQ 55, dated Aug 11**, all cleared — it predates the 08-16
#      rulings. The operative step-2 spec is the **Fearless relay text**, which says so itself.
#      One grep, and it is the same class the doctrine already names.
#   7. **F-6 DISCHARGED** in `62deb33`'s message: `parseRule`'s jitting-gate removal is **INERT**
#      (`jitting` is raised only inside `jitRunAction`, so it is false during parse).
#
#   ## ⚠ DOCTRINE EARNED
#
#   - ⚠⚠ **A SURPRISING RED IS A HYPOTHESIS. RUN THE CONTROL BEFORE YOU NAME A CAUSE.** 37-vs-40 had
#     a ready story (three regressions from Tony's edits) that was **entirely wrong** and would have
#     sent the session hunting in three unrelated fixtures. The control cost one command. This is
#     doubt-the-instrument met from the cheap direction, and it is the second time in two sessions
#     that a one-command control beat a plausible reading.
#   - **`${PIPESTATUS[0]}` BIT AGAIN, IN THIS SEAT, ON THE DAY ITS TRAP WAS RE-READ.** `tok ... | tail`
#     reported an **empty** exit status; taken directly, `tok` was exiting **139**. Third recorded
#     instance on this project. **Knowing the rule does not prevent the error** — which is the
#     make-it-unconstructable argument, again.
#   - **A REGENERATED ARTIFACT IS A TEST, AND IT SHOULD CARRY A PREDICTION.** `PLG.C` was regenerated
#     under three pre-registered predictions (pure deletion · exactly the `attachActions` hunk vs HEAD
#     · `PLG.h` byte-identical). All three held, which is what made the commit safe to write rather
#     than hopeful. `tok` being dated **Nov 10 2024** — the same binary that produced the working copy
#     — is why the test had no drift in it, and that was checked, not assumed.
#
#   ## THE INSTRUMENTS
#
#   Unchanged fleet: `pop.sh` (**40 green / 1 parked**) · `smoke.sh` · `smokelib.sh` · `parked.sh` ·
#   `kantRatchet.sh` · `kantCensus.sh` · `completePop.sh` · `alphaLint.sh`.
#   ⚠⚠ **`jitLadder/ladder.sh` IS ON THE SEAL ROSTER AS OF 2026-08-17** (Clay's call, Tony
#   ratified). **EVERY SEAL FROM HERE RUNS IT AND RECORDS ITS STATE BESIDE `pop.sh`.** Current
#   state: **199 ok / 1 OWNED RED / exit 1 / stderr 0 bytes.** The red is **JV**, annotated in
#   place and naming **`docs/fixIts.md` F-12**; it is **pre-existing, not the sweep** — bounded by
#   one look to **at least 2026-08-11**, standing across every seal since, *unnoticed precisely
#   because the ladder was not on the roster.* That is the argument for putting it there.
#   ⚠ Its stderr was **90 bytes of shell syntax error on every run** until 2026-08-17 — backticks
#   inside a double-quoted `echo` read as command substitution. Now 0. **Standing stderr noise in
#   an instrument is where a real failure hides**, so a non-zero byte count is itself a finding.
#   **NEW DOCS:** `docs/commentMinion.md` (**Track B charter, DRAFT — Clod drafted, CLAY REVIEW OWED,
#   no minion sees it until both sign**) · `docs/jitterBrief.md` (**queued behind step 2; do not start
#   before `processJit(field)` exists**).
#
#   ## ⚠⚠ MILESTONE — THE STRICT BINARY/COMPARISON SWEEP IS COMPLETE, 10 OF 10
#
#   Every strict `(argument,target,selector)` op now emits through a `jitEmitter` slot on its own
#   node instead of an `if jitting` gate inside its interpreter body:
#   **`*` `>` `>=` `<` `<=` `==` `!=` `+` `-` `/`** — pathfinder, op two, then two batches of four.
#   Ledger, recipe and obligations: **`docs/jitSlotMigration.md`**.
#   ⚠⚠ **THIS IS NOT THE SWEEP CLOSING, AND NEVER-NULL STAYS OPEN.** What remains is
#   **out-by-SHAPE, not unswept** — the `jitEmitDot`/`jitEmitRem` pair take a **third** argument
#   (`ruler->tempField`) and need a shape-extension ruling; three are `jitEmitUnary`;
#   `jitEmitAssign` is a shape *fit* parked for other reasons. **The null slot therefore still
#   means "not yet migrated", so hardening now would fail on every one of them.**
#   **THE CERTIFICATION IS A COUNT AND HAD TO BE:** the fork is value-transparent by construction,
#   so products are blind to it. `gJitSlotCount` is asserted by rungs **JM1-JM4**, a batch of N
#   asserts the count moving by exactly N, and **five H7 pulls** have now shown the same shape —
#   pull one registration, the count drops by one, **the values do not move.**
#   **THE UNARY EDGE IS HARDENED** — `gJitSlotUnaryRefused`, loud and counted, **demonstrated to
#   fire** by temporarily slotting `'++'` (refused 2, slot count 0, values still right). Retire
#   guard, counter and rung row **together** when the unary specimen lands.
#
#   ## NEXT SESSION OPENS ON — step 2, and two things waiting on other people
#
#   1. ⚠ **STEP 2 IS OPEN AND UNBLOCKED.** Pathfinder **`opMultiply`/`jitMul`**; slot **`jitEmitter`**;
#      **slot beside the BINDING**, not beside `operateMethod`; **presence-gated fork in `runOP`'s
#      existing seed gate ONLY, no new gates**; ⚠ **`jitCantEmit`-delegating-to-`operat` FORBIDDEN in
#      every window.** Spec is the relay text (see dead citation, #6 above).
#   2. **Clay's review of `docs/commentMinion.md`.** Its live recommendation: take the trial from
#      **`Commands.rtn`** (`arrondir` 42 lines, optional second `guard` 22) and **NOT** from
#      `Instruct.rtn`, whose fattest targets are `opMultiply` (the pathfinder itself), `opPlusPlus`
#      (parked as F-7) and `runOP` (the seed gate) — *"tracks don't touch"* would otherwise be
#      nominally true and literally false.
#   3. **Tony:** the two `iterT1m` sentences (KE-4), and whether `compile`'s return shape is what he
#      wanted.
#
# ⚠⚠⚠ SEALED 2026-08-16 — shutdown seal (superseded 2026-08-17, kept as the reasoning trail).
#
#   THE ONE-LINE STATE: **the kitchen-cleaning session. It opened on the curve ball's residue —
#   an unreconciled tree, an instrumented binary and a fleet reading 29 green — and closes at
#   **40 green / 2 red / 1 parked**, Groups clean, both repos pushed, fourteen commits.
#   ⚠ **THE SEAL CAPTURE ITSELF IS NOT DONE.** It waits on Tony: the F-5 declaration, two
#   `iterT1m` sentences, and the landable-set declaration. **Next session opens there**, and
#   step 2 fires behind one capture.
#
#   ## THE ARC, because the shape is the lesson
#
#   A B0 gate census (measurement only) → a classifier fix → an isLiteral recon → an arbitration
#   that overturned the recon's own inference → a reconciliation → a fixit register → the
#   generator quarantine. **Every step was generated by the measurement before it**, which is why
#   `docs/fixIts.md` now exists: findings were arriving faster than anyone could act on them and
#   were living in commit messages, which is recorded and simultaneously lost.
#
#   ## WHAT LANDED — 14 commits, all pushed to `jit-unified-emit-wip`
#
#   | commit | what |
#   |---|---|
#   | `8b4c0da` | **B0 gate census** — 51 live gates, 21 SHIM / 29 SHARED / 1 CROSSER / **0 PARSE-ADJACENT** |
#   | `ffb145f` | `jitDfProbe`'s `aCTionIterate` no-gate claim corrected in the current-truth block, not in place |
#   | `0a75df5` | **`planTerm` plans literals as LIT again** — keyed to the representation, never `isLiteral` |
#   | `73294e5` | isLiteral recon — the flag is not lost in transit |
#   | `85690e5` | **the `:1381` arbitration** — flag SET, gate LIVE, my own inertness flag withdrawn |
#   | `b1482ff` `2364b05` | `Aside/` and `BackupIncant/` ignored **and untracked** (52 files out of the index) |
#   | `9f0a73f` | four targets re-pinned, `useDefaultSpace` semantics kept |
#   | `16f165c` | **bear-traps #29 and #30** |
#   | `b18b2a3` | `aCTionDefinE:376` named as the operator-naming site |
#   | `6212a71` | **Tony's offline work committed** (13 files) + support `2c6e101` |
#   | `3e86fab` | **`docs/fixIts.md`** — the capture queue |
#   | `5b63e6b` | **F-1** — `aCTionParens` clears unconditionally, audit runs again, 12 → 0 |
#   | `83cbbd7` | **generator quarantined** into `incant/generating`, off the roster |
#
#   ## ⚠ RULINGS BANKED, WITH OWNERS — do not re-derive any of these
#
#   **STEP 2 IS FULLY ARMED. All three design questions are CLOSED** (Clay, ratified by Tony):
#   1. **The slot sits beside the BINDING**, not beside `operateMethod` — uniform across binary
#      (`operateMethod`/`isOperator`) and unary (`ruleMethod`/`method`/`isMethod`). The
#      binary/unary split is **interpreter dispatch anatomy and the jit does not inherit it**.
#      This is what reaches all 13 selectors; an `operateMethod`-adjacent slot reached only 10.
#   2. **The slot is named `jitEmitter`.** `jitMethod` is TAKEN — `rStuff.jitMethod` means the
#      compiled **OUTPUT** of a field's method; this slot holds the emitter **FUNCTION**. Same
#      stem as `jitEmitX`/`jitEmitters.rtn`, so the mechanism greps under one name.
#   3. **Presence-gated fork during migration** — slot installed → driver calls it; absent →
#      existing gated handler, untouched. ⚠ **`jitCantEmit`-delegating-to-`operat` is FORBIDDEN in
#      every window** (a silent identity default). Never-null hardens at sweep close, certified by
#      a slot census. Pathfinder **`opMultiply`/`jitMul`**; fork in **`runOP`'s existing seed gate
#      only**, no new gates. The reissued brief is in the Clay channel.
#   **GENERATOR QUARANTINED** (Tony) — `incant/generating`, off the POP roster, exhibit captured
#   non-normative. Rationale: **a baseline over inactive work pins a moving target** and turns
#   every grammar edit into re-attribution on rows nobody owns.
#   **THE TONY-COMMITS RULE** (ratified): Tony's verified work is committed by Clod as **separately
#   labelled Tony-commits**, once Tony declares the landable set. **Forbidden: mixing his hunks
#   into a commit describing other work.** Tony alone declares landable vs mid-thought.
#   **THE FIXIT CHARTER** — `docs/fixIts.md`. **Capture, don't chase.** A row is minion-ready or it
#   isn't a row. **Plain language first: the list's first reader is Tony**; if it can't be stated
#   plainly it is still a measurement, not a finding. Three registers — **fixIts** (parked
#   findings) / **knownErrors** (deep defects awaiting rulings) / **TODO** (roadmap). **A
#   waystation, not a residence.**
#   **THE DIRECTIVE CONTRACT, measured in 3 cases** — one directive per target function; the
#   **first ARMED** entry in file order wins; **disarmed entries are skipped entirely and hold no
#   slot**; **anchors do NOT create separate slots**; losers fail **SILENT** with a clean `tok`.
#   ⚠ **BY DESIGN per Tony — do not propose fixing tok.** Discipline: **grep the `.mm` for your own
#   marker before trusting any directive run.**
#
#   ## ⚠ THE THINGS A FRESH READER MUST NOT RE-DERIVE
#
#   1. **`isLiteral` DIES AT EXACTLY ONE LINE** — `aCTionTraiTdata`'s else arm, `setContent`: a
#      **content copy, and a flag is not content.** It is ALIVE at the `:1381` gate (measured: all
#      eight relabelled literals arrive `isLiteral=1 isRule=1`, so **the gate is LIVE and stays**)
#      and dead by rule-term arrival. **NOT duplication loss** — the copy constructor shares
#      `groupBody` and cannot lose it. The yak is parked with a one-sentence choice waiting: carry
#      the flag at that assignment, or ratify that content copies don't carry flags. **Nothing
#      depends on it** — `planTerm` is representation-keyed now.
#   2. **`aCTionDefinE:376` IS THE OPERATOR-NAMING MECHANISM.** `tag = text; text = 0` fires **55
#      times, every one an Operators-registry node, ZERO rules.** It looks like dead weight beside
#      the literal-labelling change; **delete it and every operator in the language unnames
#      itself, silently.** Guardian comment landed. It reads `NewGroup`, the thing being DEFINED,
#      never the terms inside it — which is why labelling literal terms does not reach it.
#   3. ⚠⚠ **THE GRAMMAR IS NOT CONFIGURATION. INNOCENT GRAMMAR CHANGES ARE GUILTY.** One
#      labelled-literal edit produced **three confirmed casualties**, each surfacing in a different
#      file from the edit: `planTerm`'s classifier (fixed — LIT/LITTO from the data), the
#      `InvokeArg` tag-sentinel (fixed in F-1's chase), `aCTionParens`' vacancy-clear (fixed, F-1).
#      **Two census rows stand for the two classes**: tag-comparisons-as-sentinels, and
#      clears-safe-only-by-vacancy (**F-9**, minion candidate, model repair is `aCTionBraced`).
#   4. **A PIN AT THE NATURAL-LOOKING ZERO ASSERTS NOTHING — collected, not theoretical.** The dead
#      rStuff audit emitted `0 missing rules, 0 missing terms, 0 loose, 0 unconsumed` and **would
#      have read GREEN forever** had the line been pinned at zero. It is pinned at its real
#      non-zero population, which is the only reason a dead instrument was visible. **Pins name
#      their population** — the 12 MISSTERM are named by hand in `pop.sh`.
#   5. **`oneTest`'s INCLUDES ARE LOAD-BEARING FOR THE AUDIT, NOT THE GENERATOR.** It no longer
#      generates anything, but `include(generate)` populates the registries the audit counts.
#      **Dropping it reads exactly like a regression** in a check re-pinned one commit earlier.
#   6. **TONY'S OFFLINE rStuff WORK CLOSED A POPULATION** — 12 MISSTERM → 0, **closed by
#      construction** (`aCTionDefinE` now mints rStuff for any `isRule` term lacking it), plus 10
#      uncounted `AUDIT TERM` rows. ⚠ **It was UNMEASURED until F-1 re-armed the instrument: the
#      reds were the audit failing to WITNESS a fix, not a fix breaking anything.**
#   7. **TWO DEAD CITATIONS.** The 08-15 seal's **"18 shims"** — the census says **21 SHIM** under
#      the ratified liftable definition, precedence **CROSSER > SHARED > SHIM > PARSE-ADJACENT**;
#      and there are **two different 18s** that coincide by accident (selector-passing sites vs
#      one-line-return bodies in `Instruct.rtn`). And **cross-session addresses cite `.rtn`/`.twk`
#      sources, NEVER `.mm` line numbers** — the brief's `GroupRules.mm:3904→2424` had expired.
#
#   ## ⚠ DOCTRINE EARNED
#
#   - ⚠⚠ **A MEASURED VALUE IS MEASURED AT A NODE AND AT A TIME. Moving it to another node is a
#     NEW CLAIM NEEDING A NEW MEASUREMENT.** Ledger-grade, and paid for by my own strike-through:
#     the B0-2 recon established that writer and reader are different nodes, then I applied that
#     finding to the flag's death **without applying it to my own inference**, and declared the
#     `:1381` gate inert. It is live. **The structural claim held; the causal extension did not** —
#     the standing asymmetry, collected again.
#   - **`diff -w` BEFORE "IT'S JUST SPACING".** `spell.target` was **69 spacing lines + 1 content
#     line**, and the 1 was the file's truth. Re-pinning on "it's just spacing" would have been
#     true of 69/70 and wrong about the file.
#   - **A BLOCK COMMENT'S POSITION IS LOAD-BEARING** — bear-trap #29. Between two arms of an
#     `if`/`or` chain it wipes the extern block to zero; above the chain or inside an arm body it
#     is fine. ⚠ **Every paragraph killed it individually**, which is what proves POSITION rather
#     than any token inside it — an hour hunting a bad character is an hour wasted.
#   - **`useDefaultSpace`'s persistent-`$` REVERSAL IS CONFIRMED DELIBERATE**, re-pinned across six
#     targets with H6 sentences. The `displayForm` case was **one byte**, checked with `od` because
#     the two lines render identically.
#   - **AN INSTRUMENTED BINARY MUST NEVER BE LEFT BEHIND A MEASUREMENT.** Three directive probes
#     this session, each restored byte-exact (md5 verified) and rebuilt bare before any POP.
#
#   ## THE INSTRUMENTS, so nobody rebuilds one
#
#   `pop.sh` (fleet, **40/2/1**) · `smoke.sh` · `smokelib.sh` (sourced never copied) · `parked.sh` ·
#   `kantRatchet.sh` · `kantCensus.sh` · `completePop.sh` · `alphaLint.sh`.
#   **NEW:** `incant/litProbe` (labelled vs bare literal shapes) · `incant/litFlagProbe`
#   (`isLiteraL` at the read sites) · **`incant/generating`** (the quarantined specimen — RUN ON
#   DEMAND, never in the roster) · `docs/emitted/generating-exhibit-2026-08-16.txt` (**an EXHIBIT,
#   not a pin — nothing compares against it**).
#   ⚠ **A PROBE NEEDS `Start();` AS ITS FIRST LINE**, with `include`/`search` ABOVE the comment
#   header. Otherwise the includes never run, `search` fails token by token, and **`print` emits
#   ZERO BYTES at exit 0** — indistinguishable from a short successful run.
#
#   ## NEXT SESSION OPENS ON — Tony's queue, then one capture, then step 2
#
#   1. **F-5** — `Parse` (`PLG.C`, `PLG.twk`) and `Tokf` (`Name.h`) carry unaccounted dirt. H8
#      verdict per hunk: commit, revert, or named-WIP with an owner.
#   2. **Two `iterT1m` sentences** — the KE-4 re-pins, older than the SEQ 55 seal.
#   3. **Landable-set declaration** → Tony-commits → **capture ONCE** → seal → **step 2 fires**.
#   **PARKED DELIBERATELY:** the DesignDocs pancake, for a fresh head — Clod drafts the brief
#   against his four constraints (walker not bare-locate; no double quotes in entry text;
#   site-scoped warnings stay at their posts; walk entries, don't trust exit status) plus the
#   pancake criteria (mid-sized, spans the comment species, NOT `ruleActions`/`GroupActions`, NOT
#   the two giants); **Clay reviews before any minion sees it.** **F-6** (the correction owed to
#   `6212a71`'s message — the `parseRule` gate removal is INERT, `jitting` is raised only inside
#   `jitRunAction`) folds into the next landing.
#
# ⚠⚠⚠ SEALED 2026-08-15 — SHUTDOWN SEAL (CURRENT VINTAGE). READ THIS FIRST.
#
#   THE ONE-LINE STATE: **the curve-ball day. Tony coded offline in kant, brought back a
#   machine-written parse-method family and a rewritten `Generate.rtn`, and the reconciliation
#   of that work found and closed TWO defect classes hiding behind one another.** The fleet
#   closes at **41 green / 2 red / 1 parked — one green BETTER than the 08-13 seal it opened
#   from.** Both reds are `iterT1m`, pre-existing, older than the SEQ 55 seal, verdicts banked
#   in `docs/knownErrors.md` KE-4. **Kitchen is clean; the next session opens on a CHOICE.**
#
#   ## WHAT LANDED — one commit, one vintage (Tony waived the per-hunk walk on the fleet line's
#   ## authority)
#
#   | thing | state |
#   |---|---|
#   | Tony's offline work | `Generate.rtn` rewritten as a 12-method `parse*` family; `parseMethod`/`actionMethod` fnptr slots; `IncantForms/WorkingOn/parser` (kant emitter for parse bodies) |
#   | `opSetGroup` two-line fix | stamp inside the `if argument` guard, `isInitialized` set alongside |
#   | `opPlusPlus` exhaustion | `result.group = 0` on an exhausted iterator, via `setGroup` |
#   | `useDefaultSpace` | **BOTH halves restored** to `processAction`; the `aCTionPrinT` copy removed |
#   | `parseContainer` | the two lines lost in transcription from `testContainer` restored |
#   | alphabetical order | 8 `.rtn`, 288 units, **0 out of order**; `genLadder/alphaLint.sh` is the checker |
#   | DesignDocs pilot | `jitFieldMethod` 66 comment lines → 3; entry + 8 children in `incant/designDocs` |
#   | op-selector | **RATIFIED as the slot model**, no design session needed |
#   | probes | 7 new fixtures, all exit 0 with sentinels (see THE INSTRUMENTS) |
#
#   ## ⚠ THE SIX THINGS A FRESH READER MUST NOT RE-DERIVE
#
#   1. **`setGroup()` SET FOUR THINGS, AND BYPASSING IT DROPPED THREE OF THEM.** Tony's offline
#      `opSetGroup` wrote `gGroup` raw — deliberately, to stash a field without touching parent or
#      affiliation, which is right and stands. But `setGroup` also set `isInitialized`, cleared on
#      a null argument, and copied when the argument had a parent. **Two separate reds and one
#      SIGSEGV came out of the two flags it stopped setting.** When a raw-ivar write replaces a
#      setter here, enumerate what the setter did.
#   2. **`aCTionIF` READS `isInitialized` ON THE CONDITION'S VALUE** (`ruleActions.rtn`, generated
#      as `if ( result && result->groupBody->flags.isInitialized )`). That is why
#      `if action := generator[argument];` took the ELSE arm and the whole bytecode emit path went
#      dark at exit 0. **Certified by `incant/setGroupInit`**: row D `:=` in condition, row E `=`
#      control, row F `:=` as a statement then a bare test — **F is the load-bearing row, because
#      it proves the bind WORKED and isolates the failure to the condition-position read.**
#   3. **AN EXHAUSTED ITERATOR USED TO BE CLEARED BY ACCIDENT OF `setGroup(0)`.** With the guard
#      added it kept `isGROUP` and a stale `gGroup`, and `aCTionIterate`'s first line
#      (`while iterator.isGROUP  iterator = iterator.group;`) then **redirected the next iterate
#      onto the stale node**. Symptom: a second `iterate` over the SAME local walks zero items.
#      **Certified by `incant/iterReuse`** — A one local 3/0, B two locals 3/2, C reversed 2/0.
#      ⚠ **ROW C IS THE EXHIBIT**: reversing the order moves the zero, so it was never
#      "members are broken", it was reuse of the local. `incant/ruleCount` had been working around
#      this for weeks with `rcCur`/`rcCur3` and never said why.
#   4. **BOTH-PRESENT IS ZERO AND IS NOW REJECTED BY FIAT, like data+list.** No rule in the live
#      population carries both an attribute set and a member list: **0 both / 43 attrs-only /
#      13 members-only / 23 neither, over all 79 `Grokking` entries** (`incant/bothCensus`).
#      ⚠ **The zero is only worth the control that backs it**: `incant/bothControl` builds a node
#      with 3 attributes and 2 members and it reads `A M`, so the instrument can see a both-rule.
#      **The emitter template is closed: pure sequence or pure alternation.** The `else` bridge and
#      the mid-body restore problem are both gone.
#   5. **THE OP-SELECTOR IS NOT A VOCABULARY PROBLEM.** The 13 selectors
#      (`jitOp`/`jitCmp`/`jitUnary`, `jitContext.h:454-465`) are **never computed** — each is a
#      compile-time constant hardcoded at the site that already knows which operator it is.
#      **RULED: the slot model** — the op node carries `jitMethod` beside `operateMethod`, the
#      driver calls the slot, the selector parameter retires. **A kant-side name→enum table was
#      REJECTED**: it re-introduces name lookup the language works to eliminate, gives the op's
#      identity two homes, and an unmapped op yields 0 which IS `jitAdd` — a `-` emitting an ADD,
#      silently, degrade count 0. ⚠ **And the cost is smaller than it looks: 18 gates already have
#      a body that is exactly one `return jitEmitX(...)` line.** The shims are written; they are
#      anonymous and trapped inside `if jitting`.
#   6. **`iterT1m` IS THE SAME STANDING QUESTION IT WAS BEFORE THE CURVE BALL.** Both reds are
#      pre-existing and are NOT this session's. Re-pin rulings are Tony's, sentences bought in KE-4.
#
#   ## ⚠ DOCTRINE EARNED, AND THE FIRST ONE IS LEDGER-GRADE
#
#   - ⚠⚠ **A CONTENT-COMPLETE DIFF THAT STILL FAILS EARNS A BYTE-LEVEL LOOK BEFORE IT EARNS
#     ANOTHER THEORY.** Paid for the same day. After the iterator cure `displayForm` still failed,
#     so the tempting read was "a second walk defect". **The walk was already correct**: all 21
#     content lines matched byte for byte and the sole difference was **ONE TRAILING SPACE** on the
#     sentinel — two lines that render identically and only `od` separates. The real cause was the
#     unreverted second half of a two-half change. **Had the search gone hunting for a walk defect,
#     the space it searched would not have contained the answer** — bear-trap #19's corollary, met
#     from the cheap direction for once. Diff bytes before theorising.
#   - **A TWO-HALF CHANGE NEEDS BOTH HALVES REVERTED.** `useDefaultSpace` was *moved* from
#     `processAction` to `aCTionPrinT`. Restoring only the origin left it set in BOTH places, which
#     is a third state nobody designed. Certified in both directions: line out → `spell.target` and
#     `manyScratch.target` RED with `lit(t1,"x")` becoming `lit( t 1  , " x " )`; line back → green
#     and the fleet byte-identical to the pre-edit capture.
#   - **A PREDICTION THAT NAMES ITS OWN GAP IS WORTH MORE THAN ONE THAT PASSES.** The relay-#3 fix
#     was predicted to clear `oneTest` and the two spacing rows **and to leave `displayForm` red**,
#     because that chain lived in `opPlusPlus` and violated neither ruled invariant. All four rows
#     landed as predicted. The value was in the row predicted to FAIL — it named the second cure
#     before anyone went looking for it.
#   - **A PRE-REGISTERED PREDICTION THAT FAILS IS THE CHEAP WIN.** "`displayForm` shares
#     `oneTest`'s cause" was recorded, then falsified by one grep — **only ONE `:=`-in-condition
#     site exists in all of `incant/`.** That failure is what split one investigation into two
#     correct ones.
#   - **A REORDER IS NOT CODEGEN-NEUTRAL, AND THE CONTROL IS HOW YOU KNOW.** tok's bare-name
#     resolution is order-dependent, so the alphabetical pass was certified by a function-level
#     diff — **288 functions in, 288 out, none lost, none gained, 15 bodies differing ONLY by tok's
#     `::` global-scope qualifier** — then by build, then by a fleet that did not move. A build
#     that succeeds is not evidence that a reorder was safe.
#
#   ## ⚠ THREE VIGRAM CANDIDATES NOW STANDING (design intent; no vigram work opens today)
#
#   1. **`isGROUP ⇒ gGroup non-null`** — ⚠ **it has a live NEGATIVE CONTROL**: `x := f["MissingKey"]`
#      built the violation on demand and `if x;` **exited 139 with zero bytes** before the fix.
#      The invariant can be shown to fire before it is trusted, which is the H7 bar.
#   2. **`isGROUP ⇒ isInitialized`** — the flag `aCTionIF` actually reads. Stamped together now, so
#      neither can be forgotten separately.
#   3. **AN EXHAUSTED ITERATOR CARRIES NO GROUP.** ⚠ **Load-bearing for Tony's `IterateIf`**
#      (`if iterate grup on X attributes;`, desugaring to opIterate + opPlusPlus-as-test + back-edge
#      advance), which leans on the `isInitialized` work. **An argument for the invariant, not a hold.**
#   ⚠ **FILED, NOT RULED: `isGROUP` carries TWO meanings** — *carries a group* and
#   *follow-me-redirect* (`aCTionIterate`'s first line reads it the second way). One-channel-one-
#   meaning, newest member. **No channel split ruled today.**
#
#   ## THE COMMENT PROBLEM, MEASURED — and `genParse.rtn` is now crowned by THREE independent
#   ## measurements
#
#   **299 comment blocks over 3 lines, 4053 lines**, across the `.rtn` fleet.
#   `genParse.rtn` **1242** · `jitEmitters.rtn` **1066** · `ruleActions.rtn` 603 · `GroupActions.rtn`
#   509 · `Instruct.rtn` 359 · `Commands.rtn` 246 · `Debug.rtn` 20 · **`Generate.rtn` 8**.
#   ⚠ **`Generate.rtn` is the reference specimen and the gap to the next file up is ~150x.** That is
#   the target style stated in numbers. And `genParse.rtn` is now worst on **comment volume**,
#   **alphabetical disorder (23 of 56)**, and Tony's own read — three independent measurements
#   agreeing, which is why its spa treatment is queued rather than argued.
#
#   ## ⚠ DesignDocs — SCHEMA v2 RULED, AND ONE BLOCKER A NAIVE VERB WOULD HAVE HIT
#
#   **Sub-entries are MEMBERS, and members are not bare-locatable.** Measured: bare name → empty
#   node; `Parent["Child"]` → empty node; **reached by ITERATING the parent's members → the real
#   node with its 3 children**; top-level parent as control → 8 children. **So the registry's whole
#   content below the top level is walkable but NOT addressable**, and a query verb written the
#   obvious way (locate by key) would silently return empty nodes for every sub-entry.
#   **RULED: the verb is a WALKER, not a restructure** — sub-entries stay members, the walker walks
#   by tag and enforces key uniqueness in passing, and this is the general answer wherever data
#   registries recur (`gDO`'s "members are not bare-locatable" wall included).
#   **Schema v2 adopted, next-relay work:** `Status` (canonical / measured `<date>` / open, owner
#   `<name>`) · `Evidence` (verbatim, no reflow) · `CodeSite` (a field, so entry-outlives-method is
#   lint-checkable) · `Rejected` (earned by two independent authors reaching for it).
#   ⚠ **SITE-SCOPED WARNINGS ARE THE NAMED EXCEPTION AND NEVER MIGRATE** — a warning stays one line
#   at its post in the function it guards; the registry may carry the why.
#   **Mechanical:** entry text **cannot contain a double quote** (it terminates the string);
#   apostrophes and semicolons are fine.
#   ⚠ **PARSE-GREEN IS NOT SHAPE-CORRECT** — the pilot entry was verified by walking it
#   (8 children, `Contract` sub 3), not by exit status. The registry's own header records why.
#
#   ## PARKED, WITH OWNERS — nobody has to guess whose these are
#
#   | item | owner |
#   |---|---|
#   | `IterateIf` construct | **Tony**, in flight |
#   | `parseRule` rec sheet — the `isAction` fork into `setParse` slots, `parseFail` (7 duplications), the `if jitting` stub → `actionMethod` slot | **Tony** |
#   | `genParseTest` both-present guard line | **Tony**, his file |
#   | DesignDocs schema v2 + the walker verb | next relay |
#   | op-selector campaign — de-gating the 31 `Instruct.rtn` gates and unblocking the kant jit driver **close together as ONE mechanism** | post-pause |
#   | `opPlusEQ` as a named exception (per-leaf dispatch, outside the slot model) and the `jitEmitAssign` call-shape wrinkle | **Clod**, to propose when the campaign opens |
#   | `iterT1m` ×2 re-pins | **Tony** |
#
#   ## ⚠ THE KANT JIT DRIVER — DOABLE, AND ITS KEYSTONE WAS ALREADY IN TONY'S OFFLINE WORK
#
#   `incant/jitDrive` runs: it finds a real action's `BlocK`, walks it, dispatches per node.
#   **62 jit externs, 4 reachable from kant today** (`jitTrace`, `jitRefire`, `jitShowRecord`,
#   `jitFieldMethod`) — so kant→jit-extern calling is already proven, not hypothetical.
#   ⚠ **The guessed missing-bits list was HALF WRONG and the correction is the finding**: a
#   **builder handle is NOT needed** — 20 externs take `()` and work on module-level state, so kant
#   calls them as bare commands and registration is the whole cost. `jitStoreResult()` and
#   `jitNodeInFlight()` already exist. **The real blocker was the op selector**, which is now ruled.
#
#   ## THE INSTRUMENTS, so nobody rebuilds one
#
#   `pop.sh` (fleet, 41/2/1) · `smoke.sh` (the bell) · `smokelib.sh` (**sourced never copied**) ·
#   `parked.sh` · `kantRatchet.sh` · `kantCensus.sh` · `completePop.sh` ·
#   **`alphaLint.sh` (NEW — hygiene tier, report only, deliberately NOT in `pop.sh`, and it
#   certifies itself: zero method lists extracted exits 2 rather than printing a clean banner)**.
#   **NEW PROBES, report tier, all exit 0 with sentinels:** `incant/iterReuse` (iterator reuse, with
#   its reversed-order exhibit) · `incant/setGroupInit` (`:=` in condition, with its `=` control) ·
#   `incant/bothCensus` + `incant/bothControl` (both-present, with its positive control) ·
#   `incant/ddProbe` + `incant/ddProbe2` (DesignDocs shape and addressability) · `incant/jitDrive`
#   (the kant jit driver stub).
#   **RULE H10: smoke-green authorizes CONTINUING, only a fleet check authorizes LANDING — and the
#   landable property is UNMOVED, not green.**
#
#   ## ⚠ TWO STANDING HAZARDS RE-CONFIRMED THIS SESSION, both cheap to lose
#
#   - **A BARE `for r in Grokking;` WALK EXITS 139 WITH ZERO OUTPUT.** Reproduced independently and
#     **it is NOT `genKant`-specific** — a walk whose body does nothing but count also dies. The
#     workaround is the `iterate`/`while ++` idiom (`incant/ruleCount`) or one-rule-per-process.
#   - **A STALE `.mm` COMPILES AND RUNS.** The binary that opened this session was built from a
#     `GroupRules.mm` generated BEFORE two of that morning's `.rtn` edits — Xcode recompiled the
#     `.mm`, `tok` was never re-run. **Verified before trusting any measurement**: `opSetGroup`,
#     `opPlusPlus` and `aCTionIF` were byte-identical between the stale and fresh `.mm`, which is
#     the only reason the day's chains stood. **No mechanization ruled** (Tony's practice is
#     always-retok); treated as one-off unless the fleet says otherwise.
#
# ⚠⚠⚠ SEALED 2026-08-13 LATE — SHUTDOWN SEAL (CURRENT VINTAGE). READ THIS FIRST.
#
#   THE ONE-LINE STATE: **the OPT vocabulary is BUILT and LANDED — `optRK` compiles, emits and
#   trebles the emittable population from 1 to 4 — and RUNG ONE STUMBLED at 139 on the live
#   install.** The stumble is banked with evidence and NOT diagnosed, on purpose. **Tomorrow
#   opens on a CHORE, not a choice.**
#
#   ## WHAT LANDED TONIGHT
#
#   | thing | state |
#   |---|---|
#   | **decision (a) RULED** | the vocabulary charter is **OPT** (Tony, off SEQ 72's stamped table) |
#   | `optRK` shim | **BUILT, COMPILED, LIVE** — `nm` shows `_optRK`; externs 276 → 277, no cascade |
#   | `kantLeaf` OPT arm | emits `optRK` for a CALL optional; **REFUSES** LIT and CONTAINER optionals **by name** |
#   | **emittable population** | **1 → 4**: `Braced` (was), **+ `InvokE`, `Parens`, `PrintField`** |
#   | rung one (live install) | ⚠ **STUMBLED — exit 139.** Banked, not chased |
#   | fleet | **UNMOVED** across a C++ change and a full rebuild — every `pop.sh` check row byte-identical |
#
#   ## ⚠ THE SIX THINGS A FRESH READER MUST NOT RE-DERIVE
#
#   1. **THE DENOMINATOR IS 78. `47` IS DEAD EVERYWHERE.** 60 rule members + 18 rule attributes,
#      out of 79 `Grokking` entries; the one non-rule entry is **`Operators`**. That single fact is
#      the whole of the 78-vs-79 "discrepancy" two passes recorded — **both numbers were right and
#      neither was labelled.** `docs/jit.md`'s columns 2–5 now have their denominator.
#   2. **SEQ 72's stamped table is 78/78, zero blank, zero unclassified** —
#      `genLadder/kantCensus.sh`, raw run at `docs/emitted/kantCensus-2026-08-13.txt`. The 39
#      blanks that voided SEQ 71 are gone and a blank row is **unconstructable**.
#   3. **THE (a) RULING'S BASIS IS THE TABLE, NOT A CITATION.** OPT opened the most rules of any
#      single vocabulary item. ⚠ **AND THE RE-RUN MOVED THE NUMBER, EXACTLY AS THE FENCE SAID IT
#      MIGHT: SEQ 72 said "5 held out by OPT"; closing OPT opened THREE.** `RunRulE` wants
#      `optLK` (a LITERAL optional — `';'-?`), `TokenXP` wants a CONTAINER optional (`UnaryOPS?`).
#      **A first-blocker count is not a promotion count. This is the discipline paying out, not
#      failing.**
#   4. **THE FENCE PROBE CAME BACK FENCED.** `locate(argument.text)`-shaped resolution exists at
#      **three** live sites and **none is on the install or parse path**: `dumpRuleTerms`
#      (instrument, filed), `runNotified` (`GroupItem.twk:1562`, listener dispatch) and
#      `styleComponent` (`GroupDraw.twk:220`, drawing). ⚠ **The kant doors do NOT use it** —
#      `parseViaKant` and `kantDoor` build `"kp" rule.tag` as a **String** and `locate` that, so a
#      name never passes through a node's `.text`. `parseRuleMethod:1908` does read `.text`, but of
#      a `parseMethod=` attribute whose value the source assigned with `=`, it dlsyms rather than
#      locates, and it names the empty case. **The walk proceeds clean.**
#   5. **RUNG ONE'S STUMBLE IS `docs/emitted/parens-opt-stumble-2026-08-13.txt`, AND ITS CAUSE IS
#      NOT WRITTEN DOWN ON PURPOSE.** `Parens` bound cleanly, entered the kant door **3556 times**,
#      never reached `parseR`, never refused, and died with **zero bytes of stdout**. That is the
#      signature of unbounded re-entry — **a description, not a diagnosis.** Two mechanisms are
#      available (Mechanism 3's re-entrant frame; the ALT-option `into`-not-`label` frame) and
#      **NEITHER is named as cause**; `Braced` is also an `InvokeArg` option and works, which alone
#      sinks the easy story. ⚠ **Mechanism 3 stays a filed tension. Do not pre-solve it.**
#   6. **THE FIRST PICK WAS `InvokE` AND IT WAS GREEN AND HOLLOW.** Exit 0, both legs printed 251,
#      **and the kant door never fired** — `fireIt()` parses `TokenXP → InvokeArg → Parens`, not
#      `InvokE`. The bind took (the SEQ 58 seam reads correctly); the parse never forked. ⚠ **The
#      STRUCTURAL claim held and the CAUSAL one — "this input reaches this rule" — was read off the
#      grammar by eye and was false.** GM-30 had already recorded that `InvokE` does not fire; the
#      note was cited and not measured. **251 alone proves nothing** did its job again.
#
#   ## ⚠ TOMORROW IS A CHORE, NOT A CHOICE — deliberately, and in this order
#
#   1. **Separate the two mechanisms behind the 139**, one run. Then fix-or-skip is Tony's.
#   2. **Rung one re-run on `Parens`** — it is `Braced` with term 2 made optional: same parent
#      alternation, same attach frame, and the control is already green and committed. The fixture
#      pair is in the stumble specimen, **one `cp` from live**.
#   0. ⚠ **THE DOOR-ENTRY ASSERTION — proposed by Clay, SECONDED, and it is the session's
#      structural answer to the hollow green.** `InvokE` exited 0 with both arms at 251 and
#      proved nothing because **the input never reached the rule**. The arm-by-name discipline
#      catches WHICH code answered; **nothing yet asserts the target was ever ASKED.** So the
#      fixture contract gains: **the target rule's door fired, or the run is not a result.**
#      ⚠ **AND THE PREMISE NEEDED CORRECTING BEFORE ANYONE BUILDS IT: there is NO door-entry
#      counter.** The `3556` was a grep over a `cerr` inside `parseViaKant` that is **gated on
#      `parseTrace`**. What DOES exist is `genLadder/kantRatchet.sh:131` — `grep -q
#      "parseViaKant $RULE -> kp$RULE"`, R3's third assertion. **So this is not new machinery;
#      it is R3's door check PROMOTED out of the ratchet into the general contract.** Two
#      refinements agreed: **print the COUNT, do not merely test presence** (R3's `grep -q`
#      would have passed `Parens` at 3556 had it not crashed — `>=1` is the weakest possible
#      form, and a non-crashing runaway satisfies it); and **the residual is named** — this is
#      an instrument reading an instrument, coupled to a `parseTrace`-gated line's exact text.
#      Polarity is right: delete the line and the count goes 0 and the run fails CLOSED.
#      ⚠ **Count 0 catches TWO failures** — bind-took-but-never-reached (`InvokE`) and
#      bind-never-took. The `SEAM bind`/`SEAM read` lines separate them, one grep away.
#      **Fourth refuse-by-kind promotion in three dispatches.**
#   3. **Then the promotion**, gated on rung one green — and ⚠ **the fence's re-run of all five is
#      part of the chore, not optional**: two of them (`RunRulE`, `TokenXP`) are already known NOT
#      to be opened by `optRK`. **`optLK` and the container optional go on the vocabulary shelf as
#      named, priced follow-ons — not tonight's debts** (Clay, ratified at close).
#
#   ## ⚠ INSTRUMENT DEFECTS FOUND IN MY OWN WORK TONIGHT — the class is the point
#
#   - ⚠ **THE CENSUS KINDS COLUMN HAD A PRECEDENCE BUG AND 11 OF 78 ROWS WERE WRONG.** It tested
#     `REFERENCE` **before** the data row, so every term that is **both a reference and carries
#     data** was called `R` where the tree calls it a container or a charset. **`row42`'s own header
#     warns about exactly this** — it mirrors `setTestMatch`'s cascade *in its own order* and says a
#     classifier reading the table top-to-bottom would already disagree with the tree. **It was read
#     top-to-bottom anyway.** Corrected and re-run; the delta is `TokenXP`, `UnaryXP`, `DatA`,
#     `Token`, `BrancH`, `FloaT`, `NumbeR`, `PrintField`, `ANYorNum`, `FormaT`, `ScopeField`.
#     ⚠ **WHAT CAUGHT IT WAS `planTerm` REFUSING BY KIND** — `TokenXP`'s `UnaryOPS?` came back
#     CONTAINER where the census had said `R`. **Third time in two dispatches that refuse-by-kind
#     has named an instrument defect. Structure, not vigilance.**
#   - **ONE APOSTROPHE IN AN awk COMMENT KILLED THE WHOLE TABLE** — the program lives in a
#     single-quoted shell string and `row42's` closed it. Output: a full header and **ZERO ROWS**.
#     ⚠ **The self-certification floor caught it by name** (`rows != population`), which is
#     H2-turned-on-the-harness doing precisely the job it was added for.
#   - **RESIDUAL, NAMED NOT FIXED: the census's KINDS column and its SHIM column are TWO
#     CLASSIFIERS** (`row42` vs `planTerm`) and they still disagree — `PrintField` reads `RC?` and
#     emits anyway. **The SHIM column is authoritative** (it is the emitter itself). Same family as
#     the precedence bug; do not read KINDS as a shim predictor.
#
#   ## RULING CARRIED ACROSS THE SESSION BOUNDARY
#
#   **THE REGISTRY WIRE FORMAT IS `ALWAYS-BZ1`** (Tony, 2026-08-13). Every buffer field prints as
#   its compressed form: one code path, no chooser, no escaping anywhere. **Support minion SEQ 2
#   Part B is UNBLOCKED — and unblocked is NOT scheduled.** `ipc/support-to-clod.md` has been open
#   at `working` since 2026-08-03; the gate is now answered.
#
#   ## BANKED, BY NAME — none of these are diagnosed
#
#   · ⚠ **bare `ANYstring` resolves to a node tagged `DatA`** (symptom measured, mechanism NOT
#     written down). Matters past the census: **any bare-identifier rule reference in incant may be
#     reaching a different node than its spelling says.**
#   · **the in-process walk exits 139** after one rule (`for r in Grokking; genKant(r);`) —
#     sidestepped by one-rule-per-process, still undiagnosed.
#   · **`dumpRuleTerms` carries the same `locate(argument.text)` hazard** — a C++ edit, unpaid.
#   · **`iterT1m`'s live question** and the other two KE-4 reds — re-pins are Tony's, still owed.
#   · **IT-3 attrition + the K5/K6 GATE** — standing from before this campaign, cheap to forget.
#
#   ## THE INSTRUMENTS, so nobody rebuilds one
#
#   `kantCensus.sh` (the stamped table; counts its own population first, cannot print a blank row,
#   carries its own H7 negative control for name-passing) · `smoke.sh` (the bell) · `smokelib.sh`
#   (**sourced never copied**) · `parked.sh` · `kantRatchet.sh` · `pop.sh` (fleet; **3 pre-existing
#   reds, older than the SEQ 55 seal**) · `completePop.sh`.
#   **RULE H10: smoke-green authorizes CONTINUING, only a fleet check authorizes LANDING — and the
#   landable property is UNMOVED, not green.**
#
# ⚠⚠⚠ SEALED 2026-08-13 EVENING — SHUTDOWN SEAL (CURRENT VINTAGE). READ THIS FIRST.
#
#   THE ONE-LINE STATE: **the kant loop is CLOSED on a real rule** — `Braced` parses live input
#   through a body written in kant, emitted by machine from its own live terms. The bind defect
#   that blocked it for a week is found, closed and pinned. The jit-parse door is refused with the
#   lock described. **The next session opens on a CHOICE, not a chore** — see the decision queue at
#   the foot of this seal.
#
#   ## WHAT LANDED, SEQ 56 → 71 (all pushed; branch `jit-unified-emit-wip`)
#
#   | SEQ | commit | what |
#   |---|---|---|
#   | 56 | `fcc5371` | `aCTionDefinE` arm reorder — the coded test wins. Fleet byte-identical AND not inert: M1b's silent inertness is repaired |
#   | 58 | `996ad5a` | **THE BIND-READ SEAM, FOUND AND CLOSED.** The door bound a SATELLITE node; `definingRule()` on that very node already returned the reader's. Both doors now resolve the reader's way. ⚠ `parseBraced` had never been compiled — added |
#   | 59+60 | `ca606ee` | IA-2 trial ladder (rung 1 green, reverted per the wall); `smoke.sh` built |
#   | 61 | `e6438ba`, `9693f04` | **PC-1 RULED.** Narrow spelling landed, `bindSeamB` PINNED at 251 with the ARM asserted by name, IT-3's demolition list marked |
#   | 63 | `79186c3` | **FIRST LIGHT.** `bracedK` — kant `Braced` body, first live fire of `parseRK`; the two arms diff clean over 30 lines |
#   | 65/66-r1 | `728265a` | Jit-parse leg PRICED and STOPPED at the first exit |
#   | 67 | `39a86d7`, `2f6203c`, `92f57f7` | Frame/baked-address tension filed with its cost tripwire; **KE-3 degrade crash repaired**; **`genKant` — the emitter replaces the hand** |
#   | 68 | `7b8f8fe`, `9ffeb94` | Walk stops at `Braced` (two table rows were wrong); jit census column 1 answered |
#   | 70 | `55481d1` | **THE THREE REDS: all three are older than the SEQ 55 seal.** Verdicts with evidence |
#   | 71 | `5276a89` | **`genKant` was emitting WRONG bodies for alternations — fold gate added.** Survey partial, tally VOID and named |
#
#   ## ⚠ THE FIVE THINGS A FRESH READER MUST NOT RE-DERIVE
#
#   1. **The bind defect was a SATELLITE NODE**, not a clobber. `parseMethod=` from another file
#      bound onto the node `aCTionDefinE` hands the door, while `parse()` forks on
#      `definingRule().rStuff`. Both doors now resolve through `definingRule()`. Same-file binds
#      (`kantParse1`, `genScratch`, the Scaf family) were never affected and are untouched.
#   2. **PC-1 is RESTATED, not overridden.** The generated arm may consult `isTarget` ONLY where
#      there is no parent label — no subtree to destroy, which is the rationale GM-22 protects.
#      `bindSeamB` at 251 is the pin AND IT-3's tripwire.
#   3. **The jit-parse door is REFUSED (c), with the lock described.** Mechanism 3 — re-entrant
#      frame vs baked stable address — is **two correct rulings meeting**, filed as a TENSION with
#      a **cost tripwire** in `docs/jitDesign.md`. Nothing is owed until the walk gives the fleet
#      real rule counts. **Do not pre-solve it.**
#   4. **`251` ALONE PROVES NOTHING** anywhere in this campaign. The interpreted arm has always
#      produced it. Read the ARM by name: `promote=0` generated, `promote=1` interpreted.
#   5. **The three `pop.sh` reds are OLDER THAN THE SEQ 55 SEAL** and are not this campaign's.
#      Verdicts and evidence in `docs/knownErrors.md` KE-4. `iterT1m` is the one with a live
#      question in it.
#
#   ## ⚠ THREE DOCTRINE SPECIMENS EARNED THIS SESSION
#
#   - **THE WRONG-LEAD LEDGER GAINED ITS FIFTH.** KE-3's filed cause — *"the return dereferenced an
#     absent value"* — sent the search at `jitEmitReturn`. **The site said otherwise three lines
#     earlier:** `arg = arg.gMethod(arg)` is overwritten by the emitter's `nullptr`, and the STAMP
#     dereferenced it. The instruction to *verify at the site before repairing* is the only reason a
#     correct-looking repair did not land in the wrong file.
#   - **THE 42-CONTROL.** `0 = 0` is the weakest possible agreement. Paired with a body that
#     degrades **mid-body** then returns 42, it asserts what the zero row could not: **a degrade in
#     the middle of a body does not poison what follows** — *fallback sound*, not *fallback
#     occurred*.
#   - **A PER-ITEM GUARD CANNOT SEE A WHOLE-BODY PROPERTY.** `kantLeaf` refuses by KIND and covered
#     every unknown term; **the JOIN is not a term**, so `genKant` emitted `AND` chains for
#     alternations — bodies that parse and answer wrong — until SEQ 71's fold gate.
#
#   ## ⚠ AND THE T-0 FAMILY COLLECTED **FOUR** MORE IN ONE DAY. Stop citing tables; re-run them.
#
#   `Xpress`/`UnaryXP` cited `ref · ref` (both wrong — `SemI` is `isSTRING`, `ANYtoken` is
#   `isGROUP`) · **"47 live rules"** (matches nothing measured; `popScratch` says 78, iteration says
#   79, **and none is confirmed**) · `incant/parseCode` shaped for the unbuilt MINT door
#   (`parseViaKant` locates `kp<Tag>`, not `<Tag>`) · the survey's own blocking-kind tally, **VOID**
#   because 39 blank rows hid three different causes. **What caught the first was `kantLeaf`
#   refusing by kind rather than guessing** — structure, not vigilance.
#
#   ## THE DECISION QUEUE — the next session picks from this list
#
#   | # | decision | state |
#   |---|---|---|
#   | a | **Next vocabulary charter** | ⚠ **BLOCKED on the stamped table.** The optional's claim to "opens the most rules" is unverified citation. SEQ 71 did not deliver the table; two instrument fixes are owed first (driver name-passing, both refusal shapes) |
#   | b | **Invokable mechanism, yes/no** | Reframed: it is **kant-at-large** work, not parse work. Jittability is 0 without it and total with it — no partial credit — so the decision is purely price (`728265a`). Mechanism 3 stays a filed tension |
#   | c | **Minion consult** | Parked. SEQ 70 was its trial assignment and is done; re-cut against surviving backlog, which may be the honest test of whether the role is needed |
#   | d | **Promotion gate** | `incant/parseCode`'s `fILEs` line into `incant/setup`. **One line, whenever called** |
#   | e | **IT-3 attrition + K5/K6 GATE** | Standing from before this campaign, cheap to forget. IT-3's list now carries the IA-2 demolition item |
#   | f | **The three reds' re-pins** | Sentences bought (KE-4); every re-pin ruling is Tony's |
#
#   ## THE INSTRUMENTS, so nobody rebuilds one
#
#   `genLadder/smoke.sh` (5 slots, the bell — slot 1 is `bracedK`) · `smokelib.sh` (shared helpers,
#   **sourced never copied**) · `parked.sh` (two-stage retirement; green flushes, RED reinstates,
#   UNRUNNABLE is never a pass) · `kantRatchet.sh` (generate → byte-compare → install → run, all on
#   one run's own output) · `pop.sh` (fleet; **3 pre-existing reds, older than the seal**) ·
#   `completePop.sh` (137 swept / 242 green / 3 abandoned, all recorded).
#   **RULE H10: smoke-green authorizes CONTINUING, only a fleet check authorizes LANDING — and the
#   landable property is UNMOVED, not green.**
#
# ⚠⚠⚠ SEALED 2026-08-11 EVENING — SHUTDOWN SEAL (CURRENT VINTAGE). READ THIS FIRST.
# **THE LOOP IS CLOSED. A RULE PARSES REAL INPUT WITH ITS PARSE METHOD WRITTEN IN KANT,
# ONE STATEMENT, SPELLED AS AN `AND` CHAIN.** Nine dispatches (SEQ 47–55), seven commits,
# three rebuilds, and the fleet finishes byte-identical to where it started.
#
# ⚠⚠ NEXT ACTION — **THE RULE LIST** (SEQ 51 items 2–3, ruled by Tony as tomorrow's top
#    item). A census **RE-RUN against today's source** — ⚠ **NOT Phase A's numbers, which
#    predate GX-1 and the AND/OR rung.** Per rule: **term count · term kinds** (literal /
#    charset / reference / container) **· shims available yes-no · first blocker if refused,
#    H9-STAMPED.** ⚠ **NO INSTALLS AGAINST IT.** Tony + Clay eyeball it, mark walk order
#    simplest-first, and the walk then runs **until it stumbles into body-and-fender work**;
#    stumbles get banked and filed, fix-or-skip per stumble.
#
# ⚠ **WHAT CLOSED, IN ONE PARAGRAPH.** `parse()` forks on `rStuff.parseMethod`, a **C++
#   function pointer**; a kant method is a GroupItem carrying CodE/BlocK. **`parseViaKant`
#   (`genParse.rtn`) stands in that slot and forwards** — the cheap door, versus widening the
#   pointer's signature, which `RuleStuff.twk` ruled a **LAYOUT change** on 2026-08-05. It
#   binds through the **existing** `parseMethod=` dlsym door, finds its action **by
#   convention** (rule `Foo` → action `kpFoo`), and **owns the frame**: mark, minted label and
#   rule saved around the body and restored after, so **the C++ call stack IS the frame
#   stack.** Shims `litK`/`parseRK` do the matching. `incant/kantParse1`:
#   `ScafKB isRule "["- "]"-`, method `return litK(1) AND litK(2);`
#
#   | row | lit lines | verdict | mark |
#   |---|---|---|---|
#   | `ScafKB '[]'` kant | 2 | **WIN** | consumed |
#   | `ScafKB '['` kant | 2 | FAIL | **rewound** |
#   | `Scaf2 '{'` **C++ ORACLE, same shape** | 2 | FAIL | **rewound — the arms agree** |
#   | `ScafKB 'x'` kant | **1** | FAIL | **unmoved** |
#
#   ⚠ **ROW 4 IS THE EXHIBIT AND IT PAYS TWICE:** one lit line where the others have two, so
#   **the AND chain short-circuited inside a LIVE INSTALLED PARSE METHOD**; and **`unmoved`
#   against row 2's `rewound`**, which is the discrimination the cursor rule exists for.
#
# ⚠⚠ **THE CONVENTION AS LANDED — STANDING, first of its line, citable by future rungs
#   (Tony, SEQ 54 item 3, ratified SEQ 55 item 2):**
#
#     **AN EMITTED KANT BODY NEVER SEES PARSER INTERNALS. It names a term BY POSITION and
#     holds no node at all; POSITION, LABEL and INVARIANT belong to the C++ frame around the
#     dispatch.**
#
#   ⚠ **AND THE SUBSTRATE ENFORCED IT ON ITS OWN, which is why it is grounds and not taste.**
#   The shims were priced to take *nodes* via the `:scope` multi-arg idiom. **kant CANNOT
#   INDEX A RULE'S TERMS:** `argument[1]` handed the shim a node tagged with the **command
#   name**, which dutifully tried to match the literal `"litK"` — bear-trap #26's family, a
#   plausible string where a node was wanted. So the shims take a **position**, the frame
#   indexes in C++ (`rule[1]` → `rule->get(1)`), and **the convention came out cleaner than
#   priced.** The `:scope` hoist was never needed.
#
# ⚠ **THE MARK RULING (Tony, 2026-08-11): THE MARK NEVER CROSSES.** `String from = atRuleMark`
#   is a **position, not a value** — it cannot travel as kant data *by nature*, not by missing
#   plumbing — and keeping it C++-side leaves **Invariant R with one writer**, where
#   `RuleStuff.twk:657` rules it lives. Reversibility is asymmetric: widening to a handle later
#   is additive; retracting a crossed mark is a full-population regenerate-and-re-pin **for a
#   correctness reason.** Full pricing: **`docs/kantShims.md`**.
#
# ⚠⚠ **FOUR FINDINGS THAT OUTLIVE THE DAY.**
#   1. ⚠ **THE CURSOR, NOT THE VERDICT, IS THE INSTRUMENT — and it is now standing doctrine
#      for parse fixtures (SEQ 50 item 3).** `incant/kantRuleS` is `kantRuleA` with the
#      alternation spelled `||`: it ends at **cursor 4 where the word form ends at 3**, a token
#      eaten by an option that did not match — **and BOTH spellings return SUCCESS on that
#      row.** A harness asserting the rule's verdict would have certified the eager one.
#   2. ⚠ **A DEFECTIVE CITATION DOES NOT MERELY STATE SOMETHING FALSE — IT GENERATES
#      WELL-REASONED QUESTIONS NOBODY NEEDED TO ASK.** The respell charter nominated `Braced`
#      as its flagship exhibit citing GM-13's *"LEAD … UNMEASURED"* line. **That lead had been
#      dead since the day after it was written** (GM-16, 2026-08-05), seventy lines below it in
#      the same file, and its actual cause was **repaired 2026-08-06** (GX-1). ⚠ **And the
#      failure §3.0 was written to prevent was LIVE: had Braced been installed as the exhibit
#      and come back green, GX-1 — landed five days earlier for an unrelated defect — would
#      have been read as the respell's proof.** Forward pointer now at GM-13.
#   3. ⚠ **PARSE-GREEN IS NOT SHAPE-CORRECT.** The canonical `DesignDocs` text carried **three
#      missing terminating semicolons**, each NESTING what followed it. Exit 0, sentinel
#      printed, stderr empty — and `EmissionPrinciple` governing layout, targets and events.
#      **A registry with no verb over it yet is exactly where that survives**, and its first
#      reader would have been a consolidation minion.
#   4. ⚠ **`&&` OVER CALLS DOES NOT ANSWER WRONGLY — IT KILLS THE PARSE**, exit 139 with ZERO
#      bytes, before the `Search list:` line, so it reads as a broken binary. Bisected one
#      operator at a time. ⚠ **This moves the symbols repair: KE-5's believed one-liner
#      (`'&&' operateMethod=opAND`) would give a right truth table ON FIELDS and leave it
#      EAGER — finding 1's over-consumption. THE SYMBOLS RUNG AIMS AT TIER 3, NOT AT
#      `operateMethod`.** Both KEs amended; neither run.
#
# ⚠ **TWO INSTRUMENT DEFECTS CAUGHT IN MY OWN WORK, sealed because the class is the point:**
#   · **the guard was `if !action.isCoded`, and `isCoded` is CONSUMED BY RUNNING** —
#     `processAction` compiles to a cached BlocK and clears it — so it passed on fire 1 and
#     **refused every fire after**, and a rule parses many times. Cross-filed with bear-trap
#     #25, which records the same fact from `testing()`'s side.
#   · **the frame's R line printed `"mark rewound"` UNCONDITIONALLY** — an absence-shaped
#     assertion sitting in the exact place a cursor fixture reads. It now mirrors `leaveRule`'s
#     own comparison, **which is why rows 2 and 4 differ at all** and why the kant arm is
#     *diffable* against the C++ arm rather than merely similar.
#   · ⚠ **AND A THIRD, IN THE MEASUREMENT RATHER THAN THE CODE:** a first fleet comparison
#     reported three of four fixtures as DIFFERING. **The baseline had been captured with
#     `2>&1` merged and the new run separated the streams.** Compared like for like, all four
#     are byte-identical. **Doubt the instrument.**
#
# ⚠ **THE RESPELL IS CLEARED AS A *STOP*, NOT A DELIVERY — carried here so it is not lost by
#   being cleared.** §3.0 answered **NO**: the goto scaffolding is not the cause of the Braced
#   red, and ⚠ **NO EMITTED METHOD HAS EVER CONTAINED A GOTO** — regenerated today,
#   `parseBraced` is already an `&&` chain, byte-identical to the 08-05 banking. **So §3.5's
#   promised exhibit ("goto out, chains in") is not producible from ANY rule**, and §1's
#   premise is falsified by the emitted text. **The §1 RULING is NOT withdrawn; what moved is
#   the description of what it buys.** ⚠ **`docs/respellRung.md` needs §1 RESTATED by Tony
#   before the rung re-opens.** With §1 restated, §2's third bullet needs re-deciding — that
#   failure shape ceased to be expressible via **GX-1**, not via anything the rung does.
#
# ⚠ **OWED AND NOT DONE, so nothing here reads as finished that is not:**
#   · **The RULE LIST** — tomorrow's first action, above.
#   · **A SHELL POP FOR `incant/kantParse1`** — it **NARRATES, it does not self-assert.** Its
#     evidence is `parseTrace` on stderr, read against the C++ oracle **by eye**. The right
#     instrument greps the four rows and takes `$?` from the binary. **Queued with tomorrow,
#     explicitly not tonight** (SEQ 55 item 4).
#   · **Phase R rung 2 (Family C)** — RECON ONLY, banked in `docs/gapBPhaseR.md`, **not built**.
#     ⚠ Its two measurements are **RATIFIED AS PRE-REGISTERED PREDICTIONS** (SEQ 53 item 4):
#     **the rule-level `isSET` site holds SIX rules, not four** (`BrancheS`, a bin, and `PoweR`,
#     Family D, share it — so `if rule.isSET` is the wrong test **and would pass every positive
#     row while being wrong**), and **expected movement is 94→90 refusals / 16→20 plannable —
#     FOUR, not thirteen.** ⚠ **A rung 2 close moving more than four has widened scope.**
#     Family C needs a NEW plan kind; rung 1's cheapness is **not** inherited.
#   · **`leaveRule`'s `into` is VESTIGIAL** (PC-4 removed its attach; its own comment says so).
#     **Noted, deliberately NOT tidied** — a separate job, not a mid-rung edit.
#   · **KE-5 / KE-6** — amended today, **neither run**. **The symbols rung aims at tier 3.**
#   · **KE-4** · **K6c** · **the vestigial `recursive` flag** · **`BLOCKED KANT-B1`** · **the
#     bare-`if` truthiness fork** — all untouched today and all still standing.
#
# ⚠ **ALSO LANDED (SEQ 47): the `DesignDocs` registry is homed at `incant/designDocs`** —
#   design documents as kant data, registered in `incant/setup`'s `fILEs` — **and
#   `docs/displayDesign.md` is HISTORICAL**, marked with a supersession banner rather than
#   deleted. Forward-looking pointers repointed (`wakeup`'s drawer entry, `note-to-clay-style`);
#   **provenances left standing.** ⚠ **The HTML event fence MOVED at that review** — the target
#   now handles simple events and reports back to kant — so *"static only, no JS"* is no longer
#   the scope. ⚠ `IncantForms/WorkingOn/incant++` still carries the source text and is **held
#   back deliberately**: Tony's offline status note, his call (H8).
#
# ⚠ THE FLEET AT SEAL, after three rebuilds: ladder **184 / exit 0** · pop **33 green / 1
#   parked** · **completePop 133 swept / 0 MISSING SENTINELS / 234 green** (was 129/0/226 —
#   +4 fixtures, +8 checks, and the zero held) · decodePop 22 · recordPop 48 · gapB 22 ·
#   formsPop 14 · containerPop 11 · printPop 9 · mixed 7 · tree exit 0 ·
#   **oneTest / jsonTest / phaseA / emitAll BYTE-IDENTICAL ON BOTH STREAMS** ·
#   **`TALLY` still 94 refusals / 16 plannable** — the trampoline and the shims add no
#   plannability, which is correct. Commits **`68e2f69`** (DesignDocs) · **`7e1c1e1`** (§3.0
#   stop) · **`6cf0000`** (the chain on a rule shape) · **`086a151`** (recon + cost
#   correction) · **`7c3338f`** (the trampoline) · **`b25eaf0`** (shims priced) ·
#   **`adcbe3b`** (the loop closed). Working tree carries only Tony's own
#   `IncantForms/WorkingOn/incant++`.
#
# ⚠ **NEW FILES, all swept and all sentinelled:** `incant/designDocs` (registry, not swept —
#   no `Start()`, correctly) · `incant/kantRuleA` (the AND/OR rule shape) · `incant/kantRuleS`
#   (its H7 eager control) · `incant/kantLoop` (trampoline dispatch + refusal control) ·
#   `incant/kantParse1` (the closed loop) · **`docs/kantShims.md`** (the pricing).
#
# ═══════════════════════════════════════════════════════════════════════════════
#
# ⚠⚠ AMENDED 2026-08-11 MIDDAY (SUPERSEDED BY THE SEAL ABOVE, WHICH REPORTS ITS CONSEQUENCES) — THE RESPELL FIRED, TOOK §3.0 FIRST, AND **STOPPED
# ON THE ANSWER**. READ THIS AMENDMENT BEFORE THE SEAL BELOW IT, WHOSE "NEXT ACTION" IT MOVES.
#
# ⚠⚠ **§3.0 ANSWERED NO. THE GOTO SCAFFOLDING IS NOT THE CAUSE OF THE BRACED RED — AND THE
# CHARTER'S §1 PREMISE IS FALSIFIED BY THE EMITTED TEXT.** Four measurements, none needing an
# install. Full record: **`docs/respellRung.md` §6's Braced block**, which is the file to read.
#   1. **GM-13's lead was already dead** — falsified 2026-08-05 by **GM-16**, seventy lines below
#      it in the same file. The charter cited the lead, not the file. A forward pointer is now at
#      GM-13 so the next reader cannot repeat it.
#   2. **The goto WAS a cause and was REPAIRED 2026-08-06** by GX-1's `fireLabelMethod`
#      extraction. Verified in TODAY's source: `GroupItem.twk:1231-1232` fires the action
#      **before** the `goto`.
#   3. ⚠⚠ **NO GENERATED METHOD HAS EVER CONTAINED A GOTO.** Regenerated today rather than cited
#      (`INCANT_PARSE_RECORD` on `incant/recordPT`): `parseBraced` is
#      `lit(t1,"[") && parseR(t2,label) && lit(t3,"]")` — **already an operator chain, and
#      byte-identical to the 2026-08-05 banking.** The `goto` lives in `parse()`'s hand-written
#      arm. **So §3.5's promised exhibit — "goto out, chains in" — is not producible from ANY
#      rule**, and the real delta is `&&`/`||` → `AND`/`OR`.
#   4. **The surviving red is GM-29's mechanism**, named to one line: `attachLabel`'s no-label
#      guard, `GroupItem.twk:1101`. `Braced` is an option of the **alternation** `InvokeArg`, and
#      an option's label under a label-transparent parent is dropped silently at exit 0.
#
# ⚠ **HONEST LIMIT: `Braced` ITSELF HAS NOT BEEN RE-RUN SINCE 2026-08-05.** GM-29's post-GX-1
#   reproduction is on `Parens`. "Braced is still red" is structural and pointable, **not
#   measured** — measuring it is an install, which is a rung, and it was not taken.
#
# ⚠ **AND THE DISPATCH'S FEARED FAILURE WAS LIVE:** had Braced been installed as the exhibit and
#   come back green, **GX-1 — landed five days ago for an unrelated defect — would have been read
#   as the respell's proof.** That is the whole reason §3.0 was written before step 1.
#
# ⚠⚠ **NEXT ACTION IS NOW TONY'S, AND IT IS A DECISION, NOT A BUILD: RESTATE §1 IN TERMS OF THE
#   REAL DELTA.** The §1 ruling is **NOT withdrawn**; what moved is the description of what it
#   buys. With §1 restated, §2's third bullet (*"the Braced red's failure shape ceases to be
#   expressible"*) needs re-deciding — **that shape ceased to be expressible via GX-1.** The
#   `&&`→`AND` widening may still be worth doing on §2's first two bullets alone. **Nobody should
#   start the rung until that sentence exists.**
#
# ⚠ **PHASE R RUNG 2 IS UNAFFECTED AND ITS ORDERING ARGUMENT NOW CUTS THE OTHER WAY.** The seal
#   below puts the respell first so rung 2's rules are emitted in their final shape. With the
#   respell stopped pending a ruling, **that reason no longer holds anything up** — Family C
#   (CHARACTER SET, 4) is the recorded and accepted pick and opens without re-litigating it.
#   ⚠ But note what §3.0 found on the way past: the emitted form is **already** `&&`-chained, so
#   a later `&&`→`AND` respell moves generated text for every rule installed before it, rung 2's
#   included. That is a re-pin, not a correctness risk.
#
# ⚠ **ALSO LANDED THIS SESSION (SEQ 47, commit `68e2f69`): the `DesignDocs` registry is homed at
#   `incant/designDocs` and `docs/displayDesign.md` is HISTORICAL.** The Display First Light
#   drawer entry below is repointed in place. ⚠ **The canonical text needed three semicolons** —
#   parse-green is not shape-correct, and the mis-nested tree it built exited 0 with a sentinel.
#
# ⚠ **NOTHING ELSE MOVED.** Docs and ipc only; no engine surface, no fixture, no baseline. The
#   `incant/recordPT` run was read-only and env-gated.
#
# ═══════════════════════════════════════════════════════════════════════════════
#
# ⚠⚠⚠ SEALED 2026-08-11 — SHUTDOWN SEAL (CURRENT VINTAGE). READ THIS FIRST.
# **THE AND/OR RUNG IS BUILT, GREEN AND SEALED — ALL SIX PARTS, ONE SESSION.** Ladder
# **173 → 184 / exit 0** and there are **NO INVERTED ROWS LEFT ON IT** for the first time.
# `AND`/`OR` short-circuit in both engines and byte-agree. Two KEs filed, one KANT claim
# repaired, one prediction failed and filed as failed.
#
# ⚠⚠ NEXT ACTION — **THE GENERATOR RESPELL ONTO AND/OR. AUTHORIZED, RULED, AND FIRING.**
#    Charter transcribed to **`docs/respellRung.md`** (it was dictated in chat, and a ruling
#    whose only home is a thread is an unmeasured citation waiting to be made). **§1's
#    ruling is GRANTED — Tony, 2026-08-11:** the frozen section of
#    `docs/attributesTemplate.md` may be edited to emit AND/OR chains, dated with the old
#    form left legible; and **generated-code use of AND/OR is a NEW population, named and
#    granted** — the landed consumer respell (`a7fcb34`) was ALTERNATION-only, and nothing
#    slips in unscoped.
#    **WHAT IT DOES, in one sentence:** an installed rule's generated parse method is built
#    today from **`goto generatedExit`** scaffolding (`GroupItem.twk:1232`/`:1269`); the
#    respell replaces it with **operator chains** — a term sequence becomes
#    `t1() AND t2() AND t3()`, an alternation an `OR` chain. ⚠ **It is sound ONLY because of
#    what landed 2026-08-11**: short-circuit stops the chain at the first failed term, and
#    the convention puts the **mark-restore INSIDE each term**, so stopping early cannot
#    strand the rule mark.
#    ⚠ **FIRST MOVE IS NOT STEP 1. It is §3.0 — MEASURE GM-13's LEAD** before committing
#    `Braced` to the structural-exhibit slot. The charter picks Braced because *"first
#    install went red on the goto structure"*; `GM-13` (`docs/grammarCorpus.md:268`)
#    confirms the RED but names its cause **"LEAD, at the usual odds, UNMEASURED and NOT
#    HARDENED."** If the goto structure is not the cause, the flagship exhibit either stays
#    red or **goes green for an unrelated reason and is read as proof.** One before/after
#    against `docs/emitted/braced-red-specimen.txt`, which already exists.
#
# ⚠ **AND THE ORDERING IS DELIBERATE — RESPELL BEFORE PHASE R RUNG 2, on this project's own
#   precedent.** `docs/andOrRung.md`'s scheduling note put AND/OR *before* genKantParse for
#   exactly one reason: **"ordering AND/OR first means genKantParse emits the final shape the
#   first time."** The same argument applies one link down the chain. Rung 2 **installs new
#   rules**; the respell **changes the form every installed rule is emitted in**. Install
#   first and rung 2's rules are emitted in a shape that is about to move — **generated text
#   produced twice, and an oracle re-pinned for a reason that says nothing about
#   correctness.** So: **respell, then rung 2.**
#
# ⚠ **SECOND ACTION — PHASE R RUNG 2**, unchanged in substance and no longer conditional on
#   anything: **Family C, CHARACTER SET (4)** is the **RECORDED AND ACCEPTED** pick (SEQ 33)
#   and **opens on that pick without re-litigating** — single-token, self-delimiting terms,
#   no container work, where **Family A REFERENCE (5)** leans on rule-reference resolution
#   the refusal census still calls a frontier. ⚠ **And that census reports the FIRST blocker,
#   not the blocker SET** (H9's corollary), so *"Family A is nearly unblocked"* is **not a
#   claim the census can support** — re-run the rules after any close before believing it.
#   Denominator stays **47**; the metric moves only on installed, verified-green rules.
#
# ⚠ **WHAT LANDED (spec and full record: `docs/andOrRung.md`, whose §Status table is the
#   LEDGER OF RECORD, part by part).** `AND`/`OR` take C++ semantics — **return 1 or 0
#   always, short-circuit, both engines agree**.
#   **THE SEAT IS `interpretXP`, AND IT IS TONY'S RULING.** The first build gated at the top
#   of `runOP` and he moved it. **`TokenXP` — the natural guess, since unaries live there —
#   CANNOT work for a binary**, and the reason is pointable in the grammar:
#   `TokenXP UnaryOPS? ANYorNum^ InvokeArg?` **groups** a unary with its operand, so the
#   pairing is a *parse fact*; `ExpressioN Token+` is **FLAT**, so at that seat `AND` has no
#   arms and no precedence. The binary first exists in `interpretXP`'s tree build, which is
#   therefore where the **category** decision belongs — paid **once per expression** instead
#   of once per dispatch, and `runOP` stays what §6 calls it, *the strict operator dispatcher
#   and nothing else*. **`runOP` is untouched.**
#   **ONE CONTRACT, ONE PLACE:** `truthOf` (`Instruct.rtn`) — null false · numeric **by
#   value** · non-numeric true **by presence** · **text DELIBERATELY UNRULED and refused at
#   emit**. Both arms of both words go through it, so the engines cannot grow separate ideas
#   of truth.
#   **THE EMITTER:** `jitEmitShortCircuit` + `jitScBegin`/`jitScEnd`. Entry-block alloca (so
#   mem2reg can promote it), the short-circuit answer **PRE-STORED** so the skipped path
#   needs **no block at all**, **no hand-written phi**, and the result **seeded onto the
#   node's `jitData`** — ⚠ without that last step the topology was right and **the value had
#   nowhere to go**: `x2Out` returned 0 on every fire while the diamond and the ticks were
#   both already correct.
#
# ⚠⚠ **THE PLACEMENT DOCTRINE — RULED BY TONY, RATIFIED IN CLOD'S FORMULATION (SEQ 33), AND
#   THE NEXT TIER-3 CONSTRUCT INHERITS IT BY CITATION. Doc of record: `docs/andOrRung.md` §6a**
#   (filed there rather than in the corpus because §6 is already where the tier table and the
#   phase rule live, so a reader arriving at "what tier is this and where does it go" finds
#   both in one place):
#
#     **An evaluation-controlling operator intercepts at `interpretXP`, where the expression
#     tree is BUILT — never at the strict-operator handler, and never at the strict
#     dispatcher's door.** Paid **once per expression** instead of once per dispatch, and the
#     **tier-3 set becomes one line you edit to widen.**
#
#   **AND ITS COMPANION RULE, which the exhibit forces: A TIER-3 PROMOTION IS NOT LANDABLE IN
#   HALVES.** Promote the category and emit for it **in the same rung**, and make the emit-side
#   gate a **REFUSAL** rather than a fall-through — a refusal is counted by every rung's
#   degrade-zero assertion; a fold is counted by nothing.
#
# ⚠ **THE SPLIT, SAID PLAINLY, which is the whole requirement:** SEQ 31 §4 made Phase R rung 2
#   conditional on this rung sealing clean. **It sealed clean and rung 2 was still not opened**
#   — the session went to the truthiness contradiction, the seat move and the emitter.
#   **A KNOWING SPLIT under the practicality valve, not an overrun.**
#
# ⚠ **RESULTS, VALUES NOT COUNTERS:** `jitXand2` fire 1 **0** / fire 2 **1** (was 0, silently
#   wrong) · `jitXor` fire 1 **0** / fire 2 **1** (was 0, silently wrong) · `jitXand` fire 1
#   `ticksR` **0 = SKIPPED**, fire 2 `ticksR` **1**, `ticksL` **2 = emitted per fire** ·
#   `xaOut` fire 2 **1** · **degrade 0 on all three** · `orProbe` `hasOnly` → *"disjunction
#   caught it"* · `andProbe` §1 unchanged across the rung, which is the claim.
#
# ⚠⚠ **FOUR FINDINGS THAT OUTLIVE THE RUNG:**
#   1. ⚠ **THE PROMOTION ALONE MADE THINGS WORSE, AND THIS IS THE ONE TO REMEMBER.** On the
#      intermediate build — interpreted arm promoted, **no emitter** — the `AND`-under-jit
#      **139 DISAPPEARED AND WAS REPLACED BY THE SILENT WRONG ANSWER**, at **degrade count
#      0**. Trading a loud crash for §2's *"dangerous one"* is a **REGRESSION IN LOUDNESS
#      WEARING THE SHAPE OF PROGRESS**, and it was visible **only** because the two inverted
#      JXD rows were watched across *both* builds. **A partial landing of a two-arm change can
#      be worse than not starting**, which is why `runShortCircuit`'s jitting gate is a
#      **REFUSAL** and never a fall-through.
#   2. ⚠ **THE H7 NEGATIVE CONTROL IS THE BEST EXHIBIT THE RULE HAS.** Short-circuit removed
#      (`CreateCondBr` → unconditional `CreateBr`), rebuilt, rung re-run:
#      **tick rows RED · `xaOut = 1` GREEN · degrade 0 GREEN.** **The value row and the
#      degrade row both survived the mechanism's removal**, so a rung built the obvious way
#      would have certified **eager code as short-circuiting** — and nobody would have looked,
#      because it tested the right feature and got the right number. **Only counting can see
#      a skipped arm.** Recorded in the ladder at JXD-3.
#   3. ⚠ **A CORRECT CLAIM CARRIED A WRONG MECHANISM FOR TEN DAYS. `CLAIM KANT-35` IS
#      REPAIRED** — `||` on `!absent` went from *"saw BOTH PRESENT"* to *"caught it"* — and
#      **the cause is NOT the evaluation-order mechanism the claim recorded**. `opOR`'s
#      structure was **INVERTED**: it consulted `argument` only when `target` was **already
#      truthy**, so a false left arm returned `falseResult` **without ever reading the right
#      arm**. Structural claims hold, causal claims fail — **and the symptom kept reproducing,
#      which is exactly how the wrong mechanism survived.** `KANT-34` splits: statement holds
#      for the **symbol** forms, its *not-expressible* mechanism claim **retires**.
#   4. ⚠ **THE CENSUS MISSED A FILE INSIDE ITS OWN SCOPE.** Part 3's 08-09 census read
#      **165 surface / 7 genuine**; re-measured **294 / ~30**, and the miss is
#      **`incant/utilities`** — six uses, **`include`d by every fixture preamble in the
#      tree**. **The CONCLUSION stands** (zero side-effecting right arms under the wider net),
#      which is why this is a **census** failure and not a rung failure. **H9 again, on the
#      paragraph below the rule about censuses.** Reachability measured: `displayIfVisible`
#      **LATENT (defined, never called)**, `listRules` **LIVE**.
#
# ⚠ **A PRE-REGISTERED PREDICTION FAILED AND IS FILED AS FAILED** (`andProbe` §4). Clod
#   predicted the assignment-position change was inert. **It is not:** a false conjunction
#   used to yield a node with **no data** (a bare `if` reads it **false**) and now yields one
#   **holding 0** (a bare `if` reads it **TRUE**). Only shipping consumer is
#   `displayIfVisible`, which is **never called**, so **nothing live moved**.
#   ⚠ **AND THE FACT UNDERNEATH IT, WHICH THE RUNG DOES NOT CLOSE: `if <field>` AND
#   `<field> AND …` ALREADY DISAGREED, BEFORE ANY OF THIS.** `if aFalse;` reads **TRUE** on a
#   field holding 0 (bare tests go by **presence**); `aFalse AND aTrue` reads **false**. The
#   ruled contract governs **the operator**, deliberately. **Closing that gap is a ruling with
#   its own customer, and nobody has one.**
#
# ⚠ **FILED, NOT FIXED — the symbol forms, and they want taking TOGETHER** (`docs/knownErrors.md`):
#   **KE-5** — `&&` answers **`true && true` as false**. Not a truth table at all. Mechanism
#   **structural and pointable, not inferred**: `'&'` is registered **bare at `incant/setup:162`,
#   no `operateMethod`** — the exact state `'|'` was in before 2026-08-01, and `setup:100-111`
#   describes that failure mode in those words. ⚠ **The one-line repair is BELIEVED and was
#   DELIBERATELY NOT RUN**, because applying it *is* the repair and the repair is out of scope.
#   **KE-6** — **`OR` short-circuits and `||` does not, ON ONE SHARED HANDLER.** Created by
#   this rung and **named rather than hidden**; values agree, only evaluation differs.
#   **Widening tier 3 to the symbol forms is a RULING, not a rung.**
#
# ⚠ THE FLEET AT SEAL: ladder **184 / exit 0** (was 173) · pop **33 green / 1 parked**
#   (unchanged) · gapB 22 · mixed 7 · **completePop 129 swept, 0 missing sentinels (was 2),
#   226 green** · tree/printPop/containerPop/recordPop/formsPop/decodePop exit 0 · oneTest
#   (`maximus = 11` then **26 ×4**), jsonTest (**13 ok**), phaseA, emitAll, kant8T exit 0.
#   **Blast radius: every other stream byte-identical but the H1 binary echo.** Commits
#   **`3483167`** (Groups) and **`3bdcd2d`** (support — `groups.ext` gained `truthOf` and
#   `runShortCircuit` prototypes; ⚠ **out-of-repo build dependency, bear-trap #11, named
#   here because it will not show in a Groups `git status`**). Working tree carries only
#   Tony's own `IncantForms/WorkingOn/incant++`, deliberately held back.
#
# ⚠ **`incant/andProbe` IS NEW AND KEPT** — sibling to `orProbe`, the AND truth table plus the
#   short-circuit and assignment-position rows. **Zero text-bearing locals**, so the 08-10
#   audited set is intact. `completePop` picked it up automatically (128 → 129).
#   ⚠ **Its first header KILLED THE PARSE** — code-shaped lines, **bear-trap #27 reproduced
#   exactly**, exit 0 with the run truncated — and had to be wrapped in a comment block. The
#   trap's "headers get PROSE" rule is **necessary but not sufficient: the block delimiter is
#   also required.**
#
# ⚠⚠ **DRAWER AT SHUTDOWN — the menu, updated by SEQ 33. Two items DE-PARKED or NEW because
#    of today, and they are marked so the next session reads a current menu:**
#   · ⚠ **THE GENERATOR RESPELL — NOT IN THE DRAWER ANY MORE. It is the NEXT ACTION above,
#     authorized and ruled.** Charter: **`docs/respellRung.md`**. Its prerequisite line
#     (`docs/genKantParse.md` §2(c) row 2, *"emitted AND/OR short-circuit"*) **read ❌ THE WALL
#     and now reads exactly today's seal.** Charter amendments applied at de-park, per its own
#     provision: **(a)** §5 controls gain **`incant/andProbe` and `incant/orProbe` as KEPT
#     instruments** — the respell composes *chains*, so per-operator semantics must be pinned
#     **before the first regenerated rule fires**, or a chain defect and an operator defect are
#     indistinguishable at the only moment anyone is looking; **(b)** ladder reference updated
#     to **184 / 0**; **(c)** the charter **inherits** the truthiness ruling (SEQ 32) and the
#     placement doctrine (§6a) as standing context.
#   · **Phase R rung 2** — the SECOND ACTION above, behind the respell for the freeze-once
#     reason stated there. **Family C (4) is the RECORDED AND ACCEPTED pick** (SEQ 33) and
#     **opens without re-litigating it**. Family A (5) stays available if Tony overrides.
#   · ⚠ **NEW, NAMED, UNRULED — the BARE-`if` TRUTHINESS FORK.** `if <field>` and
#     `<field> AND …` **disagree on a datumless node**: statement position reads
#     absence-of-datum as **false**, operand position reads presence as **true**.
#     **Pre-existing, zero live customers**, wants a ruling — **unify, or declare it
#     deliberate**. On **nobody's schedule**. Opening exhibit: `incant/andProbe` §4 and §5.
#   · ⚠ **NEW — THE SYMBOLS RUNG, KE-5 + KE-6 JOINTLY.** `'&'` bare-registered at
#     `incant/setup:162` (the pre-08-01 `'|'` state) **plus** the one-handler short-circuit
#     gap. **Bounded, cold, and wants taking TOGETHER** — one question asked about two words.
#     ⚠ **The believed one-line repair stays deliberately UN-RUN until the rung opens.**
#   · **KE-4 refusal rung** — still cold, still ruled refuse-at-emit. **Untouched by the
#     AND/OR rung and not oversold.** ⚠ **It now carries finding 1 as PRECEDENT for its
#     posture**: refuse-and-count beats fold-and-be-quiet, demonstrated rather than argued.
#   · **`KANT-35`'s orphaned consequence** — its *"multi-attribute presence checks MUST stay
#     sequential"* instruction and `incant/genMany`'s site warning are **BELIEVED obsolete now
#     that the claim is repaired. BELIEVED IS NOT MEASURED** — the check is re-running
#     `spellMany`'s collapsed form against `manyScratch.target`. ⚠ **DO NOT tidy those guards
#     on the strength of the note alone.**
#   · **Display First Light (HTML)** — bounded opener, wiki-scope static documents, first
#     customer docs-to-HTML. ⚠ **REPOINTED 2026-08-11: the live ruling is the
#     `DisplayDesignHTML` entry of `incant/designDocs`**, not `docs/displayDesign.md`, which is
#     now HISTORICAL and carries a supersession banner. ⚠ **And the fence MOVED at that review:
#     the HTML target now handles simple events (resize, mouse clicks), passing them back to
#     kant to re-lay-out and re-emit — "static only, no JS planned" is no longer the whole
#     scope.** Whoever opens this reads the registry entry, not the md.
#   · **K6f re-size** — spec'd, **awaiting Tony's nod**, owner = next K-row rung.
#   · **First Light (parse)** — waiting. Behind it: **H3's 3–4 command registrations** · the
#     **contract RUN** that converts H4 from READ to signable.
#   · **At Clay's station, undrafted:** the **minion-channel addendum** and the
#     **citation-sweep dispatch** — ⚠ **which gains a `MECHANISM-UNVERIFIED` tag to its
#     classification set (SEQ 33), minted on `KANT-35`: a claim whose STATEMENT is measured
#     and whose CAUSE was never run.** Three fresh exhibits from this session: the §3
#     truthiness **TABLE**, the part-3 **CENSUS** (both cited-not-measured, both wrong, both
#     caught by one run each), and **`KANT-35`'s mechanism**, which survived ten days because
#     the symptom kept reproducing.
#
# ⚠ **BASELINE NOTE FOR WHOEVER NEXT CAPTURES (SEQ 33): the seal's fleet table above is the
#   NEW REFERENCE — ladder 184, `completePop` 129 swept / 226 green / 0 missing. ANY DOC STILL
#   CITING 173 IS CITATION-SWEEP FODDER, NOT A LIVE CLAIM.** `docs/genKantParse.md`'s
#   "green at 150 checks" is **deliberately left standing** — it is a *provenance* naming the
#   run its §5 table was measured against, and repointing a provenance falsifies the record;
#   it carries a dated pointer to this seal instead.
#
# ⚠ **STILL STANDING, so nothing here reads as finished that is not:** **KE-4** · **K6c**
#   (the argument-carrier's mutual failure) · **the vestigial `recursive` flag** (bear-trap
#   #16 territory, removal deferred with a dated note) · **`BLOCKED KANT-B1`** — kant still
#   cannot express a null · **KE-5/KE-6**, above · **the `if`-vs-operator truthiness gap**,
#   above.
#
# ═══════════════════════════════════════════════════════════════════════════════
#
# ⚠⚠ SEALED 2026-08-10 EVENING (SUPERSEDED BY THE BLOCK ABOVE) — its NEXT ACTION was
# "none mandated, the drawer is the menu", and the **AND/OR rung** was taken off that
# drawer and is reported DONE above. READ THIS FIRST.
# **CLAIM KANT-8 IS REPAIRED AND CLOSED** — open since 2026-07-29, shut in ONE campaign,
# TWO rungs, ONE seal, no split. **THE TWO DOORS ARE RULED AND CERTIFIED.** Display has a
# design doc. Fleet green at **173/0** and **33 green / 1 parked**.
#
# ⚠⚠ NEXT ACTION — **NONE IS MANDATED, AND THAT IS ITSELF THE NEWS.** The campaign that
#    has headed this file since 08-08 is DONE, and nothing replaced it at the head. **THE
#    DRAWER IS THE MENU.** Full list at the FOOT of this seal under DRAWER AT SHUTDOWN;
#    the two bounded openers, for a session that wants a clean win, are:
#      · **KE-4's refusal rung** — still cold, still ruled refuse-at-emit, still the right
#        cold-open. **Deliberately not taken today** — today already had its win.
#      · **DISPLAY FIRST LIGHT — the HTML target.** Wiki-scope **static documents only**
#        (no JS, no events, per §7.1); **first customer is docs-to-HTML**; opens whenever
#        a session wants a green-fleet build day. `docs/displayDesign.md`.
#
# ⚠ **WHAT LANDED (full record: `docs/kantCorpus.md`, CLAIM KANT-8, the block at the
#   END of the claim — that table is the LEDGER OF RECORD; `KR-3` stays retired).**
#   **RUNG A — value-capture in `runAction`:** the result's value is copied into a
#   freshly minted node BEFORE the restore sweep, and that node is returned. Gated
#   `!jitting`, because the jitted arm already returns by capture and owed
#   byte-agreement only — which it delivered. ⚠ **The copy constructor could not be
#   used: `GroupItem(GroupItem)` SHARES the body**, the very thing the sweep
#   overwrites. Mint on the tag, then `setContent`.
#   **RUNG B — the unconditional bracket:** all four `if field.recursive` gates gone.
#   ⚠ Those four were the flag's ONLY readers, so `recursive` is now **VESTIGIAL as of
#   `168453d`** — written (`ruleActions.rtn:1389`), cleared (`GroupActions.rtn:653`),
#   **read by nothing.** Removal DEFERRED, not forgotten: it is a field removal and so
#   bear-trap #16 territory (`groups.ext`'s mirror first, then `tokall`). **Same family
#   as the `ruleSTUFF` write-only ruling.** Dated note carried in the corpus entry **so a
#   future census reads it as a KNOWN state instead of rediscovering it as a mystery.**
#
# ⚠ **THE ORDER WAS THE WHOLE THING.** The 08-10 attempt did B without A and
#   universalised the defect. A-then-B was ruled by measurement and it held exactly:
#   **K3 stayed at 42 through both rungs**, so the fixture never went void this time.
#
# ⚠ **RESULTS, VALUES NOT COUNTERS:** K1 `k1loc`→**42** · K4 `k4loc`→**42** · K5
#   `k5loc`/`k5loc`→**42/42** · **K6a 2→3, rung B's payoff** (mutual recursion, which
#   the gate could NEVER cover because `recursive` is set at parse time by identity) ·
#   K2 unchanged at 7 · **K6c unchanged at `k6small` — the argument-carrier's mutual
#   failure is NOT repaired** · `kant8M1o` `m1count`→**42**, the second witness.
#
# ⚠ **TWO PRE-REGISTERED PREDICTIONS FIRED, AND BOTH INSTRUMENTS CAUGHT THEIR OWN
#   REPAIR** — ladder **JRt3** (*"That is not a regression, it is NEWS: KANT-8 may have
#   been repaired"*) and `kant8M1o`'s header. **Both graduated per H6 with their re-pin
#   sentences.** Ladder stays at **173**: a graduation, not an addition.
#
# ⚠⚠ **THREE FINDINGS THAT OUTLIVE THE RUNG:**
#   1. **THE TWO DOORS, MEASURED ON BOTH SIDES.** Door one (`runAction`) **523
#      crossings, 523 action, 0 RULE**; door two (`runRule`→`rule.parse(0)`) **1183,
#      0 action, 1183 RULE**. 1706 dispatches, **zero overlap**, name sets disjoint
#      (211 vs 12). ⚠ **The 0 is a POSITIVE named-set result, not an absence claim** —
#      door two carries the entire rule population elsewhere. **THE CENSUS CERTIFIES THE
#      RULING RATHER THAN MERELY SCOPING THE RUNG**, so it stands on measurement and not
#      on authority alone — ruled and certified the SAME DAY. Filed as **`CLAIM KANT-41`**
#      (RUN). Under it this campaign is **maintenance of door one, the LEGACY door**, and
#      **proposals to EXTEND door one's machinery should cite the ruling first.** ⚠ The
#      convergence question **inverts and PARKS**: not *"does door two need a bracket"*
#      but, post-self-hosting, *"does door one still need to exist."* **Nobody's task.**
#   2. **K6f HAS COLLIDED — number unmoved, MEANING changed.** Its "5 = no trample"
#      reading assumed the outer COUNTER carries across; with the bracket
#      unconditional the counter is per-activation too, so the outer counts its own 4
#      — **which is also 4**. One number, two eras. **K6a disambiguates** (3-wide
#      outer: 2 = trampled, 3 = kept its own) and moved 2→3 on the same build.
#      **Annotated, deliberately NOT re-sized** — a fixture whose meaning changed is a
#      design object again. ⚠ **THE RE-SIZE IS SPEC'D AND AWAITS TONY'S NOD** (SEQ 29):
#      differentiate the outer and inner widths, **e.g. 5 / 3**, so the two eras stop
#      aliasing on one number and *"no trample"* is discriminating rather than
#      coincidental. One-line edit; **owner is whoever next takes the K-row table.**
#      **The failure class now has a NAME** — `oneNumberTwoEras`, minted into the decoder
#      corpus: *a green that survived a semantics change by arithmetic accident.*
#   3. ⚠ **CLAUSE 3'S FIXTURE WAS GREEN AND CERTIFIED NOTHING, and only the negative
#      control knew.** `runAction` has TWO null paths. The **reachable** one is its
#      early return on a parse failure, ABOVE the seam. The **guarded** one measured
#      **0 occurrences in 128 files**. So the null guard is **confirmed correct by
#      census** and prevents a dereference, but is **uncontrolled by any fixture** —
#      **honestly labelled uncontrolled-until-reachable** in `incant/kant8N`'s header
#      rather than papered over with an invented green.
#      ⚠ **AND THE ZERO HAS A MECHANISM, found by reading the corpus: `BLOCKED KANT-B1`,
#      filed a week earlier by a different round, tried FOUR ways to produce a null from
#      a kant body and could not.** So the 0-in-128 is not *"nobody happens to"* but
#      ***"kant cannot express it"*** — much stronger, and it settles the ambiguity a bare
#      count would have left. **The two findings were made a week apart and each would
#      otherwise have been re-derived; both entries are now cross-linked.** B1's blocker
#      is thereby located as **UPSTREAM of the seam** — clause 3 preserves a null if one
#      ever arrives, so the probe belongs at `processAction`'s `BlocK` result.
#      ⚠ **THIS IS THE DAY'S BEST EXHIBIT FOR THE VIGRAM THESIS: A CONTROL NEEDED A
#      CONTROL.** The fixture was green; only the mechanism-removed run — by **failing to
#      go red** — revealed that the green certified nothing. Without it the seal would
#      have read *"clause 3 controlled"* and been wrong **in the flattering direction**,
#      which is clause 3's own documented danger. **Discipline-as-structure caught it,
#      not care.** Same lesson, same day, one level down: `${PIPESTATUS[0]}` — this
#      repo's own documented bear-trap, read this morning — **bit anyway**, and was
#      caught by re-measurement rather than by knowing.
#
# ⚠ **NOT REPAIRED, so it is not oversold:** **KE-4** (text local on the JITTED arm
#   returns its LENGTH) — rung A is `!jitting` by design and could not have touched it.
#   **K6c**, above. The vestigial flag, above.
#
# ⚠ THE FLEET AT SEAL: ladder **173 / exit 0** · pop **33 green / 1 parked** · gapB 22 ·
#   mixed 7 · **completePop 128 swept** (was 127; +1 and +2 green are `kant8N`, named) ·
#   tree/printPop/containerPop/recordPop/formsPop/decodePop exit 0 · oneTest, jsonTest,
#   phaseA, emitAll, kant8T exit 0. **Blast radius: every harness differs by the H1
#   binary echo ONLY**, every exit status identical, `oneTest`/`jsonTest`/`phaseA`/
#   `emitAll`/`kant8M1`/`spellScratch` byte-identical. Working tree carries this work
#   plus Tony's own `IncantForms/WorkingOn/incant++`. Commits `168453d` (the campaign),
#   `7f99e66` (Display design), plus the SEQ 30 closeout.
#
# ⚠ **SEQ 29 — DISPLAY IS DESIGNED AND RECORDED: `docs/displayDesign.md`.** source →
#   form → attributes → target. Two rulings inside it: **§3 the stream model** — output
#   is a **forward-only stream, not a scope tree**; named styles replace state wholesale,
#   **no restore exists BY CONSTRUCTION** (no bracket, no seam — §4 cites this repo's own
#   freshly measured failure class as the reason); and **§5 emission** — targets receive
#   **resolved** output, **no CSS**, everything inline. ⚠ **Independently convergent with
#   the 2026-08-06 Display ruling** ("context + one style slot + pen + measure"): §3's
#   current style IS that slot, §6's measurement IS that measure. **Two design passes,
#   different entry points, same architecture — checked, not assumed.**
#   `docs/note-to-clay-style.md` (the 06-27 ask) carries a dated pointer to it, naming
#   what is settled and what is **not** (Cocoa seams, the SVG sink, §9(a) based-on chains).
#   **`layout-recon.md` and `gui.md` get NO pointer** — they are §7.2 window-target
#   INPUTS, not superseded designs.
#
# ⚠⚠ **DRAWER AT SHUTDOWN — the menu, in no mandated order:**
#   · **KE-4 refusal rung** — bounded opener, cold, ruled refuse-at-emit. **Cold and NOT
#     oversold: rung A is `!jitting` by design and could not have touched it.**
#   · **Display First Light (HTML)** — bounded opener, scope-fenced to wiki-like static
#     documents, first customer docs-to-HTML.
#   · **K6f re-size** — spec'd, **awaiting Tony's nod**, owner = next K-row rung.
#   · **`AND`/`OR` rung** — ruled, **drawer-ready** in `docs/andOrRung.md`, NOT built.
#     Part 3 changes shipping text, so it wants the TOP of a session.
#   · **First Light (parse)** — waiting. Behind it: Phase R rung 2 (Family A REFERENCE 5,
#     or Family C CHARACTER SET 4) · **H3's 3–4 command registrations** · the **contract
#     RUN** that converts H4 from READ to signable.
#   · **At Clay's station, undrafted:** the **minion-channel addendum** and the
#     **citation-sweep dispatch**.
#
# ⚠ **STILL STANDING, so nothing here reads as finished that is not:** **K6c** — the
#   argument-carrier's MUTUAL failure is **not** repaired by either rung and remains
#   `k6small`. **KE-4** — text local on the JITTED arm returns its LENGTH. **The
#   vestigial flag.** **`BLOCKED KANT-B1`** — kant still cannot express a null.
#
# ═══════════════════════════════════════════════════════════════════════════════
#
# ⚠⚠ SEALED 2026-08-10 MIDDAY (SUPERSEDED BY THE BLOCK ABOVE) — its NEXT ACTION, the
# seam + bracket campaign, is the work the block above reports as DONE AND CLOSED.
# THE SEAM IS RULED · THE CENSUS IS EMPTY · KE-4 IS RULED · THE CHANNEL IS TRACKED.
# TODAY REVERTED ITS ONLY BUILD AND STILL ENDS AHEAD: four premises retired, two
# doors found, a channel made legible, and the next session opens at a FIXTURE LIST.
#
# ⚠⚠ NEXT ACTION — **THE SEAM + BRACKET CAMPAIGN. ONE CAMPAIGN, TWO RUNGS, ONE SEAL**
#    (Q3 MERGED, Tony 2026-08-10). Scheduled for the ~16:00 restart the SAME DAY —
#    Tony's siesta-then-afternoon pattern, which worked on 08-09. In order:
#      1. THE CROSSING COUNTER in `runAction` — quantified expectation before the
#         edit, because the seam's territory is `actionType` calls ONLY (two doors).
#      2. VALUE-CAPTURE: **mint a fresh node, copy the value in, return that** —
#         never the local's node, never a bare scalar, and **PRESERVE NULL AS NULL**.
#      3. THE CONTROL FLEET: K3 at 42 gate-irrelevant · JRt1 interpreted == jitted ·
#         **JRt3's certified divergence FLIPS to agreement, with its H6 re-pin
#         sentence** · `incant/kant8M1` as the template witness · the speller's 85
#         rows byte-identical · **K6 READABLE — the voided control back in service.**
#      4. THE BRACKET RUNG, on the same seal, inheriting a green K6 as a free entry
#         control.
#    ⚠ **PRACTICALITY VALVE (Tony): the merge is PREFERRED, NOT MANDATORY.** If
#    session length or a finding forces a split, **split KNOWINGLY and say so in the
#    seal.** Full spec: `docs/kantCorpus.md` CLAIM KANT-8. **KE-4's refusal rung
#    cold-opens whenever a fresh session wants a bounded win.**
#
# ⚠ THE FLEET AT SEAL: ladder **173 / exit 0** · pop **33 green / 1 parked** ·
#   gapB 22 · mixed 7 · completePop 127 swept. Junction verified AFTER the census.
#   Working tree clean but for Tony's own `IncantForms/WorkingOn/incant++`.
#
# ═══════════════════════════════════════════════════════════════════════════════
#
# ⚠⚠ SEALED 2026-08-09 EVENING (SUPERSEDED BY THE BLOCK ABOVE) — READ THIS SECTION FIRST.
# PHASE T DELIVERED · E2 BUILT · THE DECODER BUILT · STEP 1 ARTIFACT MEASURED ·
# AND/OR RULED (not built). THE METRIC IS 0/47 (see T-3 — it did NOT move to 0/46).
# Everything from the `# ⚠⚠ SEALED 2026-08-08 EVENING` header down is older vintage.
#
# ⚠ SUPERSEDED 2026-08-10 — THE BRACKET FIX WAS ATTEMPTED AND IS **BLOCKED ON
#   `CLAIM KANT-8`'s OWN REPAIR**, which is a design call and is TONY'S. It was
#   built as specified, it runs, and it UNIVERSALISES KANT-8 rather than fixing
#   it: kant8T's K3 control goes void, so the rung's prediction could not be
#   evaluated. REVERTED — the fleet is back at 173/0 and the junction is still
#   intact for whoever takes it next. Sites and scope below are CONFIRMED
#   correct; only the prerequisite was missing. See the two blocks below and
#   `docs/kantCorpus.md` CLAIM KANT-8 (2026-08-10).
#
#   (Superseded text, left legible: "NEXT ACTION IS UNCHANGED AND STILL FIRST IN
#   LINE: THE KANT-8 UNCONDITIONAL BRACKET FIX. Nothing today installed
#   anything, so ITS JUNCTION IS INTACT — the fleet is green at 173/0 and the
#   argument for taking it on the cleanest baseline still holds.")

# ═══════════════════════════════════════════════════════════════════════════
# 2026-08-09 — THE FAMILY TABLE LANDED, E2 IS BUILT, AND A SEALED CENSUS
#              TURNED OUT TO BE WRONG FOR 13 OF 21
# ═══════════════════════════════════════════════════════════════════════════

## ⚠⚠ RUN 2026-08-10 — **BLOCKED, AND THE BLOCKER IS `CLAIM KANT-8` ITSELF. READ THIS BEFORE
## THE BLOCK BELOW, WHICH IS LEFT AS WRITTEN BECAUSE ITS SITES AND SCOPE ARE STILL CORRECT.**
**The fix was built exactly as specified — all four `if field.recursive` gates removed — and it
runs. It does not repair `CLAIM KANT-8`; IT UNIVERSALISES IT.** The gate was the only thing
keeping `restoreLocalFields` off the return seam on ordinary calls, so ungating it makes *every*
action that returns a local return a blanked node, not just self-mentioning ones.

**`kant8T`'s own validity control is what says so.** K3 — *non-recursive, returns a local, "want
42; if this is not 42 the fixture is void"* — returns **`k3loc`**. By the fixture's declared
terms every K6 row below it is then **uninterpretable, not wrong**.

⚠ **SO THE PREDICTION THIS RUNG CARRIED COULD NOT BE EVALUATED.** K6 neither inverted nor
partially recovered — **it stopped being readable**. And the thing "hiding in the blast radius"
was never hidden: it is `CLAIM KANT-8`, RUN-confidence since 2026-07-29, on the same seam, whose
own text already names the repair as **Tony's design call** (detach the result before restoring,
or restore before reading it).

**RULED BY MEASUREMENT: KANT-8's repair is a PREREQUISITE of the unconditional bracket, not a
follow-on.** The two cannot be sequenced the other way — the gate is what currently bounds
KANT-8's blast radius. **That design call is now on the critical path, and it is Tony's.**

## ✅✅ SEAM RULED 2026-08-10 (Tony): **VALUE-CAPTURE, ALIGNED TO THE JIT'S CHANNEL.** CENSUS RUN,
## **REAL CUSTOMERS ZERO — FORK BRANCH 1 EXECUTED.** THE SEAM FIX OPENS A FRESH SESSION.
`runAction` captures the result's value **before** the restore sweep and returns it. **The bracket
is untouched** (M1: locals restore perfectly at every depth on both engines). Not a workaround —
**the jit already returns by capture**, so this is the interpreter adopting the certified arm's
semantics, and the jit owes **byte-agreement only**.

**NODE-RETURN CENSUS — 727 surface / 65 statement-position / 51 candidates / 2 node-valued /
ZERO real customers.** `JSONfield`'s `token` is **out of the seam's reach by mechanism**;
`testNew`'s `grup` is **dead** (both call sites commented out). ⚠ **THE MECHANISM FINDING IS BIGGER
THAN THE CENSUS: A CODED *RULE* NEVER ENTERS `runAction`** — `ruleActions.rtn:352` binds
`processAction` directly, and `runRule` goes to `rule.parse(0)`. **Two entry paths into an action
body; only one has a bracket or a seam.** So the whole grammar/XML population sits outside both.
⚠ **CARRIER DISCIPLINE RETIRED (dated note, not deletion)** — obsoleted by the seam fix, surviving
for **no** population. Full record: `docs/kantCorpus.md`, `CLAIM KANT-8`.

⚠ **THE SEAM RUNG STARTS FROM THIS CONSTRAINT: MINT A FRESH NODE, COPY THE VALUE IN, RETURN THAT
— never the local's node, and never a bare scalar.** `genParse.rtn:847` and `:964` both null-check
the result **and then read `.text`** off it — four reads at two sites that a raw integer breaks.
**The census pre-cleared the minting**: zero identity customers means a fresh node is
indistinguishable from today's behaviour for every living caller. ⚠ **ONE SENTENCE OF SPEC FOLDED
INSIDE IT — THE NULL PATH: preserve "no result" as NULL, do not mint an empty node**, or both
`if !result` checks silently invert and an empty answer reads as a successful one.
⚠ **AND THE SEAM'S TERRITORY IS NARROWER THAN "THE INTERPRETER": only `actionType` calls reach
`runAction`. Coded RULES bind `processAction` direct (`ruleActions.rtn:352`) and cross no seam.**
So a moved **parse** row in the seam capture is a **finding, not noise** — the diff is a sharp
instrument rather than a broad one. **Opening move of the campaign: a crossing counter in
`runAction`**, so the expectation is quantified rather than reasoned.
**Named controls, so the session starts at the fixtures:** K3 at 42 with gate-irrelevance ·
JRt1 interpreted matching jitted · **JRt3's certified divergence flipping to agreement, with its
H6 re-pin sentence (values, not counters)** · `incant/kant8M1` as the template-population witness ·
the speller's 85 rows byte-identical · **K6 with readable rows — the voided control returning to
service.** Then the bracket rung unblocks, inheriting a green K6 as a free entry control.

✅ **KE-4 RULED refuse-at-emit** (`docs/knownErrors.md`), repair deferred to its own unscheduled
rung. ✅ **`i32`-by-rule fence frozen into `docs/attributesTemplate.md` §6.**

⚠ **AND KE-4 HAS REAL CUSTOMERS WAITING:** `genEmit`'s `leaf` and `genMany`'s `answer` are
body-born **text** locals returned across the genParse kant seam, which *does* go through
`runAction`. **Audited 2026-08-10 — the AND/OR fixtures and every named seam control carry ZERO
text-bearing locals**, so their greens are trustworthy; the text population is confined to
`genEmit` (7), `lessProbe` (4), `genMany` (2).

⚠ **M1 + M2 RUN 2026-08-10, AND THE CONDITIONAL DETACH PICK IS OFF — M2's PRECONDITION FAILS.**
`restoreLocalFields` pairs **positionally**, via an **unkeyed LIFO**: save walks forward pushing a
body per member, restore walks backward popping one per member, and nothing but walk position ties
a body to its field. **A mid-frame detach therefore hands the wrong body to a surviving local and
strands one on the stack** — silent both ways. The tree already says so in the JIT's own rationale
(*"restoreLocalFields walks BACKWARD because it pops a stack … the stack discipline was the bug
surface, and it is gone rather than reimplemented"*). **So "one unlink at one site" does not hold;
a correct detach is walker surgery.** The principled form — **key the restore by field, not by
position** — is bigger than either option weighed, and it is Tony's. **STOPPED AND RECONVENING; no
code written.**

✅ **M1 CONFIRMS THE CHANNEL SPLIT AND NARROWS THE REPAIR.** Interpreted hands back the **node**;
jitted hands back a **value** already out of it (42, then 45 on refire, degrade 0). **So the defect
is interpreter-side aliasing and the jit arm owes byte-agreement only.** And the more useful half:
printed from *inside*, **the frame bracket is not broken** — both locals restore perfectly at every
depth on both engines (42/41/40 in, 40/41/42 out). The bug is only that *the returned pointer points
into the frame being restored*. ⚠ M1 also found a **silent wrong answer nobody was looking for**: a
**text** local on the jitted arm comes back as its **LENGTH**, degrade 0, exit 0 — filed
`docs/knownErrors.md` **KE-4**, unruled, Tony's. Fixtures `incant/kant8M1`, `incant/kant8M1o`.

Three witnesses, one signature: `kant8T` K3 → `k3loc` · `incant/genEmit`'s speller → `leaf` (85
`spell.target` rows plus `rung5.target`) · ladder **JRt1** interpreted `''` vs jitted 21.
`oneTest`, `jsonTest`, `phaseA`, `emitAll`, `tree`, `printPop` stayed **byte-identical**, so the
damage is precisely the returns-a-local population. **REVERTED — the fleet is back at baseline
(ladder 173/exit 0, pop 33 green/1 parked), every remaining diff an H1 echo or a pinned-crasher
PID.** Full record: `docs/kantCorpus.md`, `CLAIM KANT-8`, the 2026-08-10 block.

## ⚠⚠ NEXT ACTION — **THE KANT-8 UNCONDITIONAL BRACKET FIX.** GO given (Tony, 2026-08-09),
## scheduled for the afternoon session. Everything it needs is in this block; no archaeology.
## ⚠ **ATTEMPTED 2026-08-10 AND BLOCKED — see the block immediately above. The sites and the
## scope below are CORRECT and were confirmed by measurement; what is missing is the KANT-8
## prerequisite. Nothing below is withdrawn.**

**Why now, and it is perishable:** the scheduling term was *"at the green-fleet junction"*, and the
junction is **open right now** — the fleet is green at **173/0** and freshly re-certified by rung
1's blast-radius capture. **Every campaign rung from here lands on a progressively less pristine
baseline**, so taking it today puts its blast radius on the cleanest fleet the project will have
for a while.

**THE SITES, located 2026-08-09 so the afternoon starts at the edit:**
- `GroupActions.rtn:746-754` — `jitSaveFrameRT` / `jitRestoreFrameRT`, both `if field.recursive`.
- `GroupActions.rtn:748 · 753 · 782 · 799` — the four `field.recursive`-gated bracket calls.
- `saveLocalFields` `:924` · `restoreLocalFields` `:648`.
- **The gate is the defect.** `recursive` is set at PARSE time **by identity**
  (`ruleActions.rtn:1310`), so **mutual recursion never sets it** — and bear-trap #25's sibling
  records that it is additionally **CLEARED AT RUN TIME** by `restoreLocalFields`, so whether the
  bracket runs depends on **invocation history**. Unconditional kills both failure modes.

**SCOPE — the defect is the bracket's ABSENCE and only that.** K6: blast radius wide but **entirely
bracket-shaped**. K5 **dissolved its own premise** (flag-clear reachable only where harmless;
sequential re-entry sound). K6a confirmed the restart mechanism. **The measurements ARE the spec;
nothing re-opens them.**

**OBLIGATIONS, all standing precedent now:**
- **H6 graduations** — any `kant8T` row pinned green-while-defective goes red on repair and
  graduates **with the re-pin sentence**, exactly as JE2/JXN did. **Values, never counters.**
- **H7 control — measured, not inferred.** Rung 1 set the bar: **show the discrimination**, not
  just the green (11 red / 5 still-green was the shape).
- **Blast-radius rider is STANDING PRECEDENT, not a per-rung request.** Full fleet captured before
  and after, **every stream diffed**, the impact record as deliverable. **Rung 1's format is the
  template** (`docs/gapBPhaseR.md`), and its noise classes are already characterised: H1 binary
  echo, PIDs in pinned-crasher segfault lines, pop.sh's working-tree readout.
- ~~**KR-3 ledger rows updated with the repair outcome.**~~ ⚠ **`KR-3` RETIRED 2026-08-10 (Tony).
  THE LEDGER NEVER EXISTED AS A FILE** — a tree-wide grep returns exactly one hit, **this sentence
  citing it**. A ledger spoken into being by the instruction to update it; Amendment A's family,
  and the defective citation was Clay's. Struck rather than deleted, per the legibility rule.
  **THE LEDGER OF RECORD IS THE K-ROW TABLE UNDER `CLAIM KANT-8` IN `docs/kantCorpus.md`** — future
  briefs name that file and that table.
- ⚠ **DOCTRINE CHECK AT THE TAIL:** K1–K4 established **carrier discipline** as a working
  mitigation for **direct** self-recursion and **invalid for mutual**. If the unconditional bracket
  makes that mitigation obsolete, the doctrine line gets a **dated retirement note — not deletion**
  (same legibility rule as everywhere). **If it survives for some population, say which.**

**NOT IN SCOPE:** Family C waits behind the bracket (follow-on if the afternoon runs long, next
session otherwise). **The `jitEmitUnary`←`opPlusPlus` 139 stays parked** — it is *adjacent*, and
**adjacency is not scope**: if the bracket's neighbourhood is touched, **note it, do not chase it**.

## THEN — Phase R rung 2 — Family A (REFERENCE, 5) or Family C (CHARACTER SET, 4). Both have a §2.5 spec
(A is ITERATE, C is ACCUMULATE). ⚠ **§3's ordering aims at `InvokeArg`'s alternation via
`NumbeR`/`ANYtoken`/`SemI`, and the DOUBLE-BLOCK RIDER still bites:** `SemI`'s **rule-level** block
is now closed but its **term-level** half is not, and `ANYtoken` is likewise blocked twice. **Rule-
level work alone closes neither cascade head.** Rung records: `docs/gapBPhaseR.md`.

## ✅ PHASE R RUNG 1 — FAMILY B (LITERAL) IS GREEN. REFUSALS 97→94, PLANNABLE 13→16.
**The metric's first movement under the charter — on the PLANNABILITY gate.** ⚠ **16 plannable is
NOT 16 installable; the metric line stays 0/47** (§1: this charter buys gate 1 only).
- **The treatment reuses `planTerm`'s existing `LIT`/`LITTO`** — no new plan kind, no new support
  function, and the LIT-vs-LITTO split is *copied* from `planTerm` rather than re-decided. That
  reuse is why it was rung 1.
- **The test is `rule.isSTRING`, not `rule.data`, deliberately** — widening would re-merge the three
  constructs the taxonomy exists to separate, **and would pass every positive row while doing it.**
  Five negative controls ride along for exactly that reason.
- **Bear-trap #26 was the live risk and did not bite** (`rule.text` → `;`, not `SemI`). The rung
  asserts **the literal text by name**: *"it planned"* cannot tell `LITTO ;` from `LITTO SemI`.
- ✅ **H4 DISCHARGED — both ruling-4 numbers are PRINTED as scalars** by `phaseA`
  (`TALLY refusals` / `TALLY plannable`). `planTally` counts at **3 sites not 17**, licensed by a
  **measured** invariant (`97 == 65 + 32`), and **the invariant is cross-checked against the grep
  every run** so a future two-line refusal path names itself instead of moving the metric quietly.
- ⚠ **THE TALLY'S FIRST DRAFT BROKE THE FIXTURE'S OWN COMPLETENESS GUARD** — prefixed `PLAN TALLY`,
  it was counted by phaseA's A1 marker as two extra walked rules (**80 PLAN / 78 DONE**): *the
  instrument that detects a truncated walk reported one, caused by the instrument added beside it.*
  Caught first run because the rung asserts A1 **from outside**.
- **NEW HARNESS `genLadder/gapB.sh` — 22 checks, exit 0**, with self-certification at the foot that
  a vanished helper set cannot satisfy. **H7 negative control measured:** 11 rows red without the
  treatment, **and the five negative controls stay green on that same capture** — so it
  discriminates rather than reddening on any input.
- ⚠ **BLAST RADIUS RECORDED, and rung 1 sets the precedent that every install documents what it
  touched.** Exit statuses identical across all 13 entry points; **`phaseA.err` shows the intended
  change and only it** (3 refusals → 3 plans, plus the 2 TALLY lines); every other diff is the H1
  binary echo or **PIDs in the shell's segfault lines for the pinned crashers**. **No baseline
  moved, no target re-pinned, no harness changed verdict.**

## ⚠⚠ THE FINDING THAT OUTRANKS THE DAY'S WORK — T-0
**`docs/gapB-staging.md`'s rule→kind mapping was WRONG FOR 13 OF 21.** Counts reproduce exactly
(9/6/3/1/1/1) on the **byte-identical binary**; memberships are scrambled. Mechanically diffed:
8 agree, 13 do not. `loopOnAttributes="attributes"` is a string literal and measures **isSTRING**,
not isGROUP; the rule literally named **`Any`** measures **isANY**, not isSET.
- **RULED (Tony):** the re-measurement is the truth of record. The wrong table stays legible with a
  dated correction banner on top — **no silent overwrite.** Cause stays **UNDIAGNOSED**: two
  explanations were tested and both falsified, and nobody guesses a third in.
- ⚠ **IT IS AMENDMENT A'S TWIN, ONE LAYER DOWN.** Amendment A exists because a *fixture name* was
  cited from a sealed doc instead of checked. This is a *table* cited from a sealed doc instead of
  re-run. **Cost of the re-run: one grep, against a fixture that already existed.**
- ⚠ **AND THE EXPENSIVE SHAPE: T-1's whole premise was an artifact of it.** The resolved-vs-declared
  question was designed carefully, fenced properly, and aimed at a divergence **that did not exist**
  — `Looper` measures isGROUP, exactly what its declared shape predicts. **A defective citation does
  not merely state something false; it generates well-reasoned questions that need not be asked.**
  CLAUDE.md's asymmetry paragraph now carries the sharpened form: **the pattern is
  unmeasured-citation-losing-to-measurement, not one seat losing to another.**

## ✅ T-1 ANSWERED — `planRule` READS THE **DECLARED** KIND. ONE PARTITION SERVES.
`genParse.rtn:517` is a single field read of `rule.data` with no chasing anywhere. The
discriminator used is stronger than a divergence: **four reference-shaped rules whose referents
carry NO rule-level data at all** (`NamE`, `RunRulE`, `TraiT`, `StatemenT` all pass :517) while the
referrers all report `isGROUP`. **Resolution cannot manufacture a kind from a referent that has
none.**
⚠ **T-1a, RAISED AND NOT DIAGNOSED:** the grammar-text→stored-kind map is *not* naive
(`counter=[0-9]` stores isCOUNT; `ShortcuT=[..]+` stores isGROUP). "Repetition promotes set→group"
is broken by `numberSet`; "length-1 literal→isCHAR" is broken by `SemI`. **Two counterexamples, so
it is an observation and not a mechanism.** Gates OPEN rows only.

## ✅ THE FAMILY TABLE — 21 rows, complete and closed, verified mechanically
```
  A REFERENCE      5  ANYtoken Looper Attributes InitiatE Start   (+NewGroup DEFERRED, IT-3)
  B LITERAL        3  SemI loopOnAttributes loopOnMembers      <- next rung
  C CHARACTER SET  4  nameSet Modifier followedBy numberSet
  D SET+SUBFIELDS  2  PoweR NumbeR      <- the shape §2.5 does not cover AT ALL
  E REPEATED SET   2  ShortcuT ANYstring
  OPEN             2  FloaT counter
  EVICTED          2  BrancheS (container, paid) · Any (not a grammar rule)
```
A is §2.5's ITERATE and B maps onto `planTerm`'s existing `LIT` — both have known treatments.
**D's two members disagree on kind**, which is the first thing its rung must explain. E was minted
separately so a collapse into C has to be **argued**.
- **`Any` EVICTED (ruled):** not a grammar rule — a **C++ bootstrap primitive**, `GroupMain.twk:156-158`,
  `isANY` set explicitly, absent from `incant/grammar` entirely.
- **Amendment B's `BrancheS` row cites "censused isGROUP"; it measures isSET.** Corrected on top;
  the eviction stands because it rests on `bin`, never on the kind.
- **Charter §2 annotated (text untouched):** "the scalar kinds" shares exactly ONE rule (`SemI`)
  with what it denoted at ratification. ✅ **§3's attack order SURVIVES — by measurement, not
  argument:** it keys on `NumbeR`/`ANYtoken`/`SemI`, **all three among the 8 filed correctly.**

## ⚠⚠ T-3 — THE METRIC IS **0/47**, NOT 0/46. HELD, WITH THE MEASUREMENT.
The `Any` eviction arrived with an attached arithmetic (`47→46`) and a documentation ask (*"note how
the liveness census came to count a rule no grammar line defines"*). **Both assume `Any` was one of
the 47. It was not.**
- IA-4/GM-31 defines the 47 as *names in `incant/grammar` that can consume a bind at their own
  definition site*, provenance *`incant/grammar`'s 163 lines*.
- **`Any` appears NOWHERE in `docs/emitted/liveness-census-2026-08-07.txt`.** Never probed.
**So the census never counted it and there is no instrument limitation to record.** `Any` was in the
**21** (from the **78**, Grokking's registry, where a C++-minted member is a full citizen), never in
the **47** (from grammar text) — GM-31 warns in bold these are different axes.
⚠ **Decrementing would UNDERSTATE the denominator and flatter the metric** — Amendment B's overcount
running backwards, sealed into the metric line. ✅ **CLOSED — Tony reviewed 2026-08-09, nothing to
add. The metric line stands at 0/47 as sealed and the awaiting-Tony flag is down.** The Gap B
population itself *does* move: **21 censused → 20, 18 in scope.**

## ✅ E2 IS BUILT — R1's CAMPAIGN PREREQUISITE IS DISCHARGED. LADDER 170 → 173.
`jitXe2`: was jitted **222/999** against an interpreted 111/0; now **111/0 then 222/999**, degrade
**0**, **one compile**, two fires on **opposite arms** with the input changed after emission.
**The fix: an inlined region gets an epilogue of its own** — one `JitInlineFrame` per inline, whose
exit block is the branch target for a return inside the callee. Branching to `gJitEpilogueBB` would
have returned from the **caller**. The old refusal's diagnosis was right and became the spec.
- **The exit block is unparented until first use** — an H7 obligation: a return-free callee must
  emit **byte-identical** IR.
- ⚠ **The value channel was not `gJitResult`, and the IR said so.** An assignment reads its
  operand's `jitData->jitValue`. A first cut set only `gJitResult` and produced **a merge that was
  correct and ignored**, plus a dominance violation. `jitInlinePop` now stamps the result node.
- ⚠ **One self-inflicted bug worth knowing:** re-inserting a block that was already parented
  surfaced as **"pointer being freed was not allocated" inside `~Function()`** at module teardown,
  with a backtrace naming `LLJIT::lookup` and nothing of ours.
- **THREE PINS FELL TO ONE REPAIR AND NOTHING ELSE MOVED** — JXT (degrade 2→0, its old pin
  *predicted* this), JE2 (222/999→111/0), **JXN (out 1/999 → 0/0 — the two-deep template now
  REJECTS what it must reject)**. All graduated per H6, each with the sentence the re-pin rule asks
  for. Banner corrected: **JXD-1/JXD-2 are the only inverted rows left.**
- **H7 negative control recorded at the rung**, and stronger than a synthetic gate-removal: the
  mechanism-absent run was **pinned green in a shipping harness for a day** — 222/999, degrade 2,
  exit 0, sentinel printed. **The wrong answer cost nothing visible.**

## ✅ EVENING — AND/OR RULED, THE ARTIFACT CORRECTED TWICE, AND ONE WITHDRAWAL
**`AND`/`OR` RULED (Tony, 2026-08-09): C++ semantics.** Return **1/0 always**, both engines
byte-agreeing, **short-circuit with the unreached arm never evaluated, side effects included.**
**The last open ruling on the promotion.** ⚠ **RULED, NOT BUILT** — transcribed to
`docs/andOrRung.md` with the six-part rung drawer-ready (interceptor handlers per the `if`
precedent · emitter diamond on the operand's `jitValue` channel, no phi, parent-once · **pre-flight
census of right-arm side effects in shipping text**, grep-then-migrate-or-certify in the SAME
commit · `jitXand`/`jitXand2` flip from documenting-the-139 to certifying, with H6 sentences ·
KANT-34's both-arms line gets a **dated retirement note, not deletion** · H7 control by **tick
count**, because a right arm that runs anyway still usually produces the right *answer*).
**Scheduling: post-First-Light natural, earlier permitted, Clod's clock.** Parked tonight on
purpose: part 3 is a **behaviour change to shipping text**, which is the loudest reason on the list
to start at the top of a session rather than the bottom of one.
- ⚠ **THE RULING WAS MADE IN CHAT AND NOW LIVES IN A FILE.** Today's two lessons — the decoder's
  reason for existing and T-0's cost — arriving on the day both were written down.

### ⚠ D1 WITHDRAWN FOR THE KANT ARM — my own claim, and the withdrawal is the useful part
I ruled that the SEQUENCE template's mark save/restore was a **second writer** against
`leaveRule`'s ownership of Invariant R, and recommended dropping it. **Correct for the C++ emitted
arm. It does not apply to the kant arm, which is the one the template is for:** `leaveRule` is
called by an emitted method's own return expression, and **it is not command-registered**, so a
kant method cannot reach it. **No first writer ⇒ no second one.** The **entry-save / tail-restore
epilogue stands, exactly as Tony ruled** — short-circuit stops the *evaluation*, it does not give
back what the arms that DID run consumed.
⚠ **The method failure, named: I asserted a conflict without measuring whether the first writer
was on the arm in question — and the grep was one I had already run, for H3.** A structural claim
about the arm I was reading, applied to an arm I had not.
✅ **And it leaves a cheap decision: registering `leaveRule` collapses the question.** It is already
a candidate on H3's 3–4-command list. Register it and the kant arm inherits S1.8's single
implementation and the epilogue drops; leave it and every kant template carries its own — two
implementations of Invariant R, which is what S1.8 exists to prevent.

### ✅ THE RUNG-NUMBER DIVERGENCE IS NOT ONE — BOTH CITATIONS WERE RIGHT
`docs/gapBCharter.md`'s own title reads *"Gap B Charter — rule-as-data (§4.1, **rung 5**)"*. So
**rung 5 is the genParse ladder's number for the workstream** and **rung 1/2 are the FAMILY rungs
inside the charter.** Family A is *charter rung 2, part of genParse rung 5.* ⚠ **Two axes, not two
numberings of one axis — GM-31's 47-vs-78 warning in a new hat.**
✅ **Sequencing settled and no longer conditional: rung 2 = Family A in the plan layer** (which is
what makes `Attributes` plannable), **then** the hand-written install. Picking an
already-plannable rule for First Light instead would forfeit the template work and the `parseR`
alignment for a shortcut that certifies less.

### ⚠ THE ALTERNATION PRECONDITION IS NOW INSIDE THE TEMPLATE, NOT A FOOTNOTE
*Every alternative must be a rule reference.* Written into the code block itself, because the first
literal-bearing alternation to reach for the template would otherwise inherit a justification that
does not cover it. ⚠ **It survives the `AND`/`OR` collapse unchanged** — non-restoring is a property
of the **operand**, not the operator.

## FLEET AT SEAL
```
sh genLadder/decodePop.sh      22 checks, exit 0     NEW -- the decoder POP (34 terms)
sh genLadder/gapB.sh           22 checks, exit 0     NEW -- the Phase R rung POP
sh jitLadder/ladder.sh        173 checks, exit 0     (was 170; +3, three rows graduated)
sh genLadder/pop.sh            33 green / 1 parked (exit 1, the same 3 owned reds)
sh genLadder/mixed.sh           7 checks, exit 0   (parse-arm pin holds)
sh genLadder/completePop.sh   123 swept · 3 abandoned · 2 missing sentinels · 212 green · exit 1
sh genLadder/tree.sh · printPop · containerPop · recordPop · formsPop      exit 0
<binary> incant/oneTest · jsonTest · kant8T · phaseA · emitAll             exit 0
```
**Metric: 0/47 installed** (T-3 — NOT 0/46; ruled, `Any` was never in the 47). Ruling-4 numbers:
**94 total plan-layer refusals · 16 fully plannable of 78** — moved by rung 1, and now **printed as
scalars** rather than grepped. `incant/phaseA` is the ruling-4 instrument, **Amendment A discharged by
measurement** (exists · reaches the Gap B branch, 21 hits on `:518` · completes 78 PLAN / 78 DONE).

## ✅ STEP 1 ARTIFACT — the parse-method TEMPLATE FAMILY + `Attributes` v0. `docs/attributesTemplate.md`
All six holes filled by measurement. **Nothing installed.** Two answers move the draft and one
wants Tony before First Light.
- ⚠ **H4 (the gate) — YES for rules, NO for `lit`.** Native rule failure restores to `hereAt`
  (`GroupItem.twk:1267`), generated to `from` (`leaveRule`, unconditional). **But `lit` commits its
  skip pass before matching and returns false with the mark ADVANCED** (`RuleStuff.twk:525`), which
  `leaveAlt`'s S4.2 comment already records. So the draft's ALTERNATION *"no save, no restore
  anywhere"* is **false for any chain with a literal alternative** — Tony's fork, one level lower
  than the seat-note expected: at a primitive, not at the seam. ⚠ **GRADE: READ, NOT RUN** — the
  run is owed before the contract is signed, and both routes are named in the artifact.
- ⚠ **H3 IS THE REAL BLOCKER, AND IT IS SMALL: the templates are kant, and every primitive they
  need is unreachable from incant.** `atRuleMark` (the real spelling — Tony's working name is the
  actual name), `checkSkip`, `parseR`, `lit`, `leaveRule` — **none registered as a command**;
  search space named in the artifact. ⚠ **`setMark` is a FALSE FRIEND** — it is the *Buffer* mark
  and would half-work. **This is Tony's own `incant++` note arriving as a measurement**, and the
  gap is a bounded 3–4 command registrations, not a design question.
- ✅ **H2 — Clay's citation was RIGHT: `Attributes=TraiT+;`.** One-or-more, pure reference, no
  literals, so v0 is the bare ITERATE with no SEQUENCE wrapper. **A structural claim holding, which
  is what the asymmetry predicts** — recorded as a hit, since the ledger wants both columns.
- ⚠ **H1 INVERTS: `Attributes` is NOT among the 16 plannable — it REFUSES** (`rule-level data
  isGROUP`). ⚠ **And its refusal names RUNG 5 while the family table calls Family A the RUNG 2
  candidate** — two rung numberings in circulation for the same work, cheap now, T-0 later.
- ⚠ **§2's mark save/restore is a SECOND WRITER — recommend dropping it.** `leaveRule` owns
  Invariant R by explicit design (S1.8, one implementation every rule), and PC-4 records that a
  second writer there produced GM-17's divergence. This dissolves H5 as well.
- **SEQUENCE is already a green rung** — JXT *is* "the genKantParse body", degrade 0 **as of today**
  (E2 took it from 2). **ITERATE has no rung**: built from certified parts, composition unrun — its
  rung is step 2's. Loop is **`while`** (J3); ⚠ **never `for`** (the iterator divergence is a named
  JIT-0.1 exclusion, `jitJUi`, 0 leaves vs 2).
- ⚠ **`Attributes` lands on a PRE-RECORDED OPEN:** `parseR`'s header fences `parseMethod`-is-
  per-node against *"rung 4, the first cross-method call"*, and `TraiT+` is nothing but a
  rule-reference term. Right subject, but choose it knowingly.

## OPEN, AND WHOSE
**PARKED TONIGHT, DELIBERATELY, EACH WITH ITS REASON — the clean-kitchen list:**
`AND`/`OR` rung (behaviour change to shipping text — top of a session, not the bottom) ·
the **contract RUN** that converts H4 from READ to signable (needs an instrumented build or a
behavioural probe; a misfiled measurement here becomes doctrine) · **H3's 3–4 command
registrations** · **rung 2 = Family A** · then the install arc. ⚠ **The KANT-8 bracket fix is still
FIRST IN LINE and its junction is intact — nothing today installed anything.**

**Tony's:** ⚠ **the parse contract's formal nod** — ⚠ **hold it until H4 has its RUN**; a signature
converts a read into doctrine, and today is the day that lesson cost the most. And with it the
*"exactly as at entry"* wording,
which is stronger than the native arm provides (native restores **post**-skip, generated **pre**-skip) ·
⚠ **the ALTERNATION fork** (non-destructive `lit`, or keep the `from` save) ·
⚠ **`parked` — the decoder's ONE HELD SLOT, and Clay asked for the hold himself**
(§8 of `docs/decoder.md`): the dispatch's *"a scheduling state, not a verdict"* against SEQ 44
PINCH 6's *"parked means nobody has ruled; pinned means we ruled it wrong and are watching."*
**Incompatible, and PINCH 6 was written first.** If PINCH 6 wins, `parkdiff` / `parked-WIP` /
`owned reds` sort into **three terms, not two**, and **a registration schema inherits whichever is
pinned** — which is why the pin comes before the schema. ⚠ **Entangled with it: H6's wording**, whose
dictated sentence is narrower than `CLAUDE.md`'s headline and is silent on exactly the parked case ·
`FloaT` and `counter`, the two OPEN taxonomy rows · child-drop decision, no clock ·
`completePop` owned-red vocabulary (2 standing sentinel misses, `jitXand`/`jitXand2`) ·
migration ruling (waits on child-drop) · vi grammar offline.
**Parallel track, unchanged:** scale fixture · the not-gated sweep (22 operators left, `jitXor`
shape, two discriminating fires each) — **`AND`/`OR` (JXD-1/JXD-2) remain the two measured members.**
**`docs/vigram.md`** — the 2026-08-09 addition is imported and **both files are now COMMITTED**
(ruled: an untracked founding document is Amendment A's citation-rot risk in a new hat). §10 carries
the V0 pass. **O1–O4 open by ruling, gating V1, Tony's at the V1 gate — not before.**
## ✅ THE DECODER IS BUILT AND GREEN — 34 terms, `genLadder/decodePop.sh` 22 checks exit 0
`incant/decoder` (corpus + verb) · `incant/decode` (edit the decode line, run) · `incant/decodeT`
(fixture) · `genLadder/decodePop.sh` (instrument) · one line in `incant/setup`. **Discipline 2 is
now `WT-14`**, registered in `docs/walkieTalkie.md` and **enforced in code, not documented** — an
undefined term prints a fail-loud line naming itself, and the POP asserts that line with the
arm-removed run as its control. Full record: `docs/decoder.md`.
- ⚠ **THREE OF THE DISPATCH'S OWN ENTRIES CAME BACK CORRECTED**, caught only because Clay marked
  them ⚠ PULL — *"my draft is a citation, not a measurement"* — and the seal was re-read instead of
  transcribed. **H4**'s sentence was rung 1's *discharge* of H4, not H4. **H9**'s was the corollary,
  not the primary. **`degradeAssertsOccurrence` was a materially different fact** — the seal is
  *fallback occurred, never fallback was sound*; the draft was about jit occurrence, and serving it
  would have retired E2's per-construct warning **by definition**. The two-class discipline is the
  entire reason these were caught, on the artifact's first run.
- ⚠ **THE LOAD-BEARING CHECK'S FIRST DRAFT WAS VACUOUS AND WENT GREEN** — `definition == taG`,
  copied from `jiquery` section 0; deleting a definition **left it green**. Measured: an absent
  attribute reads **0** (falsy, so a count catches it); a `definition=(#)` one reads the string
  `"definition"` and **compares equal to nothing**, so only a grep on the printed line sees it.
  **That asymmetry is why there is a shell POP beside the fixture at all.**
- ⚠ **AND IT TRAVELS: `jiquery`'s own section-0 content check CANNOT FIRE.** It compares the value
  against the **claim's** tag while a dataless value echoes the **attribute's** name. The check
  written because *"the corpus silently lost its content and nothing noticed for a month"* is,
  measured on the identical shape, unable to detect it. **Reported, not fixed — jigcorpus's
  instrument, not the decoder's.**
- **Three candidate incant traps, symptoms bisected and none diagnosed:** `group[argument.text]`
  exits **139 with zero output** where `[argument.taG]` works · `if !x.attribute;` exits **139 with
  zero output** · `print "":;` prints the string `quoteBody` (use `print :;`). Also mechanical and
  worth knowing: **`include()` searches no path** — every includable file is registered by hand in
  `incant/setup`'s `fILEs` registry, and an unregistered one fails **at exit 0**.
⚠ **Its brief had existed in NO FILE until Tony asked** — relayed in chat, acknowledged in chat,
never written down. **The decoder exists because vocabulary lives outside the system, and its own
brief was living outside the system.**

# ═══════════════════════════════════════════════════════════════════════════

# ⚠⚠ SEALED 2026-08-08 EVENING — the 08-08 evening section follows. Older vintage from here down.
# ⚠ ITS METRIC LINE AND ITS "NEXT ACTION" (T-1) ARE BOTH DISCHARGED ABOVE.

# ═══════════════════════════════════════════════════════════════════════════
# 2026-08-08 EVENING — SHUTDOWN SEAL. CHARTER IN HISTORY, FOUR RULINGS SETTLED,
#                      E2 PROMOTED INTO THE CAMPAIGN, PHASE T PARKED CLEAN
# ═══════════════════════════════════════════════════════════════════════════

## ⚠ NEXT ACTION, SO TOMORROW NEEDS NO ARCHAEOLOGY
**T-1's mechanism check FIRST** — *which kind does `planRule` actually read when it refuses:
the RESOLVED/transitive kind, or the DECLARED one?* **Then** the family table, built on
**declared shape**, one grammar line cited per rule. **Then E2.** Working notes and the two
findings that shape it: `docs/gapBPhaseT.md`. Charter: `docs/gapBCharter.md` (+2 amendments).

## THE CHARTER IS IN HISTORY, AND ITS DEFECTS ARE AMENDMENTS ON TOP
`f8cf727` commits it **unedited**; `a9fa6ce` amends it. Deliberate order — the charter's own
defect history stays readable in the log rather than being quietly tidied.
- **AMENDMENT A — the ruling-4 instrument slot is OPEN, not assumed.** §5 named
  `incant/censusScratch`, which **does not exist** (renamed `incant/popScratch`, wakeup 08-05).
  ⚠ **The cause is the keeper: the name was cited from a sealed wakeup instead of checked** —
  doubt-the-instrument failing *inside a governing document*, the most expensive place for it.
  Now a **measurement obligation**: the instrument is whichever fixture demonstrably produces
  **both** ruling-4 numbers. `phaseA` is the candidate; `popScratch` is on record as *"a sample,
  never a census"*. **No rung may cite an unverified oracle.**
- **AMENDMENT B — THE TABLE'S COUNT IS THE COUNT.** "21" is now "21 censused, provisional".
  Evictions land as **rows with reasons, never silent renumbering** (H9's overcount running
  backwards). Three already identified: `BrancheS` **container, already paid (CT)** ·
  `NewGroup` **DEFERRED**, carries `TraiT@` under IT-3's expiry · `Any` **ESCALATED as a
  POPULATION QUESTION** — censused but absent from `incant/grammar`, which is a **census-instrument**
  question and gets asked of the instrument before the taxonomy.

## ✅ FOUR RULINGS SETTLED (Tony, 2026-08-08 evening)
**R1 — E2 IS A CAMPAIGN PREREQUISITE, IN THE CAMPAIGN, NOT THE PARALLEL TRACK.** It gates v1 for
**CORRECTNESS**, not purity: `incant/jitXnest` shows a **two-deep template accepting input it must
reject, at exit 0**. ⚠ **"Template certified" is bounded to DEPTH 1, tail-position leaves only.**
Sequence: **family table first** (gating, open — finish the started thing), **E2 immediately
after**, before any Phase R rung concludes.
**R2 / R3 —** amendments A and B as written above.
**R4 — Phase T order confirmed:** T-1's mechanism check **first**, then the table on **declared
shape**. The census column is **resolved** kind (`Looper → ANYtoken → NamE → set`); grouping on it
files **references under scalars** — §2.5's build-wrongly failure one layer up, **caught before a
row was written.** ⚠ **The refusal to ship a partial table was correct and is the standing standard.**

## PINS — E2 IS OWNED WHILE IT WAITS. LADDER 162 → 170.
New inverted rows **JE2** and **JXN** (green while the defect is present, red on repair, H6):
- **JE2** — mid-body return in an inlined callee: jitted **222/999**, interpreted **111/0**.
- **JXN** — the nested template **accepts a failing term** (out 1, tail 999); oracle 0.
Standing: **JXT** degrade pinned at 2 · **JXD-1** (`AND` → 139) · **JXD-2** (`OR` → silently wrong)
· `genLadder/mixed.sh`'s child-drop pin.

## DOCTRINE ADDED (CLAUDE.md)
- ⚠ **A DEGRADE LINE ASSERTS A FALLBACK *OCCURRED*, NEVER THAT IT WAS *SOUND*.** Soundness is
  **per-construct**: E2 at **tail** position is sound, at **mid-body** it changes the answer — **same
  degrade count 2.** So degrade-zero cannot tell a handled fallback from an unhandled one; JE2/JXN
  assert **values**, never the counter.
- ⚠ **MATCH THE TASK'S FAILURE LOUDNESS TO THE SEAT'S MECHANICAL STATE.** A misfiling in a precision
  classification **does not fail loud** — it becomes a charter-level mistake that gets built on.
  Late-session mechanical state routes to self-checking work or to shutdown, **never to
  silent-failure work.**
- **BEAR-TRAP #27 (candidate)** — a fixture's **comment header is not inert**: exit 138, **zero
  bytes**, before the first statement; bisected to the header alone, body innocent. Headers get
  **prose, not pasted code**. ⚠ The `<-` rebind theory was **tested and falsified before** the
  bisect — the only reason a wrong cause is not written down.

## ⚠ THE EIGHT-SLIP INVENTORY — verbatim, because it is the citation behind the scheduling doctrine
Self-read at the pause: **the reasoning layer held; the mechanical layer degraded.** The findings
were solid and several decisive (E2 gating the campaign, the parse arm answering NO, a
pre-registered prediction falsified). Against that, **eight instrument slips in one session**:
1. `mixed.sh`'s PASS banner said the **opposite of its own verdict**
2. its census grep **matched prose** — 5 bindings for 4
3. an anchored `^diffcheck` regex **undercounted pop.sh 13→8**
4. `git add -A genLadder incant docs` **omitted `jitLadder/`** — a commit whose message
   **described work it did not contain**
5. `git add -A docs` **swept up `verification.md`**, held back one command earlier
6. a fixture header **crashed the parser**
7. a broken `printf` in the census loop
8. **`${PIPESTATUS[0]}` used — a bear-trap in this repo's own CLAUDE.md, read the same day**

Every one was caught, **mostly by accident or by a guard written earlier, not by care**. ⚠ **#8 is
the tell: knowing the rule did not prevent the error** — which is the argument for structure and
scheduling over more care, and is why the scheduling doctrine sits beside the
make-the-failure-unconstructable family.

## BOARD STATE
- **Campaign runway OPEN** — Phase T is actionable now (T-1, then the table).
- **Behind it:** step-5 remainder — the **E2 rung is now IN-CAMPAIGN per R1**; **scale fixture** and
  the **not-gated sweep** (22 operators left, `jitXor` shape, two discriminating fires each) stay
  parallel-track.
- **`docs/vigram.md` — HONESTLY FLAGGED: NEVER OPENED.** Still the interleave track, steps 1–3 per
  SEQ 46. Clod acknowledged the priority and then never read the file; nothing in it has been absorbed.

## OPEN, AND TONY'S
**child-drop decision** — charter it or bank it; **no clock, but not silent** · **migration ruling**
(waits on child-drop) · **completePop owned-red vocabulary** (2 standing sentinel misses, `jitXand`
/`jitXand2`, whose missing sentinel *is* the defect they record) · **vi grammar offline.**

## FLEET AT SEAL
```
sh jitLadder/ladder.sh        170 checks, exit 0
sh genLadder/pop.sh            33 green / 1 parked (exit 1, the same 3 owned reds)
sh genLadder/mixed.sh           7 checks, exit 0   (parse-arm pin holds)
sh genLadder/completePop.sh   123 swept · 3 abandoned · 2 missing sentinels · exit 1
sh genLadder/tree.sh · printPop · containerPop · recordPop · formsPop      exit 0
<binary> incant/oneTest · jsonTest · kant8T · phaseA · emitAll             exit 0
```
**Metric: 0/47 installed.**

# ═══════════════════════════════════════════════════════════════════════════

# ⚠⚠ SEALED 2026-08-08 (morning/afternoon vintage) — the earlier 08-08 section follows.

# ═══════════════════════════════════════════════════════════════════════════
# 2026-08-08 — planB OPENED (genKantParse), AND THE SKETCH'S SPELLING DIED ON
#              SEVEN FIXTURES WHILE ITS PREMISE SURVIVED
# ═══════════════════════════════════════════════════════════════════════════

## WHAT IS RUNNABLE
```
sh jitLadder/ladder.sh        150 checks, exit 0    (re-run today, green)
sh genLadder/pop.sh            33 green / 1 parked  (the SAME 3 owned reds)
sh genLadder/recordPop.sh      48 checks · formsPop.sh 14 · printPop 9 · containerPop 11 · tree 0
sh genLadder/completePop.sh    121 swept · 3 abandoned · 2 missing sentinels · 208 green · exit 1
sh jitLadder/ladder.sh         162 checks, exit 0     (150 + JXT + JXD pins)
sh genLadder/mixed.sh            7 checks, exit 0     NEW — the parse-arm decomposition, PINNED RED-SIDE
<binary> incant/oneTest · jsonTest · kant8T · phaseA · emitAll      exit 0
```
**Metric: 0/47 installed.** Nothing regressed today; today's work added fixtures only.

## ⚠ THE SEAL CORRECTIONS OWED FROM THE 08-07 VINTAGE, APPLIED
The section below this one says **0/78** in three places and it is **stale, not wrong-headed**:
- **THE DENOMINATOR IS 47** (IA-4). 78 counts **Grokking's registry population** (60 members + 18
  attributes); 47 counts **names in `incant/grammar` that can consume an install bind at their own
  definition site**. Different sources, different axes — 47 does not *correct* 78, it **replaces
  it as the campaign's denominator**, because a rule that cannot consume a bind cannot be
  installed however plannable it is. 102 sites probed: 67 LIVE, 35 dead, 0 VOID.
- **The oracle is amended to EVIDENCE-OF-EXECUTION** (IA-5). For a **deferred** rule neither axis
  of the union lens discriminates the arms — `BlocK` reads `fire=2 attach=0` identically with the
  install on and off, because `defer` skips its label at the yield guard long before
  `attachLabel`'s no-label guard. **The crash was the evidence the lens could not supply.**
- **The abandonment instrument is LIVE with three catches** (IA-6). `genLadder/completePop.sh`,
  structurally defined population. Three pre-existing live abandoners, all at
  exit 0, none session-caused: **`delimTest`, `grammarOnTheFly`, `hashProbe`**. Reported, not
  diagnosed. **The sweep is RED on arrival and that is the instrument working.**

⚠ **AND IT PROVED THE STRUCTURAL POPULATION WORKS BY CATCHING TODAY'S OWN FIXTURES — the numbers
moved and the movement is named, not absorbed.** `112 / 3 abandoned / 0 missing sentinels`
became **`121 / 3 / 2`**. The two new sentinel misses are **`jitXand` and `jitXand2`, and their
missing sentinel IS the finding they were written to record**: `AND` under jit exits 139, so the
sentinel cannot print. Nothing regressed — the abandoner count is **unchanged at 3**, and the
sweep swept nine new fixtures with nobody maintaining a list, which is exactly what IA-6 bought.
**⚠ But two deliberate crashes are now STANDING REDS with no way to own them.** `pop.sh` has an
owned-red/parked vocabulary and `completePop.sh` has none, so these will be re-explained every
session until someone rules. **That is IA-6's own named follow-on** (*"hardening their choke
points is day-size but not this fire's day"*) arriving with a concrete demand case. **Tony's
call:** an owned-red list, or measurement fixtures kept out of the swept population — noting that
the second option weakens the structural-population property that makes the sweep worth having.
- **GATE discharged on K5/K6** · **bracket fix scheduled at the green-fleet junction.**

## ⚠⚠ THE FORK: planB / genKantParse — ASSESSED, NOT SCHEDULED
Full assessment with every measurement: **`docs/genKantParse.md`**. Three sentences of it:

**THE PREMISE IS SOUND AND THE SKETCH AS WRITTEN DOES NOT RUN, AND THOSE ARE SEPARATE FINDINGS.**
The proposal — generate the parse as **kant CodE** installed in the rule's `method` slot, with the
semantic action moved to `actionMethod` — collapses the whole PC divergence class for generated
rules, because there stops being two artifacts to keep in parity. **But the body it is written in,
`sukcess = t1() AND t2() AND t3()`, uses the two worst-behaved constructs the JIT currently has.**

| measured today | result |
|---|---|
| `AND`, plain field operands | ❌ **exit 139, and NO degrade line — it crashes before the counter sees it** |
| `OR`, plain field operands | ❌ **exit 0, degrade 0, WRONG ANSWER** (fire 2 wants 1, gets 0 — emit-time fold) |
| action→action call, acyclic | ✅ emitted, runs per fire |
| **action→action, MUTUALLY RECURSIVE** | ✅ **the cycle closes** — ticks 4→10, one compile, degrade 0 |
| two value-returning callees, sequential | ✅ green (degrade 2, the known E2 tail-return) |
| **the proposed replacement template** | ✅ **short-circuits for real — ticks 1→3** |

**THE REPLACEMENT NEEDS NO NEW JIT WORK — ONLY A DIFFERENT SPELLING**, built from constructs the
ladder already certifies (comparison, `if`, mid-block `return`, sequential calls):
```
    xtSuk = xtT1();   if xtSuk == 0;   return 0;
    xtSuk = xtT2();   if xtSuk == 0;   return 0;
    return 1;
```
⚠ **AND IT SHORT-CIRCUITS BY CONSTRUCTION, WHICH IS THE POINT AND NOT AN OPTIMISATION.** KANT-34
records `&&`/`||` as evaluating both arms **in the interpreter too**, and records the reason as
structural. **For a parser that is a correctness requirement, not a style choice** — a parse term
consumes input, so an eager right arm advances the mark past text the rule never matched. The AND
spelling cannot express parse semantics in **either** engine. The if-chain does not need to.
If short-circuit is ever wanted as an *operator*, it must become **control flow** with its own
`aCTion*` handler and emitter — the shape `if` and the loops already have — **not** a repair to
`opAND`.

## ⚠ THE FINDING THAT MOST CHANGES THE CAMPAIGN'S SHAPE — put in front of Tony first
**`t1()` DISPATCH IS UNIFORM.** `aCTionRunRulE` dispatches on `rule.isMethod` and never asks
whether the method was generated; under jit the callee is **inlined**, and `jitXmutual` shows a
**two-cycle closes**. A generated and a non-generated callee are **the same call at both layers**.
**So the mixed-shape world is safe — and IA-0's premise is what that undermines.** IA-0 ("the
migration unit is the ALTERNATION, all of one parent's options cross together") exists precisely
to prevent mixed shapes. If they are safe, **the migration unit can be the RULE**, and IA-1's gate
loses the reason it refuses every install. **IA-0/IA-1 would dissolve rather than get satisfied.**
⚠ Measured for **action** dispatch only. The **parse-arm** fork inside `parse()` is a separate
question these fixtures do not cover, and the claim must not be stretched over it.

## WHAT planB DOES NOT DO, STATED SO IT IS NOT OVERSOLD
**It does not move the metric.** The gate is **GAP B (rule-as-data)**, and both of its refusals
live in the **PLAN layer** — `planRule`'s *"rule-level data"* and `planTerm`'s *"inline group /
character data"* — which genKantParse **shares unchanged**. A second back end respells plans that
already succeed; it cannot make a refused rule plannable. **Close Gap B in the plan layer first**,
where it pays both back ends and where a red has exactly one cause.

## ⚠ genParse WAS ALREADY BUILT FOR A SECOND BACK END, and this is the cost answer
`genParse.rtn` is already two layers with a clean seam, **and says so in its own comments**:
`planRule` DECIDES (a GroupItem plan tree — `SEQ`/`ALT` over `CALL`/`LIT`/`LITTO`/`CONTAINER`/
`OPT`/`MANY`), `emitPlan` WRITES, *"nothing between them knows about C++."* So **genKantParse is a
second back end on a shared plan, ~200 lines of respelling — not a second campaign.** Adjudication
is then the H8 shape Tony asked for almost for free: same rule, same plan, two back ends, one
comparison fixture.
**And the fork the brief did not name:** emit **kant source text** through the ordinary
`define … code={ }` door (cheap, keeps `emitPlan`'s shape, keeps the artifact human-readable) vs
**synthesize the BlocK tree** (needs the tree-synthesis idioms, bypasses `aCTionDefinE`).
**Take the text route for v1.**

## THE COMMAND TALLY IS SHORT — but the library needs REGISTERING, not writing
~8 → **~11 for parity with today's frontier, ~13 to clear it**. Missing and load-bearing:
**`inGuard`** (every member option is `(inGuard(...) && parseR(into))`) and **`stashDefer`**
(`defer` is the parse→generate seam — where `gIF`/`gFOR`/`gPrinT`/`gXpress` come from).
`containerTo` is **already paid**. `upTo`/`upToOver`/`macroVal` are beyond the frontier in *both*
generators, so not owed for v1. ⚠ **But the seven support functions already exist as `extern "C"`
in `RuleStuff` — making them kant-callable is shims + registration, not implementation.**
**What is actually hiding is not a command:** Invariant **R′**'s two-part label-recycling
handshake (an obligation on the emitted loop, deliberately not inherited), and **§7.1's
min-zeroing defect**, which a kant action re-inherits the moment it reads `rs.min` at RUN time —
which is the worked example that earns Tony's **generation-era doctrine** its promotion.

## DOCTRINE / DEFECTS ADDED TODAY
- **TWO PRE-EXISTING JIT DEFECTS, LOGGED INDEPENDENTLY OF planB.** `AND` under jit **crashes with
  no degrade line**; `OR` under jit is **silently wrong at degrade 0**. Both are the ungated-
  operator class. ⚠ The general statement — *an ungated operator in a jitted body folds its
  emit-time value* — is **inferred from two members and NOT swept**; the not-gated list has **24**
  entries. **A sweep is the obvious next instrument** and is cheap (the `jitXor` shape, one
  fixture per operator, two discriminating fires).
- **`if !field;` IS INERT ON A FIELD CARRYING A VALUE** — measured interpreted-only, `0` and `1`
  both failing to fire, **both engines agreeing**, so it is a language question and not a JIT one.
  KANT-35's `if !a;` idiom is measured only against **absent attributes**. **Use `== 0`.** Tony's.
- ⚠ **THE ANTI-VACUITY RULE PAID ITS BILL INSIDE TODAY'S OWN INVESTIGATION.** The first `jitXor`
  used `0 OR 1` and `1 OR 1` — both 1 — and **reported green**. It would have entered the
  assessment as *"OR is fine."* The re-run with a discriminating pair found the fold. **A fixture
  that cannot distinguish the answers distinguishes nothing** — including one written by someone
  who had just finished reading the rule.
- **E2 IS SURVIVABLE BY ACCIDENT, AND SHOULD BE KNOWN AS SUCH.** A `return` inside an inlined
  callee degrades (*"it would branch to the enclosing function's epilogue"*). Every fixture shows
  it. It is green today **only because a TAIL return needs no branch**, so falling through is
  accidentally equivalent. genKantParse's templates are tail-shaped naturally — fine, but that is
  an accident to be aware of, not a property to lean on.

## ⚠⚠ CAMPAIGN OPENED — genKantParse (SEQ 41, Tony, 2026-08-08). FIVE STEPS, TWO FENCES.
The assessment is **adopted**. Order: **1** Gap B in the plan layer · **2** the parse-arm dispatch
fixture then the migration-unit ruling · **3** genKantParse v1 · **4** the adjudicator, before any
rule crosses · **5** parallel jit-ladder work (E2 rung, scale fixture, not-gated sweep).
**FENCES, exactly two:** the **Gap B charter precedes Gap B edits** (director's), and the
**migration-unit ruling follows the parse-arm fixture**. Everything else is Clod's discretion.
**Victory condition, stated so it is not re-litigated:** *not* "the same parse, generated" — **a
compiled parser with the grammar folded in**. Generation is **partial evaluation of the parser
with respect to the grammar**; the JIT compiles the frozen form. Full text: `ipc/clod-to-clay.md`
SEQ 41.

## ⚠⚠ STEP 2 IS ANSWERED AND THE ANSWER IS **NO** — the fence earned its keep on first use
`genLadder/mixed.sh` (new, pinned, exit 0). **Parse-arm dispatch is NOT uniform.**
```
    variant   installed                '(a)'      '(i)'
    none      (interpretive)           ScafALT    ScafALT
    leaf      ScafA ScafI              NONE       NONE      <-- child DROPPED
    alt       ScafALT                  NONE       NONE      <-- child DROPPED
    out       ScafOUT                  ScafALT    ScafALT
    all       everything               ScafA      ScafI
```
**Both PURE configurations keep the child; a MIXED one drops it** — not retagged, not
mis-parented, **gone, at exit 0, with no diagnostic.** Strictly worse than the §2.4 retag
divergence, and **new**: `tree.divergence` records a tag changing, never a node vanishing.
⚠ **So IA-0 STANDS AS WRITTEN — the migration unit stays the ALTERNATION**, and the previous
section's hopeful reading of `t1()` uniformity is **corrected**: `jitXmutual`'s **action**-dispatch
uniformity is real and **does not extend to the parse arm**. Two forks, two answers.
**Mechanism is a LEAD, not a ruling** (usual odds): IA-2's silent return generalised — the
generated arm's `promote=0` meets a label-transparent parent whose label is null, and the promote
case that rescues it interpretively sits on the **other arm**.
⚠ **Built as a DECOMPOSITION, and that is why it found anything.** *"Does a mixed config parse"*
is nearly vacuous — something always comes out. Asking whether an install **perturbs only itself**
is what exposed the loss.

## ⚠ GAP B IS 21 RULES ACROSS SIX DATA KINDS, NOT 3 ACROSS TWO (`docs/gapB-staging.md`)
Staged under fence 1 — **measurement only, no plan-layer edit made.** Every prior statement names
`NumbeR`/`ANYtoken`/`SemI` and `isGROUP`/`isSTRING`; those are **the specimens that were looked at,
not the population.** Measured: `isGROUP` 9 · **`isSET` 6** · `isSTRING` 3 · `isCOUNT` 1 ·
`isCHAR` 1 · `isANY` 1 = **21 rules, 45% of the 47 denominator.** `isSET` is **twice** `isSTRING`
and appears in no prior statement — **RULE H9 again.**
- ⚠ **§2.5 IS A PARTIAL MAP, and it is the charter's first problem.** Accumulate/iterate covers
  **8 of 21**. **Inline group (9) is explicitly NOT the iterate case** — `planTerm` classifies a
  reference as `CALL` *before* the data test and names the leftover a *"named future kind"* that
  **must not quietly become one**. `isSTRING`/`isCOUNT` (4) are in **neither** family. **Three
  constructs wearing one refusal message**; a charter sized on two shapes will meet 21 rules.
  Suggested rung order: **accumulate (8, has a spec and `testMacro` as precedent) → scalar (4) →
  inline group (9, the only genuinely new construct).**
- ⚠ **THE CASCADE IS A FRONTIER** (H9's corollary): closing rule-as-data **reveals** the next
  refusal in `Iterate`/`ANYorNum`/`UnaryXP`/`StatemenT`/`Xpress` rather than unblocking them.
  **And `ANYtoken` and `SemI` are each blocked TWICE — rule-level AND term-level — so rule-level
  work alone closes NEITHER cascade head. Both axes or neither.**
- ⚠ **PLANNABILITY AND INSTALLABILITY ARE NOW TWO SEPARATE GATES.** Gap B buys the first. After
  step 2 it does **not** buy the second: a plannable rule still cannot cross alone while partial
  installs lose nodes. **The charter should say which one it is purchasing.**

## LADDER 150 → 162, and three rows that assert defects rather than fixes
**JXT** graduates `jitXtemplate` — ticks **1→3** (cumulative on purpose, so no folded constant
satisfies both rows), oracle agrees, and **degrade PINNED AT 2**, the honest value: E2's
tail-return accident is what makes it green, so **when E2's rung lands the count drops and JXT
goes red demanding graduation.** Using the generic `rung` helper would have forced a choice
between weakening the fleet's degrade-zero rule and not landing the rung; asserting the true value
costs neither. **JXD-1/JXD-2** pin `AND`'s 139 and `OR`'s **wrong value by name**, both inverted.
⚠ **`genLadder/mixed.sh` caught itself three times** and records all three: its anti-vacuity guard
fired on **its own census** (matched `treeScratch`'s header *comment*, 5 bindings for 4 — H9 on the
guard rather than the guarded) · its first verdict was an unreadable **diff-of-diffs** when the
finding was plain in the trees · and its **PASS banner said the opposite of its verdict**,
inherited from the draft written before the answer came back. **A harness whose summary line
contradicts its own rows is the worst instrument failure available**, because the banner is the
line most readers see.

## OPEN, AND WHOSE
**Director's, in priority order:** (1) **the Gap B charter** — fence 1, and now with numbers · (2) **Gap B's brief** — still the largest thing on the
board and still the metric · (3) planB scheduled or parked, on §4's five-point recommendation ·
(4) the ungated-operator sweep · (5) `if !field;` on valued fields.
**Reconciliation (H8):** `docs/verification.md` is **untracked** — stage-1 durable, asOf
2026-08-07, VI-1..VI-7, its own SURVEY ROW open and self-graded ASSUMED. Explainable as yesterday's
output not yet committed, **but it has had no verdict** — commit / revert / named-WIP is Tony's.
`IncantForms/WorkingOn/incant++` is Tony's own working document, dirty as normal, safe to ignore.
**Flagged, not chased:** `litTo` still unimplemented · the three IA-6 abandoners
(`delimTest`, `grammarOnTheFly`, `hashProbe`) · GM-19's single audit line.

# ═══════════════════════════════════════════════════════════════════════════

# ⚠⚠ SEALED 2026-08-07 — the 08-07 section follows. Older vintage from here down.
# ⚠ ITS METRIC LINE (0/78) IS SUPERSEDED BY 0/47 ABOVE.

# ═══════════════════════════════════════════════════════════════════════════
# 2026-08-07 — THE PARSE-CONTRACT CAMPAIGN OPENED, THE EXTRACTION LANDED,
#              AND THE FORMS ARC GREW A COMMAND, A HARNESS AND A RECIPE
# ═══════════════════════════════════════════════════════════════════════════

## WHAT IS RUNNABLE — six POPs now, two of them new
```
sh jitLadder/ladder.sh        150 checks, exit 0
sh genLadder/pop.sh            33 green / 1 parked   (the SAME 3 owned reds)
sh genLadder/recordPop.sh      48 checks, exit 0     NEW — ParsE/JiT records
sh genLadder/formsPop.sh       14 checks, exit 0     NEW — displayFill, BY PIXEL
sh genLadder/printPop.sh        9 · containerPop 11 · tree exit 0
<binary> incant/oneTest · jsonTest · kant8T · phaseA · emitAll      exit 0
```
**Metric: 0/78 installed.** Nothing regressed today; everything below either landed green or
reverted clean.

## ⚠ THE ONE PROTOCOL TO CARRY: **CONVERT, GATE, THEN INSTALL**
Earned three times today, in ascending cost. A change to the parse layer is proved against the
INTERPRETIVE arm **before** any rule is installed. When the discriminator in `aCTionInvokeArg` was
wrong it failed as **18 diagnostic lines and one moved baseline**; the same class of error two
passes earlier, un-gated, arrived as a **fleet-wide SIGSEGV**. The gate is where this campaign's
errors are supposed to die.

## THE PC CAMPAIGN — the three walls were one finding
`parse()`'s two arms never had a shared, enumerated contract. Every wall this week was a place they
quietly disagreed. PC is the ledger; each divergence gets a row, measured both arms, dated.
- **Row 1, fire-label — CLOSED (GX).** `fireLabelMethod` extracted; both arms fire the same rule
  action. Was: the generated arm's `goto generatedExit` jumped clean over it.
- **Row 2, attach — CLOSED (PC-1/PC-4).** `attachLabel` owns the attach for both arms;
  `leaveRule`'s attach removed. **The generated arm passes `promote=0` (attach-under always), the
  interpretive arm `promote=1` (legacy)** — the fork is a PARAMETER, not an inference, and carries
  IT-3's expiry in its own comment. `tree.sh` green for the first time since LA.
- **Row 3, empty-yield — CLOSED (PC-3).** `labelNO` is the return channel's third value:
  **NULL = failed · labelNO = succeeded, yields nothing · any node = succeeded, yields that.**
  ⚠ **Minted `isCOUNT` 0, and that is the whole trick.** The JIT's value channel is an **i32
  alloca** and cannot carry a GroupItem, so a non-numeric labelNO would have split the engines
  permanently. The meaning lives in **identity** (`lab == labelNO`); the numeric reading is
  courtesy, unchanged at 0, so both engines still agree and rung JV needed no re-pin.

## ⚠ IT — isTarget PROMOTION IS RETIRED AS A PARSE-LAYER MECHANISM (director)
**The parse builds one shape; opinions about shape belong to actions.** Promotion becomes opt-in in
one line: an action returns the child's label as its own yield, and attach-under plants it.
Interpretive promotion runs untouched as legacy and retires by attrition. **End state, nameable
now:** the `isTarget` predicate deletes, the promote case leaves `attachLabel`, three cases become
one — `pStuff.label +% lab`, skip NULL and labelNO, both arms, no fork.
**And the cost model beside it (IT-6, Tony's observation):** an action is ONE artifact serving BOTH
engines — the interpreter fires it through `fireLabelMethod`, the jitter calls it through the
fallback column — so **action-layer fixes are two-for-one and arm fixes pay per-arm.** Prefer the
action layer where a divergence permits the choice. Exception: an action containing an `if jitting`
fork is arm code in disguise and pays arm prices.

## WHERE THE METRIC IS STUCK, AND IT IS ONE NAMED GAP
**IA-0: the migration unit is the ALTERNATION** — all of one parent's options cross together, so the
mixed-shape world never exists. **IA-1's gate then refuses every install**, because no
reader-bearing alternation is fully plannable:
```
    InvokeArg  Braced OK · Parens OK · UnaryXP BLOCKED     <- nearest by far
    ANYorNum   0 of 2        StatemenT  2 of 5        DatA  blocked (+ NotA is not a rule)
```
- **GAP A — container terms: CLOSED TODAY (CT).** `containerTo` in the support library, `CONTAINER`
  a plannable kind classified BEFORE the reference test (a bin term is also a reference).
  Partition moved **REFUSE 99 → 97**.
- **GAP B — rule-as-data (§4.1, rung 5): OPEN, BANKED, AND NOW THE ONLY THING IN THE WAY.**
  `NumbeR`/`ANYtoken`/`SemI` refuse on rule-level `isGROUP`/`isSTRING`, cascading into `Iterate`,
  `Xpress`, `ANYorNum`, `StatemenT` — and into `UnaryXP`'s second term, which is why Gap A alone did
  not unblock `InvokeArg`.

⚠ **AND THE INSTRUMENT LESSON THAT CORRECTS ITS OWN SEQUENCING CLAIM: A REFUSAL CENSUS REPORTS THE
FIRST BLOCKER, NOT THE BLOCKER SET.** The classification walk stops at the first term it cannot
classify, so a refusal census is a census of **frontiers**. Closing a gap does not unblock the rules
it appeared in — it reveals their next refusal. **Total refusals falling is real progress and is not
the same measurement as any rule becoming plannable.** CLAUDE.md, H9 corollary.

## WHAT ELSE LANDED — capability, not campaign
- **DRAWING EXISTS, INTERPRETED AND JITTED.** `displayFill` fills a frame's rect through a style
  slot into a `CGBitmapContext`. Interpreted `r0 g0 b0 a0 → r255 g0 b0 a255`; **jitted fire 2 tracks
  a style swapped AFTER emission** (`r0 g128 b128 a255`), degrade 0, one compile — so it ran from
  compiled code. **FR §4's prediction held: the route is the fallback column, not IR emission** —
  a drawing method must be CALLABLE, not EMITTABLE. Five-seam recipe with file:line in
  `docs/formsRecon.md` §8, plus §8.6's **handover fences**.
  ⚠ Named `displayFill`, not `fill` — bear-trap #17, `fill()` is in the shared `OCframe` alias table.
- **`ParsE` and `JiT` records.** `genParse` hangs the generated source on the rule; `jitRunAction`
  hangs the post-mem2reg IR on the action. **One writer per fact**, both `noPrint`, both gated
  (`INCANT_PARSE_RECORD` / `INCANT_JIT_RECORD`, and `recordParse()` for the in-fixture door).
  **`showParse('Rule')`** prints the record — ⚠ **a command and not a kant action, because naming a
  rule in expression position INVOKES it.** `incant/showGen` is the no-preparation looksee: run it,
  edit one line, read any rule's generated method.
- **`aCTionIF` no longer SIGSEGVs on a missing statement.** `if 1;` used to exit 139 with zero
  output — **that was bear-trap #4's crash all along**, and the trap only ever described the parse
  bleed above it. Refuses loudly now, naming the three known causes.

## DOCTRINE ADDED TODAY
- **BEAR-TRAP #26 — a field with no data returns its own TAG from `.text`.** Six payments in the
  ledger, in both directions; one of them is a case where the trap made something *work*.
- **RULE H9 — a census matches the IDIOM FAMILY, not the surface form**, plus the frontier corollary
  above. Written after a census miscounted its own subject twice, in both directions.
- **A minion inherits FENCES, not just crossings** (`docs/formsRecon.md` §8.6). The recipe says how;
  the fences say when you have left it. Every finding worth having today was a fence product.

## OPEN, AND WHOSE
**Director's:** Gap B's brief (largest thing on the board — its blast radius wants its own charter) ·
the IA-0 refinement for non-rule alternation options (`NotA`) · `aCTionTokenXP`'s conversion to the
attached shape, which is specified and unblocked but pointless until an alternation can cross.
**Flagged, not chased:** `litTo` still has no implementation in the support library — the labelled
LITERAL road is a stub while the labelled CONTAINER road is now paved · guiDesign §10.0 vs §10.2
disagree about whether measurement belongs on Display (flagged at the insert, reconcilable) ·
GM-19's single audit line (`AUDIT TERM Parens [3]`) stays banked, unpinned, uncaused.

# ═══════════════════════════════════════════════════════════════════════════

# ⚠⚠ SEALED 2026-08-05 — the 08-05 section follows. Older vintage from here down.

# ═══════════════════════════════════════════════════════════════════════════
# 2026-08-05 — KANT-8 CLOSED, `return` EMITTED, AND THE GRAMMAR CAMPAIGN OPENED
#              ON MEASURED GROUND
# ═══════════════════════════════════════════════════════════════════════════

## ✅ RULED (Tony) — **KANT-8 IS CLOSED BY DISPOSITION**
- **jitted side correct** (JRt F3, ledger row one) · **characterisation complete** (K1–K6d, deterministic)
- **interpreter repair PARKED pending the frame model**, and **strengthened by K6**: patching
  `saveLocalFields` would not touch the mutual-recursion gap; **only per-activation state kills both**
- **carrier discipline NARROWED by measurement** — valid for **direct** self-recursion (K2),
  **invalid for mutual** (K6c)
- **frame-model gate SATISFIED**, opening fixture named: **K6a's shape, jitted**

## ✅ ITEM 1 — the inlined self-call died at its cause (option **(b)**, build-on-discovery)
`jitEmitSelfCall` said `CreateCall(gJitCurrentFn)` unconditionally; a self-call inside an **inlined**
body got the **enclosing** function and replayed the driver's preamble every recursion. **The map is
the predicate**, populated by the inline-stack test at discovery. S1 extraction byte-identical · S2
names from action identity (`jit_<tag>`) · S3 restart bounded and checked · S4 entry by name · S5 rung
**JS**. H7: the pre-S3 binary exits **139 after 173,400 replays**. **Rule H5 reached the JIT ladder** —
it had never had a wall-clock cap.

## ✅ ITEM 2 — `return` IS EMITTED. **Ladder 129 → 150.**
Rung **JRt**: returned scalar 21/27 · **factorial(5)=120 through real recursion** · KANT-8's shape
jitted **42/45 with the interpreted tag asserted as an intended divergence** · mid-block return
111/222 with tail 0/999. **E3 was not real — a bare `return;` is correct by construction.** A fifth
edge the brief did not name: **a bare field read as the returned expression emitted nothing.**
**Bear-trap #25** records both oracle traps (`isCoded` routing; post-jit interpreted calls are not
clean oracles for *returned* values).

## THE GRAMMAR CAMPAIGN — opened, and at its real question
- **Population 78**, not 60 — Grokking's **60 rule members + 18 rule attributes**. ⚠ A one-axis walk
  reports 60 **and looks right**; `GrouP`/`NamE` were the tell.
- **Partition 12 PLAN / 66 REFUSE / 0 UNKNOWN**, guard-controlled, with a **role axis**
  (6 declaration-flag, 72 parsing). **`docs/phaseA-partition.txt` is corpus.**
- **`popScratch`** (was `censusScratch`) — a **sample**, never a census; `debug` is a **deliberate
  negative control**.
- **Gap #6** (flag-setting as a plannable term kind, any position) chartered to the **main line**.
- **Corpus stood up** — `docs/grammarCorpus.md`, **GM-1…GM-16**, stage-1 durability in force:
  every claim written for a reader with **no session context**.
- **Install vocabulary registered in `incant/setup`** (`parseMethod`, `parseTerms`) with the
  **consumed-check standing** in the audit family; H7 control is today's Braced SIGSEGV.
- **Rule one `Braced`: installs clean, verifies RED, parked** with a 253-line specimen.

## ⚠⚠ THE DAY'S LAST FINDING — **THE GENERATED ARM DOES NOT FIRE THE RULE ACTION**
The FU-2′ localizer worked on first use **and falsified the lead it was built to test**: `parseR`
attaches `ExpressioN` under the label, correctly named. **The fork point is elsewhere and now has
file:line** — `parse()`'s generated arm ends `goto generatedExit` (`GroupItem.twk:1050-1054`), and
`generatedExit` (`:1109-1113`) skips **`:1073-1079`, *"Success. Fire label method if there is one."***

**So Braced's red is an ACTION-LAYER divergence, not a parse divergence — the exact thing GM-6 rules
must not exist.** GM-6's isolation property is **true of the design and false of the code today**,
which the very first red exposed. **The ruling stands; it is now a work item with a named site rather
than an assumed invariant — and that is why it was worth writing down before it was needed.**
**No fix taken:** `Parens` runs first; two specimens make the pattern systemic and the fix lands
**once at the right level**.

## WHAT IS RUNNABLE
```
sh jitLadder/ladder.sh        150 checks, exit 0   … JC JS JRt + J-R
sh genLadder/pop.sh            33 green / 1 parked  (the SAME 3 owned reds)
sh genLadder/printPop.sh        9 · containerPop 11 · tree · harnessCensus (6 harnesses, 112 fixtures)
<binary> incant/oneTest        exit 0, 11 then 26 x4
<binary> incant/jsonTest · incant/kant8T · incant/phaseA · incant/emitAll      exit 0
```
**Metric: 0/78 installed** — honest, and blocked by **rule behaviour**, not by the door.

## QUEUE
**Next fire: `Parens`** (designed discriminator — same three-term shape, different action), preceded
by **FU-1** (answered: `parseTerms` is a **guard only**, define-time, GM-12a) and **FU-2′** (built:
`parseTrace` extended to `parseR`/`lit`, gated, **fleet byte-identical with the gate closed**).
**Gap #6 brief on Clay's shelf.** **Frame arc gated open**, opening fixture named (K6a's shape, jitted).
**Still open:** ipc SEQ 38 consequence 3 (the `locate` never-assertion) · the print-length defect ·
`pop.sh`'s three owned reds.

**Housekeeping:** `IncantForms/WorkingOn/incant++` is Tony's own working document, safe to ignore.

# ═══════════════════════════════════════════════════════════════════════════

# ⚠⚠ UPDATED 2026-08-03 — the 08-03 section follows. Older vintage from here down.

# ═══════════════════════════════════════════════════════════════════════════
# 2026-08-03 — THE JIT'S LAST KNOWN CRASH DIED AT ITS CAUSE, THE SWEEP LANDED,
#              AND FOUR CONFIDENT CLAIMS DIED ON MEASUREMENTS
# ═══════════════════════════════════════════════════════════════════════════

## ✅ CLAIM JIT-0.1 — DECLARED, and written as a claim rather than a banner

**The JIT compiles the certified instruction families with interpreter parity, certified by
`jitLadder/ladder.sh` (83 checks, exit 0), asOf this reseal.** Families: assign · arithmetic ·
compare · **unary (`++ --`, new today)** · if/else · while · do · multi-statement operand reuse ·
an emitted call · the fallback column · **recursion on real frames**. Every rung compiles ONCE and
fires TWICE with the input changed after emission, so the answers are proven to come from compiled
code; every rung asserts **degrade count 0** and records the interpreted oracle beside its value.

⚠ **EXCLUDED, AND NAMED ON THE FACE OF THE CLAIM — this list IS v0.2's contents:**
- **Iterator semantics divergence.** A jitted action containing an iterator walk visits **0** leaves
  where the interpreter visits **2**. Pinned in `incant/jitJUi`; **measured pre-existing** (both the
  old and new seed gates give 0/2), and it waits on Tony's `iterT3`/trunk-arity ruling. **It is an
  interpreter question wearing a JIT fixture.**
- **IR persistence** — designed, unbuilt, next arc.
- **Inlining** — parked question, blocks nothing.

**The honest form of the parity statement, and it is stronger than a clean banner:** we do **not**
claim the engines agree everywhere. We claim **they agree everywhere certified, and the one known
disagreement is pinned and owned.**

## THE FIX — the unary crash died at its cause, not under a bandage
`jitInc`/`jitDec`/`jitNeg` had exited 139 inside `jitEmitUnary` since the 06-30 unified-emit pivot.
`runOP`'s seed gate read `if jitting && op.isOperator`, but unary operators are registered
`unary ruleMethod=` — **isUnary and isMethod, NOT isOperator** — so dispatch took the `isMethod` arm
and **no operand was ever seeded**. `jitEmitUnary` derefs `target->jitData` unconditionally, so the
miss was a SIGSEGV rather than a wrong answer.

```
    if jitting && (op.isOperator || op.isUnary)
```
**`isUnary` is the precise gate** — widening to `isMethod` would seed an operand for every rule
method in the language. **No layout change** (`isUnary` was already in `.twk`, `.h` and
`groups.ext`). Now 14 / 12 / -13, degrade 0, pinned by **ladder rung JU** (+7 checks, 76 → 83).

**What made it VERIFIED rather than inferred** — the corpus had graded the cause `inferred` for four
days and wrote its own graduation criterion. A **debugger probe** closed it:
`gJitSeeded.size() == 0` at the crash, with `gJitBuilder`/`gJitCurrentFn`/`gJitResultSlot` **all
non-null**. That last line **refuted the rival hypothesis by measurement** — "the emit context is not
set up on the newly-live `jitRunAction` path" predicts a null builder — so the shared-prologue design
question it would have raised never arose.

## THE SWEEP — and the disease was nastier than the one we thought we had
`oneTest`: 5 × `generateCode failed` → **0**; `maximus = 11` then **26 ×4**.

⚠ **`generatE` WAS NEVER THE DARK NAME.** C++ reaches it via `generator["generatE"]`, a **parent
index**. The names that went dark were **`gXpress` and `emitBC`, called by bare name from INSIDE
SIBLING MEMBER BODIES** — so the dispatched action ran and **its innards quietly did nothing**,
at exit 0. Repaired by hoisting the sibling once per body through the table that owns it (31 sites).

## ⚠ THE REGISTER LAW, STATED AS MADE
**`register` as a `noPrint` definition attribute publishes an otherwise-dark member into a registry**
— `currentRegistry` by default, `registries[name]` when the attribute carries data. Dormant prior
art, POP'd before being trusted (`incant/regProbe`, three legs): the registered entry is
bare-findable, **the unregistered sibling stays dark**, and both stay reachable through their parent.
**First production use today: `emitBC`**, with a negative control confirming `gXpress` stayed dark.

**And the rule it operates on, measured four ways:** a member is on its **parent's** list and **not**
on the registry's (`Generating` 49 entries with `generator` among them and no `gXpress`; `generator`
10 with `gXpress` among them). **`incant/vantage2x2`: two names × two vantages, ALL FOUR CELLS
DARK** — not the vantage, not the entry. **The members gate IS the mechanism**, and it is complete.

## ⚠⚠ FOUR CONFIDENT CLAIMS DIED ON MEASUREMENTS TODAY — the tally, because the pattern is the point
1. **`generatE` is the dark name** (wakeup 08-02 + briefs, carried as settled fact) — died on one
   grep. **A parent index was working the whole time.**
2. **"The gate has drifted, tools down"** — my own alarm, from leg B of the register POP. Died on
   re-measuring the real specimen. **Interrogating the failing measurement before escalating is what
   produced everything below it.**
3. **"Registry membership is not the discriminator"** — my overturn claim. **Wrong**, and so was the
   self-correction I offered after it. Both were inference; walking the lists settled it.
4. **Vantage as the discriminator** (Clay's lead suspect, offered at the usual odds) — died on the
   2×2. All four cells dark.

⚠ **AND THE INSTRUMENT THAT CAUSED #2 AND #3, worth more than any of them:
NEVER TEST EXISTENCE WITH `if x.taG;`.** A GroupField accessor returns a **fresh temporary field of
property text**, so it is **truthy whether or not the lookup found anything**. Use `if x;`. This is
in project memory already and was used wrongly anyway; it survived two fixture rewrites and produced
a false tools-down alarm that would have sent Tony hunting corrupted lists — **his least favourite
quarry, and there was nothing there.**

**The standing asymmetry held again:** structural claims survived, causal claims died 4-for-4.

## ERRATA AGAINST THIS FILE'S OWN EARLIER SECTIONS
- **"`groups.ext` changes have NO COMMIT TRAIL"** (said three times below) — **false.** It is
  **tracked in the support repo** (`~/data/support`, its own git, 5 commits naming the file).
  Bear-trap #11's practical warning stands — *this* repo's history will not save you — but the
  **distrust-the-audits corollary was overdrawn.**
- **The `generatE` diagnosis** in the 08-02 section — superseded by the sweep above.

## ⚠ A LATENT FINDING NOBODY WAS LOOKING FOR — `oneTest` RUNS ONE SECTION OF SIX
`incant/oneTest` has **six `stop()` calls** and terminates at the **first**, on line 31. **32 lines
below it never execute** — including `testUnitTests()` and the GUI-utilities section. Verified by
marker: `hello world`, `dumpBC for`, `testGXLeaf`, `Unit Tests`, `printDefinition` all appear
**zero** times in a full run.

**This is `jiquery`'s disease (RULE H2's own worked example) sitting in the project's PRIMARY
BASELINE**, and it means `oneTest.base` certifies only the five `generateAction` rows. **Whether the
later sections are deliberately parked or a debug `stop()` was left in is Tony's call** — reported,
not touched. It also corrects today's own census: the four `dumpBC` calls were **`stop()`-dead, not
bare-lookup-dead** (deleted today per Tony's ruling; the baseline did not move, byte-identical).

## WHAT IS RUNNABLE
```
sh jitLadder/ladder.sh       83 checks, exit 0   J1..J7, JE, JF, JP, JPd, JU + J-R
sh genLadder/pop.sh          32 green / 1 parked  (2 documented reds, see below)
sh genLadder/printPop.sh      9 checks, exit 0
sh genLadder/containerPop.sh 11 checks, exit 0
sh genLadder/tree.sh                     exit 0
<binary> incant/oneTest      exit 0, ZERO `generateCode failed`, 11 then 26 x4
```
⚠ **`pop.sh`'s two reds are still deliberately unpinned.** `census.target` (genParse refuses to plan
`MemberS` — a capability regression tangled with a deliberate grammar change; **they want separating
before either is pinned**) and `oneTest baseline` — **whose bytecode-emit half is now FIXED**; its
remaining 9-line diff is **only** the already-signed audit movement (the three named terms
`JSONtoken[1] JSONblock`, `JSONvalue[1] JSONblock`, `JSONvalue[2] JSONarray` plus the `pROPERTIEs`
index shift). **The re-pin is its own act and was deliberately not taken today.**

## ✅ RULED 2026-08-03 (Tony) — TWO PRINT FORMS FROM ONE WALK
**display** — today's behaviour, `noPrint` attributes elide, the default **for eyes**.
**fidelity** — **`noPrint` attributes SURVIVE**; the archive persists this and the round-trip oracle
runs against it.

**The law line:** *a form meant to be **re-read as definition** must be **fidelity**; a form meant
for **eyes** may elide.*

**Why it was forced:** the archive persists entities **through the print form**, and **re-reading a
printed definition is defining.** A `noPrint` `register` that vanished at print **never fires on
re-read — a lit member comes back dark.** Byte-identical storage, different citizen. It also closes
a real oracle blind spot by construction: `register` is consumed silently and does not echo in
`printDefinition`, so a round-trip POP is blind to it — but **the archive prints what survives,
because fidelity is *defined as* what survives.**

⚠ **PREREQUISITE, TONY'S** *(⚠ corrected 2026-08-03 — the first wording was wrong in a way that
changes the fix)*: `aCTionDefinE` does **NOT delete** a `noPrint` attribute that has a method — **it
never ATTACHES it.** `ruleActions.rtn:207` runs the method inside `if noPrint && immediateACTION`
and falls past the `else` that would attach it; the source comment says so outright (*"item gets run
but is not added to the new group"*). **"Stop deleting" and "start attaching" are different edits**,
and only the second exists. Fidelity print needs those attributes present, so this must change
before the fidelity form can round-trip. Named now so it is not discovered at build time.
Nothing builds today; the flag is parked at the site (`docs/supportMinion.md` TASK 2).

## NEXT
0. **Fire order is ruled: FORMS BEFORE SEARCH** — the forms corpus carries **43 measured
   `register`-as-attribute uses**, so search's question 3 inherits a real population instead of a
   hypothetical. Forms fires once support's census legs settle and the channel is judged clear.
1. **Minions.** Three charters are shelf-ready (`docs/formsMinion.md` added): `docs/supportMinion.md` (recon → Buffer compress +
   registry → Display; TASK 0 is a verbatim floor-snapshot commit; NO GRINDING) and
   `docs/searchMinion.md` (the first **design** minion — five questions of search law, deliverable is
   a proposal with no oracle, judged at Tony's gauntlet). **Stagger the firing** so two minions'
   pause-and-ask traffic does not interleave in one relay channel.
2. **The disposition sorting** — `docs/bareLookupCensus.md`, 39 sites. Unblocked now that
   *"register it"* has a known meaning.
3. **The census signature** / separating the `MemberS` regression from the grammar change.
4. **`checkSkip` capture** — lower-level scan, not a callback (Tony's ruling).

# ═══════════════════════════════════════════════════════════════════════════

# ⚠⚠ UPDATED 2026-08-02 — the 08-02 section follows. Older vintage from here down.

# ═══════════════════════════════════════════════════════════════════════════
# 2026-08-02 — THE DAY THE FLEET STARTED TELLING THE TRUTH. FOUR DEFECTS FIXED,
#              ONE ENTIRE ARC BUILT AND THEN DELETED, AND THE INSTRUMENTS WON
# ═══════════════════════════════════════════════════════════════════════════

## IF YOU READ NOTHING ELSE — five things, in the order they will bite you

**1. `tok sourceFile directivesFile` — THE DIRECTIVES FILE IS AN ARGUMENT.** A bare
`tok GroupRules.twk` applies **ZERO** directives and says nothing about it: no warning, exit 0,
and the injected code simply is not in the output. So a retok **silently strips every directive**
unless the file is named on the command line. This cost a full bisect — the directives vanished,
reverting `groupDirectives` did not bring them back, and the edit looked guilty because the edit
was the only thing in the search space. **It was never the variable; the INVOCATION was.**
⚠ **BUT THE DEFAULT IS BARE — cross-annotated 2026-08-05, because this item and the 08-02
"diagnostic trace off stdout" fix below point OPPOSITE WAYS and the fork has now cost a rebuild in
each direction.** `groupDirectives` carries ~10 `active` hooks, so naming it injects live `cerr`
trace into ordinary runs. Use `tok GroupRules.twk` **bare** for any build whose output a POP,
baseline or measurement will be read from, and for anything committed; name the directives file
**only** for ephemeral instrumentation, and then neither measure a POP on that binary nor commit
its `.mm`. Full discriminator table: `CLAUDE.md` bear-trap #23. **A trap explaining how to turn
something ON is not a ruling that it should be on.**

**2. NAME IT BEFORE YOU USE IT.** A reference term resolves by *sharing the definer's child
list*, so a name that does not exist yet mints an empty stub that **never becomes a reference**.
Forward-declare then flesh out:
```
    JSONblock isRule;      <- two lines, and they retired an entire arc
    JSONarray isRule;
```
Symptoms when you get it wrong are TWO and they look unrelated: genParse plans `LITTO` where it
should plan `CALL`, and the *first* parse fails while a later identical one succeeds.

**3. ⚠ AN INCANT ACCESSOR IS NOT A tok ACCESSOR, and the failure is displaced by three files.**
`listLengtH` is incant; in a `.rtn` it produced bear-trap #10's exact signature — `Expected } or
statement` / `FAIL Body3` / `Expected a semi-colon` — which **cascaded and wiped GroupRules.h's
extern block to ZERO**, surfacing as `no member named 'opEQ'` in `Bytecode.mm`. tok exited 139.
Use `groupList` / `contents()`. **The extern canary (`grep -c '^extern' GroupRules.h`) is what
caught it** — check it after every retok.

**4. A HANG IS USUALLY NOT A HANG.** Two separate impostors met today: the **Swift backtracer's
interactive prompt** (`Press space to interact… (30s)`) makes a SIGSEGV look like an infinite
loop — `SWIFT_BACKTRACE=enable=no` turns it back into an honest 139; and **copying a binary over
the signed one gets it SIGKILLed** (137) by macOS, which reads as a timeout. Re-`codesign
--force --sign -` after any swap.

**5. rStuff IS BEAR COUNTRY (Tony, and he is right).** `parse()`'s first act is
`getStuff(pStuff)`. Anything wired in beside it crashes in ways that do not name themselves —
null `groupBody` in `addGroup`, via `parse → testAttributes → parse`, with **zero bytes of
output**. If a change touches rStuff, expect the failure to arrive somewhere else entirely.

## WHAT IS RUNNABLE — five POPs
```
sh genLadder/pop.sh          32 green / 1 parked   genParse ladder + baselines + iterators
sh genLadder/printPop.sh      9 checks, exit 0     print family, fully green
sh genLadder/tree.sh          exit 0               §2.4 divergence unchanged (OPEN, not broken)
sh genLadder/containerPop.sh 11 checks, exit 0     NEW — testContainer + Buffer::shorten
sh jitLadder/ladder.sh       76 checks, exit 0     J1..J7, JE, JF, JP, JPd + J-R
```
⚠ **`pop.sh` reports FAILED on 2 reds that are DELIBERATELY UNPINNED** — see "TWO REDS" below.
Everything else is green. The parked count is down from 4 to 1.

## THE FOUR FIXES

**`testContainer` — LONGEST-ENTRY MATCH.** The greedy scan over the container's *character set*
is an UPPER BOUND, never the answer: set membership can say "this character could belong to some
entry", never "is this prefix an entry", because a set has no notion of where an entry ends. Any
container holding both a symbol and a word poisons the symbol with the word's letters. `Operators`
holds `negate` and `modedOP`, so `n e g a t m o d` are all in its set and **`9 -grup` scanned
`-g`** — an entry of nothing — taking the enclosing statement's parse with it, silently, at exit 0.
Now the buffer backs off one character at a time (`Buffer::shorten`, new, mark-unaware on purpose)
until it IS an entry or is empty. **Same disease class as the ShortcuT `+`-merge that sank `,`:
set-based character grouping making token decisions. Two specimens; the class has a name if a
third surfaces.**

**Forward references — and the fix is grammar, not machinery.** See item 2 above. jsonTest went
11 ok / 2 FAIL → **13 ok / 0 FAIL**, and its baseline is byte-identical again.

**Iterator refusal — announced once, poisoned, and the advance is the only reader.** A refused
`iterate` returned 0 *before* setting `isIterator`, so `while ++grup` missed `opPlusPlus`'s
iterator arm and fell through to the **DATA** arm — `if !data count = 1;` returns the node, which
is truthy, **so the loop could never end**. Now `aCTionIterate` announces once at the door and
sets `fLAG`; `++`/`--` gate on it before any advance work; the `while` is untouched.
**THE RESET LIVES ON `aCTionIterate`'s SUCCESS PATH** and nowhere else — the poison means "the
LAST iterate on this node was refused", so a fresh successful iterate is exactly what clears it,
and re-running the Iterate rule is now the only way to change a source. `iterT1m` went from HANG
to exit 0. Uses the existing `fLAG`, so **no layout change** — no `groups.ext`, no `tokall`.

**Diagnostic trace off stdout.** Three POP targets were broken by an *instrument*:
`printFamily.target` diffed `0a1,288` and `printFamilyNew.divergence` `0a1,292` — lines
**prepended**, zero content divergence. Cause: directive hooks tracing with `cout`, which is never
divertible. All 47 sinks in `groupDirectives` are `cerr` now (not just the 3 live ones — the other
44 are landmines for whoever flips a `ctive` to `active`), and the `.mm` are retok'd without
directives at Tony's word.

## ⚠ THE ARC THAT WAS BUILT AND THEN DELETED, and why that is a good outcome

A whole deferred-repair mechanism — `finalizeRegistry`, `finalizeRegistries`, `finalizeIfDirty`,
`registriesDirty`, `markRegistriesDirty`, a dirty flag, a `currentDefine` gate, two reader entries
— was built, made to work on the census half, and then **deleted in favour of two lines of
grammar**. Trail: `3957233 / 713d45f / 8bb989e`, superseded by `c8d38f6`.

**Read this before rebuilding any of it.** The arc was not wasted: it produced the measurement
that made the two-line fix findable (`incant/termScratch` showing three sibling options of ONE
alternation split by nothing but declaration order). But **the deletion was licensed by a probe,
not by optimism** — the census was re-run with the sweep disabled and still read `CALL`, because
*"the fix works"* and *"the old machinery is redundant"* are different claims and only the second
justifies a deletion.

**Three hypotheses died in that arc, each on one measurement, and the pattern is the lesson:**
- *"identity — the readers see different nodes"* → pointer probes: **same GroupItem, same
  GroupBody, both readers.** Killed.
- *"the write does not stick"* → probe right after the assignment: `kids=1`. **It stuck.** Killed.
- *"the hook site is wrong, find a better one"* → true but unfixable, because **input lifetime and
  define lifetime are independent**. popInput was too late (only the 10 base registries exist at
  include-pop); pushInput crashed. That is the same fact from both ends.

## TWO REDS LEFT, BOTH DELIBERATELY UNPINNED — pinning either would freeze a real defect
- **`census.target`** — the diff is now ONLY Tony's `MemberS ':'- MEMBERs- Mlist=DefinE+;`
  rewrite, but **genParse now REFUSES to plan MemberS**. The grammar change is deliberate; the
  planner losing a rule is a capability regression. **Those two want separating before either is
  pinned.** Tony's signature.
- **`oneTest baseline`** — the audit movement plus **`generateCode failed`: the whole bytecode
  emit is gone.** `generatE` (`incant/generate:233`) sits one indent deep — a MEMBER — and is
  reached by bare lookup, which the new members gate no longer serves. **That is the bare-lookup
  sweep's first fix, not a re-pin.**

## NEXT, in order
1. **The bare-lookup sweep**, gXpress first. Grep the tree for every site that locates a
   member-depth name by bare lookup and fix the population in ONE pass — the gate's blast radius
   becomes a counted list instead of a series of ambushes. `oneTest baseline` goes green with it.
2. **The census signature** (or the separation above).
3. **`checkSkip` capture — LOWER-LEVEL SCAN, NOT A CALLBACK** (Tony's ruling). One skip/consume
   primitive that understands quoted strings and comments, with BOTH `checkSkip` and `aCTionCodE`
   routing through it. A callback bolted onto `checkSkip` leaves `aCTionCodE` to grow its own
   quote-awareness later — two implementations in one subsystem. **This retires `CLAIM KANT-40`
   by construction**: an action containing a comment containing `}` survives capture and runs.
   C++ now, kant at self-hosting.
4. **Timed green pass → per-block POPCAP budgets** at measured-time × margin. The 90s default is a
   courtesy allowance, not a target.

## TONY'S OFFLINE WORK THAT LANDED TODAY (his words, kept because they explain the fleet)
- **Iterators finished.** They filter on attributes or members, triggered by whether the iterator
  `isAttribute` or `isMember`. **Resetting an iterator is REMOVED from `:=`** — to change a source,
  run the Iterate rule again. All the unused `iterWhatever` methods were removed rather than
  updated for changes not worth making.
- **The attribute-pollution fix**: `aCTionDefinE` did not gate on member processing.
  `aCTionNewGroup()` sets `currentDefine`; `processFlags()` gets a `MEMBERs` toggle from the
  `MemberS` rule setting an `addingMembers` flag that `aCTionDefinE` gates on. So
  `MemberS ':'- MEMBERs- Mlist=DefinE+;`. **Note the consequence, and it is load-bearing: if
  `currentRegistry.isRule` members get added to it; if not they are NOT added to the
  currentRegistry and so are not found by `locate()`.** That is what `generateCode failed` is
  downstream of.
- Still open, his: mutual recursion loses locals (`iterT1m` pins the wrong answer at 14 lines
  where 7 is correct) · `iterT3`, the last parked fixture.

## DOCTRINE ADDED TODAY
**RULE H5 — A FIXTURE MUST NOT BE ABLE TO DELETE THE REST OF THE SUITE.** `iterT1m` began to hang,
so `pop.sh` never reached its summary, its exit status, or the eleven checks below the iterator
block. Those checks did not fail and did not pass — **they ceased to exist**, and the operator
sees a terminal that is merely quiet. Worse than the missing-sentinel case, because there is no
output to be suspicious of. **And the fixture that did it was a PARKED one**: parking bounds a
VERDICT, and it never contemplated a fixture bounding nothing at all by never returning. So every
fixture runs under a wall-clock cap, and **a timeout fails the suite even when parked** — a hang
is not a wrong answer, it is the absence of a run, and nobody parked that.

**A PARKED PIN THAT STARTS PASSING MUST GRADUATE.** `WOKE` fired twice today and both fixtures
came off the list. Parking means *"the answer has not been chosen"*; once it is chosen the item is
either a full check (`iterT1`, whose original target held byte for byte) or a deliberately pinned
known defect (`iterT1m`, the `tree.divergence` pattern) — **never still parked**. A pin that
silently begins to hold is how a parked item becomes a forgotten one.

**A RE-PIN NEEDS A SENTENCE, NOT A GREEN DIFF.** Both of today's "probably fine, just re-pin it"
candidates came back **regression** on one grep each. The audit's `15 → 12` was signed only once
the three vanished terms were *named* (`JSONtoken[1] JSONblock`, `JSONvalue[1] JSONblock`,
`JSONvalue[2] JSONarray`) and explained. **Without that discipline both breakages would have been
frozen into the baselines as truth.**

**PRIOR ART BEATS SPECULATION.** The forward-reference fix was two lines that a worn path already
sanctioned, reached after a day of armchair analysis about fill-in-place and cycle depth. Tony's
call — *"act like it won't until it do"* — was right, and the experiment answered in under a
minute. **When a question is measurement-shaped, measuring is cheaper than deciding it is safe to
measure.**

# ═══════════════════════════════════════════════════════════════════════════

# ⚠⚠ UPDATED 2026-08-01 — the 08-01 section follows. Older vintage from here down,
# still broadly accurate, just no longer the top of the story.

# ═══════════════════════════════════════════════════════════════════════════
# 2026-08-01 — THE LONGEST DAY IN THE RECORD. J-R WENT GREEN, THE CONVERSION
#              ARC OPENED AND RAN TWICE, AND THE NUMERIC TOWER GOT ITS RULINGS
# ═══════════════════════════════════════════════════════════════════════════

## IF YOU READ NOTHING ELSE — five things, in the order they will bite you

**1. `cerr` AND `cout` ARE NATIVE STATEMENT KEYWORDS.** Three sinks, three different things:
`print` is DIVERTIBLE (buffer if armed, else stdout); `cout` is NOT (always stdout); `cerr` is
NOT (always stderr). Neither `opCout` nor `opCerr` consults `toBUFFER`, and **in both cases the
missing test IS the feature** — adding it back to `opCout` restores KANT-23 exactly. Fixture
`incant/sinkT` pins all three under an ARMED diversion, the only condition that tells them apart.

**2. THE JIT NOW DOES RECURSION, ON REAL FRAMES.** `J-R` is green — factorial through an
**emitted self-call**, fired at two depths (6→24), plus `jitJRL` where a LOCAL read *after* the
recursive call returns proves per-activation storage (5→9; aliased slots would give 4→6).
**Depth-1 passes on aliased slots and depth-N cannot**, which is why both depths are asserted.

**3. ⚠ INLINING IS THE CALLING CONVENTION, BY CONSTRUCTION.** A non-recursive jitted call is
INLINED — emit-on-walk re-executes the callee's BlocK into the caller's builder, so there is no
`call` instruction at all. Only a SELF-call gets a real call, because inlining one cannot work.
Zero call overhead, mem2reg optimises across dissolved boundaries, and **small composed actions
are the FAST idiom** — which the conversion arc should know, since it is minting that population.

**4. THE CONVERSION ARC IS OPEN AND HAS RUN TWICE.** Order ratified:
`emitMany` → `countRuleTerms` → `printPlan` → `emitPlan` → `unresolvedTerms` → `planRule` →
`planTerm`. **Conversion 1 is CLOSED** (kant `emitMany` answers through the seam, `rung5.target`
byte-identical, `MANIER kant` pinned). **Conversion 2's kant is written and NOT wired** — see
OPEN below, it is blocked on a real ordering problem.

**5. ⚠ A CLOSE-BRACE CANNOT APPEAR ANYWHERE IN AN ACTION BODY — INCLUDING IN A COMMENT.**
`aCTionCodE` scans for the first one with no quote awareness and no comment awareness.
`CLAIM KANT-40` was earned by writing a comment *explaining* this, which contained the character,
which ended the capture. The whole action vanished at exit 0. **Do not write it in any form,
including while describing it.** Emitters carry `closeBrace="}"` as a define-line trait instead.

## WHAT IS RUNNABLE — four POPs, all exit 0
```
sh genLadder/pop.sh        29 green / 5 parked-WIP   genParse ladder + baselines + conversions
sh genLadder/printPop.sh    9 checks                 print family, now fully green
sh genLadder/tree.sh                                 §2.4 divergence unchanged (OPEN, not broken)
sh jitLadder/ladder.sh     76 checks                 J1..J7, JE, JF, JP, JPd + J-R
```
⚠ **"5 parked-WIP" IS THE CLEAN STATE, NOT DEBT.** The five iterator fixtures are pinned to an
OLD design; Tony reworked iterators offline and their semantics are his. They re-pin when his
work lands, as part of it. **A `WOKE` alarm fires loudly if one starts passing** — negative-
controlled, so it is known to work.

## THE LANGUAGE MOVED — rulings implemented today
- **`/` PROMOTES.** `10/4` → `2.5` typed double. **Always** a double, including `8/4` — because
  premise 1's datA-stability contract forbids a result type that depends on runtime values.
- **Narrowing rounds HALF-UP, uniformly**, in ONE place: `getCount`'s `isNUMBER` arm. Not
  `lround`, which rounds half away from zero and disagrees on negatives.
- **Compound assign computes in doubles and narrows the RESULT**; the **binary family PROMOTES**.
- **`arrondir(x)`** is explicit rounding. ⚠ Named in French deliberately: `round` is libc and an
  `extern "C"` clash is bear-trap #12. **Borrowing a word from another language beat inventing
  one** — it removed both the collision and the `=method` indirection.
- **`||` is registered** (`'||' operateMethod=opOR`). ⚠ **It EVALUATES BOTH ARMS** — structural,
  an operateMethod receives already-evaluated operands. And **`!a || !b` IS NOT `if !a; or !b;`**
  on absent attributes (KANT-35) — multi-attribute presence checks MUST stay sequential.
- **`isRulE` has its opDot case.** ⚠ The fix was TWO lines, not one: unnumbered GroupFields
  entries get no index at all, so they hit the `default` arm. Ten more are in that state.

## ⚠ OPEN, AND WHOSE

**Blocking conversion 2 (foreman's, needs one measurement):** `parseRuleMethod` calls
`countRuleTerms` at **DEFINE** time, but `genScratch`'s `search … list;` runs AFTER the define
block — so a `locateCounter` fork would find nothing at define time and **the binder would run
C++ while `planRule` ran kant**. Two implementations in one subsystem, which that method's own
header forbids. Fixture ordering is the remedy. **Do not land the fork before settling it.**

**Tony's:** the T6 generation assessment (below) · the iterator semantics · the name-scope
pollution fix (`docs/nameScopeRecon.md`) · the `ruleOrRefuse` convention change.

**Foreman's, parked demand-driven:** the `}`-scan and quoted-whitespace gaps. Neither blocks
anything; they jump the queue with a specimen attached.

## T6 — THE GENERATION ASSESSMENT, awaiting Tony's go (`docs/jitDesign.md`)
**34 ops carry an `operateMethod`; exactly TWO have a `switch(data)` dispatch tree.** So
`opPlusEQ` — the probe — is the OUTLIER, not the exemplar. Answer is **per-family**: GENERATE the
comparison six (character-identical but for three slots, and generation closes §3.5's bypassed
null-guards by construction); SHELLS for arithmetic + compound assign; DON'T for the ~20
structural ops. **15 ops still carry the top-gate shape T1 condemns**, ~1 mechanical edit each.

## INSTRUMENT LESSONS PAID FOR TODAY — all three were the harness lying
- ⚠ **`pop.sh` called `sentinel` without defining it.** Copied the idiom, not the helper. Every
  run printed `command not found` and CARRIED ON — the check did not pass, did not fail, **it
  ceased to exist**. H2's own failure mode inside the harness that enforces H2, and the second
  instance after `jiquery`. Found by minionA, which deliberately did NOT fix it because the brief
  pinned the count.
- ⚠ **A negative control needs its own negative control.** Renaming a sentinel to
  `MS SENTINEL-BROKEN` still passed — `grep -F` matched it as a SUBSTRING.
- ⚠ **A number written without measuring it is a lie in the ledger.** One commit says
  "jitLadder 78/78"; the real count was 76.

## THE MINION HARNESS — two rounds, both strong
Round 2 (`emitMany`) and round 3 (`countRuleTerms`) both held the carve-out exactly: kant only,
no `tok`, no `xcodebuild`, no `groups.ext`. **Round 3 hit no obstacle a corpus claim should have
prevented** — the corpus worked as an instrument. Its own headline: **a double-quoted literal
SPANS NEWLINES**, so ten `cerr` statements became one and the emitter now looks like the C++ it
emits. That was Tony's instruction and it held.
⚠ **A crash autopsy (KANT-25) found the loss from a mid-round 500 was ZERO** — the transcript is
the persistence layer and resume reads it. **Do not build preservation machinery against it**; the
cure proposed at the time collided with the spawn rule's only-write-to-the-corpus clause.

# ═══════════════════════════════════════════════════════════════════════════

# ⚠⚠ UPDATED 2026-07-31 — the 07-31 section follows.

# ═══════════════════════════════════════════════════════════════════════════
# 2026-07-31 — THE STRING EXPRESSION MOVED TO `#`, TWO LANGUAGE RULINGS LANDED,
#              AND THE JIT GREW A LADDER THAT CERTIFIES ITS OWN CLAIMS
# ═══════════════════════════════════════════════════════════════════════════

## IF YOU READ NOTHING ELSE

**`#` is the string-expression opener.** `x = #"a" "b";` replaces the old `string` keyword.
It was tried as `,` first and that had to be abandoned: `,` is already in the shortcut set
(`ShortcuT=[-+~`$_:,]+`, `incant/grammar:92`) whose `+` MERGES adjacent shortcut characters, so
a `,` inside a print had two readings — and `print "it is", maximus + 3, "done":;`, live in
`unitTests`, SEGFAULTED. `#` is not in that set. Record: `incant/hashProbe`.

**`$` is now a PERSISTENT TOGGLE.** `useDefaultSpace = true` was removed from `opPrint`/
`opString`. `processAction` resets it before each action runs, so it cannot leak *into* one, but
it survives across statements *within* one and a nested call resets it. **The safe idiom is
BALANCED `$ … $`** — off at the start of a statement, on at the end. `incant/printFamily` is
the worked example; `incant/stringT` row 4 pins the persistence itself.

## WHAT IS RUNNABLE — five POPs, all green, all exit 0
```
sh genLadder/pop.sh        30 checks   genParse ladder + baselines + branch semantics
sh genLadder/printPop.sh                print family (moving half still pinned WRONG)
sh genLadder/tree.sh                    §2.4 divergence unchanged (OPEN, not broken)
sh jitLadder/ladder.sh     47 checks    THE JIT LADDER, rungs J1..J7
<binary> incant/jiquery                 the JIT minion corpus, queried
```
⚠ **`pop.sh` echoes the binary it is testing as its first two lines.** All three genLadder POPs
used to hardcode a DerivedData path from a project that no longer exists; a stale binary does
not fail as a diff, it HANGS. They now use `${INCANT:-$HOME/bin/incant}`.

## THE JIT LADDER — the month's main artifact
`jitLadder/ladder.sh`. **Nothing in this tree had ever asserted that an ACTION, jitted end to
end, RETURNS THE INTENDED VALUE.** Each rung is the previous plus ONE construct, so a red NAMES
the construct.

| rung | adds | the claim it proves |
|---|---|---|
| J1 | assign + arithmetic | the OPERANDS are read at run time |
| J2 | if/else | the BRANCH is decided at run time |
| J3 | while | the loop RUNS THE RIGHT NUMBER OF TIMES |
| J4 | do | the body runs ONCE when the condition starts FALSE |
| J5 | multi-statement operand reuse | **attribution, not coverage** — the clobber's trial |
| J6 | an emitted call (`jitTrace`) | a call is EMITTED and runs PER FIRE |
| J7 | fallback column on a real opMethod | emit a call, GET A VALUE BACK, layout-free |

**EVERY RUNG COMPILES ONCE AND FIRES TWICE**, input changed *after* emission. A right answer
does not prove compiled code produced it — under jitting the interpreter executes the body for
real at emit time, so a naive POP goes green on an emit-time side effect. Fire 2 recompiles
NOTHING; if its answer tracks the input, the computation happened at RUN TIME.
⚠ **INJECTIVITY: the two ANSWERS must differ, not just the inputs.** J1–J6 satisfied this by
luck; J7 (`17 % 3` and `20 % 3` are both 2) is where it surfaced.
Every rung also asserts **degrade count 0** and records the **interpreted oracle** beside its
value — §0 sentences the interpreter, so the ladder banks its testimony while it can.

## THE FRAME MODEL IS NEXT, AND IT IS TEED UP
**Recon done, nothing built.** `docs/jitDesign.md` Part III.

⚠ **THE FRAME SCHEMA ALREADY EXISTS IN THE TREE** — `(isArgument || isLocal) && !noPrint`,
walked forward by `saveLocalFields` (`GroupActions.rtn:697`) and backward by
`restoreLocalFields` (`:524`). The JIT **inherits** it rather than inventing one.
⚠ **THE FUNCTION §0 SENTENCED TO DEATH IS THE ONE THAT DOCUMENTS WHAT TO BUILD.** Read it
before deleting it; do not delete until the replacement is green. **Inherit the schema, NOT the
bug** — `CLAIM KANT-8` lives in the same machinery.

**Increment 1:** schema walk at emit → one alloca per local → prologue in → locals via alloca
while **globals keep baked addresses and immediate store-through** → epilogue out.
⚠ **IT IS NOT INDEPENDENTLY PROVABLE.** Without recursion, allocas-for-locals is
behaviour-neutral. A rung can assert STRUCTURE plus a value regression net, and **must label
itself not-the-proof**. **J-R is the proof** — factorial-shaped, fired at TWO DEPTHS, because
depth-1 passes on aliased slots and depth-N cannot.

## LANGUAGE RULINGS IMPLEMENTED (Tony's, 2026-07-31)
- **A bare `return;` yields the PRIOR statement's value.** An action's value is the value of the
  LAST EXECUTED STATEMENT; `return` means *stop*. It used to yield the string `"return"` —
  KANT-10 leaking through `aCTionBrancH`. Fixture `incant/retProbe`.
- **`break` is CONSUMED by the innermost loop** and propagates nothing, so statements after the
  loop run. It used to make post-loop code unreachable. Fixture `incant/loopBranchT`.
- ⚠ Both share a structural root — **the VALUE and the BRANCH SIGNAL ride the same node** — and
  both are retired at crossover rather than fixed, because in IR a `br` carries no value.

## RULES ADOPTED THIS MONTH (CLAUDE.md Testing)
**H1** a harness echoes its binary · **H2** every harness asserts its own completeness with a
sentinel unreachable except through the final section · **H3** assert what only moves when the
answer moves · **H4** presence-with-value, never absence-of-message (fleet-audited, no
conversions owed) · **E1** a bracketing emitter leaves nothing in flight · **one channel, one
meaning** · **prefer a structure that makes the failure unconstructable** · **retirement by
mapping** · **in a demolition arc the recon is how you learn what the condemned code knows**.

## OPEN, and whose
**Tony's:** the crossover ruling (degrade loudly?) · `sink=`'s run-time half (the define-time
half is cheap; `definingRule()` cannot reach a rule from a parsed instance — `ipc/clod-to-clay.md`
SEQ 36) · `knownErrors.md` KE-1/KE-2 · FormaT does not fire, and when fixed its lead character
should be `%` not `#`.
**Mechanism curiosity, blocks nothing:** why seeding happens per use against bear-trap #9, and
why a `do` body is not block-wrapped where a `while` body is (`openWalkStructureReads`).

## ⚠ THE INSTRUMENT THAT CHANGES HOW YOU DEBUG
```
INCANT_JIT_DUMP=2 <binary> incant/<fixture> 2>&1
```
**Mode 2 is PRE-mem2reg — the EMITTER'S OWN output.** Mode 1 cannot tell you whether the emitter
emitted something or the optimiser produced it, which is the first question any emitter failure
raises. The result-slot clobber was invisible at `=1` because folding hid it.
And **`jitTrace(field)` is the print that survives jitting** — `print` fires at EMIT time under
jitting and reports compile-time state once: **it appears to work and it lies.**

# ═══════════════════════════════════════════════════════════════════════════

# ⚠⚠ UPDATED 2026-07-30 — the 07-30 section follows.
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
`docs/jitDesign.md`, TODO's JIT sections).

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
⚠ **CROSS-REFERENCE ADDED 2026-08-10 — LIKELY DIAGNOSIS FRAME, still parked, still not chased:**
this backtrace carries the **inverse** signature of the phase rule in `docs/andOrRung.md` §6
(*emit time never enters a runtime handler for its value; run time never enters an emitter*) —
here a **runtime handler enters an emitter** (`opPlusPlus` → `jitEmitUnary`), where §2's `OR`
silent-wrong is the same rule broken the other way. **Frame only; adjacency is not scope.**

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
