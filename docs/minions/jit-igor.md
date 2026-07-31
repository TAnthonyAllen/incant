# JIT Igor — Corpus

> **RETIRED AS A DOCUMENT, 2026-07-31. This file is a pointer, not a corpus.**

The corpus is `incant/jigcorpus` and it is canonical. **The render is now
`incant/jiquery`, which is a program rather than a copy:**

```
<binary> incant/jiquery          # exit 0, sentinel at the foot
```

## Why the hand-maintained markdown render is gone

It was a **duplicate that drifted**. It carried `lastBaked: 2026-06-28` while
`jigcorpus` moved on, and its headline claim — *"Phase 1 complete, 24 POPs proven
end-to-end"* — was **false by 2026-07-30**, when three of those POPs were
measured exiting 139. A stale render of a corpus is worse than no render: the
whole point of the format is that *a minion cannot confidently serve a
falsehood*, and a second copy is a second thing that can be wrong.

`jiquery` cannot drift, because it reads the corpus it renders.

## What `jiquery` prints, and why in that order

It is built around the format's **Acceptance Test**, not around dumping fields:

| section | what it is for |
|---|---|
| **0. self-check** | every claim carries data. Exists because the corpus once **silently lost its own content** — see below |
| **1. servable as fact** | `verified` only — a run was observed |
| **2. hedge these** | `inferred` — read, reasoned or counted, never run. Each prints its `searched` scope, because an inferred claim is only as good as the space that was searched |
| **3. must not be served as true** | `refuted` and `stale-suspect`, named as such |
| **4. open** | work, not knowledge. Each says what it **blocks** and what settling would **cost** |
| **5. blocked** | tried, cannot be done this way, evidence attached |
| **6. next step** | including an explicit `notProgress` field, because the cheapest available fix moves no frontier |

## Two traps this corpus paid for, both worth knowing before you edit it

1. **`name=(text#)` — the delimited-literal form — parses cleanly and produces
   an attribute WITH NO DATA.** A field with no data returns its own TAG, so
   `content` read back as the literal string `content`. The corpus looked
   populated and every claim it held was empty. Measured under both the old and
   the new grammar, so it is pre-existing and not a consequence of the `#`
   change. **Use multi-line double-quoted strings** — they preserve newlines and
   indentation and they do carry data. Section 0 of `jiquery` exists to catch a
   recurrence.

2. **Every attribute name a query reads must be declared `virtual` at the top of
   `jigcorpus`.** An undeclared name parses fine, stores fine, and reads back as
   `0` — so the corpus looks right and the query returns nothing, at exit 0 with
   no diagnostic. `content`/`confidence` were declared and worked;
   `action`/`test`/`blocker` were not and did not, in the same file in the same
   run.

Both failures share a shape, and it is the shape this whole format exists to
prevent: **the corpus reads as knowledge while holding nothing.**

*Format and its two rules (an absence claim names where it looked; an open item
is its own shape): `docs/minion-corpus-format.md`. The material the corpus is
baked from: `docs/jit.md` and `docs/jitDesign.md`.*
