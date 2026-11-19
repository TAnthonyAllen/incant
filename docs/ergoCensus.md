# The kant ergonomics census (2026-11-19, measure only)

Clay's dispatch, Tony's rulings R1-R3 of 2026-11-19, on the five complaints at the head of `Topics/kant` (Clod's, from
writing typeset). Measured on the bare build of 2026-11-18 14:10 (2190112 bytes). Nothing was built.

**How each cell was read.** *Action body*: the spelling in an action's `code={ }`; old road = `incant/grammar`
(processCode on the first run), new road = `kantGrammar` (the action moved by the fixtures' compileIn mover, `ieNew`),
one process each under an alarm, read as stdout, REFUSED count, exit, sentinel. *Top level*: old road = the statement
in the file; new road = `STARt("...")` then `testOP`, as `elseIfT` does. **works** = the intended answer, exit 0;
**refuses** = refused by name; **silent-wrong** = a wrong answer or nothing, at exit 0; **crash** = exit 139.
A top-level cell marked *probe* was read by a scratch probe (2026-11-19) and has no fleet row.

## The table

| spelling | action body, incant/grammar | action body, kantGrammar | top level, old / new | row |
|---|---|---|---|---|
| **break** (`if c; break;` in a while / a for) | works | works | works / works | ifElseShapeT IE-17, IE-19; forT FR-3, branchT |
| **continue** | works | works | works / works | IE-18; forT FR-4 |
| **return with a value** | works | works | -- | IE-15 |
| **`&&` in a condition** | works | works | works / works (*probe*) | IE-20 |
| **`\|\|` in a condition** | works | works | works / works (*probe*) | IE-21 |
| **`and` / `or` as words in a condition** | not a spelling: `qa == 2 and qb == 4` refuses (old: "a chained comparison", and the body is lost; new: "a list of adjacent operands") | refuses | refuses / refuses (*probe*) | -- (`or` is else-if, below) |
| **multi-statement else** (indented arms) | works | works | braces: works / works (*probe*) | IE-3, IE-4, IE-10, IE-11, IE-16 |
| **a brace block arm** in a body | refuses by name at define time, by design ("use indentation") | refuses | -- | IE-12 |
| **`or` as else-if** | works (one or two `or`, with an else) | works | works / works | IE-5, IE-6, IE-7; elseIfT EI-1..8 |
| **if on a call's truth, with an else** | works | works | -- | IE-13, IE-14; callTruthT |
| **iterate over a body** (`iterate ic on x; while ++ic`) | works | works | works / works | iterT IR-1 (top); scratch probe c7 (body) |
| **for over a holder** (`h := x; for e in h`) | works | works | -- | IE-22 |
| **for over a starred holder** (`for e in *h`) | **silent-wrong**: walks two items, the star and the name | works | -- | IE-23 |
| **for over a parse result** (`for e in t`) | works (the pieces, in order) | works | -- | IE-24 |
| **iterate over a sibling chain** (`e := x.firsT; while e.datA != 0; ... e := *e.nexT;`) | works (typeset's spelling) | works | -- | scratch probe c9 |
| **a parse result's piece by label name** (`n := *t.name;`) | works | works | works / works (*probe*) | IE-24 |
| the same by subscript (`n := *t["name"];`) | works | **crash** (139) | -- | IE-25 |
| **more than one argument**: `f(a, b)` | the whole body fails to parse (an ERROR line, exit 0) | the same | -- | scratch probe d1 |
| `f(a b)` | the callee gets a two-item list (`argument.listLengtH` 2); `*argument.firsT` refuses ("argument is a binding") | refuses ("a list of adjacent operands") | -- | scratch probes d2, d6 |
| named members in: `=:argument a b;` (the caller passes a group) | works (utilities' frameMembers) | refuses (fixit newRoadScopeStatement) | -- | scopeValueT; scratch probe d3 |
| **a return carrying named members** (`o := copyDeep(rec); *o.w = argument; return *o;`, caller `r := f(5); x := *r.w;`) | works | works | -- | IE-26 |
| the same, writing `o.w = 5` with no star | **crash** (139), both roads | crash | -- | scratch probe d8 |
| (R3) copyOf vs copyDeep: a starred write through the copy | copyOf reaches the source; copyDeep does not | the same | -- | IE-28 |
| (R3) a compare on a holder (`h := qa; if h == 2`) | **silent-wrong**: compares the holder, reads "no"; `*h == 2` reads "yes" | the same | -- | IE-27 |
| ⚠ **since 2026-11-19, branch compare-holder (the compare law, Tony R1-R4)** | refuses by name: "h holds qa; compare *h"; holder == holder stays legal | the same | refuses / refuses | IE-27, IE-29..IE-35, TP-1..TP-3 |

Two more found on the way, not on the list:
- **At top level, a `for` whose cursor is not declared runs nothing**, silently, at exit 0, on both roads; declared, it
  runs right (`for lp in fsrc; { ... }` with and without `lp;` in the define). In an action body the undeclared cursor
  is a local and works. Scratch probe, no row.
- **An attribute in a `define` named like a field in the same define writes that field**: `myBase pageFill="green";`
  set the field `pageFill` itself (found building the specimen's check). Not chased.

## What it says about the five

1. **Control flow -- already there, on both grammars.** break, continue, `&&`, `||`, a multi-statement else and `or` as
   else-if all answer right in an action body on incant/grammar and on kantGrammar (IE-1..IE-21). Bear-trap #32's shape
   does not bite today in a body. The only refusal is the brace, by design. typeset's flags were written without these.
2. **One argument, no return value -- partly there, the rest is design.** A return value works, and a record with named
   members comes back (IE-26). More than one argument has no spelling: `f(a, b)` loses the body, `f(a b)` hands an
   unreadable list, and `=:argument` is the old road's named-members-in, refused on kantGrammar. Clay's screwdriver.
3. **Parse results by position -- already there.** `*t.name` reads a piece by its label on both grammars, and
   `for e in t` walks the pieces (IE-24). The subscript spelling `*t["name"]` dies 139 on kantGrammar (IE-25): a grammar gap.
4. **Holder or held -- design (Clay's), narrowed by R3.** copyOf shares what a starred write reaches; copyDeep does
   not (IE-28). A compare does not deref on its own: `h == 2` silently compares the holder (IE-27), and `o.w = 5` on a
   held record crashes where `*o.w = 5` works.
5. **List walking -- already there.** `for e in h` walks a held group, unstarred, on both grammars (IE-22), and a parse
   result (IE-24); `iterate ... while ++` is the kept cursor. Gaps: `for e in *h` walks the wrong thing on the old road
   (IE-23), and the `attributes` / `members` filter is refused on kantGrammar (fixit newRoadForFilter).

## The specimen

`IncantForms/WorkingOn/ergoSpecimen`: resolveLook rewritten with continue, `&&`, `||` and `if / or / else`.
**32 lines (30 without comments) -> 19**; the flags msPh and msDone are gone. Checked byte-identical against the
original with each arm taken (look, base, refusal, skip), two setups; the file carries how.

## Fixits filed (Clay's dispatch after the census, 2026-11-19; Clod's lane, `incant/fixits/`)

multiArgLosesBody (f(a, b); NEXT is RULED, R2: refuse by name naming the request-field pattern) · starlessHeldWriteCrash
(o.w = 5 on a held record, 139) · newRoadLabelSubscriptCrash (IE-25) · oldRoadForStarWalk (IE-23) · topForNoCursor ·
defineAttrWritesField (only fields on the search list when the define is read; forms exposure: describe= in eight form
files writes utilities' describe value, the action still runs). R3: whether a compare derefs on its own (IE-27) is Clay's
write-up, not a fixit.
