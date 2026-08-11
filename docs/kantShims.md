# The kant shim convention — priced before building (SEQ 53 item 4)

**Status:** ⚠ **PRICED, NOT BUILT.** One ruling is owed before step 2 starts; everything else is
mechanical and is marked so. asOf 2026-08-11.

**Why a note at all:** SEQ 53 item 4 — this convention is likely to become inherited convention for
emitted code generally, so a wrong guess is expensive to move later. What follows is the shape, the
naming, what a second argument carries, and the one thing that is a design call rather than a
spelling.

---

## 1. The measured surface

Seven `extern "C"` functions in `RuleStuff.twk`, and the argument counts are the reason this note
exists — a kant action takes **one** argument.

| function | line | args | argument kinds |
|---|---|---|---|
| `lit` | :520 | 2 | node, grammar literal |
| `parseR` | :758 | 2 | node, node |
| `containerTo` | :566 | 3 | node, node, text |
| `litOption` | :601 | 3 | node, node, text |
| `inGuard` | :623 | 3 | node, text, char |
| `leaveAlt` | :694 | 3 | node, **mark**, int |
| `leaveRule` | :661 | 5 | node, node, node, **mark**, int |

---

## 2. ⚠ THE FIRST FINDING SHRINKS THE PROBLEM: MOST ARGUMENTS ARE NOT ARGUMENTS

The emitted C++ method derives nearly everything from the rule it was handed:

```
GroupItem   into  = rule.rStuff.parentLabel;
GroupItem   label = new("Braced");
GroupItem   t1 = rule[1];   t2 = rule[2];   t3 = rule[3];
String      from  = atRuleMark;
    return leaveRule(rule,into,label,from, lit(t1,"[") && parseR(t2,label) && lit(t3,"]") );
```

**`rule`, `into`, `label`, and every `t<n>` come from the ONE argument `parseMethod` already
passes.** `parseMethod`'s own header states the reason it is one-argument: *"kant methods take one
argument, so a two-argument parse method could never survive the kant handover; `into` is derived
from parentLabel instead of passed."* **That design decision was made for this handover and it pays
here.**

So the genuinely-two-argument calls in a Braced-shaped rule are exactly **`lit(term, literal)`** and
**`parseR(term, into)`**. The 5-argument `leaveRule` is 5 arguments *in C++*; across the seam it is
one node, one mark, and one boolean.

⚠ **AND ONE OF ITS FIVE IS ALREADY VESTIGIAL, found by reading it rather than counting it.**
`leaveRule` no longer attaches — PC-4, 2026-08-07 — and its own comment says so: *"`into` is still
taken and still passed by every emitted method: the emitter is untouched and parse() derives the
same node from pStuff."* **So `into` is carried for signature compatibility and used for nothing**,
and a kant shim has no reason to thread it at all. The seam is a legitimate place to stop passing
it; the C++ emitter keeping it is a separate and lower-priority tidy, **not** something to change
while a rung is in flight.

---

## 3. ⚠⚠ THE RULING OWED — WHERE THE MARK LIVES. This is the design call, and it is Tony's.

**`String from = atRuleMark` is not a value. It is a cursor into the input buffer.** `leaveRule`
rewinds to it on failure. A kant field can hold *text*; it cannot meaningfully hold a position, and
copying the text and restoring it would restore the characters and not the place. **So `from`
cannot cross into kant as data, by nature and not by missing plumbing.**

This matters more than a spelling because `RuleStuff.twk:657` says **Invariant R lives in
`leaveRule`/`leaveAlt` "and nowhere else"**, and this decides how that survives the handover.

**Two doors.**

**(a) THE MARK NEVER CROSSES — RECOMMENDED.** A C++ `enterKantRule`/`leaveKantRule` pair owns the
mark, and the kant body never sees it. **The storage already exists:** `RuleStuff` carries `hereAt`
and `failedAt` as `String` fields, which is exactly this shape. The kant body then reads:

```
    kpBraced code={
        return litK(rule1, "[") AND parseRK(rule2) AND litK(rule3, "]");
        };
```

with entry/exit handled by the trampoline that already exists. **Cost:** two small externs, both
one-argument. **Property:** Invariant R stays in C++, one writer, exactly where the tree says it
lives — the handover cannot weaken it because the handover cannot reach it.

**(b) KANT HOLDS AN OPAQUE HANDLE.** A field carrying the mark as an opaque. **Cost:** a new value
kind that means nothing to any other incant construct, plus every emitted method threading it.
**Property:** it puts a thing in the language that only the parser understands, and bear-trap #26's
family says a field whose meaning is not its content is where silent wrongness lives.

⚠ **The recommendation is (a), and the argument is not effort — it is that (b) moves Invariant R
into a place the tree has ruled it should not be.** But it changes the emitted body's shape for
every future rule, which is why it is put rather than taken.

---

## 4. MECHANICAL ONCE §3 IS RULED — recorded so the ruling is not confused with the plumbing

- **The second argument.** `lit` and `parseR` need one extra value each. The established idiom is
  attributes on the single argument plus a `:scope` statement to hoist them
  (project memory: multi-arg incant actions). No new mechanism.
- **Naming.** `litK` / `parseRK` — the `K` suffix marks the kant-callable shim and keeps the
  `extern "C"` name free, so bear-trap #12's collision class cannot fire.
- **Registration.** `name immediateAction=name;` in `cOMMANDs`, the form bear-trap #7 and project
  memory both say to use, plus a `groups.ext` decl if a cross-file reference needs one
  (bear-trap #11 — out of repo, and it will not show in a `git status` here).
- **Term access.** `rule[1]`/`rule[2]` is ordinary incant descent; no shim.
- **`new("Braced")`** is ordinary incant.

---

## 5. What a wrong guess costs later

**Cheap to move:** shim names, the attribute names a second argument rides on. One regeneration.

**Expensive to move:** §3. If the mark crosses and later must not, **every emitted body changes
shape** and every installed rule is regenerated and re-pinned — the same re-pin cost SEQ 50 item 4
accepted knowingly for the respell, but paid on a larger population and for a correctness reason
rather than a spelling one. **That asymmetry is the whole reason this note exists rather than a
build.**
