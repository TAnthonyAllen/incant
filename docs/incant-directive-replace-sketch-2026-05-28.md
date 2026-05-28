# Incant directive replace — design sketch, 2026-05-28

*Sketch, not plan. Working from: tok-directives-mechanism-recon-2026-05-28.md + the spliceDirectives infrastructure that landed this morning. Goal: lay out what enhanced incant needs to do to add `replace` to the directive mechanism, identify which primitives already exist and which are new, flag open design calls.*

---

## Surface syntax — proposal

Splice (current, working today):

```
targetAction += DiRSpliceThing;     // routes to applyDirectives via opPlusEQ DiR hook
```

Replace (proposed):

```
targetAction :+ DiRReplaceThing;    // routes to ReplaceDirective via opReplace DiR hook
```

Delete = replace with empty `to`:

```
targetAction :+ DiRDeleteThing;     // same operator, just `from` with empty/missing `to`
```

**One operator surface per semantic.** Each operator dispatches to its own apply-function based on DiR-prefix tag. Composition via multiple directives.

---

## Directive shape — proposal

Splice directive (already works):

```
DiRSpliceFoo {
    at = ending;
    /* body lines */
    spliceCode1;
    spliceCode2;
};
```

Replace directive (new shape):

```
DiRReplaceFoo {
    from {
        oldCode1;
        oldCode2;
    };
    to {
        newCode1;
        newCode2;
    };
};
```

`from` and `to` are sub-attributes of the directive, each holding a code-block.

Delete variant — same shape, `to` absent (or empty):

```
DiRDeleteFoo {
    from {
        oldCodeToRemove;
    };
};
```

**Why from/to as sub-attributes (rather than `match=` text or position-based addressing)**: keeps the pattern AST-native. The directive is incant; the pattern is incant; the replacement is incant. No text matching, no string anchors. The same code-is-data property that makes incant's BlocK manipulable also makes the directive's match pattern manipulable.

---

## opReplace's role — minimal extension

Current opReplace (Instruct.rtn) is already the right primitive for the **leaf** operation (swap one node for another). What it needs is the DiR-prefix dispatch hook, paralleling the opPlusEQ change from this morning:

```tawk
extern GroupItem opReplace(GroupItem argument,GroupItem target)
{
GroupItem   grup;
    if !compare(head(argument.tag,3),"DiR")
        return ReplaceDirective(argument,target);
    if argument.isLIST
        while grup = argument.prior(grup)
            opReplace(grup,target);
    else    target.replace(argument);
    return target;
}
```

**Three lines added, no behavior change for non-DiR arguments.** opReplace's existing role (tag-keyed swap within target's children, via `GroupItem.replace` at GroupItem.twk:1084) is untouched. It just gains a routing entrance for the directive case.

The actual replacement orchestration happens in `ReplaceDirective`, parallel to today's `applyDirectives`.

---

## ReplaceDirective — tawk sketch

The function the DiR hook routes to. Mirrors applyDirectives' shape (list-recurse, idempotence via DiRs registry, processCode to build BlocKs) but does match-and-swap rather than splice-into-end:

```tawk
extern GroupItem ReplaceDirective(GroupItem argument,GroupItem target)
{
GroupItem   grup;
GroupItem   DiRs;
GroupItem   from;
GroupItem   to;
GroupItem   anchor;
GroupItem   targetLines;
    if argument.isLIST
        while grup = argument.prior(grup)
            ReplaceDirective(grup,target);
    else {
        // idempotence — same pattern as applyDirectives
        DiRs = target["DiRs"];
        if !DiRs {
            DiRs = target += "DiRs";
            DiRs.noPrint = true; }
        if DiRs[argument.tag]   return target;
        DiRs += argument;

        // ensure both target and directive parsed
        if !target["BlocK"]     processCode(target);
        processCode(argument);
        from = argument["from"];
        if !from {
            cerr "Replace directive missing 'from':",argument.tag:;
            return target; }
        to = argument["to"];   // may be null for delete-shape

        // find the anchor span in target's BlocK Lines
        targetLines = target["BlocK"].getLabelGroup("Lines");
        if !targetLines    return target;
        anchor = matchSpanInLines(targetLines,from);
        if !anchor {
            cerr "Replace directive could not match 'from' in target:",target.tag:;
            return target; }

        // swap
        ReplaceAtAnchor(targetLines,anchor,from,to);
    }
    return target;
}
```

---

## New primitives needed

### `matchSpanInLines(targetLines, fromBlock)` — the match engine

**Input**: target's Lines (a GroupItem with a list of statement-members), and the directive's `from` block (a GroupItem with its own Lines).

**Output**: the first member in targetLines that's the start of a matching span — or null.

**What "matching" means** — open question (see below). Cheapest v1: top-level tag/data match on each from-Line vs corresponding target-Line, advancing both in lockstep for the span length.

**Sketch**:

```tawk
extern GroupItem matchSpanInLines(GroupItem targetLines,GroupItem fromBlock)
{
GroupItem   fromLines = fromBlock.getLabelGroup("Lines");
GroupItem   firstFrom;
GroupItem   candidate;
GroupItem   tWalk;
GroupItem   fWalk;
    if !fromLines || !fromLines.groupList   return null;
    firstFrom = fromLines.firstInList;
    candidate = targetLines.firstInList;
    while candidate {
        if statementMatches(candidate,firstFrom) {
            // walk both in lockstep to verify the whole span
            tWalk = candidate.nextInParent;
            fWalk = firstFrom.nextInParent;
            while fWalk && tWalk && statementMatches(tWalk,fWalk) {
                tWalk = tWalk.nextInParent;
                fWalk = fWalk.nextInParent; }
            if !fWalk   return candidate;   // matched all of fromLines
            }
        candidate = candidate.nextInParent; }
    return null;
}
```

`statementMatches` is the equivalence test on individual statement trees. Could start as `a.matches(b)` (GroupItem.twk:699 — tag/data-level equality) and grow into a recursive walk if the v1 falsely matches too readily.

### `ReplaceAtAnchor(targetLines, anchor, fromBlock, toBlock)`

**Input**: target's Lines, the matched anchor (first member of the span to replace), the from block (to know the span length), the to block (the replacement content; may be null for delete).

**Behavior**: detach the matched span from targetLines, then splice in to's Lines members at the same position.

**Sketch**:

```tawk
extern void ReplaceAtAnchor(GroupItem targetLines,GroupItem anchor,
                                  GroupItem fromBlock,GroupItem toBlock)
{
GroupItem   fromLines = fromBlock.getLabelGroup("Lines");
GroupItem   toLines;
GroupItem   spanWalk;
GroupItem   adjacent;
GroupItem   priorAnchor = anchor.priorInParent;   // remember where to splice
int         spanLength = fromLines.listLength;
int         i;
    // detach the span
    spanWalk = anchor;
    for i = 0 to spanLength - 1 {
        if !spanWalk  break;
        adjacent = spanWalk.nextInParent;
        spanWalk.parent = null;
        spanWalk = adjacent; }
    // splice toLines members in at priorAnchor (or at front if priorAnchor null)
    if toBlock {
        toLines = toBlock.getLabelGroup("Lines");
        if toLines && toLines.groupList {
            spanWalk = toLines.lastInList;
            while spanWalk {
                adjacent = spanWalk.priorInParent;
                spanWalk.parent = null;
                if priorAnchor   priorAnchor.insertAfter(spanWalk);   // see below — primitive availability
                else             targetLines.insertGroup(spanWalk);
                spanWalk = adjacent; } } }
}
```

**Primitive availability check needed**: does GroupItem have an `insertAfter(prior, newNode)` operation, or just `insertGroup(node)` (which inserts at front of list)? If only the latter, the "splice after a specific node" case needs a small new method on GroupItem, OR we work around it by inserting in reverse-iter at front when priorAnchor is null and using a different approach when not.

This is the kind of low-level GroupItem-list primitive question that's worth a one-method addition to GroupItem.twk if not already there.

---

## Open design questions

### Q1: depth of structural match

`a.matches(b)` (GroupItem.twk:699) compares **top-level only** — tag, data type, content. Two if-statements with different conditions would both have tag "ifStatement" (or whatever the parse produces) and would match-as-top-level even though they're semantically distinct.

Options:
- **(a) Accept top-level match for v1.** Anchor by uniqueness of top-level shape; if user wants a deeper distinguisher, they make the directive's `from` start with a more-distinct statement. Brittle but simple.
- **(b) Recursive AST-equal walk.** Match recurses through children; two GroupItems are equal iff tags match AND all children walk equal in order. Stronger semantics, more code.
- **(c) Pattern variables.** `?x` in from-pattern matches anything and binds; equality checks honor bindings. Like Prolog unification. Strongest, most code.

Tony's call. My instinct: (b) is the right v1 floor — top-level alone will produce false positives the first time a user writes a non-trivial directive. (c) is HPDL.

### Q2: what if multiple spans in target match `from`?

First match wins (the sketch above walks linearly and returns on first hit)? Or error if non-unique? Or apply to all?

My instinct: first match wins, with a way to mark a directive as "applyToAll" via an attribute if needed later. Most directive use cases probably target a unique anchor.

### Q3: span boundaries when `from` has nested blocks

If `from` is `if cond; { a; b; };` — that's ONE statement (the if), which contains an inner block of two members. Does the matcher need to match the inner block too, or is matching the if-tag enough?

For (a)/(b) recursion: (b) handles this correctly because the recursive walk goes into children. (a) doesn't.

### Q4: idempotence semantics for replace

The current applyDirectives idempotence: a directive tagged X applied twice to target only registers + splices once. Same pattern carries over to replace? Probably yes — if you apply the same DiRReplaceFoo twice, the second application is a no-op even though the matched-span has already been swapped out.

BUT: if you apply DiRReplaceFoo, then someone else applies DiRReplaceBar that re-introduces the from-pattern, then DiRReplaceFoo should... what? Idempotence says no-op. User intuition might say "match again, replace again."

Tractable design call. Idempotence is the safe default; explicit re-apply (e.g., remove the DiRs entry first) is the opt-out.

### Q5: should opReplace's existing tag-keyed swap interfere?

opReplace today: `target.replace(arg)` finds-by-tag-and-swaps in target's children. The DiR-prefix dispatch is the early-out, so non-DiR args follow the existing path unchanged. Should DiR-tagged args ever go through the existing path? No — they're directives, not slot-replacement values. The DiR-prefix hook catches all of them.

This is fine. But worth noting: anyone who happens to name a GroupItem field "DiR..." for unrelated reasons would hit the directive path. The `DiR` prefix is a soft convention being elevated to a dispatch trigger. Probably worth documenting in the bible's directives section.

---

## What's already in place (won't need to be built)

- **Idempotence pattern** — DiRs registry on target, single-registration-per-directive. Already proven by applyDirectives.
- **BlocK building** — `processCode(target)` and `processCode(directive)` parse the action code into a BlocK with Lines. Already used by spliceDirectives.
- **GroupItem.replace** (the leaf swap) — Instruct.rtn:484, the C++ underpinning at GroupItem.twk:1084. Tag-keyed swap, already does what's needed when the target node is identified by tag.
- **GroupItem.matches** (top-level equality test) — GroupItem.twk:699. Sufficient seed for v1 statementMatches; promote to recursive if needed.
- **insertGroup, parent=null detach, addMember** — used by spliceDirectives already. Confirmed working.
- **DiR-prefix dispatch idiom** — `head(tag,3)` + `compare` to "DiR". Proven by opPlusEQ change this morning; mechanism is recipe-reusable in opReplace.

## What's new

- **`ç`** function in Instruct.rtn (parallel to applyDirectives).
- **`matchSpanInLines`** function — the match engine. Loops over target's Lines, tests each candidate against from's first Line, then walks both in lockstep for the span length.
- **`statementMatches`** function — the structural equality test. v1 = `a.matches(b)` top-level. v2 = recursive walk.
- **`ReplaceAtAnchor`** function — detach the matched span, splice toLines members in its place.
- **Possibly: one new GroupItem method** for "insert after this specific member" (if `insertGroup` only does front-insert and there's no insertAfter). Verify before writing.
- **DiR hook in opReplace** — 3 lines, same shape as opPlusEQ's.
- **groups.ext externs** — 3-4 lines (ReplaceDirective, matchSpanInLines, ReplaceAtAnchor, statementMatches).

---

## Buffer-work convergence

Tony's parked buffer/string offline work (setMark, insertAtMark, etc.) is **substrate-for-the-pattern**, not substrate-for-the-implementation of incant directives. The incant directive layer doesn't need Buffer span ops — it operates on GroupItem list members directly. Same conceptual pattern (mark-start, mark-end, swap), different concrete substrate (list-pointer pairs vs char-pointer pairs).

But the buffer work IS the dependency for one related question: when an incant directive needs to find its anchor by text rather than by AST pattern, the find-string-in-buffer primitive becomes the foundation. v1 might not need it; v2 ("find a comment marker `// X` and replace the following statement") would.

---

## Path forward (suggested)

If you wanted to land v1 of incant directive replace in the smallest cohesive set of changes:

1. Add `statementMatches` to Instruct.rtn — wrap `a.matches(b)` for now; trivially extensible later.
2. Add `matchSpanInLines` to Instruct.rtn — uses statementMatches.
3. Add `ReplaceAtAnchor` to Instruct.rtn — uses existing GroupItem detach/insert primitives (verify insertAfter primitive exists; add to GroupItem.twk if not).
4. Add `ReplaceDirective` to Instruct.rtn — orchestrates.
5. Add DiR dispatch hook to `opReplace` in Instruct.rtn.
6. Add 4 externs to `Include/groups.ext`.
7. Write a unit test: `targetAction :+ DiRReplaceFoo;` with a known from/to pair, verify target's BlocK Lines are swapped.

Estimated diff: ~80 lines of tawk source plus 4 extern lines. Could land in a single commit.

**Sequencing vs your Buffer.twk work**: independent. The incant directive replace doesn't depend on Buffer span ops. Both arcs can proceed in parallel; they converge later when (or if) we want text-anchor-based directives.
