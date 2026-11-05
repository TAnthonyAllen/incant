# The parse-label parent (recon, 2026-11-05; nothing built, nothing on trunk but this file)

RULED (Tony, 2026-11-04): a member's parent must be its enclosing field; forms' bubbling needs it. The cure's shape is not ruled.

## What is wrong, measured by pointer (kant define, a C++ tap in a clone)
`evWin` holding `evBody` holding `evDeep` holding `evLeaf`. Going DOWN from the registry entry:

| field reached | its body | its parent is |
|---|---|---|
| evBody | B | evWin (correct) |
| evDeep | D | a field with evBody's body B, NOT the evBody reached going down |
| evLeaf | L | a field with evDeep's body D, NOT the evDeep reached going down |

Going UP from evLeaf: evLeaf -> evDeep (the other field) -> MemberS -> DefinE -> end. It never reaches evWin.

So the parent is the right body on a stale field, and that stale field's own parent is the parse's label. The first level is right; every level below it is wrong. The earlier reading (evDeep -> evBody -> MemberS -> DefinE -> MemberS, forms' Event firing) reported the same chain by name, which could not show the two fields.

## Why (read, and the trial below agrees)
1. A member finishes its own define while it sits under the MemberS label, so it has a parent.
2. aCTionDefinE's member loop does `NewGroup += item`. addGroup: `if group.parent  group = new(group)`, so the enclosing field gets a COPY.
3. A copy shares its source's body, so the copy's children are the same nodes. Their parent still points at the source, and the source's parent is the label.

## Two trials (clone only, reverted; single fixture under an alarm first)
| shape | chain | oneTest | fleet |
|---|---|---|---|
| A: clear the parent, so the member MOVES instead of copying | not read: exit 142, alarm, in bootstrap | exit 142 | not usable (the run was stopped) |
| B: keep the copy; when `item.parent == MemberS`, walk the new member's list and repoint each child whose parent is `item` to the copy | evLeaf -> evDeep -> evBody -> evWin -> EvR, each the field reached going down | exit 0 | pop.sh 2534 row for row but the fixture-name count; jitLadder 224 / 0; printPop, decodePop 0; ddPop 5 / 1; frontier = capture |

**A's hang:** the walk is `MemberS.next(item)`, and next() follows `item.nextInParent`, an intrusive link on the node, which joining the new list rewrites. That is read, not run, as the cause. A would have to capture the next member first; that variant was not tried, and A also changes every copy's `ruleOf`.

**B is in passthrough in the trial**, because the walk needs nextGroup and a pointer compare. It is one statement at the one site.

## What B's green does NOT say
- **No fleet row reads a member's parent chain**, so zero movers is evidence about what the fleet reads and nothing more (H12). A cure owes its own fixture: walk up from a depth-3 leaf and assert each hop by field against the walk down (H13's "same field" question: the field column, since the two share a body), with a depth-1 row that was already right as the control. The H7: remove the repoint and the depth-3 row goes red.
- **137 `parent` mentions in *.twk / *.rtn were not audited.** Only behaviour under the instruments was measured.

## The limit no parent fix removes (read, not measured)
Children live in the shared body and each has ONE parent. A second field over the same body (a form used twice, a member added from an existing field, which keeps the copy path because its parent is not the label) has children pointing at only one of the fields. So a walk up is sound for one instance of a form and not for two. If forms ever need the same definition placed twice, bubbling should carry its path down from the hit test (a stack built on the way to the hit) instead of reading parents. **That is Tony's call and not needed for firstLight's one-level OK.**
