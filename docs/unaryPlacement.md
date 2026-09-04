# C-163 — `UnaryOPS` PLACEMENT RECON

**Read-only, 2026-09-04. No grammar, action or fixture was edited.** The deliverable is a sketch
for Tony and Clay to argue with; the build is its own stroke after a ruling.

---

## §0 THE HEADLINE, BECAUSE IT CHANGES THE QUESTION

**The asymmetry is not where the unary sits. It is that the DOT and the SUBSCRIPT are different
KINDS of thing, and the unary is only outside one of them.**

```
TokenXP   UnaryOPS? ANYorNum^ InvokeArg?          incant/grammar:138
InvokeArg   Braced "[" ExpressioN "]" | Parens | UnaryXP
ANYorNum    NumbeR | ANYtoken            ANYtoken = NamE
NamE        first-=[a-zA-Z] nameSet-^*   nameSet = [a-zA-Z0-9]     <- NO DOT
```

- **The subscript is INSIDE the term.** `InvokeArg?` is a sibling of `ANYorNum` in one `TokenXP`,
  so `*a[0]` is one term and the star binds to the name → `(*a)[0]`. **Law 3, and it is structural.**
- **The dot is BETWEEN terms.** `nameSet` has no `.`, so `a.b` is not one name. `.` is registered
  **`operateMethod=opDot`** (`incant/setup:181`) **and is a member of the `UnaryOPS` bin**
  (`incant/setup:255`). So `.b` can itself be a `TokenXP` whose unary is `.`, resolved through
  `lastREF` by `opDot`'s bare-accessor fixup. `*a.b` is therefore **two terms**, and KANT-43's
  right-to-left association applies the star **last** → `*(a.b)`.

⚠ **`.` BEING IN BOTH PLACES IS THE LOAD-BEARING FACT AND IT IS EASY TO MISS.** It is the only
token that is both an operator and a unary, which is exactly what makes the bare accessor work —
and exactly what makes a leading unary reach the wrong operand.

**So "move the unary inside the dotted term" has no dotted term to move into.** Option A below is
re-scoped accordingly, and that re-scoping is this recon's main result.

---

## §1 THE ROAD AS IT IS

### §1a Where each piece lives

| piece | site |
|---|---|
| `TokenXP UnaryOPS? ANYorNum^ InvokeArg?` | `incant/grammar:138` |
| `UnaryXP UnaryOPS ANYtoken` (mandatory unary) | `incant/grammar:129` |
| `IterSource UnaryOPS? ANYtoken` — iterate's own slot | `incant/grammar:130` |
| `UnaryOPS` bin: `-- - ++ @ ! $$ * .` | `incant/setup:247-255` |
| `'.' operateMethod=opDot` | `incant/setup:181` |
| `NamE` — **governing construction is C++**, the grammar line is an inert mirror | `GroupMain.twk`, and `incant/grammar:34-40` says so |

⚠ **The `^` on `ANYorNum^` is `noSkip`, not a dot mechanism.** It stops whitespace being skipped
before the name; it does not glue a path together.

### §1b The second unary — THE DROP SITE, NAMED

S3a measured that `**x` behaves as exactly one star and left *where* undiagnosed. **Measured
2026-09-04, and it is not a silent drop:**

```
G1  *uxHold     ERROR unary * on uxSrc -- it holds no group        -> 0
G2  **uxHold    ERROR unary * on uxSrc -- it holds no group
                ERROR Operator * failed on Token and a refused operand
G3  * *uxHold   identical pair -- spacing is irrelevant
```

**`UnaryOPS?` is singular, so the second `*` cannot join the same `TokenXP`. It falls out to the
`Operators` alternative of `Token` (`grammar:139-143`) and runs as a BINARY multiply**, which fails
for want of a usable left operand and says so by name.

⚠ **WHY S3a SAW NOTHING.** Its run was flip-ON, where the star **succeeds**, so there was no
`unary *` refusal to notice — and the message that does appear names **`Operator *`**, a different
string it was not looking for. **The second unary was never dropped; it was mis-parsed into a
binary and its failure was reported under another name.**

### §1c What the consumers assume

- **`opDot`** (`Instruct.rtn:327-345`) — the jitting gate returns `jitEmitDot` **before** the
  bare-accessor fixup at `:331`, so a starred operand never reaches the fixup on the JIT road at
  all. Interpreted, the fixup takes `lastREF.group` when `argument` is absent.
- **`jitEmitDot`** — bakes `argument` as a **constant address at emit time**, carries **no
  `jitDegrade`**. A null left operand is baked as null. (F-54.)
- **`jitEmitUnary`** — reached from `opPlusPlus`/`opMinusMinus` only for the **non-iterator** arm;
  the iterator arm goes to `jitEmitIterStep`/`…Back`, which emit a call to the interpreter's own
  function (bear-trap #46).

---

## §2 THE UNARY CENSUS

Live sites, `incant/ genLadder/ minionWork/`, comment and prose lines excluded.

| unary | sites | on a plain name | on a dotted operand **today** | if the rule generalised |
|---|---|---|---|---|
| `*` | **312** | deref one holder level | applies to the **accessor result** — `*(a.b)` | should apply to `a`, then `.b` on the target |
| `++` | **208** | advance an iterator / increment | `++grup.next` reads as `++(grup.next)` — increments the ACCESSOR RESULT | ⚠ **the one to think about**: almost certainly means *advance `grup`, then read `.next`* |
| `-` unary | **111** | negate | negates the accessor result | probably correct as-is |
| `!` | **83** | logical not | nots the accessor result | probably correct as-is |
| `@` | **28** | aim `lastREF` at the operand | aims at the accessor result | should aim at the field |
| `--` | **25** | retreat / decrement | as `++` | as `++` |
| `$$` | **0** | debug marker | — | — |

⚠ **`*` and `++` together are 520 of the 767 sites, and they are the two whose current dotted
reading is wrong.** `-` and `!` want the accessor result and are already right, which is why this
has never bitten in arithmetic.

---

## §3 THE SKETCH

### §3a Option A — placement only, RE-SCOPED

**The original phrasing — "move the unary inside the dotted term" — has no referent**, per §0. The
only placement change that means anything is to **make the dot a term-internal construct like the
subscript**, i.e. give `TokenXP` a dotted tail:

```
    TokenXP     UnaryOPS? ANYorNum^ DottedTail* InvokeArg?;
    DottedTail  dot-="." ANYorNum^;
```

- **Consequence:** `*a.b` becomes ONE term. The unary binds before the tail, giving `(*a).b` — dot
  now agrees with subscript.
- **Parse actions:** `aCTionTokenXP`'s arm must walk `DottedTail*` and chain `opDot` itself rather
  than leaving `.` to the expression. **This is the expensive part** — the dot stops being an
  operator in that position.
- ⚠ **It collides with the bare accessor.** `.taG` with no left operand is today a `TokenXP` whose
  unary is `.`; under A the leading `.` must still parse that way, so `.` stays in `UnaryOPS` **and**
  becomes a tail marker. Two roles, one token, in one rule — the one-channel-one-meaning hazard,
  and the reason A is not obviously cheap.
- **Still one unary.** `**x` unchanged.
- **JIT:** `jitEmitDot` unaffected in shape; it would receive a real node more often.
- **groups.ext/extern:** none.

### §3b Option B — placement plus composition

```
    TokenXP     UnaryOPS* ANYorNum^ DottedTail* InvokeArg?;
```

- `UnaryOPS?` → `UnaryOPS*`, so `**x`, `@*x`, `!*x` parse as one term with a unary **list**,
  applied **innermost-first**.
- **Parse action:** the arm builds a chain rather than a pair — this is where "unary + operand
  becomes a parse fact" changes shape.
- **`interpretXP`:** must fold the list right-to-left over the operand instead of pairing once.
- **JIT:** `jitEmitUnary` is per-op and composes for free **if** the fold is done before emit;
  nothing new needed if the chain is walked in `interpretXP`.
- **Removes the §1b failure entirely** — no leftover falls to `Operators`, so
  `ERROR Operator * failed on Token` for a doubled unary disappears by construction.
- **groups.ext/extern:** none.

### §3c Blast radius, from the census

```
  *<name>.<accessor> :  4 sites, 2 files    3x *argument.taG   1x *grup.tag
                        ALL in IncantForms/ -- incant++ (Tony's WIP), Notions/fonting
                        NOT ONE in the live corpus, the fleet, or the harnesses
  *<name>[...]       :  2 sites             pointerT law-3 tripwire, one harness marker
```

**Nothing that runs today depends on the current dotted reading.** The 520 `*`/`++` sites are all
on **plain names**, where A and B change nothing.

⚠ **The exception is `pointerT`'s law-3 rows, which pin the CURRENT behaviour deliberately** — they
are the fixtures that must be re-pinned with sentences, not the ones that would break by accident.

---

## §4 THE PRE-REGISTERED CERTIFICATE

Written now so the review can argue with it.

| row | expected |
|---|---|
| `*argument.taG` | reads **the source**, both arms |
| `*a[0]` | **unchanged** — law 3 still binds the star to the bag |
| `starT` **S2b** | **goes GREEN** — but **only under B**; it is ruled red until composition works |
| `@*argument` re-aims after a call | works **only under B**; today it does not re-aim at all (C-161 pre-flight F4) |
| `spacingT` G/G2 | **unchanged at 12** |
| `pointerT` law-3 rows | **re-pinned with sentences** (H6), not silently |
| fleet | moved-set **enumerated**, every row explained |
| canary | **named**, read off the tree that stroke (H14) |
| `++grup.next` | ⚠ **decide before building** — §2 says its meaning changes under both options, and there are 208 `++` sites to be sure about |

⚠ **AND A ROW THE CHARTER DID NOT ASK FOR, WHICH THIS RECON THINKS IS THE REAL GATE:** the
`ERROR Operator * failed on Token and a refused operand` line from §1b should **vanish** under B and
**persist** under A. It is the cheapest discriminator between the two options and it exists today.
