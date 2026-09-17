# The dot chain

**Built 2026-09-17.** This file is the argument; `foldDot` and `interpretXP` carry one-line
stump markers pointing here.

## The finding: the parse groups dots in PAIRS

`TokenXP  UnaryOPS? ANYorNum^ InvokeArg?` takes **one** leading unary and **one** postfix. So a
chain does not arrive one dot at a time. Measured with `measureTokenArm`:

| source | terms |
|---|---|
| `a.b` | one — `dot-COMPOSED primary=a` |
| `a.b.c` | two — `dot-COMPOSED primary=a`, then `unary-only primary=c unary=.` |
| `a.b.c.d` | two — `dot-COMPOSED primary=a`, then **`dot-COMPOSED primary=c unary=.`** |
| `a.b.c.d.e` | three — `a.b`, `.c.d`, `.e` |

⚠ **This falsified the premise the work started from.** The 2026-09-16 seal said a longer chain
*"needs a stack, because the walk is backward"* — `.d`, then `.c`, then the primary. **It does
not arrive that way.** `a.b.c.d` is two terms, and the second one is a whole dot expression
wearing a leading dot.

## Why wrapping was wrong, and what replaced it

The orphan for `a.b.c.d` is `.`(c.d). The original fold **wrapped** it — `xdot(., a.b, (c.d))` —
which hands `opDot` a **dot node as its right operand**, where it expects a name. The answer came
back `MIDVAL`, the value of `a.b`: the outer dot failed and yielded its left.

`foldDot` now **splices**: it pushes the left operand into the **innermost-left** position, giving
`((a.b).c).d`.

⚠ **A STACK WAS BUILT FOR THE THREE-TERM CASE AND WAS REMOVED.** `a.b.c.d.e` is the first chain
that produces three terms, and folding one pair of three leaves the other orphaned — which
**truncated the run at exit 0 with no sentinel**, where the base build answered `xl1`. A wrong
value is visible; a dead run at exit 0 is not. So `canFold` gates the fold to two-term chains and
five names keeps the answer it always had. fixIts F-80.

## Two guards that are not optional

Both were paid for with a crash and a silent truncation:

- **`if operand.groupList` before reading `listLength`** — `listLength` dereferences `groupList`,
  which is **null on a leaf**, and the two-element chain reaches `foldDot` with exactly that.
  Exit 139. The raw field is what the runtime itself tests before walking.
- **`if !innerOp goto plainFold`** — the same class one level in.

## ⚠ The state it is in: four names work, five do not

| chain | before | after |
|---|---|---|
| `a.b.c` (three) | LEAFVAL — correct | LEAFVAL — unchanged |
| `a.b.c.d` (four) | **MIDVAL — wrong** | **TWIGVAL — correct** |
| `a.b.c.d.e` (five) | `xl1` — wrong, run completes | **`xl1` — unchanged, run completes** |

**Nothing regressed.** The intermediate build that carried the stack DID trade the wrong value for
a silent dead run, and that is why the stack is gone rather than shipped. `docs/fixIts.md` F-80
carries the limit. `incant/pop/dotChainT` stops at four names because a five-name row would take
the whole file hostage (rule H5).

## How the seed is proven

`DC-A`'s old wrong answer was **MIDVAL — exactly what an unseeded `dcTwig` also produces.** So
`DC-S` reads the tree stepwise through subscripts, where the answer is not in doubt, and is
checked before either chain row. Without it the two rows could pass or fail for the wrong reason.
