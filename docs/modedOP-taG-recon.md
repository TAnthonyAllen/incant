# modedOP.taG recon (2026-06-07, Tonto)

Pre-session recon for the **modedOP alias / WTF-proofing feature**. Question set:
can `.taG` be set/read on an operator field without interfering with
`gOp`/`isOperator` dispatch? What's the field shape after `operateMethod` binds it?
Is `.taG` already in use on that shape? Understanding-first; findings flagged,
nothing fixed.

## The operator field shape (`GroupBody.h`)

A `GroupBody` carries these members relevant here, **all physically separate**:

| member | what it is | operator uses it for |
|---|---|---|
| `char *tag` | the field's name/symbol | the operator **symbol** (`'>'`, `modedOP`) |
| union `gMethod` / **`gOp`** | `GroupItem*(*)(...)` fn-ptr | the bound **method** (`setFileOp`) — gOp |
| union `gText` / `gPointer` | text/pointer storage | (see tar baby #1) |
| union `gBuffer`/`gCount`/… | the data value | n/a for a bare operator |
| `bools flags` (bitfield) | `methodType:2`, `data:5`, … | `methodType==2` ⇒ `isOperator` |

Two facts that look alarming but aren't:
- **`isOperator` and `isCHAR` are both `== 2`** (GroupBody.h:81 vs :57) — but they
  test *different bitfields*: `isOperator(flags.methodType)` vs `isCHAR(flags.data)`.
  No collision.
- **`gMethod` and `gOp` are a union** — a field is a method **xor** an operator,
  never both. `setOperat` (GroupItem.twk:1248) writes `gOp` **and** sets
  `methodType=2` (`isOperator`) together.

## Answer 1 — dispatch is tag-blind ✅

`runOP` (GroupActions.rtn:650) is the operator dispatch. The decisive line:

```
if op.isOperator   result = op.operat(arg,target);   // :663
```

It keys on **`isOperator`** (the `methodType` flag) and **`operat`** (the gOp
fn-ptr). **The tag is never read at dispatch.** So setting or reading `.taG` on an
operator field does **not** interfere with `gOp`/`isOperator` dispatch — they're
independent storage and the dispatch path doesn't consult the tag.

(Confirms the shim contract too: `operat(arg,target)` ⇒ gOp signature is
`(argument, &target)`, matching `setFileOp` and `opAssign`.)

## Answer 2 — BUT tag IS the operator's matching identity ⚠️

The tag is dispatch-irrelevant but **recognition-critical**:
- The parser matches an operator by its **symbol** (the `Operators` registry is
  "unsorted, loaded descending for longest-match against the input stream" —
  setup comment). That symbol is the tag/text.
- **Guard derivation reads the tag's first char**: `guardSet += *item.tag`
  (GroupItem.twk:524, :718). The guard set is what tells the parser which
  alternatives are even worth trying for a given input char.

So changing an operator's `tag` changes **what input it matches** and **its guard
char** — without touching its dispatch. tag is load-bearing for *recognition*, not
*execution*.

## Answer 3 — is `.taG` already in use on operators? Yes, as the symbol ⚠️

The tag on an operator is not a free annotation slot — it **is** the operator: the
match key, the guard seed, plus the usual print/compare uses. No runtime `setTag`
path exists (grep clean) — tags are set at field creation, not mutated live.

## Implications for the alias / WTF-proofing feature

The feature presumably wants `modedOP` to be **self-documenting** ("what is this
operator currently bound to?") and/or **aliasable** (reach the same gOp by another
name). The recon says:

- **You cannot repurpose the single `tag` as a binding-label.** Setting
  `modedOP.taG = "setFile"` to show its current binding would also retarget what
  the *parser matches* (`setFile` instead of `modedOP`) and reseed its guard. Tag
  is identity, not annotation.
- **A current-binding label needs a separate slot.** Candidates, in rough order of
  cleanliness:
  1. A **sub-attribute child** (e.g. `modedOP.boundTo = "setFile"`) — the
     established incant idiom for "second invokable/inspectable behavior" (cf. the
     `interpret` sub-attribute pattern). Zero risk to dispatch or matching.
  2. The **`gText`/`gPointer` union** (tar baby #1) — physically free of `gOp`, but
     whether operators already use `gText` for anything is unverified.
- **"Alias = a second name for the same behavior"** is a *registration* question,
  not a tag-overload: register a second `Operators` entry whose `gOp` is the same
  (or shares via pointer). Not in scope of `.taG` at all.

## Tar babies / open questions (for the design pass)

1. **Is `gText`/`gPointer` actually free on a bare operator?** It's a separate
   union from `gOp`, but operators may stash their text representation there.
   Needs a one-field dump of a live operator (`dumpField('>')`) to confirm before
   anyone reaches for it.
2. **Which "alias" do we mean?** (a) a second *name* that dispatches to modedOP's
   current gOp, or (b) a human-readable *label* of what modedOP is currently bound
   to. Different mechanisms (registry entry vs. annotation slot). The brief says
   "alias / WTF-proofing" — possibly both; they don't share an implementation.
3. **FINDING — rebinding can't go through `=`.** The original sketch
   `modedOP = setFile;` will **not** rebind the gOp: `=`/`setContent` copies
   data+lists but **ignores `gMethod`/`gOp`** (see `[[setcontent-ignores-methods]]`).
   The working rebind path is `operateMethod=` → `setOperat(dlsym(name))` (what the
   current build does in setup). Any "writable from incant at runtime" story must
   route through `operateMethod`/`setOperat`, not assignment. This is the crux the
   WTF-proofing feature has to design around.

## One-line answer for the brief

`.taG` is **safe to read** and **dispatch-neutral to set** (runOP never reads it),
but it is **not a free slot** — it's the operator's match key and guard seed, so a
binding-label or alias must live in a *separate* slot (sub-attribute is cleanest),
and runtime rebinding must go through `operateMethod`/`setOperat`, never `=`.
