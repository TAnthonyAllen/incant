# Borrowed ideas: what other languages have that kant does not

**Every "existing machinery" claim in this file is from the project record (CLAUDE.md, the topic files, the seals),
NOT checked against the tree. A read-only check comes before any design on it.**

Notes only (SEQ 793, 2026-11-27; Tony's dispatch via Clay). Nothing here is ruled, scheduled or built. A long-term
goal: take the best computational ideas of Forth, Self, Smalltalk, Scheme, Prolog and APL, not the languages. Tony's
write-up with ChatGPT listed thirteen languages; Clod's reading is that Tony's six cover the ground, and that the
agenda is better kept by missing primitive than by language. The parking line is `Topics/features` item 41.

## The four missing primitives

| missing primitive | why it is missing today | what it would unlock | already on the list as |
|---|---|---|---|
| A frame that outlives its call | a local is one node, blanked on entry and restored on exit (saveLocalFields) | closures, continuations, generators, recursion, Erlang-style entities | features 24 |
| Undo on failure | old-road actions fire during the parse, so a failed branch leaves its side effects | Prolog search, unification | features 1 (parse-then-fire), 21 |
| Aggregates as operands | pour is not designed yet | APL, laziness, parallel order | the source / pour exercise (docs/sourcePourRecon.md) |
| Declared effects and signatures | `argument` is the caller's own field; a callee can write a caller's local by name; a header word is not a parameter (bear-trap 61); `f(a, b)` is refused | stack-effect checking, purity, ownership | nothing yet |

**Undo on failure, second half (Clay).** Rules match text. Unification needs a rule over a field's attributes and
members, and a kant action that can reject a match (`IncantForms/WorkingOn/macros`, open question 1; features 21).

**The new road (Clay).** Its actions only build an instruct, so nothing fires during its parse. The side-effect half
of "undo on failure" is an old-road problem.

## What incant already has

- **Forth:** kant has no precedence and runs right to left over instruct chains. Features 40 (a tiny stack language
  as a template) is already this idea.
- **Self:** `copyOf` shares its source's attributes, close to a prototype. Missing: the fall-through, a lookup that
  misses on a field going on to ask its prototype.
- **Smalltalk:** listeners and middlemen intercept. "A call with nothing to call refuses by name" (seal 504) is the
  seat where an unrecognised-message handler would hook.
- **Prolog:** rules are AND over attributes and OR over members, and the parser backtracks. The attach-at-success law
  (Ruling E-A) is Prolog's undo discipline, for structure only.
- **APL:** pour; and operators already pick an arm by kind, so a group arm on `+` would be elementwise add.
- **ML:** the kant jitter's kind pass (krResolve) is a small type inference, its tables held as data in
  `incant/setup`.

**A speculation, not a lead:** a field with no data reads as its own name (bear-trap 26), which is how an unbound
Prolog variable behaves. Recorded as a speculation only.

## What should influence decisions now, with nothing built

1. The source / pour exercise is where APL lands. Decide there whether a pour promises an order, whether a source can
   yield on demand, and whether reduce and scan are pours (added to docs/sourcePourRecon.md, "Open for the exercise").
2. Slot locals in the kant jitter are already real stack frames. Do not design them so they can never be kept after
   the call.
3. Keep the instruct chain immutable and shareable. A closure is then one chain plus a different frame.
4. Signatures and effects should be data on the action's own line, the way the kind tables are. The jitter's
   sure-kind pass would use them straight away.
5. Parse-then-fire is on the critical path to Prolog, which raises its value.

## Concurrency blockers

One `lastREF` for the whole run; one search list; a collector whose `operator new` has no thread check (seal 417).
Each stands in the way of anything concurrent (Erlang-style entities, parallel pours).

## Before any design

A read-only check of every row above against the tree. The "existing machinery" column of the ChatGPT write-up is from
memory of conversations, and this file's is from the record; neither was measured.
