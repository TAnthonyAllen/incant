# fieldNav — a path/visitor vocabulary over GroupItem trees

*2026-06-29. Design thread, Clod owns the semantics; **surface syntax is Tony's call**
(every token below is a proposal, not a decision — see §7). Seeded now because the
virtual-tag + `defining`-gate fix (commit 504d87f) makes corpus reads reliable, and the
four corpus operations all need traversal. Audience: Tony, Clay, Clod.*

---

## 1. Why this exists

Every one of the four corpus operations (`docs/minion-corpus-format.md` §"four operations")
is a **traverse → access → test → maybe-mutate** pass over the `minion` GroupItem tree:

| op | traversal | access | mutate |
|---|---|---|---|
| **Query** | walk `claims` | read `confidence`, `text`, `provenance` | — |
| **Absorb** | locate claim by `id` (or make one) | read to dedup | set `confidence`/`provenance`/`asOf`; maybe `supersedes` |
| **Bake** | walk all `claims` | read `asOf` | refresh `asOf`, age stale, append `sources`, set `lastBaked` |
| **Challenge** | walk related `claims` | read for conflict | conditional absorb |

Today every one of these is hand-rolled. `incant/jiquery`'s `findRefuted` is the canonical
example — `for grup in claims; if grup.confidence == "refuted"; …`. The recon
(`acb734ae`) found the same shape repeated across `utilities` (`flatten`, `listRules`,
`toXML`, `setFrame`) and the `generate.rtn` walkers. **fieldNav is the reusable vocabulary
those hand-rolls collapse into.** It is to tree traversal what the operators are to
arithmetic: a small, composable, homoiconic algebra.

---

## 2. The grain to fit (from the recon)

fieldNav must not invent parallel machinery. It maps onto what exists:

- **Engine:** `walk()` (GroupItem.twk:1455) — depth-first, members→attributes, parent
  re-entry, safe `nextInParent`/`priorInParent` links. The descend step compiles to `walk()`;
  the single-level step to a `nextMember`/`nextAttribute` loop.
- **Accessors:** `.` opDot (members + attributes + GroupFields), `=/` opGetMember
  (members only), `=%` opGetAttribute (attributes only), `[ ]` index (position or name).
  These are the per-step landing operations.
- **Predicates:** reuse the expression machinery. `confidence == "refuted"` is already a
  GroupItem expression tree evaluated by opEQ/`compareValues` (GroupItem.mm:93). A filter
  step carries such an expression as a sub-field and evaluates it against the current node.
- **Mutators broadcast already:** `+%`, `:+`, `:%` walk a list argument backward and apply
  to each (GroupRules.mm:2875/3711/3691). So an apply-write step over a node-set composes
  with existing ops — no new broadcast primitive.
- **The read/write mode bit is `defining`** (the §3 spine).

---

## 3. The spine: read vs write = `defining` off vs on

This is why the work is hot now. The virtual-tag fix (`aCTionNamE`, ruleActions.rtn:516)
gated virtual-copy on `defining`:

- **Read path** (`defining` off) — naming a virtual field returns the *real* member, so a
  walk reads each claim's own `confidence`. Without the gate every read returned `0`.
- **Write path** (`defining` on) — naming a virtual field forks a fresh per-instance body,
  so a set lands on a distinct node, not a shared prototype.

fieldNav inherits this directly: **`select`/`filter` run with `defining` off** (read the
tree as it is); **apply-write steps run with `defining` on** (each touched node forks
correctly). `defining` stops being merely a parser flag and becomes fieldNav's mode bit. A
directive that reads must never run hot; a directive that writes repeated tags must.

---

## 4. The vocabulary — three composable verbs

A fieldNav directive is **itself a GroupItem** (homoiconic, §6): a `path` whose members are
ordered *steps*, optionally terminated by an *apply*. The path engine carries a **node-set**
(a list of GroupItems, initially `[root]`); each step transforms it.

### 4a. `select` — steps that move the node-set

| step (proposed token) | meaning | compiles to |
|---|---|---|
| `name` | members of each node tagged `name` | `getMember(name)` per node |
| `*` | all members of each node | `nextMember` loop |
| `**` | self + all descendants (depth-first) | `walk()` |
| `@name` / `@*` | attribute axis (one / all attributes) | `=%` / `nextAttribute` loop |
| `^` | parent of each node | `.parenT` |
| `#name` | a GroupField/flag (`#confidence` reads the field; `#isVirtual` a flag) | opDot via groupFields |

Steps chain: `claims / * / confidence` = "the confidence member of every member of claims".

### 4b. `filter` — narrow the node-set by a predicate

A `[ … ]` step carries a predicate expression evaluated against each node with that node as
scope (the `:` ScopeXP mechanism, GroupRules.mm:912, supplies the node's fields as locals):

```
claims / *[ confidence == "refuted" ]          ← the refuted claims
claims / *[ asOf < "2026-06-01" ]               ← claims aging past a date
```

Predicates are ordinary incant expressions (opEQ/opLT/AND/OR + the isX flag accessors), so
nothing new is parsed — a filter is "an expression step."

### 4c. `apply` — terminal visitor

Two kinds:

- **collect (read)** — return the node-set (or a projected field of it). `findRefuted`
  becomes `collect( claims / *[ confidence == "refuted" ] )`. Runs `defining` off.
- **set/add/replace (write)** — apply a mutation to each node in the set, reusing the
  existing ops. Runs `defining` on.
  - `set confidence = "refuted"` → opAssign per node
  - `set supersedes = id` ; `add sources <- file` (opAddAttribute) ;
    `replace claim` (`:+`, broadcast)

The visitor is a function-GroupItem; an apply step holds it as a sub-field, exactly the
"one method per field" dispatch idiom (CLAUDE.md). This is also where the existing
`spliceDirectives` structure-level infra (recon §6B) plugs in for range replace/delete,
which it can't express today (insert-only).

---

## 5. The four operations, in the vocabulary

```
Query      collect( claims / *[ confidence == "refuted" ] )           # respect-confidence read
Absorb     let c = claims / *[ id == newId ]  ?:  claims.new(newId)   # locate-or-make
           on c: set text=…, provenance=…, confidence=…, asOf=today   # write (defining on)
Bake       on  claims / *[ asOf < cutoff ]: set confidence="stale-suspect"
           on  minion: set lastBaked=today ; add sources <- newSource
Challenge  let hits = collect( claims / *[ conflictsWith(finding) ] ) # read
           if hits.bonesConfirm(finding): Absorb(verified) else Absorb(inferred)
```

`findRefuted` is the Query line, verbatim shape. That it already runs by hand (proven
2026-06-29) is the existence proof that the compile targets are all present.

---

## 6. The homoiconic payoff

Because a directive is a GroupItem tree (steps as members, predicates as expression
sub-trees, visitor as a method-field) — the same representation as bytecode ops walked by
`interpret()` — fieldNav directives are **constructable, inspectable, and rewritable by
incant code**. Consequences:

- A corpus can *store a directive as a claim's verification recipe* ("to re-confirm me, run
  this select+bones-check"). Challenge becomes data.
- Directives can be *generated* (a bake routine emits the select that refreshes itself).
- A directive can be *walked by fieldNav itself* — the vocabulary navigates its own trees,
  the reflexive property the whole language is built on.

This is the reason fieldNav must be GroupItem-shaped and not a string mini-language: strings
aren't walkable, rewritable, or storable as corpus structure.

---

## 7. Boundary — what's mine vs Tony's

**Mine (this doc):** the node-set algebra, the step/filter/apply semantics, the read/write =
`defining` mode rule, the compile targets onto walk()/opDot/mutators, the homoiconic
representation.

**Tony's:** every surface token. `/ * ** @ ^ # [ ]` are *placeholders chosen to read
clearly here* — Tony decides the actual grammar (and whether path-step uses `/`, which today
is opDiv, or a new separator). The semantics survive whatever syntax he picks; the tokens are
swappable.

---

## 8. Smallest first proof

Re-express `jiquery`'s `findRefuted` as a single `collect( claims / *[ confidence ==
"refuted" ] )` directive and run it against the live `jigcorpus` — same known answer
(`gifBranchPoison`). That exercises: a tag step, a `*` step, a filter predicate, and a
collect apply — the whole read half — against a real corpus, mapping onto `getMember` +
`nextMember` + opEQ + the `defining`-off read path. The write half (set/add over a node-set,
`defining` on) follows as Absorb's first proof. Build only after Tony rules on §7 syntax.

---

## 9. Open questions / risks

1. **Predicate scope mechanism.** §4b assumes `:` ScopeXP can expose a node's fields as
   predicate locals cleanly inside a step. Needs a spike — ScopeXP's duration is "per
   statement" (recon §2); a filter evaluated per-node may need a tighter binding.
2. **`:=` byRef stickiness (bear trap #3).** `let c = …` binding a node-set element must not
   stamp `byRef` such that a later `set` references instead of copies. Audit any `:=` in the
   bind step.
3. **Cycle handling.** `**`/walk() over a cyclic structure needs `listRules`' visited-set
   pattern (recon §6A) or it loops.
4. **Member vs attribute default.** The corpus puts claims *and* claim-fields as members, so
   the default axis is members; `@` reaches attributes. Confirm this matches how baked
   corpora will be shaped (vs GUI defs, which lean on attributes).
5. **`defining` toggling discipline.** A directive that both reads (filter) and writes
   (apply) flips `defining` mid-run. The engine must set it per-step, not per-directive, or a
   filter on the write side would wrongly fork. This is the subtlest part and the place a bug
   would hide.
```

*Deferred per the four-ops-first rule until 2026-06-29; Clay activated it while the machinery
is warm. Pairs with `docs/minion-corpus-format.md` (the trees fieldNav walks).*
