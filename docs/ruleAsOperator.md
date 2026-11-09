# A rule as an operator -- design recon (SEQ 578, 2026-11-09)

Read-only. Road: **kant**, new road (`incant/kantGrammar`) only. Trunk `13b1237a`, binary built bare. Every tap was a scratch
copy of kantGrammar loaded by path; `incant/kantGrammar` md5 15e4b965 unchanged. The notion is Tony's and Clay's and is
**not ruled**; it is recorded in `IncantForms/WorkingOn/macros` as a design notion, not scheduled.

**One plain line: a good direction for the regular rules -- five of them could lose their hand actions entirely and the
refusals would name the right thing for free -- but it does not reach the irregular ones, and the hard part (a keyword form in
the middle of an expression) is a grammar question about `;` that this does not solve.**

## What was measured

**A rule's label already IS its operand list.** Tapped at the top of each action, the label's children in order:

| rule | label children (measured) | the instruct's operands today |
|---|---|---|
| WHILe | EXPRESSIOn, STATEMENt | cond, body |
| Do | STATEMENt, EXPRESSIOn | body, cond |
| If | EXPRESSIOn, STATEMENt, ELSe (only when present) | cond, then, else? |
| FOr | LOOPEr, reversE (only when present), EXPRESSIOn, STATEMENt | cursor, source, body, rev? |
| ITERATe | ANYtoken, members (or attributes, only when present), ITERSOURCe | cursor, source, aOn, mOn |
| BRANCh | BRANCHEs, EXPRESSIOn (only when present) | the keyword, or [keyword, value?] |

Keyword terms (`while-`, `if-`) are no-label and never appear; an absent optional term is simply absent. So a default action
needs no slot declaration: it walks the label. And because a required term that is missing means the rule did not match, the
only refusal a default owes is **"slot X handed up no instruct"**.

**Declaring the op on the rule does not work today.** `op="whileLoop"` on WHILe's grammar line, or on a second mention
(`WHILe op="whileLoop";`, the shape `ELSEIf ruleMethod=If;` uses), becomes a TERM: WHILe stops matching and its action never
fires (`qa` stays 2; control without the line: fires, `qa` 3). `ruleMethod=` and `guard=` survive only because the define's
flag processing knows those names. The attribute is on the rule (a top-level read gives `whileLoop`); the rule just has a new
term.

## R3 -- the rules that build an instruct

| rule | op | operands = label order? | refusals today, by slot | what a default action could not cover |
|---|---|---|---|---|
| If, ELSEIf (one action) | ifThen | yes | then arm, else arm ("handed up no instruct"); the condition only through `+%` naming `ifArms` (F-148) | nothing |
| WHILe | whileLoop | yes | body; the condition through `+%` naming `whileArms` | `loopOwnsBody(*built)` after the build |
| Do | doLoop | yes | body; the condition naming `doArms` | `loopOwnsBody` |
| STARt | seq | yes -- every child, a variadic slot | none | nothing |
| BLOCk | seq | yes -- variadic | none | nothing |
| FOr | forLoop | **no**: `<-` sits second in the label and rides last, as a presence mark | body; restrict (parked, refused by name); source naming `forArms` | the `<-` mark, LOOPRESTRICt's refusal, `loopOwnsBody` |
| ITERATe | iterateOn | **no**: the filters become two counts after the source | cursor, source ("handed up nothing") | the filter counts, the source star built as a deref instruct |
| BRANCh | branchSignal | **no**: the operand's shape depends on the keyword | none of its own (TOPSTATEMENt refuses a top-level branch) | the return value arm |
| PRINt, CERr, COUt | printList / cerrList / coutList | no: items are flattened (ADJACENt spread, empty items dropped) | none | already share `makePrint` |
| SHORTCUt | printShortcut | no: its operand is a copy of matched text | none | the text copy |
| SEARCh, DEBUg, SCOPEXp | runRule | no: the operand is the label bound to a C++ method | none | uniform among the three: a second default ("bridge") would cover them |
| INVOKEr | call or `=[` | no: the op depends on the bracket | the ADJACENt argument (in EXPRESSIOn) | the bracket choice |
| XPRESs | (hands up its child's) | -- | -- | it builds nothing |
| TOPSTATEMENt | (runs, does not build) | -- | top-level branch | it is a runner |
| EXPRESSIOn | the chain | -- | many | see R4 |

**How many need no hand action at all:** three with the plain default (If with ELSEIf, STARt, BLOCk); **five** if the op can
carry "owns its body" so the default calls `loopOwnsBody` (adds WHILe, Do); **eight** with a second "bridge" default (adds
SEARCh, DEBUg, SCOPEXp). The rest keep hand actions. Measured in kantGrammar's live region: its actions total 480 lines (EXPRESSIOn alone 156); the removable bodies are 53 lines (plain default), 95 (with the loop trait), 122 (with the bridge default) -- before adding the default action itself, about 25 lines by estimate.

**A side gain:** a default that refuses by slot label would name `EXPRESSIOn` where the F-147 cure today names the internal
list (`REFUSED whileArms -- Operator +% -- an operand that is nothing`) -- that is docket F-148, cured as a by-product. It is
also a mover: refusedCondT's eleven rows, ruleIfT RI-C and ruleForT RF-O pin those words.

## R4 -- EXPRESSIOn

Today it does seven jobs in one walk: (1) tell operator from operand (`prevOp`); (2) prefix runs, `-` to negate and `*` to
deref, nested (SEQ 571); (3) bind a call's method and refuse a call whose argument is an ADJACENt run; (4) ADJACENt runs, refused
when they meet an operator; (5) the arithmetic tier, folded at once; (6) the compare, logic and assign tiers, each parked in a
pending slot, with the chain refusal (SEQ 570) and the assign target's allow-list; (7) closing the slots.

**If prefix and mixfix forms were rules,** (2) leaves -- a prefix rule (`UnaryOPS+ TOKEn`) builds the nest -- and (3) is
already INVOKEr's. ⚠ The old grammar had exactly that prefix rule (`UnaryXP`) and stroke 4 (SEQ 361) took it out in favour of a
flat run read by position; that was the old road, but it is the precedent to read before putting one back. **An infix-only
EXPRESSIOn keeps** (1), (4) unless adjacency also becomes a rule, (5), (6) and (7): operand / operator alternation and the four
tiers. That is about two thirds of today's action, so the narrowing is real but modest.

## R5 -- a keyword form in operand position (measured, not resolved)

Today, on the new road, `qr = if qa; 1 else 2;`, the same in parentheses, and `qr = while qa; 1;` **build nothing, silently**:
STARt hands back an empty node, no refusal, exit 0, `qr` untouched. The statement form `if qa; qr = 1; else qr = 2;` builds and
runs. Two things would be needed:

- **A grammar path.** `if` is an ANYtoken today (keywords are not reserved), so a control rule would have to be tried as a TOKEn
  before ANYtoken, guarded by its keyword.
- **A `;` that means one thing.** If's grammar is `if- EXPRESSIOn SemI- STATEMENt ELSe?`. In operand position the `;` after the
  condition is also what ends the enclosing statement, and the then arm is a STATEMENt that wants its own `;`, so
  `x = if a; 1; else 2;` leaves the outer statement without one. The choices: operand-position forms take braces only; a
  separate expression form with no `;` (`if a then 1 else 2`); or the outer statement's `;` made optional after a keyword form.
  Each is a ruling.

## R6 -- how a rule could declare its op

1. **An attribute on the rule (`op=`).** Measured: today it becomes a term. It needs the define's flag processing to know `op`,
   as it knows `ruleMethod` and `guard` -- one recognised name, C++, small; reaches no frame, ruler slot or gJitMethod.
2. **The Operators entry names its rule** (`whileLoop operateMethod=opWhile rule="WHILe"`). Operators entries already carry
   attributes (`compareTier`, `assignTier`); the default action finds its op by the label's tag. No engine change; a lookup by
   a computed name.
3. **A small kant registry, `RuleOps`, rule name to op name.** Measured: it reads back at the top level (`whileLoop`). Read
   from inside the action by a CAPTURED name (`RuleOps[tapT]`) it read nothing in the two spellings tried, while the literal
   `Operators["whileLoop"]` control read fine -- the spelling of a subscript by a computed name is open, and shapes 2 and 3 both
   need it.

## R7 -- the first proof, pre-registered, not built

**WHILe**, its hand action deleted, a shared default action bound by `WHILe ruleMethod=<default>;` (the ELSEIf shape), its op
declared by whichever spelling Tony rules.

- **Rows first, on trunk:** WHILe's own body refusal ("handed up no instruct") is pinned by **no fleet row** today -- add it
  (old road and new road). whileT WH-0..WH-8 and WH-8S (both roads) must not move.
- **Registered movers:** refusedCondT RC-While (`whileArms` becomes the slot's name); the two pop.sh rows that count
  Operators entries (`whileLoop` registered, 7682 and 8945) if spelling 2 adds attributes there, or a registry census row if
  spelling 3 adds `RuleOps`.
- **H7:** the default's slot walk removed -> WHILe builds nothing, whileT's new-road rows go red, the old-road rows hold.

## R8 -- against the plan's "expressions stay chains, statements become lists"

The notion keeps the plan's line and sharpens it. Statements are already lists -- a seq instruct with a list operand -- and a
mixfix rule's instruct is the same shape: one op, its operands a list built from the rule's slots. Making the build generic
does not change what is built, only who writes it, so it does not cross the line. Expressions stay chains, and EXPRESSIOn
narrowing to infix keeps it the only chain builder. The line it would cross is R5: a keyword form in operand position puts a
statement-shaped instruct inside a chain. The engine can already run that (testOP runs any instruct), but the grammar and `;`
are not ready, and the plan never ruled on it.
