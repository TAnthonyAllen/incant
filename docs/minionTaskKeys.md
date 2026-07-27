# Minion Corpus — Task-Keyed Retrieval

```
KIND:       design sketch
STATUS:     proposed — not built, not committed to
DATE:       2026-07-27
COMPANION:  minionfire.md, vision.md (corpus architecture, the four ops)
            CLAUDE.md (the bear-trap list — this proposes its successor)
ANSWERS:    How does an implementation minion find the lesson it needs
            BEFORE it walks into the wall, rather than after?
ORIGIN:     Tony's correction to Clay's critique of the FAQ approach,
            2026-07-27. Recorded here because it existed only in chat.
OPEN:       retrieval key vocabulary (§5); whether to build at all until
            the JSON/genParse thread is closed
```

---

## 1. The problem: symptom-space and cause-space share no vocabulary

The FAQ approach fails on a specific class of question. "Why is my extern never
called" shares no words with its answer — "a command must live in a `.rtn` that
is `include`d into `GroupRules.twk`." A minion searching from the symptom cannot
reach the cause, because nothing in the symptom's phrasing appears in the cause's
statement.

Clay's proposed patch — an index of hand-authored question→pointer entries — only
works if someone anticipates every phrasing a future minion might use. That is
the same guessing problem the FAQ had, moved up one level.

## 2. The fix: key on the task, not the symptom

A minion does not know in advance that it will hit the extern wall. It *does*
know, at pickup, that its task is "modify a `.twk`/`.rtn` file."

The task is knowable up front. The symptom only becomes knowable at failure.

So keying retrieval on task-type lets the lesson arrive **before** the wall
rather than as a diagnosis after it. That flips the mechanism from reactive
(hit error → search) to preventive (pick up task → preload the gotchas for this
task-type). It is progressive disclosure applied to hard-won environment
knowledge: load what the task needs when the task is picked up.

This is the whole idea. Everything below is consequence.

## 3. Why a stashed lesson is not a stale copy

Clay's earlier objection — a copied lesson drifts while a pointer cannot — is
answered by machinery the corpus already has. A lesson rides as a claim with
`provenance` / `confidence` / `asOf`, and `challenge` is the re-verification op.
The stored lesson is content **plus** its pointer **plus** a staleness date.

The discipline that makes this true rather than aspirational:

> **Prefer reality-anchored claims over doc-anchored ones.**

"An extern in a standalone `.twk` will not bind — confirmed from codegen
`RuleStuff.mm:567`" is checkable against the live build; `challenge` can re-run
it mechanically. "The design decision is X per `genParseSpec` §5.3" points at a
document that can itself drift — and §7.5 taught this project that docs drift
while the artifact does not.

Lean the corpus on claims verifiable against the running system, precisely so
`challenge` stays cheap and honest.

## 4. What kind of corpus this is

Different animal from a domain task-minion's corpus:

- **Subject:** the development environment itself — build mechanics, invocation
  rules, path resolution, tok's edges.
- **Consumers:** implementation minions (Clod, and the next Clod), not a domain
  query.

It is the machine-queryable successor to CLAUDE.md's bear-trap list. Those are
currently a flat numbered list read linearly. Re-keyed by task, a minion on a
twk-edit task pulls the relevant few and skips the rest.

## 5. The one real design decision: the retrieval key

**Controlled task-type vocabulary** — lessons tagged on absorb (`twk-edit`,
`extern-add`, `incant-command-add`, `bytecode-emit`). Clean proactive preload;
needs tagging discipline and a vocabulary that does not sprawl.

**Free-text keyword match** on the task description — nothing to maintain, but
noisier, and it reintroduces some of the vocabulary gap §1 describes.

Lean: controlled tags filtered with `has` (already designed — `claims has
taskType`), with keyword match as a fallback *within* a task bucket.

Cost to own honestly: tasks then need a declared type when a minion picks them
up. That is a small protocol addition to how work is handed over.

## 6. Absorption discipline — confidence is the point

Flat bear-trap prose cannot express "symptom observed, cause unconfirmed." A
corpus claim can, and that gap is not hypothetical — **bear-trap #18 is
currently banked as doctrine on an unconfirmed cause.** genParseSpec §7.6 lists
three candidate explanations and one of them is Clay's own error. `testSet` is a
working counterexample sitting in the build.

Three categories, and only the first deserves a trap as written:

| category | example | right artifact |
|---|---|---|
| **real defect** | tok exits 139 with no diagnostic | bear trap, record regardless of cause |
| **idiom violation** | incant-style single quotes inside a C++ `extern` body | "write it this way", not "tok is broken" |
| **misdiagnosis** | workaround worked for a different reason than believed | nothing — actively harmful once banked |

Reproduction proves the **symptom**, not the **cause**. #18 was reproduced three
times and still has three candidate causes.

So: a tok bear trap needs a minimal repro **and** a confirmed cause. Since Tony
is the only person who knows what tok actually promises, tok-specific traps want
his sign-off before becoming doctrine. Small gate, rare event.

Worth separating in the current record: the `ERROR Inheritance` cascade (the
actual finding) versus `char dq = 34` for emitting a `"` into generated text.
The second is a legitimate emission idiom regardless of what caused the first,
and should not be banked as scar tissue from a possible misdiagnosis.

## 7. Seed corpus — already written, no hunting required

- CLAUDE.md's existing bear-traps
- The scattered environment answers already on disk (`groups.ext` merges rather
  than regenerates; the `=value` registration form; include-path resolution)

First absorb pass is a re-keying exercise, not an authoring one. #18 is the
first claim to absorb at **low confidence** and `challenge` later.

## 8. Three arguments this idea earned today

Not theory — 2026-07-27 produced three fresh instances:

1. **`runScaf2` never dispatches.** Third recurrence of the invocation-blocker
   class. Every candidate answer was already on disk (bear-trap #16 on
   `groups.ext` merging; the `=value` form in TODO.md's Phase Bytecode note) and
   none was findable from the symptom.
2. **`include(genLadder)` not resolving** while `include(utilities)` did. Cost a
   hunt; the answer is a plain environment fact. Task-type
   `incant-script-add`.
3. **Bear-trap #18** itself — see §6.

## 9. The cheap test, before building anything

Hand-tag the existing bear-traps with task-types. Query `twk-edit`. Check that
it returns the invocation/regen/alias cluster — the very lessons a symptom
search missed.

If task-keying surfaces the extern-invocation lesson from a task description
that never mentions externs, the idea is proven on real material and
`jiquery.incant` grows a task filter. If it does not, that is learned cheaply,
on paper, with nothing built.

---

## 10. Standing caution

This is a sketch, not a commitment. The genParse ladder and the open JSON parse
bug are the live work; this waits. Its value is that it is written down — it
existed only in conversation until now, and this project's recurring lesson is
that what is not on disk does not survive.

— Clay, 2026-07-27
