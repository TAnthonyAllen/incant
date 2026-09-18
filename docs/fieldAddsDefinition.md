# fieldAddsDefinition — `field += <a field definition>`

**A docket card, 2026-09-18. Tony's brainstorm; Clod's sizing. NOTHING IS BUILT AND NOTHING
HERE IS MEASURED** — every claim below is a structural read of the grammar and the registries,
and this project's own ledger says a structural read is usually right and is still not a run.

---

## 1. Tony's brainstorm, his words

> *"I did have one late night brainstorm that might involve a subtle change to how incant works
> for consideration: righht now our model is feed incantations in to extend kant; it would be
> interesting to change that to: a field adds its own definitions. Think field += a field
> definition; Not sure about the grammar changes involved. But the gay icon would approve. Just
> saying."* — offline status, 2026-09-18

---

## 2. What it actually changes, and it is not syntax

**Today a definition's destination is AMBIENT.** `register(X)` or `registry(X)` sets a current
registry; `define` then adds every `DefinE` it parses to whatever that is, until the block ends.
The destination is a piece of state set somewhere above, and the definitions do not name it.

**Tony's form makes the destination the LEFT OPERAND.** `field += <definitions>` says where they
go at the site where they are written, and nothing ambient decides it.

⚠ **THAT IS THE SAME MOVE AS TODAY'S runRule WITHDRAWAL, one layer up, and it is the reason this
card is worth keeping rather than a syntax preference.** `runRule` was withdrawn from installing
a parse because generation must be explicit rather than folded into a gate. This is *definition*
becoming explicit rather than folded into ambient registry state. **Same doctrine, same
argument: the thing that decides where something lands should be visible at the line that puts
it there.**

**And it is the homoiconic claim cashed.** A GroupItem field IS the rule that describes it, so a
field taking definitions the way it takes attributes — `+%` for one attribute, `+=` for a block
of them — is the language saying about itself what the bible already says about it.

---

## 3. The grammar cost — smaller than it looks, and the cost is elsewhere

**What is already in place** (`incant/grammar`):

```
DefinE   NewGroup Attributes? MemberS endDefine-=[;>];
define   DEFINing-^ definitions=DefinE+ DEFINing- ';'-;
```

`define` is an ordinary **rule**, reached by naming it — and naming a rule fires it, in
statement position **and in operand position**, because `Xpress`/`ExpressioN` is a flat sequence
whose tokens include rule names. **So `field += define … ;` may need no new production at all.**
`+=` is already registered (`incant/setup:149`, `operateMethod=opPlusEQ`) and the right operand
firing the `define` rule is the ordinary mechanism, not an extension of it.

**⚠ GRADE: STRUCTURAL, NOT RUN.** It is one probe from being measured — write
`x += define y; ;` in a fixture and read what arrives at `opPlusEQ` — and nobody has written
that probe. Do not build on this paragraph before somebody does.

**Where the real cost is, and it is two places, neither of them the grammar:**

1. **`define`'s action must be able to RETURN its definitions instead of installing them.**
   Today it brackets the parse with `DEFINing` and the members land in the current registry as a
   side effect. Tony's form wants the block to *yield* a group. That is a second mode for one
   action — **and one channel carrying two meanings is this project's most expensive recurring
   defect**, five members in the ledger. So it is a **second verb or a second arm with its own
   flag**, never a conditional read of the existing one.
2. **`opPlusEQ` needs an arm for a group of definitions**, and it has to be distinguishable from
   the append/concat it already does. ⚠ **`+%` is the near neighbour** (`opAddAttribute`) and the
   discrimination between *"add one attribute"* and *"add a block of definitions"* is a design
   question, not an implementation detail. If the answer turns out to be that `+%` already does
   it for a group, the card gets much cheaper — **and that too is one probe.**

**One open question that is genuinely open:** what does the left operand become? A registry, or a
field with members? `registry(Grokking)` and `register(Utilities)` are different verbs today, and
this form collapses the distinction at the call site without saying which one it means.

---

## 4. What it would retire, if it lands

- **`register(X)` / `registry(X)` as ambient state** for any definition written this way. Not
  removed — the ambient form has the whole tree behind it — but it stops being the only road.
- ⚠ **The bootstrap does not move, and that is the constraint to state before anyone estimates.**
  `incant/setup`, `incant/grammar` and `GroupMain`'s hand-built definitions are what exist before
  there is a language to write this in. **A new definition form is for source that runs after the
  bootstrap, never for the bootstrap itself**, and a proposal that forgets this is proposing a
  rewrite of the seed.

---

## 5. Where it sits

**Gated behind station 6 and the JIT resume.** Both are load-bearing gates and neither is
arbitrary:

- **Station 6** — *the parse writes matched data into the label it minted* — is the frontier's
  live edge and is what F-83 is about. **Until a rule's body can see what it parsed, a new way of
  writing definitions adds a second unfinished road beside an unfinished one.**
- **The JIT resume**, because the definition road is on the hot path and a second mode through
  `opPlusEQ` is a jit-eligibility question the moment it exists.

**Two probes are cheap and can be run any time, ahead of the gates, because they cost a fixture
each and would size the whole card:**

1. Does `field += define … ;` parse today, and what arrives at `opPlusEQ`?
2. Does `+%` already accept a group of definitions, and if so what does it do with them?

**Neither is authorized by this card.** It is a docket entry; Tony schedules it.
