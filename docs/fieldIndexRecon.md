# fieldIndex recon, step 0 (SEQ 794, 2026-11-27; read-only)

Topics/fieldIndex step 0, by Clay's go order released by Tony. Nothing was built and no tracked file but docs and
topic notes changed. Each claim is marked READ (from source, file:line as of this date) or MEASURED (a scratch fixture
on the trunk binary of seal 554, exit status taken from the binary). The fixtures were throwaway and are not in the tree.

**The short answer.** A definition records what a field is and where it lives, and nothing about where it came from.
An action's body is built at its first call, not at define, so "where used" does not exist for an action that has
never run; `compile()` is the nearest existing way to force it. The seat that resolves a name has the name as
written, the action it is in and the field it found, all three, but not whether the use is a call. Delete and
redefine do not reach a body already built: it goes on reading the old field. Neither jitter compiles an action twice
today; the kant jitter could swap by a new name, the old one cannot.

## A. What each definer records today

| definer | where | records | does not record |
|---|---|---|---|
| a `define` entry | `aCTionDefinE`, ruleActions.rtn:285 | the registry it joins (`parent`, :318, :326, :427); `isInitialized`; for a rule `isRule` and its `rStuff` (:319-320); for an action `isCoded` and the body text as a `CodE` property (:366, :400), plus the locals `this` and `tempField` (:374-380) | file, line, the text as written, which define block |
| the `registry(X)` command | `rEGISTER`, Commands.rtn:656 | makes X a registry and the current one; since seal 530 the registry is its entries' home and is listed in `registries` | file, line |
| `register(X)` / the `register` attribute | same extern | adds the field to the current or the named registry | anything else |
| a name first met in an action body | `aCTionNamE` / `resolveName`, ruleActions.rtn:724, :2188 | a local minted on the action, `isLocal` | where in the body |
| an action's first call | `processCode`, GroupActions.rtn:814 | the built `BlocK` as a property; `isAction` set, which clears `isCoded` | which names the body resolved |
| a description | a separate entry in `dESCRIPTIONs`, keyed by name (incant/utilities:568-571) | the text | nothing on the field itself |
| `include` | `getFile`, Commands.rtn:184; the `fILEs` registry in incant/setup | name to path, written by hand | which entries a file defined |

READ, all rows. Three points from docs/warningsRecon.md (2026-11-22) still stand and were not re-measured: the
parser's line is in `sourceLINE` and at `aCTionDefinE` it is the line where the entry ENDS; an entry defined from text
that is no file has no file; a property is readable from kant by `=<`, so `definedAt` as a property needs no layout
change.

Design question 3 (the facts do not live on the field): the two fact stores that exist, `dESCRIPTIONs` and
`fORMfACTs` (IncantForms/Controls/formFacts), are both registries keyed by name. READ.

## B. Where a delete must clean up

What exists: `Registry -= entry` removes a member by tag (`opMinusEQ`, Instruct.rtn:690-701); `target -% attr` removes an
attribute (`opRemoveAttribute`, Instruct.rtn:1505); a refused define removes its own entry
(ruleActions.rtn:434-437). There is no delete command and no inverse of define. READ.

MEASURED (scratch `fiDel`, exit 0, its sentinel printed). A registry with `fiA = 7` and an action `fiRead` that
prints `fiA`:

| step | entries in the registry | `fiRead()` prints | a fresh top-level read of `fiA` |
|---|---|---|---|
| defined, `fiRead` called once | 6 | 7 | |
| after `FiT -= fiA` | 5 | **7** | |
| after defining `fiA = 99` again in the same registry | 6 | **7** | 99 |

So a removed field stays alive and readable through any body built before the removal, and a redefinition after a
removal makes a NEW field that those bodies never see. (Without the removal a redefinition writes onto the same
entry: warningsRecon section 1, `aCTionTraiT`'s `setContent`; not re-measured here.) That is F-164 (names bind at
first build) seen from the delete side.

A delete rule therefore has these places to reach. READ, except the first:
1. Every built body that resolved the name (MEASURED above). Either the bodies are un-built (drop the `BlocK`
   property and set `isCoded` back, so the next call rebuilds) or the index's "where used" names them. Nothing does
   either today.
2. The registry's member list (done by `-=`).
3. The search list, if the deleted field is a registry (seal 552's list holds each registry once).
4. `registries`, if it is a registry.
5. Listeners: the field's own list goes with it (an attribute named `notifyLIST`, Commands.rtn:407-409); a listener
   action that names the field is case 1.
6. The fact stores keyed by its name: `dESCRIPTIONs`, `fORMfACTs`, and whatever the index adds.
7. Compiled code: the old JIT's cache keyed by body and the kant jitter's table keyed by name (section D); neither
   is ever evicted.
8. Holders (`:=`) and copies that share its attributes: not reachable by any list; they keep the old field alive.

NOT DETERMINED: whether a rule removed from a grammar registry leaves parse methods bound in other rules' terms; the
same question for a form's fields after `show`.

## C. When an action's body is built

- At define, nothing is built: the text is kept as `CodE` and `isCoded` is set (ruleActions.rtn:366-401). READ.
- At the first call, by `processCode` (GroupActions.rtn:814), reached from `runAction` (:1397) and `processAction`
  (:747). Old road: `driveStep(code, BlocK, ...)` (:877). A `newRoad` body: kantGrammar's STARt, then a `BlocK` whose
  method is `testOP` (:854-870). READ.
- The mark that it is built: the `BlocK` property, and `actionType` going from coded to action (GroupBody.twk:58). READ.
- MEASURED twice (scratch `fiDel` and the reader's `fiBuild`, both exit 0): an action never called, or only passed as
  an argument, reads `isCodeD` 1, `isActioN` 0 and has no `BlocK`; after one call it reads 0, 1 and has one. Kant can
  read all three today (`isCodeD`, `isActioN`, `x =< "BlocK"`).
- Forcing a build without running: `compile(x)` (Commands.rtn:35) calls `processCode` and does not fire the body, but
  it is aimed at rules; `compileIn` (GroupActions.rtn:101) builds onto a request and does not install; `testing(x)`
  builds as a side effect of the old JIT. Nothing means "build every action". READ. NOT RUN: `compile(anAction)` on a
  plain action.
- THE NAME SEAT (design questions 1 and 2). Old road: `aCTionNamE` calls `resolveName(text, owner)`
  (ruleActions.rtn:724, :2188). In hand there: the name as written, the owning action, and the field it resolved to
  (the owner's own, one located on the search list, or a new local). So both meanings of "used" are available at one
  seat. NOT in hand: whether the use is a call, an attribute or a member; that is decided later (`handleCall`,
  `handleSubscript`, ruleActions.rtn:1576, :1596; the dot on the accumulator road). READ.
- NOT DETERMINED: the new road's name seat. kantGrammar shares `NamE` (incant/kantGrammar:14), so `aCTionNamE` is
  presumably the seat there too; not traced.

For Topics/documentation's define form: where-used can be reported only for bodies already built, and by the name seat
only as "names this field", not yet as call / attribute / member.

## D. Can the jitter swap an action's code mid-run

- THE OLD C++ JIT: no. Compiled functions are held in `gJitCache`, keyed by the action's body (jitContext.h:598);
  a cached body is reused and never rebuilt (jitEmitters.rtn:4718); a function name already in the module is refused
  as a name collision (:300-305); a refused compile marks the body not jittable for the rest of the run (:4680-4683);
  nothing evicts the cache or removes a module. Since SEQ 385 a second `testing()` answers from the cache
  (Commands.rtn:764-774). READ.
- THE KANT JITTER: not today, but there is a road. Functions are held by NAME (`gIRDoor`, jitContext.h:234), the name
  is `kw_<action>` (incant/kantJitter:13), and `processAction` reads the action's `KanT` attribute and looks the name
  up on every call (GroupActions.rtn:792-797). A second compile under the same name is reused, not rebuilt
  (jitEmitters.rtn:4436-4438). So a swap is: compile under a NEW name, then rewrite the action's `KanT` text; the next
  call picks it up and the old function stays alive. Nothing does this today. READ.
- The recorded "second testing() on one action corrupted state" (docs/jit.md:456-460) does not say what was corrupted.
- NOT MEASURED: any recompile, on either path. NOT DETERMINED: whether rewriting `KanT` is safe while that action is
  on the call stack; what LLVM does with the same name in a new module.

For design question 6: baking the switch in and compiling again when it flips is possible only on the kant jitter,
by the new-name road, and is unmeasured. A run-time check needs nothing new.

## E. Can kant list a field's set flags (added, SEQ 785 notion 3)

No. Kant reads one flag at a time by accessor: the `GroupFields` registry (incant/setup:318) names about 55, and
`argument.isCodeD` and its kin read 0 or 1 (MEASURED, `fiDel`). Nothing walks them. The only listing is C++:
`dumpContents` prints a few flags as words ("is local noPrint"; MEASURED). A kant lister is a walk of `GroupFields`
reading each accessor on the argument; whether an accessor can be applied by a name held in a cursor was NOT RUN.
The starred spelling `*argument.isRulE` refuses by name inside an action (MEASURED; bear-trap 26, payment 7).

## What this gives the design pass
1. "Where defined" is one property written in `aCTionDefinE`; the line it has is the entry's last.
2. "Where used" can be written at `resolveName`, with the written name, the action and the resolved field; the kind of
   use needs a second seat. It exists only for built bodies, so the index needs a build-all pass or says "not built yet".
3. Delete and redefine have eight places to reach (section B); the first, built bodies, is the one that changes what
   a program does, and is measured.
4. The switch and the jitter: only the kant jitter can swap, and only by a new name; unmeasured.
