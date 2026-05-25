# bcOPs Fold into opFields — Design Note

*Drafted 2026-05-25. Implementation deferred until natural lull in Phase Bytecode work. This document captures the reasoning so it doesn't have to be re-derived.*

---

## The Question

Should the `bcOPs` registry (holding bytecode markers like `bcBR`, `bcBRZ`, `bcCALL`, `bcRET`) be folded into `opFields` (the same registry referenced from incant as `Operators`, holding source-level operators like `>`, `=`, `*`)?

## The 2026-04-27 Original Decision

The two registries were kept separate based on an audience argument: user code never writes `bcBR`, and an incant program walking `Operators` should not see bytecode markers. Different audiences, different exposures.

## What This Argument Missed

The audience-separation rationale assumed `bcOPs` and `opFields` held semantically different KINDS of things — that bcBR and `>` weren't just registry entries with different display purposes but were structurally different objects requiring different dispatch.

The 2026-05-25 architecture recon clarified that runtime dispatch goes through `runOP()` universally. `runOP` is called on every instruction. It handles each tuple's op slot by:

1. If op has a real method (operators like `>` or `=`), call it
2. If op is a dummy/marker (like `falseResult` or, post-fold, `bcCALL`), fall through to inspect target — if target has a method, run that

Bytecode markers like `bcCALL` aren't opcodes with their own runtime methods. They're MARKERS that signal "the op slot doesn't carry the work; the work is elsewhere in the tuple." Same as `falseResult` already works today.

Operators and markers are shape-cousins at the runtime level: both are tuple-op-slot entries, both are recognized by `runOP`. The visible difference is whether they carry a method or signal a marker shape. Putting them in the same registry doesn't conflate kinds — it reflects the truth that they're already siblings in dispatch.

## The Real Benefit of Folding

`opFields` is a base registry. Base registries are universally searched for bare-name lookups (see Bible Architecture: Name Resolution). When source code writes `'>'`, name resolution walks the base registries, finds `>` in `opFields`, returns the entry.

`bcOPs` is NOT a base registry. So today, if incant code writes `bcCALL` bare, name resolution does NOT find it. References to bytecode markers must go through explicit registry access (or are unsupported bare).

Folding `bcOPs` entries into `opFields` makes bytecode markers participate in bare-name resolution. After the fold:
- `bcCALL` bare resolves to the bcCALL entry, anywhere in incant code
- emitBC's lookups for bytecode mnemonics work via bare references
- The eventual bytecode interpret() loop can look up markers by bare name

This is concrete utility, not aesthetic cleanup. The fold earns its keep at the bare-name-resolution layer.

## Implementation Outline

When implementing (deferred):

1. **Move `bcOPs` entries into the `opFields` registry definition** in `XML/WorkingOn/setup`. The entries themselves don't need shape changes — they're already in fields/registry form. Just live in `opFields` rather than `bcOPs`.

2. **Update generation-side consumers** that explicitly look in `bcOPs` (if any do today; emitBC currently uses bare names like `emitBC(bcStoreField=tgt)` so likely no explicit registry-name reference). Grep for `bcOPs` references and update each.

3. **Update interpret-side consumers** when the bytecode interpret() loop is built out — marker-handling for `bcCALL` etc. goes in runOP's existing dummy-op fall-through, not in any per-marker dispatch.

4. **Remove the `bcOPs` registry** once references are migrated. Or leave as an empty alias if removal cascades.

## runOP Changes Required (When Interpret Work Begins)

The fold itself doesn't change `runOP` today. But when the bytecode interpret() loop is built out, `runOP`'s marker-handling needs extension:

- `bcCALL`: structural work — fall through to target, call target's method (covered by existing falseResult logic; bcCALL replaces falseResult as the explicit marker)
- `bcBR`: unconditional branch — needs interpret-loop-aware behavior (change instruction pointer based on bcBR's target operand)
- `bcBRZ`: conditional branch — interpret-loop-aware, check top of stack
- `bcRET`: return from generated action — pop call frame

Each of these is structural at the interpret-loop level rather than method-dispatch within runOP. runOP recognizes the marker tag and the interpret loop handles the semantics.

## What This Doesn't Solve

- Source code that walks `opFields` after the fold WILL see bcCALL. Code that wanted "only source-level operators" needs to filter by "has method" or by tag-naming convention. The audience-separation property is lost.
- Some existing tests or tooling may rely on the bcOPs name. Each reference needs updating.
- The bytecode short-doc atop `XML/WorkingOn/generate` describes bcOPs as a separate registry. Needs updating post-fold.

## When To Do This

After Brief 3 closes and before the bytecode interpret() loop work begins in earnest. The interpret loop will be cleaner if markers are bare-findable; deferring the fold past that point means writing interpret code that reaches around the gap.

Not blocking any current task. Not urgent. But the design clarity is durable; capture preserves it.
