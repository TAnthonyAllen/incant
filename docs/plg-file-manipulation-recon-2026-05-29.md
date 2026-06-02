# PLG File-Manipulation Recon — 2026-05-29

**Scope.** `Parse/BeforeRefactor/*.g`, `*.act`, `*.rtn` — 7 files, ~1200 lines.
Question: what mechanisms does old PLG have that incant could draw from for
file manipulation, especially the delimited-file-with-field-projection
pattern Tony remembers (see `XML/NotGUI/playlist.xml`'s `phone`)?

## Bottom line

**The delimited-file projection mechanism isn't in `Parse/BeforeRefactor/`.**
That directory holds PLG's *parser-generator* — the grammar files for `plg`
itself, its action handlers, and its runtime. The delimited-file capability
that `playlist.xml` exercises has to live deeper in the PLG runtime stack
(PLGparse, Buffer, PLGitem) which sits upstream of these files. Recon would
need to widen to find the actual TSV/CSV machinery.

What IS here: PLG's own file-handling primitives, used while generating a
parser. Several are interesting patterns for incant's general file-manip
surface area, even though none of them are the projection feature itself.

## Primitives present

| Primitive | Where | What it does |
|---|---|---|
| `getStringFromFile(name)` | `plg.rtn:147`, `plg.act:306`, `plg.act:312` | Slurp whole file into a String. |
| `divertInput(text, rule)` | `plg.act:309` | Push text as the current input stream; optionally parse with a specific rule. (incant's `pushInput`.) |
| `divertInput(text)` | `PLGsetParse.rtn:34` | One-arg form for sub-parses. |
| `revertInput()` | `PLGsetParse.rtn:47` | Pop diverted input. |
| `output.setFile(name)` | `parts.g:27` | Bind a buffer to a destination file. |
| `output.closeFile()` | `plg.act:456` | Flush+close. The "collect-then-write" idiom: accumulate in buffer, set destination, close. |
| `process(name)` | `plg.rtn:145` | Top-level: load file, derive filename via the `FileName` rule, then run `Start` on the contents. |
| `test(name, text)` | `plg.rtn:187` | Test entry-point: load file, run *named* rule (not `Start`). Lets you exercise individual rules against a fixture file. |

## Multi-buffer output model

`plg.rtn:13-17` declares four named output buffers used during parser
generation:

- `output` — main `.twk` body
- `headerBuffer` — class declarations / extern blocks
- `includeBuffer` — `include(file)` and `insert(file)` results, plus `-% %-` inline code
- `buffer` — scratch / per-action

The "Start!" action (`plg.act:416-457`) flushes them in order at parse-end:
declarations first, then header, then keywords, then include-content, then
the generated rules, then actions, then tail. **Layered output streams** —
PLG had this pattern; incant has `toBUFFER` but not the category-bucket
idiom yet.

## include() vs insert() vs `-% %-`

`plg.g:110-116` and `plg.act:304-319` — three flavors of "bring text in":

- `include(file)` — text gets *parsed* via the `ParseInclude` rule.
  `divertInput(text, rule)` route. Content becomes part of the grammar.
- `insert(file)` — text gets *appended raw* to `includeBuffer`. Lands
  verbatim in the generated `.twk` output. Used to drop C++ snippets in.
- `-% ... %-` — same as insert but inline. The `%-` ends the block.

**Incant currently only has the parse-as-text form** (`include(grammar)`
in `setup`). The insert-raw and inline-code-block forms could become incant
features — useful when generating output files where you want to drop
verbatim payloads (think: future codegen workflows).

## `test(name, text)` entry-point

`plg.rtn:184-219` is a separate top-level entry point parallel to
`process()`. It takes a rule name and a file path, sets up the parse
environment, then runs *just that rule* against the file contents.

For incant: this is the "test a single rule against a fixture" ergonomic.
`oneTest` and `unitTests` files today run a defined set of actions; PLG had
a UX where you could point the binary at "rule X against fixture Y" from
the command line. Could fit nicely with where Phase Bytecode is heading
once the JIT lands.

## Tar babies (worth noting, not chasing)

1. **`Tail` mechanism** (`parts.g:131`, `plg.act:455`) — text after the
   second `%%` in a grammar file gets stashed verbatim and emitted at the
   end of output. The grammar file is effectively three sections: header,
   body (rules), tail. This split-by-marker pattern is common in
   generator-style files (yacc, etc.); not in incant today.
2. **`output.setFile` / `closeFile` timing.** The destination file is set
   mid-parse from a *parsed identifier* (the `FileName` rule extracts
   `name.twk` from the source's first line). The output file is determined
   by parser input content, not by command-line arg. Incant doesn't have
   this kind of "input file dictates output file" feedback loop.
3. **`PLGsetParse` as a separate parser-within-parser.** Character-set
   definitions like `[a-zA-Z]` get parsed by a *different parser instance*
   (`PLGsetParse`) running on the bracket contents, with its own grammar
   and rule table. Sub-parser composition with `divertInput`. Heavy
   machinery but the pattern of "use a small specialized parser for a
   sub-language inside the main one" is nice.

## Findings (no fixes)

- `getStringFromFile` reads whole files into memory. Fine for grammars
  (small); would be wasteful for large data files. PLG's delimited-file
  parser presumably uses streaming Buffer reads instead — that's another
  reason to look higher in the PLG stack.
- `process(name)` loads input, then parses the `FileName` rule against the
  *path argument* to derive the output filename, then parses the *content*
  against `Start`. The two-phase use of one input is slightly tangled but
  works.

## What's NOT here

The delimited-file capability Tony remembers — tab/comma-delimited file
parsed at the PLG level with `fields=` projection picking columns by name.
None of these 7 files implement it.

**FOUND in follow-on recon**: the mechanism lives in `ParseXML`, a class
that PLG generated. Archived in `OLDtawkDoNotTouch/Groups/ParseXML.*` and
`InProcess/Groups/Aside/BeforeSimple/ParseXML.*` (the latter is the
recon target). See `plg-delimited-file-recon-2026-05-29.md` for the
walkthrough. Bottom line: ~500 LOC across `ParseXML.rtn` (runtime),
`Delimited.g` (grammar — included by `ParseXML.g`), and `Delimited.act`
(actions). Port to incant is feasible; JSON parsing comes along for the
ride.

## Recommendation

When incant Phase Bytecode loops back to surface-area work:

1. **Layered output buffers** (`headerBuffer` / `includeBuffer` / `output`
   pattern) — easy port, immediate utility for code-emit workflows.
2. **`include(file)` vs `insert(file)` distinction** — `insert` is the
   missing primitive; cheap to add (it's just `includeBuffer.append(text)`).
3. **`test(ruleName, fixtureFile)` CLI entry point** — small UX win, fits
   the test-harness arc.
4. **Delimited-file projection** — defer until we've found the actual PLG
   implementation. Worth a second targeted recon into the PLG runtime
   (`Parse/PLGparse.*` and the support `Frame/Buffer*`) before deciding
   port-or-rebuild.
