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

## Affiliation census (2026-09-30, SEQ 233 part 2) -- sizing the two-axes idea. Read-only; measured with a temporary tap, reverted.

**Affiliation is already ONE field, not three flags.** `GroupItem.options.affiliation:2[isAttribute isMember
isEmbedded]` (GroupItem.twk:16) is a 2-bit enum on the NODE (not the body): 0 none, 1 attribute, 2 member, 3 embedded.
So "two of the three set at once" cannot be constructed. The F-O39 mix is a different conflict: the enum answers
**position within the term list** and is also written on **properties**, which live on a different list. That is
the two-meanings-on-one-channel problem this note is about, found in place.

### Writers and readers (tok source, code lines only)

| field | writers | readers |
|---|---|---|
| isAttribute | 8: `addAttribute` (generated GroupItem.mm:248), **`addProperty` (GroupItem.twk:171) -- F-O39's site**, the term copy (:554), `aCTionTraiT` on a Modifier (ruleActions.rtn:1114, :1144), compile's `this`/`tempField` locals (Commands.rtn:72, :79), the `+%` operator (Instruct.rtn:1380, :1383) | 18 |
| isMember | 3: `addMember` (GroupItem.twk:156), the member operator (Instruct.rtn:1402, :1405) | 17 |
| isEmbedded | 1: the embedded copy (GroupItem.twk:574) | 4 |
| (reset) | `affiliation = 0` in aCTionDefinE (ruleActions.rtn:273) | -- |

### Live co-occurrence (list the node sits on x affiliation x inferred kind)

Tap: at process exit, walk every node reachable from `ruler->registries` through BOTH `groupList` and `propertyList`,
each node once. Population: pop.sh + jitLadder + printPop, **314 processes, 429,831 nodes** (fleet 861 / 1 on the tap,
unchanged). Kind as inferred below: rule = `isRule` or `rStuff.ruleTerm`; "ff" = not rule, `noPrint`, has a method,
not a local; plain = the rest.

| list | affiliation | rule | ff | plain |
|---|---|---|---|---|
| term | none | 0 | 0 | 314 (the registries root, once per process) |
| term | attribute | 84,425 | 254 | 137,888 |
| term | member | 40,646 | 10,677 | 111,637 |
| term | embedded | 0 | 0 | 0 |
| **property** | **attribute** | **862** | **16,960** | **26,168** |
| property | none / member / embedded | 0 | 0 | 0 |

- **Control holds -- the census is valid:** every one of the 43,990 property-list nodes carries affiliation *attribute*.
  That is F-O39 (`addProperty` sets it), found at full population, not a sample.
- **`isEmbedded` has no live population.** One writer, four readers, zero nodes in the fleet. A two-axes redesign can
  drop it or keep it for free; nothing measured depends on it.
- **"Rule" kind appears in both positions** (84,425 attributes, 40,646 members), as fieldFlavors predicts: kind is not
  position. 862 rule-shaped nodes sit on property lists (not classified further today).

### Where "kind" is inferred today, and from which flags

| kind | inferred from | where |
|---|---|---|
| rule instance | `isRule` (body, definition-time: 46 code lines), `isRuleTerm()` = `rStuff.ruleTerm` or body `isRule` (22 lines), `ruleOf` (the copy link, 18), `rStuff` presence (Ruling D's liveness, 67) | four channels for one question |
| fire-and-forget | **`noPrint && immediateACTION`** (`methodType`, GroupBody.twk:61) | aCTionDefinE's attribute loop, ruleActions.rtn:294 |
| plain | the absence of the above | -- |

- **FINDING: fire-and-forget attributes are NOT kept today.** ruleActions.rtn:294's own comment: *"item gets run but is
  not added to the new group."* The direction above ("kept after they fire, with their flavor set") is a behaviour
  change, not a relabel.
- **FINDING: no flag means fire-and-forget.** It is inferred from `noPrint` plus a method, and that pair also matches
  `builtinActoR` (the 16,960 "ff" on property lists) and the command registry's entries (most of the 10,677 "ff"
  members, inferred -- not classified by name). `noPrint` is doing double duty again (#50's family). A `kind` field would be the first single-meaning
  channel for it.
