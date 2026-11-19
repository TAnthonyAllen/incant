# kant patterns

How to write the things in kant that are not obvious. Each entry is the pattern in one line, a short example, and the
test row that shows it working. The rows live in `incant/pop/` and run in the test suite (`genLadder/pop.sh`); **if a
row goes red, the pattern is wrong**, so trust the row over this page.

A word you will meet: a **holder** is a field that points at another field. You make one with `:=` (`h := qa;` makes
`h` hold `qa`), and you read through it with a star (`*h`). A plain `=` copies a value instead.

Every pattern here works inside an action (`name code={ ... };`) on both of kant's grammars.

---

**1. Did a rule match?** Pick one of two spellings and keep to it: with `=` and no stars, or with `:=` and stars throughout.

    if t = cell(text);      print "matched":;       // = : t is the result; read pieces as t.val
    t := cell(text);        if *t;  print "matched":;   // := : t holds the result; read pieces as *t.val

Rows: `ruleResultT RR-2`, `RR-10` (the `=` way), `RR-11`, `RR-6` (the `:=` way). **Don't mix them:** `if t := cell(text);`
refuses by name and tells you the cure, because `t` holds a field and would always read true (`RR-3`; `while` and `do`
the same, `RR-12`, `RR-13`); and after `t = ...`, `*t.val` refuses (`RR-5`). A rule that matches with an empty piece
counts as matched (`RR-1`).

**2. A modifier belongs to the term: write it before the `=`.** `*` (zero or more) and `?` (maybe) go on the term's name.

    cell isRule val*^=[^,] comma^=",";      // an empty cell: "ab," and "," both match
    // not val^=[^,]* -- a * or ? written after a set refuses by name and tells you the cure

Rows: `ruleResultT RR-9`, `RR-17` (term first, empty matches), `RR-14`, `RR-15` (written after the set: refused). A `+`
after a set is different: it is the set's own run, one or more (`[a-z]+`), and is fine (`RR-16`). A repeated rule of
empty cells ends: `cells isRule cell+;` over `,,` gives two pieces (`RR-18`).

**3. A piece of a parse result, by its label, not by position.** Name the pieces in the rule; read them by name.

    t := pq(text);          // pq isRule reg^=[a-z]+ dot^="." name^=[a-z]+;
    n := *t.name;           x := *n.texT;

Row: `ifElseShapeT IE-24`. To walk all the pieces in order: `for e in t;` (same row).

**4. Several arguments: hand over one request field carrying them as attributes.** `f(a, b)` is not kant.

    areaReq.w = 3;          areaReq.h = 4;          print area(areaReq):;
    area code={ w = argument.w; h = argument.h; return w * h; };

Row: `ifElseShapeT IE-36`.

**5. Several results: hand back a record.** Make your own copy, fill it in through the star, return it starred.

    o := copyDeep(pair);    *o.w = argument;        return *o;
    r := mk(5);             x := *r.w;

Row: `ifElseShapeT IE-26`.

**6. Writing through a held record: put the star on the holder.** Without the star the program stops.

    o := copyDeep(pair);
    *o.w = 5;               // o.w = 5 crashes today

Rows: `ifElseShapeT IE-26`, `IE-28`.

**7. Your own copy is `copyDeep`.** `copyOf` shares its attributes with the original, so writing one writes both.

    b := copyDeep(src);     *b.depth = 7;           // src is untouched
    a := copyOf(src);       *a.depth = 5;           // src.depth is now 5 too

Row: `ifElseShapeT IE-28`.

**8. Comparing what a holder holds: star it.** A bare holder against a value refuses by name and tells you the cure.

    h := qa;
    if *h == 2;     print "two":;       // h == 2 refuses: "h holds qa; compare *h"

Rows: `ifElseShapeT IE-29` (the star), `IE-27`, `IE-32` to `IE-34` (the refusal). Two holders compared ask whether they
hold the same field: `IE-30`, `IE-31`.

**9. Else-if is `or`.** Each arm on its own line, the `or` and `else` lined up under the `if`.

    if n < 0;       print "negative":;
    or n == 0;      print "zero":;
    else            print "positive":;

Rows: `ifElseShapeT IE-5`, `IE-6`, `IE-7`.

**10. Several statements in an arm: indent them.** Braces are refused inside an action; the indentation is the block.

    if n > 0;
        print "one":;   print "two":;       // each statement on its own line, indented under the if

Rows: `ifElseShapeT IE-3`, `IE-4`, `IE-11` (indented arms), `IE-12` (a brace refuses).

**11. Two conditions at once: `&&` and `||`.** The words `and` and `or` do not work inside a condition.

    if n > 0 && n < 10;     print "small":;
    if n == 0 || m == 0;    print "a zero":;

Rows: `ifElseShapeT IE-20`, `IE-21`.

**12. Leaving a loop early: `break`, and skipping to the next turn: `continue`.**

    while n < 9;
        n = n + 1;      if n == 3;  break;

Rows: `ifElseShapeT IE-17`, `IE-18`, `IE-19`.

**13. Walking the fields a holder holds: `for e in h`, with no star.**

    h := list;
    for e in h;     print *e:;          // for e in *h walks the wrong thing on the older grammar

Rows: `ifElseShapeT IE-22`, `IE-23`.

**14. A cursor you can stop and pick up again: `iterate`.** After a `break`, a second `while ++` goes on from there.

    iterate c on list;
    while ++c;      if *c == 2;     break;          // later: while ++c; ... carries on after 2

Row: `ifElseShapeT IE-37`.

**15. Calling an action and calling a rule look the same, `f(x)`, and mean two things.**

An **action** works ON its argument: `argument` can be anything -- a count, a string, a field. It hands back what its
`return` gives.

    area code={ w = argument.w; h = argument.h; return w * h; };
    print area(areaReq):;               // 12

A **rule** READS its argument's text. On a match it hands back its label, whose pieces you read by name; on a failure,
nothing. In an `if` it is true when it matched, an empty match included. The rule's own code runs on the label, which
it reads as `*actionLabel` and hands back with `return *actionLabel;`.

    t := cell("ab,");
    if *t;      p := *t.val;            // the piece named val

Rows: `ruleResultT RR-22` (an action takes anything and returns a value), `RR-1`, `RR-11` (a rule's truth), `RR-19` (a
rule's code and its label). Three things to watch, each pinned as it reads today:
- a rule called with no argument, or with an argument that has no text, refuses by name on the newer grammar and reads
  false in silence on the older one (`RR-20`, `RR-21`);
- an action with no `return` reads true in an `if` (`RR-24`), so give it a `return` if you test it;
- an action that returns its argument when that argument is 0 reads false on the older grammar and true on the newer
  (`RR-23`); return a value you computed, not the argument itself, until that is settled.
