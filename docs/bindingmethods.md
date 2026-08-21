# Drawing / Foreign-Binding Design Session — Summary

**Date:** 2026-08-21
**Seat:** Clay (design), Tony (ruling authority)
**Status:** Offline notebook material. All work herein gated behind parse generation reaching 54/54 (pudding proof). No contact with F-31/Arm A lane.

## Origin

The question that opened the session: can CGContext drawing methods live in kant fields as jitted code, avoiding a hand-written C++ extern wrapper per drawing command? Answer: yes, and the mechanism generalizes into the project's foreign-binding substrate. What arrived as a wrapper-avoidance question left as the Display architecture reconceived.

## The mechanism: foreign descriptor fields

A drawing field carries no kant body. It wears two attributes: `function` (the literal C symbol string, e.g. `"CGContextAddLineToPoint"`) and `signature` (a type string, e.g. `v:pdY`). All of Core Graphics is plain C functions with C symbols — no Objective-C, no C++ mangling — so `dlsym(RTLD_DEFAULT, symbol)` resolves them directly. The Swift-style names (`addLine(to:)`) are overlay renamings that do not exist in the binary; the ugly prefix-armored C names are the real symbols, quarantined to a dead string written once and read only by dlsym.

The field name itself is the kant-facing verb (`line`, `move`, `stroke`, `width`), free of charge, fixing Apple's naming per-field with no mechanical stripping scheme. Descriptors being data makes the binding population census-able: "how many foreign bindings exist and do they all resolve" is a walkable, stampable question.

## The signature language

A tiny type language — five characters, each load-bearing, fully determining emitted code:

- `v` — void return (a value-returning binding would use `d`/`p`/`i` here and the emitter captures the result)
- `:` — separator; left is return type, right is parameters in order
- `p` — pointer; **the first `p` on a Display-resident field binds implicitly to Display's context slot**, invisible to callers, so kant-visible arity is everything after it
- `d` — plain double (CGFloat is double on 64-bit), marshaled as-is
- `i` — integer, for the occasional enum (line cap style etc.)
- `Y` — a double that is a y-coordinate, marshaled as `pageHeight - v`

`Y` makes the flip a declared property of each binding rather than a convention the pen must remember, and makes "which foreign calls flip" censusable. Signature doubles as compiler-owned arity check: `line(x)` against `v:pdY` refuses loud.

Struct-by-value calls (CGRect family) are excluded from the dlsym path — ABI hand-rolling is a silent-corruption bug class. A small C++ shim family (three or four shims taking unpacked doubles) covers the handful of struct-taking calls. **Ruled: shims acceptable for exceptions.**

## Define / compile division of labor

**Ruled: define is a pure scribe.** Define stores `function` and `signature` as inert attribute data and worries about nothing. Compile owns all preconditions idempotently (R-4 verbatim): at first compile touch, the jitter interrogates in order — signature present (absent → refuse loud, field name in message), signature parses (malformed → refuse loud, string in message), symbol resolves (dlsym null → refuse loud, symbol in message), LLVM context exists. Install uses the same CodE machinery as generated parse methods — the attribute-driven-behavior pattern's next customer after jitEmitter slots and parser generation.

The no-early-fire guarantee is **structural, not guarded**: a foreign field with no installed artifact has nothing to call. "Set up" and "callable" are the same event — install. Same refuse-loud shape as R-2.

Guard caution (F-15 scar): recognition must test for the `function` attribute specifically, never for presence-of-attributes generally.

Typo detection moves from load time to sweep time: the flat compile sweep with per-rule failure reporting (parse-generation machinery, reused) surfaces a bad binding as its own named report line.

**No interpreter arm. Compile-only, refuse-loud under interpretation.** Ruled early; drawing is gated behind JIT maturity by construction.

## Gating

No `jitDone` flag — a boolean set by boot code is a claim, not a fact. Gates are propositional: **LLVM context slot non-null** (the specific capability define/compile actually need) and **Drawing is the current registry**. Both inspectable facts, neither asserted by a coordinator. A stamped capability ledger (boot facts as B0 claims, asOf-stamped, set by each capability at its own completion) is the doctrinal upgrade, chartered when a third gating customer arrives — likely anything wanting to gate on parse-generation-certified.

**Ruled: JIT machinery before drawing** in boot order; absence of the LLVM context when a foreign field compiles is a boot-order violation, refuse-loud, no graceful lazy fallback.

## Display reconceived

**Display is a graphics-context wrapper, not a bitmap wrapper.** Display owns a drawing protocol; the destination (bitmap, PDF page, window layer) is a construction-time choice invisible to drawing code. Under this conception Display's field surface is mostly foreign descriptor fields — the binding mechanism is Display's substance, not an adjacency. Pen and measure sit as kant logic atop a population of mapped CG verbs with civilized names.

## Style mirror doctrine

The CGContext graphics state overlaps Styles because a context *is* a style record with verbs attached. Resolution: Styles is the kant-resident, inspectable representation of appearance; the context state is the foreign shadow of whichever Style is current. **One context per destination, one current-style slot as the sole memory.** Style change = full push of every style field into the context + slot update.

- **Full push, never delta:** context state after applying style X is a function of X alone, never of history. A dozen scalar calls is cheap insurance against "wrong color three drawings later."
- **No SaveGState/RestoreGState:** Apple's stack exists to serve code without a corpus-resident style record to re-push from. It holds state kant can't see — prose-resident state. Banned.
- Fields like `bgColor` are **Style fields**, not missing drawing verbs. Their CG relationship is via the push translation (style field → foreign-call burst), which may demand new registry primitives (e.g. a fill-rect capability).

## Transform ban and the flip

**Transforms banned from the context entirely. CTM stays identity for the life of every context.** Serial transforms are mutable global state for geometry: trivially simple machinery, unreadable composition, history-resident effects with nothing to census. Kant computes final page-space coordinates; CG receives resolved numbers. For typesetting the arithmetic is arithmetic kant wants to own anyway (baseline origin plus advances, margin offsets).

The y-axis flip (Quartz y-up vs typesetting y-down) is **arithmetic at the exit door, not a setup transform**: `pageHeight - y`, applied once per y-coordinate, at the single marshaling boundary where kant coordinates become CG coordinates — the `Y` positions in signatures. No kant computation ever happens in flipped space. Core Text at identity draws glyphs right-side up natively; the flip touches only our own geometry.

Bonus for certification: identity CTM means the numbers kant computes are the numbers in the PDF content stream — no matrix rewriting coordinates in transit.

Noted, not ruled: retained-mode alternative (pen appends operations to a kant-resident list; a render walk plays the list into the context, flipping on the way) would move the flip literally to the end and make the drawing program inspectable data pre-CG. Cost: indirection, loss of draw-means-drawn. Parked.

## PDF as deal of the century

`CGPDFContextCreateWithURL` takes the same drawing calls as any context but produces an artifact. This gives the foreign-call mechanism a certification story despite having no interpreter arm to byte-agree with: **run-to-run agreement** — same kant drawing program → same PDF bytes. Wrinkle: default PDF metadata (creation date, document ID) varies per run; pin via the auxiliary-info dictionary or certify on a normalized form stripping volatile trailer fields. A vigram-shaped claim.

The typesetting-to-PDF run is the milestone: the project's first output a person can hold. It needs (a) the GC construction — a handful more foreign bindings (create, begin page, end page, release) plus Display's context slot minted for real — and (b) the drawing walk, where the pen logic goes live: content walk, current-style mirroring, full-push transitions, resolved coordinates, `Y`s flipping at the exit. (Larry, Curly, Moe: walk this way.)

## Chartered and shelved (gate: 54/54)

**Task 1 — Drawing registry annotation (Clod).** Annotate every Drawing verb with `function` and `signature` attributes. Symbol column verified immediately by a standalone dlsym check, run and reported — stamped fact, no waiting for the sweep. Signature column proposal-grade (MECHANISM-UNVERIFIED) until the emitter exists. **`Y` markings are proposed-not-ruled** — which doubles flip is coordinate doctrine, not header transcription; ambiguous cases (heights? dash lengths? rect-shim y's?) surfaced as a list for Tony's ruling. Committed as its own labeled change, no mixing with F-31 traffic.

**Task 2 — Forms census minion (Clod).** Walk forms, inventory appearance-bearing setter fields. Census beats stumble (the 78→47 lesson). Output is a three-column finding: Style record field inventory, push-translation requirements, registry primitives needed to serve the push. Inventory half is mechanical and Clod-sized now; the push-translation consumer is unruled design, so semantic stumbling remains the *net* under the census — an unknown field surfaces refuse-loud when the push meets a translation it lacks.

**Interim (Tony, now):** two hand-annotated exemplar definitions in the Drawing registry as pattern reminders — `line` (with a `Y`) and a no-flip case like `width` — encoding most of the doctrine by live example.

## Sequencing ruling

Parse generation first, as proof of pudding: 54 real methods with real control flow, certified by silent replacement of a working parser, is the harshest JIT customer this mechanism could want. Foreign calls are strictly simpler — no recursion, no rule structure, marshal-flip-call. Drawing inherits a debugged emitter. When the pudding proves, sic Clod on the registry; next stop, a typeset page out of a PDF context worth framing.
