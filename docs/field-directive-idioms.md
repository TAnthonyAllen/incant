# Field-Directive Idioms — incant corpus mutation

*2026-06-30. The hard-won idioms for mutating a GroupItem corpus with field-substrate
directives (the minion **absorb**/**challenge** operations). Distilled from Tony's offline
chew + the `incant/jidirect` and `incant/jiabsorb` POPs against the live `incant/jigcorpus`.
Audience: Tony, Clay, Clod. Pairs with `docs/fieldnav-design.md` (the traversal vocabulary)
and `docs/minion-corpus-format.md` (the trees these mutate).*

These are the operators you reach for when an absorb/directive action reads, tests, inserts,
or removes a claim in a corpus group. Each one bit somebody; each worked example below is in
a probe you can run.

---

## ⚠️ HAZARD (audit-for): `:=` aliases live data — `=` copies

This is the load-bearing one. Get it wrong and you silently corrupt live corpus data.

- **`localField := something;`** puts `something` into `localField.group` — in effect it makes
  `localField` an **alias** for `something`. Every later reference to `localField` unwraps
  automatically to a reference to `something`. Mutating through the alias mutates the original.
- **`localField = something;`** **copies** `something`'s contents into `localField`. No aliasing;
  a write to `localField` does not touch `something`.

**Why this is a corpus-safety hazard, not a footnote.** A directive that means to take a *safe
working copy* of a claim but writes `:=` instead of `=` will alias straight into live corpus
data — and the next "scratch" mutation lands on the real tree with no copy in between. This is
the same risk `docs/fieldnav-design.md` §9 item 2 names ("`:=` byRef stickiness") and is rooted
in bear-trap #3 (CLAUDE.md): `:=` stamps `byRef` *permanently*, so even a later legitimate `=`
on that field references instead of copies.

**Audit rule:** every `:=` in absorb/directive/fieldNav code is a thing to check. If the intent
is "give me a handle to mutate the live corpus," `:=` is correct (that is the whole insert
idiom below). If the intent is "give me a safe copy to poke at," `:=` is a bug — use `=`.

The flip side is what makes `:=` *useful*: a live handle to a nested corpus group is exactly
`target := root.member` where `root` is a live-passed argument. `cg := argument.claims` inside
an action whose `argument` is the live corpus root gives a handle whose `+=`/`-=` mutations
**persist**. `=` there would hand you a copy that evaporates when the action returns.

---

## `<:` — retag an empty field into a free lookup key

To use a string as a *field* (not just a literal), retag a data-less field to that string:

```
nc <: "probeClaim";     // nc is local, never referenced -> no data; <: sets its tag
cg += nc;               // cg now has a member tagged probeClaim
```

`nc` here is a local field not yet referenced, so it carries **no data** (a cleared field
behaves identically). `<:` changes its tag to `probeClaim`, still with no data. And incant
returns `field.text == field.tag` when a field has no data — so the retagged field is a
working lookup key for free, no value assignment needed.

Worked example: `iInsert`/`tInsert` in `incant/jidirect` (the `nc <: "probeClaim"; cg += nc`
lines). Contrast `field = new("tag")`, which **reimprints the LHS tag** (bear-trap #1) — use
`<:` or `:= new("tag")`, never `=`, when the tag must survive.

---

## `!IN` — split into two lines (there is no `!IN` operator)

`!IN` is not a thing. To get "if NOT in list" behavior, split the membership test from the
negation across two statements:

```
target = target IN someList;    // target becomes the find result (member or empty)
if !target;                     // ... is then, in effect, `if !IN`
    print "absent";
```

Worked example: `tNotIn` in `incant/jidirect` (`nc = nc IN cg; if !nc;`). For the common
*dedup* shape specifically, you don't even need this — flip to `if cand IN cg; else` (see
Dedup below). The two-line split is the general technique for when you genuinely need the
negation.

---

## Insert / remove

- **Insert:** `target += field` (addMember). Tag `field` via `<:` or `:= new("tag")`.
- **Remove:** `target -= member` removes by `member.tag`. The member handle must keep its real
  tag, so get it with `:=` (`m := group.gifBranchPoison`), not `=`. As of commit **5bad124**
  the remove gate is `groupList` (was `binType`), so `-=` removes a member from *any*
  list-shaped group, not just `bin` lists — `jidirect`'s `tRemove` now genuinely deletes
  (len 7→6), which its older "binType no-op" comment predated.

Both proven 2026-06-29/30 against `incant/jigcorpus`.

---

## Dedup — works (`if cand IN cg; else insert`)

The closing half of absorb. Write the membership test in **natural order** — item on the left,
container on the right — and flip with `else` (no `!IN` needed):

```
cg := argument.claims;          // distinct handle name — NOT `claims` (self-collision)
cand := new("absorbedClaim");
if cand IN cg;     print "skip";   // already present -> dedup
else               cg += cand;     // absorb
```

Run `absorbClaim` twice: #1 absorbs, **#2 skips** (it finds the member #1 added), so `claims`
keeps exactly one `absorbedClaim`. Proven 2026-06-30 against `incant/jigcorpus`.

**What it took (the one-token `opIN` fix).** `opIN`'s list gate originally read
`or target.groupList → argument[target.tag]` — it gated on the **candidate** (`target`, the
left operand) having a list, but a freshly-built `cand` never carries one, so the lookup never
ran and absorb double-inserted. The operand convention is the trap: `runOP` invokes operators
as `op.operat(arg, target)` = **(right, left)**, so for `cand IN cg`, `target = cand` (item)
and `argument = cg` (container). The container is always the right operand. The fix gates on
the operand it actually indexes — the **container**:

```
or argument.groupList    result = argument[target.tag];     // Instruct.rtn — gate on the container
```

So `IN` now expresses "does this group contain a member with this tag" for any candidate,
constructed or live. (Contrast the pre-fix `tFind` `gbp IN cg`, which only worked because the
live member `gbp` happened to carry its own list and tripped the old candidate-side gate.) No
new `has`/`contains` keyword was needed — the gap was a bug in `IN`, not a missing predicate.

---

*POPs: `incant/jidirect` (raw operators: `:=` handle, `+=`, `-=`, `IN`, `!IN` split, `<:`),
`incant/jiabsorb` (absorb working end to end: insert + persist + dedup). Run with the
`incant/jigcorpus` corpus loaded (see `incant/setup` search list).*
