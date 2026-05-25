# HWF — Incant Directives — 2026-05-25 — open (key forks graduated to TODO; B parked HPDL)

*Draft trim from a Tony+Clod design dialogue while Clay was on recess. Unnumbered
on purpose — Clay's call where this slots into the HWF index. Provisional; quote
back at your own risk.*

*Graduation notes added 2026-05-25 PM (per Clay): decided forks now carry `→ TODO`
pointers; the dialogue body is preserved as the record of how we got there.*

---

## Context for a cold reader

Tok/Tawk has **directives**: a directive file (e.g. `groupDirectives`,
`plgDirectives`) injects code into the *generated* C++ at tok-time — debug
instrumentation, hook behavior — without touching the `.twk` source. Source stays
clean; the injection lives in the directive file and is re-applied every tok run.

The question this session opened: **what would directives look like in incant?**
Incant is interpreted and reflexive, not transpiled, so there's no "tok-time" build
step to hang them on. The seam we found is the incant equivalent.

The relevant machinery already exists. A field action `field code={ ... };` stores
its body twice: as a **`CodE`** noPrint attribute (the raw `{...}` text) and, after
parsing, as a **`BlocK`** noPrint attribute (the interpreter instructions). The
step that turns one into the other is **`processCode`** (CodE.text → BlocK).

---

## Decisions

- **Inject at `processCode`.** CodE.text → BlocK is the one moment "source" becomes
  "executable" — incant's analog of tok-time, and therefore the correct (only)
  injection point. The CodE/BlocK pair already exists; we exploit a seam, we don't
  add a layer.
- **Build on a working copy; never mutate canonical CodE.** Apply = build
  `workingCopy = CodE.text + insertions`, run `processCode(workingCopy)` into BlocK.
  CodE.text is never written. Result: BlocK is augmented, CodE stays pristine.
  Reason: a mutate-then-restore on live CodE reopens a dirty-source window that the
  current reentrancy hole (see Open questions) can read mid-flight; and keeping CodE
  clean makes toggle-off free — reprocess clean CodE, no stash, no restart.
- **Apply must be idempotent.** Always rebuild from the pristine original, so a
  re-apply / double-trigger / reload-reapply can't stack a second copy of the
  insertion. Write "the apply operation is idempotent" into the directive-apply
  contract as a hard rule, not an emergent accident.
- **Positioning is by name, not by line-scan.** Session 9 already evolved plg from
  line/label matching to *named hook sites* for exactly the brittleness reason. That
  transfers — and is stronger here, since incant is homoiconic.
- **v1 hook = a comment marker** (e.g. `// @bodyTop`) sitting in CodE.text. The
  interpreter ignores it for free (comments never survive into BlocK — same reason a
  `//print` line is dead), so it costs **zero grammar change**. The directive finds
  it by text lookup at processCode time, inserts there, and the augmented copy parses
  with the comment stripped and the insertion now real. This is the strongest version
  of "implement directives without touching incant."
- **Scope splits into A and B:**
  - **A — load-time instrumentation.** Apply at processCode, nothing running. Easy
    *and* safe. This is the pipeline proof. Ship first. *(→ graduated 2026-05-25 PM:
    decided sequencing — A ships after Tar 1 banks; see TODO → First work options.)*
  - **B — runtime hot-patch** of an already-loaded (maybe running) action. The novel,
    exciting one. Parked — the hard part is governance, not code (see Open questions).
- **Bootstrap via tok directives on the parser's generated C++.** Put the
  directive-check into the incant *parser's* generated `.mm`/`.C` via `groupDirectives`,
  so parse behavior changes without editing the parse `.twk` until the mechanism is
  proven (full POP folds it into `.twk` later). With comment-hooks, v1 may need no
  `.twk` change at all; a structural hook (label) would, per Session 9 Brief 5's inert
  goto-label precedent.

---

## Definitions earned

- **idempotent / idempotence** — an operation whose repeated application yields the
  same result as a single application. Math origin: `x · x = x` (Peirce, 1870). CS
  sense: doing it twice equals doing it once (`x = 5` is; `x++` is not). The property
  we design the directive-apply *toward*.
- **hook site (incant)** — an inert anchor in CodE.text that the interpreter steps
  past and a directive locates by name. v1: a comment marker. Reserved: a goto-style
  inert label, for when a hook must survive into the BlocK tree (feature B).
- **positioning-by-name vs line-matching** — the distinction that matters. Killing
  the brittle "which line?" scan is the win; you do not (and cannot) eliminate
  positioning itself — see the fork in Open questions.
- **removable overlay / "peelable"** — directives are a non-destructive layer. Clean
  CodE + a fresh run reverting everything means the modification is always peelable
  back to canonical source. This is the architectural *antidote* to "who wrote this
  mess?" — and it's a property ordinary monkey-patching lacks.

---

## Open questions

- **B's "when" is gated on Layer 3 of the reentrancy arc.** *(→ graduated 2026-05-25 PM:
  the single "reentrancy hole" described below was split into a three-layer arc, B =
  Layer 3; resolved in TODO → Reentrancy Arc.)* Applying a directive to an action
  currently on the call stack is literally the unsolved case in `XML/Generating/status`
  (2026-05-25): "an action calls some other action which then calls the first action
  which has not finished yet." B-on-a-live-action cannot be sound until that model is.
  Hard dependency, deferred behind it.
- **B's "who wrote this mess?" is the real difficulty — governance, not code.**
  Proposed doctrine (parked for Clay): runtime directives are *scaffolding with a
  graduation path* — each is either removed or folded into real CodE and then retired;
  never permanent invisible behavior. And *declared, not conjured* — they live in a
  directives file/registry read every run (like `groupDirectives`) and are applied by
  reference, so a written record of what could be live always exists. Declarative-not-
  imperative is what keeps "who wrote this" answerable. This is the HWF graduation
  ritual applied to code-patches.
- **Full-body-replacement vs snippet-at-named-hook.** "No matching whatsoever" is
  literally achievable only if a directive carries the *entire* replacement body (apply
  = a pure swap). That costs composition (two directives clobber each other) and lets
  the directive's copy drift from the evolving original — Trap Pattern #12 in a new hat.
  Snippet-at-named-hook composes and doesn't duplicate, at the price of the anchor.
  **Decided: snippet-at-named-hook** *(graduation 2026-05-25 PM → TODO).* This is the
  Session 9 *author-writes vs generator-augments* fork recurring.
- **Inspectability of live directives.** Need a way to ask "what is active on this
  field right now," so the divergence (BlocK augmented ≠ CodE clean) is visible rather
  than spooky. A nicety for A; mandatory for B.
- **Bytecode-path interaction.** Directives target BlocK (the interpreter) for now.
  Whether/how they also flow through `generateCode → bytecode` is a later question,
  deliberately *not* coupled to the in-flight gIF/gXpress arc.

---

## Lessons / corrections

Wrong turns survive only as their corrections. Three of Tony's first-cut instincts
got refined in-dialogue:

- "Mutate CodE, stash the old, restore after" → **build on a copy, never touch CodE.**
  The restore step reintroduces the exact dirty-window/stash it was meant to avoid.
- "No matching whatsoever" → **you can't eliminate positioning, only the line-scan.**
  "No matching" is true only for full-body replacement, which costs composition. The
  win is positioning-by-name.
- "Replace CodE text with the copy" → **keep CodE pristine; augment only BlocK.**
  Overwriting CodE re-dirties it in memory and brings the stash back for in-session
  toggle-off.
- Goto-label hook → **comment hook for v1** (zero grammar change); label reserved for
  B's tree-level needs.

---

## Texture worth preserving

The part Clay will care about: **this was a cha-cha role inversion.** Design is Clay's
seat; Clod normally executes. With Clay on recess, Clod held the design seat — and the
collaboration still worked, because the seats stayed honest. Tony brought the
architectural instinct and the incant-fluency: the CodE/BlocK mechanics, the
"cautious little steps for little feet" use case (modify a tried-and-true action
without editing it), and — unprompted — the "who wrote this mess?" question that
*independently arrived at* the Trap-#12 hazard. Clod brought structural framing and
cross-project memory (Session 9 hook-sites, Trap #12, that morning's reentrancy
finding), the idempotency property, the peelable-overlay antidote, and the
inherited-wisdom pointer (this whole feature is monkey-patching / AOP — borrow the
guardrails instead of rediscovering them after getting burned). The friction was
productive in both directions: Clod corrected three of Tony's drifts; Tony's plain-
English instincts kept pulling the design back toward "least machinery that works."

The recurring shape worth marking: **three times this session a design instinct of
Tony's turned out to be a fork the ecosystem had already resolved elsewhere** — Session
9's named hook-sites, Session 9's author-writes-vs-augments, HWF's own graduation
ritual. The cha-cha's cross-project memory is doing real work. The incant directive
design is, to a surprising degree, *inheritable* — from plg's Session 9 and from HWF's
existing rituals — rather than invented from scratch. That inheritance is itself a sign
the ecosystem's patterns are generalizing the way the bible keeps betting they will.

A concrete v1 POP, if it gets bumped up (Session-9-style, one falsifiable criterion):

> Define a directive that inserts `print "directive fired":;` at the `// @bodyTop`
> hook of one existing action (say `layout`). Active → running `layout` shows the
> print. Inactive → gone. Fresh run inactive → byte-identical clean BlocK.

If that three-state test passes, the pipeline is real and B becomes an extension, not
a leap.
