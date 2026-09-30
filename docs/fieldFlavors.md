# Field flavors: design direction, 2026-09-30 (Tony, Clay, Clod). Not ruled, not scheduled.

Sibling of `docs/objectModel.md`, and not part of its Part 1. It records direction only: nothing here is
ruled and nothing is scheduled.

**A field knows what it is.** Its flavor is specified by its components.

**Two axes.**
- **position:** attribute, member, or property;
- **kind:** plain, rule instance, or fire-and-forget.

Each axis is a small field of its own. Do not fold both into one enum: that would put two meanings on one
channel, which is today's affiliation-boolean problem (F-O39 -- `addProperty` sets `isAttribute`, so `=%`
answers a property).

**Instances own their bodies.** An instance is a copy of its original with a link back (`ruleOf`). Its body
holds only what differs; everything else is asked of the original. `rStuff` dissolves into the instance's
body. We accept the efficiency cost. This is where R1 (copy on first write) was already heading.

**Flavor goes on `groupBody` once instances own their bodies.** Until then it stays on the instance.

**Lookup: ask the field; if it does not have it, the answer is no.** Each flavor carries a rule for whether
a miss delegates to the original. Terms delegate; `label`, `parentLabel` and activation facts never do.

**Lists.** Tony leans toward one list, but not strongly. One list requires BOTH of these:
- every walk goes through a flavored iterator;
- each flavor has a delegation rule.

Otherwise keep stroke 3's two lists (terms are shared, properties are the instance's own).

**Flags stay C++ bits, possibly forever.** Kant design should not have to think about them. Each flag gets
a `GroupFields` entry carrying its own accessor, and `opDot` dispatches through the registry instead of its
switch. 0 means off, non-zero means on. An unset flag reads 0 and must never echo its own tag (bear-trap #26).

**Fire-and-forget attributes are kept after they fire,** with their flavor set, so a definition can print
itself back out. This is consistent with the 08-03 fidelity-print ruling.

**Open:** under this model, "rule instance" as a kind replaces `rStuff` presence as the liveness test
(Ruling D).
