# tok claims — the B0 sweep

*Output of `docs/mdReorgB0.md` §4. Format is `docs/mdReorgB0.md` §2, unbent — see
"Format verdict" at the foot.*

Confidence scale: **RUN** (a POP proves it, command attached) · **MEASURED** (read off the
live tree once) · **READ** (read off source, not executed) · **REASONED** (argued, never
checked) · **ASSUMED** (inherited or guessed).

**The sweep's POP is one file:** `scratchpad/popB0.twk` — seven externs, `tok popB0.twk`,
then `clang++ -fsyntax-only -x objective-c++ -std=c++17 popB0.mm` → **EXIT=0**. It is
reproduced verbatim at the foot of this file so the runs survive the scratchpad.

---

### CLAIM TOK-1
```
statement:   tok CAN assign a dlsym result to a typed function-pointer member with no
             passthrough. It emits the cast itself, derived from the member's declared type.
confidence:  RUN
provenance:  popB0.twk popP1/popP2b -> popB0.mm:16,23
                 stuff->parseMethod = (GroupItem*(*)(GroupItem*))::dlsym(RTLD_SELF,name);
             clang++ -fsyntax-only EXIT=0.
             Independently shipping: GroupActions.rtn:451 `method = dlsym(RTLD_SELF,name);`
             -> GroupRules.mm:5632, compiled into the live binary.
asOf:        2026-07-29
scope:       Covers a fnptr member declared `Type &name(Args);` in a .twk class body
             (RuleStuff.twk:47), assigned both under `use` and plain-qualified. Does NOT
             cover a member tok cannot see a declaration for (no `external` mirror in
             groups.ext -- bear-traps #11/#16). Does NOT assert the shipping
             `setParseMethod` has been changed: B0 grades, it does not fix.
```
**This falsifies `genParse.rtn`'s own justification** (*"Passthrough because tok has no
syntax for casting a void\* to a typed fnptr member"*, genParse.rtn:1071). Tony annotated
the correction in place on 2026-07-29; this is the run behind it. Attic entry 1.

**Two things the rewrite must not lose, and they are why it is a rewrite and not a
deletion:** the passthrough body also (a) uses `RTLD_DEFAULT`, not `RTLD_SELF`, and
(b) NULL-checks the address and reports `setParseMethod: ERROR no method found %s` on
stderr before returning 0. The one-liner drops the diagnostic. Rewrite is not B0's.

---

### CLAIM TOK-2
```
statement:   A dlsym call in ARGUMENT position generates a correct single-argument call.
confidence:  RUN
provenance:  popB0.twk popP3 -> popB0.mm:62  grup->setOperat(::dlsym(RTLD_SELF,name));
             clang++ EXIT=0. Shipping at GroupRules.mm:5636 from GroupActions.rtn:454.
asOf:        2026-07-29
scope:       Covers a CALL EXPRESSION in argument position. Does NOT generalise to
             argument position broadly. Juxtaposed concat in argument position is a
             DIFFERENT construct and is still believed broken -- `f(x, pad "  ")`
             silently generated a THREE-argument call, caught only by the C++ compiler
             (wakeup.md, hit twice). Two constructs, same position, opposite results.
             That distinction is itself the claim; do not collapse it.
```

---

### CLAIM TOK-3
```
statement:   `field = value` dispatches through the setter WHEN ONE EXISTS, and is a
             direct member assignment when one does not. Both compile. The cast in the
             second form is supplied by tok from the member's declared type.
confidence:  RUN
provenance:  popB0.mm, three shapes in one run --
               popP2c  grup.method = dlsym(..)  -> grup->setMethod((cast)::dlsym(..))
                       (GroupItem::setMethod is hand-written, GroupItem.twk:1377)
               popP1/popP2b  stuff.parseMethod  -> DIRECT assignment + cast
                       (RuleStuff declares no setParseMethod)
               popP2f  grup.text = name         -> grup->setText(name)
             clang++ EXIT=0.
asOf:        2026-07-29
scope:       Three scopes tested: under `use`, plain-qualified with no `use` in scope,
             and after an intervening field mention. NOT tested: bare assignment inside
             a class's OWN method body (`this` scope). popP2f is what makes this a class
             and not a case -- setter dispatch is GENERAL, not special to fnptrs.
```
**Tony's 07-29 claim is CONFIRMED, and the condition is the useful part.** B0 §4 warned
that *"sometimes dispatches the setter"* would be worse than *"never does"* -- a trap that
passes review. It is not that trap: the two branches are **both correct**, and neither is
silent. A missing setter does not produce a no-op, it produces a direct store.

The consequence Clay flagged holds: **every explicit `setX(...)` call in the tree is
optional where a setter exists.** That sweep is a consequence, not B0.

---

### CLAIM TOK-4
```
statement:   An incant-level local referenced ONLY inside a `-% %-` passthrough is pruned
             as unused, taking its initializing call with it, leaving the passthrough
             referencing an undeclared C++ identifier.
confidence:  RUN -- but asOf 2026-07-02, NOT re-run today.
provenance:  CLAUDE.md bear-trap #13. Real tok/compiler output on two separate hits:
             `use of undeclared identifier 'c'`, and tok's own
             `Declarations ignored because not used: N`.
asOf:        2026-07-02
scope:       Recorded boundary, and it already exists in CLAUDE.md: a variable is safe
             if something OUTSIDE the passthrough also references it. Parameters are
             always safe. The contrast case is named -- `setFont` did not need the fix
             because `hold((void*)font); object = font;` follows the passthrough.
signed:      --          [PROPOSED field, SEQ 30a, UNRULED. See note below.]
```
**SURVIVES the TOK-1 correction, and B0 §4 protects it deliberately.** TOK-1 kills
`setParseMethod`'s *justification*, and probably its *instance* -- it does not touch this
mechanism. Take the distinctions, check the attributions: do not let a good correction
take a sound neighbour down with it.

**Boundary note for SEQ 30a Q1:** this was **probed by contrast, not by exhaustion** --
two failing cases and one named working case. That is a real boundary and it was
recorded; what dropped it was the one-line summary in `wakeup.md`, not the claim.

---

### CLAIM TOK-5 — a correction to B0 §4-P2, found by the POP it commissioned
```
statement:   In `ruleMethod`, the bare `method =` binds to `grup`, NOT to `input`.
             tok resolves a bare field against the MOST RECENTLY MENTIONED field, and
             `GroupItem grup = parent;` sits between the `use input` and the assignment.
confidence:  RUN
provenance:  popB0.mm --
               popP2d  `use input` + a later `grup = parent` + bare `method =`
                       -> grup->setMethod(...)      <- matches GroupRules.mm:5632 exactly
               popP2e  `use input`, no later mention, bare `method =`
                       -> input->setMethod(...)
             clang++ EXIT=0.
asOf:        2026-07-29
scope:       This is tok's last-mentioned-wins field resolution, not `use` scoping.
```
**This dissolves B0 §4-P2's stated hazard.** The brief warned that *"both `ruleMethod`
lines sit inside `use input`, so `method =` resolves against `input`, not `this`"*, and
that *"a POP written outside a `use` block tests a different construct."* Neither holds:
`use` is not what binds here, so the outside-a-`use` POP (popP2b/popP2c) tests the same
construct. **Same family as the two corrections in wakeup.md** -- a structural claim held,
a claim about what is in the tree needed checking.

---

## Format verdict — B0's acceptance test

**The format did not have to be bent.** Five real claims, five records, no field left
unusable and no claim needing a field the format lacks.

`scope` earned its place twice and would have been the difference both times:
- **TOK-2** without `scope` reads as *"argument position works"* and licenses the
  juxtaposed-concat construct that is still broken. That is precisely the
  conditional-claim-that-passes-review failure the field exists to stop.
- **TOK-3** without `scope` reads as *"assignment always calls the setter"*, which is
  false for half the cases measured in the same run.

`confidence` earned its place once, on **TOK-4**: RUN with a stale `asOf` is a different
and more useful statement than either RUN or ASSUMED alone.

**⚠ THESE CLAIMS NOW OWE A `verifier:` FIELD** (`docs/mdReorgB0.md` §2, added
2026-07-29). A RUN claim whose verifier has been deleted is not RUN anymore --
not false, no longer provable. TOK-1/2/3/5 stand on `scratchpad/popB0.twk`, which
is reproduced in this file precisely so the verifier cannot vanish with the
scratchpad. **TOK-4 has no live verifier** and its `asOf` is 2026-07-02.

**Adjacency is not provenance, demonstrated:** TOK-1's false justification sits in a
doc-comment whose *other* two sentences (bear-trap #13, bear-trap #14 stderr) are both
sound. One paragraph, three claims, one false.

## Open — the `signed:` field is PROPOSED and UNRULED

SEQ 30a proposes that a limitation (negative) claim may be PROPOSED by a minion but only
CLOSED by Tony, via a greppable `signed:` field, `--` until he replaces it. Shown on
TOK-4 as the one negative claim in this sweep. **Not adopted** -- it is under three-way
discussion and is recorded here so it is visible, not so it is absorbed.

The argument for it, which stands on its own: a positive claim is proved by one working
example; a negative claim is never proved by one failing example. Every bear trap is a
negative claim. And B0's own method -- *query first, grep for a counterexample* -- does
**not** transfer to traps: a recorded trap causes avoidance, so no counterexample is ever
written, the grep comes back empty, and the empty grep reads as confirmation.

---

## The POP source, reproduced so the run survives the scratchpad

```
include /Users/anthony/Dropbox/data/InProcess/Groups/groupIncludes

class PopB0
{
    int dummy;
}

extern int popP1(RuleStuff stuff, String name)      /* assignment under `use` */
{
use stuff
    parseMethod = dlsym(RTLD_SELF,name);
    return 1;
}

extern int popP2b(RuleStuff stuff, String name)     /* plain qualified, no `use` */
{
    stuff.parseMethod = dlsym(RTLD_SELF,name);
    return 1;
}

extern int popP2c(GroupItem grup, String name)      /* class that HAS a setter */
{
    grup.method = dlsym(RTLD_SELF,name);
    return 1;
}

extern int popP2d(GroupItem input, String name)     /* ruleMethod's own shape */
{
use input
    GroupItem   grup = parent;
    method = dlsym(RTLD_SELF,name);
    return 1;
}

extern int popP2e(GroupItem input, String name)     /* `use` with no later mention */
{
use input
    method = dlsym(RTLD_SELF,name);
    return 1;
}

extern int popP2f(GroupItem grup, String name)      /* non-fnptr setter-bearing field */
{
    grup.text = name;
    return 1;
}

extern int popP3(GroupItem grup, String name)       /* dlsym in argument position */
{
    grup.setOperat(dlsym(RTLD_SELF,name));
    return 1;
}
```
Reproduce: drop that in a scratch dir, `tok popB0.twk`, then
```
clang++ -fsyntax-only -x objective-c++ -std=c++17 \
  -I ~/Dropbox/data/InProcess/Groups -I ~/Dropbox/data/InProcess/Include \
  -I ~/data/support/Frame -I ~/data/support/Include -I ~/data/support/Maps popB0.mm
```
The dummy `class PopB0` is load-bearing: without a class in the file tok parses every
extern, prints `ERROR outputting class`, and **writes no `.mm` at all** while still
exiting 0. Exit-status doctrine, one layer down -- check that the artifact exists.

**Nothing in the repo build was touched.** No `tok GroupRules.twk`, no `tokall`
(Tony's Group-A files are still uncommitted), no rebuild.
