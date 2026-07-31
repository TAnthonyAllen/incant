# Known Errors — recorded now, ruled later

*Started 2026-07-31.*

**What this file is, and why it is not CLAUDE.md's bear traps.** A bear trap is
**settled**: the behaviour is understood, the workaround is known, and the entry exists so
nobody pays for it twice. An entry here is **unruled** — the behaviour is measured and
reproducible, but whether it is a defect, a design consequence, or a missing diagnostic has
**not been decided, and deciding it is not this file's job.**

The distinction is load-bearing. Filing an unruled behaviour as a bear trap hardens a guess
into doctrine, which is precisely the failure `CLAUDE.md` bear-trap #18 was split apart to
undo. Filing it nowhere loses it. So: **record now, rule later**, and an entry graduates to a
bear trap (or to a fix) when someone with the authority to rule does.

**Each entry carries:** what was measured · what is genuinely unclear · the composition that
makes it bite · who rules.

---

## KE-1 — an empty attribute reads back as its own TAG

**Measured 2026-07-31.** A value written in the delimited-literal form parses cleanly, stores,
and produces an attribute **with no data**:

```
content=(some text here#);      ->  attribute exists, carries NO DATA
content="some text here";       ->  attribute exists, carries the data
```

A field with no data returns its **tag** from `.text` — so `content` read back as the literal
string `content`. Not an error, not a warning, not a null. **A plausible-looking value that
happens to be the field's own name.**

**Scope, measured as a controlled comparison rather than assumed:** the same probe was run
under the pre-2026-07-31 `,` grammar and the current `#` grammar and behaved **identically**,
so this is **pre-existing** and not a consequence of the StringXP change.

**What is genuinely unclear, and why this is not filed as a bug:**
- The tag-for-empty readback is very likely **deliberate** — it is the same rule that
  `CLAIM KANT-10` records, and the 35a concatenation work depended on knowing it
  (`empty += "a" "b"` would otherwise concatenate onto the field's own name).
- Whether `(text#)` *should* assign in a define-attribute value slot at all is a separate
  question nobody has asked. It may simply be the wrong construct for that position.

**So both halves may be individually correct. The trap is the COMPOSITION** — a value form
that silently stores nothing, meeting a readback rule that returns something plausible instead
of nothing. Either alone is survivable; together they produce a data structure that reads as
populated while holding nothing.

**Where it bit:** 32 values in `incant/jigcorpus`. The corpus looked full and every claim it
held was empty, for roughly a month.

**Mitigation in place, not a fix:** `incant/jiquery` section 0 walks every claim and reports
any whose `content` equals its own tag.

**Rules:** Tony.

---

## KE-2 — an undeclared attribute name reads back as 0

**Measured 2026-07-31.** In a registry-style define file, an attribute name that is **not
declared `virtual`** at the top parses fine, stores fine, and **reads back as `0`** from a
query. No error, no warning, exit 0.

The comparison is inside one file in one run, which is what makes it clean:

| name | declared `virtual`? | reads back |
|---|---|---|
| `content`, `confidence` | yes | correctly |
| `action`, `test`, `blocker` | no | `0` |

**What is genuinely unclear:**
- Requiring declaration is **plausibly by design** — it is how the field-name universe stays
  closed, and closure is load-bearing elsewhere (the JIT frame schema depends on exactly this
  property).
- The **silence** is the questionable half, not the requirement. An undeclared name could
  refuse loudly at define time at no cost to the design.

**Again the trap is the composition, not either half:** a name that is legal to write, legal
to store, and returns a falsy value on read. The write side gives no signal and the read side
gives a value that looks like "absent" — so the natural conclusion is *"the data was never
written"*, and the search goes to the wrong file.

**Where it bit:** `incant/jigcorpus`'s `nextStep` block. Cost two wrong hypotheses
(`=` vs `:=`; attribute-vs-member structure) before the actual difference — declared vs not —
was visible, and it was only visible because a declared name and an undeclared name sat side
by side in the same record.

**Rules:** Tony.

---

## The pair, and why they are filed together

KE-1 and KE-2 have the **same shape**: a write that stores nothing or stores unreachably,
meeting a read that returns something plausible rather than nothing. Both produce
**structures that read as knowledge while holding nothing**, at exit 0, with no diagnostic.

That is the same family as `CLAUDE.md`'s testing doctrine — *exit 0 is necessary and not
sufficient* — arriving one layer down, in the data rather than in the run. **A ruling on
either should probably consider both**, because a fix that makes one loud and leaves the
other silent leaves the composition intact.
