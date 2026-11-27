# Borrowed ideas: what each of Tony's three steals would involve (SEQ 797, 2026-11-27; read-only)

Clay's go order GO 3, ruled by Tony ("recon only ... assess what would be involved"). Nothing was built; no fixture
is in the tree. Each claim is READ (source, file:line as of this date), COUNTED (a grep over tok source, not .mm) or
MEASURED (a scratch fixture on the trunk binary of seal 554, one process a row, exit status taken from the binary).
The direction itself is recorded in `docs/borrowedIdeas.md`. No syntax is proposed here.

## A. APL: arithmetic on whole lists

### A1. What the eight operators do today with a list (MEASURED, 120 rows, every one exit 0)

The operands: `va` and `vb`, each a field with three named members holding 1 2 3 and 10 20 30; `mm`, two rows of two;
`n = 5`. Each row was run at the top level, in an old-road action body, and in a `newRoad` body.

| statement | top level and old-road body | new-road body |
|---|---|---|
| `va + vb`, `va + n`, `n + va`, `mm + mm`, `mm + n`; the same with `-` and `*` | refused by name: "Operator + -- cannot apply to these operands" | the same refusal |
| `va / vb`, `n / va`, `mm / mm` | refused by name: "Operator / -- not supported for these operands" | the same |
| `va / n`, `mm / n` | **no refusal: the result is the number 0** | the same |
| `va += vb`, `va += n`, `mm += mm`, `mm += n` | the argument is appended as ONE new member (3 becomes 4; 2 becomes 3) | **"ERROR Operator += failed on va and vb"; the target is unchanged** |
| `n += va` | refused by name: "+= of a list or dataless argument onto isCOUNT" | "ERROR Operator += failed on n and va"; n unchanged |
| `va -= vb`, `va -= n`, `mm -= ...`; the same with `*=` and `/=` | nothing changes and nothing is said | the same |
| `n -= va`, `n *= va`, `n /= va` | n stays 5 and nothing is said | the same |

Three things stand out. `list / number` hands back 0 with no word (`opDiv` tests only its argument's kind,
Instruct.rtn:325). `-=`, `*=` and `/=` on a list are silent no-ops. And `+=` onto a list differs by road: the old road
reaches `opPlusEQstruct` through `pickKindOP` (GroupActions.rtn:659-676, Instruct.rtn:1001), the new road lands in the
plain `opPlusEQ` and prints its error (Instruct.rtn:889-899).

Fleet rows that pin today's answers: the per-kind `+=` arms in kindT and kindJitT (genLadder/pop.sh, the KINDARM rows
near :7654 and :7698) and the grafting row "printFamilyNew graft: arms on WardeD" (:7843). No row was found that pins
`list / number` reading 0 or the silent `-= *= /=`; the population searched was pop.sh's kindRow lines naming graft,
concat, opPlusEQstruct or appends.

### A2. A matrix as its own kind (Clay's lean, tested against the tree)

- There is room. The data kind is a 5-bit field with 14 names used (GroupBody.twk:57), so a fifteenth name appended at
  the end shifts no layout and renumbers nothing. It is still a GroupBody change: groups.ext and a full tokall. READ.
- `checkOP` picks an operator's member named `<op><kind>` when the target has data (GroupItem.twk:335;
  GroupActions.rtn:671). So a new kind gives `+=` its own arm by one line in incant/setup beside the seven there now
  (incant/setup:214-220), and `+=` on a plain list still goes to the struct arm and appends. The lean holds for the
  four assigning operators. READ.
- It does NOT hold as is for `+ - * /`: those four have no per-kind members at all; each is one C++ method with its
  kinds tested inside (Instruct.rtn:318, :664, :772, :855). An elementwise arm there is either a new test inside each of
  the four, or per-kind members added for them as `+=` has.
- What a new kind touches, COUNTED: the name table `dataName` (genParse.rtn:26, one line); 64 `case is...:` arms in 7
  files and 12 `switch(data)` sites, each to be read for whether the new kind needs an arm (GroupItem.twk 29,
  Commands.rtn 15, Instruct.rtn 5, GroupActions.rtn 4, Debug.rtn 4, RuleStuff.twk 4, Generate.rtn 3); the kant
  jitter's kind names (irCOUNT / irNUMBER, 21 mentions in incant/kantJitter, 12 in incant/setup). As a yardstick,
  isBUFFER, the nearest existing packed kind, is named 27 times in 6 files.
- Packed or one field a number. Packed (one buffer of doubles and a shape): the interpreted arm is one C++ loop a
  operator, and the jitter can address it as memory; but every existing reader of a list (for, iterate, subscripts,
  listLengtH, print, pour) sees no members, so each needs an arm or the matrix must be unpacked to be walked. One
  field a number: every reader works unchanged and a matrix is just a list of lists; the interpreted arm walks two
  lists in step; the kant jitter gains nothing, since each element is a boxed field reached by a helper call.
  NOT MEASURED: either cost.

### A3. Where the arms would sit

- Interpreted: beside the per-kind `+=` arms in Instruct.rtn, reached by `checkOP`; for `+ - * /`, see A2.
- Kant jitter: `krResolve` marks an instruct native only for count and number today; a matrix operand would be a third
  mark, and the walk would emit a loop. The jitter's text has 16 lines using alloca, branch labels or phi today and
  **no getelementptr at all** (incant/kantJitter, COUNTED): it has never indexed memory. What it lacks: a way to get a
  buffer's address and length from a field (a named helper, as irCountOf is), indexed load and store, and a loop
  written by the walk rather than taken from a kant `while`.
- Does it need full monty step 4 first? The emitter does not. Reaching it from ordinary action bodies does: today the
  kant jitter runs only where a fixture calls it by hand.

### A4. Errant, and where each would be refused

- Unequal shapes: in the elementwise arm, before the first write (the storeRuling: an armed statement stores nothing).
- A number with a matrix applying to every element: the same arm, argument kind count or number.
- An element that is no number: for one field a number, at that element, naming it; for packed it cannot happen
  after the matrix is built, so the refusal moves to wherever a matrix is made.
- The jitter: the shape test must be emitted too, or the statement handed to the interpreted arm when shapes are not
  known at compile.

### A: what it would involve

MEDIUM for the interpreted arm with one field a number (mostly C++ in Instruct.rtn, one setup line an operator, rows);
LARGE with a packed kind and a jitter arm (a GroupBody kind, every list reader, new jitter machinery). Must exist
first: nothing for the interpreted arm; the new road's `+=` reaching the per-kind arms (measured: it does not today).
For Tony, one question each:
1. Packed, or one field a number? (It decides whether the jitter arm is worth having.)
2. Does `+=` on a plain list keep appending, with elementwise only for the matrix kind? (Clay's lean.)
3. Are `list / number` reading 0 and the silent `-= *= /=` on a list defects to cure now, or left until this is built?

## B. Messages and listening

- **A notified action knows nothing about what fired it.** `listenTo` adds the listener to an attribute `notifyLIST`
  on the field listened to; "the listener does not remember the field or fields it listens to" (Commands.rtn:398-415).
  A write calls `updateListeners` (GroupItem.twk:2073), which calls `runNotified` (GroupItem.twk:1665-1669): the
  listener's method or action is run, handed the listener itself; the notifier is passed to nobody. READ.
  MEASURED (scratch `lsn`, exit 0): in a notified action `argument` and `this` hold nothing, and a bare `taG` reads
  the action that did the write, not the field written.
- **One action listening to two fields is not built.** MEASURED: with two `listenTo:=` on one action, a write to the
  first fired it 0 times and a write to the second fired it twice; the last wins and is listed twice (incant/pop/listenT
  records the same). So Tony's HPDL problem, "cannot tell which fired", sits behind this one. Cause not traced.
- **The conversation line.** `tell("target message")` (incant/utilities:11; aCTionTell, GroupActions.rtn:1) drives the
  target's own grammar through `driveStep` and returns a verdict: matched, consumed, length, stoppedAt, known, reply.
  Steps 1 and 2 are pinned (incant/pop/convDriveT, rows CD-1, 2, 3, 5); a matching member's action is PARKED on the
  reply label, not fired. Step 3 is not built: CD-4 has been red since 2026-09-23 and is banked. Still needed: a kant
  verb that fires the parked action, and a default handler for a message that matched nothing. READ.
- **A message as a small field.** What changes: `runNotified` binds an argument where today it calls
  `processAction(notified)` with none; `updateListeners` already knows the sender (it is `this`). What stays: the
  `notifyLIST` attribute, `hasListeners`, the write sites that test it, seals 549-550's rules, and the value copy for a
  listener with no action. Users today, COUNTED: 10 fixtures in incant/pop, one line in incant/setup, IBkant;
  incant/utilities and Topics/forms have none. The blast radius is small.
- **The two chains.** The parent chain is readable from kant (`parenT`) and `clickField` already climbs it, across a
  held form into its host (incant/utilities:3305-3318). ruleOf (what a field is a copy of; GroupItem.twk:46-48) has no
  kant accessor. A lookup that tries the field, then one chain, then the other, in a stated order, is new. READ.
- **The loop guard.** MEASURED: writing the same value again fires the listener again. One guard exists:
  `updateListeners` lowers `hasListeners` during its own walk, so a field's listener writing that field does not
  re-fire (GroupItem.twk:2077-2081); A firing B firing A is not stopped. A same-value guard would sit at the write
  sites, where old and new are both in hand; a cycle guard in `updateListeners`.

### B: what it would involve

MEDIUM. Mostly C++ and small: `runNotified` binding an argument, a ruleOf accessor, the fire verb, the default
handler. Kant: the pass-up walk (clickField's shape) and the message field. Must exist first: more than one
`listenTo` on an action working. NOT DETERMINED: whether binding an argument in `runNotified` disturbs the frame of
an action already running; the jitted write path (jitEmitters.rtn:666 calls `updateListeners` directly).
For Tony, one question each:
1. Is "you changed" delivered to today's listeners as a message too, or do plain listeners keep the no-argument call?
2. Which chain does an unanswered message climb first: what the field is a copy of, or its parent?
3. Should a same-value write stop firing listeners? (It would move listenT's pinned counts.)

## C. Rules on fields

- **The input today is one character pointer**, `atRuleMark` (pushInput, GroupRules.twk:320-349). COUNTED: 85 mentions
  in 9 files. About 41 are in 14 leaf matchers that read characters and advance the mark (RuleStuff.twk's test family,
  upToMatch, parseR; Generate.rtn's parseCharacter, parseSet, parseString, parseContainer, parseCondition,
  parseAction; aCTionCodE). The rest is bookkeeping: save, restore on failure (exitFromParse, Generate.rtn:74, :103),
  skip and guard (one character against a set), the reports.
- **The structure above the leaves never touches characters.** `testAttributes` walks a rule's attributes in turn and
  needs all; `testOptions` takes the first member whose guard passes (RuleStuff.twk:205-217, :259-266). READ.
- **`pushInputField` pushes a field's TEXT, never its list** (Commands.rtn:613-629). The only list-walking state is
  the iterate cursor (aCTionIterate; the isIterator arms of `++` and `--`, Instruct.rtn:732, :1026): one list, one
  cursor, no rewind stack. READ.
- **Attributes by name in any order, members in order: half natural.** Members in order is natural: an ordered list
  and a cursor with a saved position is the mark. Attributes by name is natural on the field side (`getAttribute` is
  how every read works) and forced on the rule side: a rule's own attributes are an ordered sequence, and nothing in
  the parse looks a term up by name in the input. It would be a third kind of test, not a re-aim of the sequence walk.
  Repetition (min, max) means something for members; for an attribute it can only mean present or optional.
- **Capture.** The label machinery is input-agnostic above the leaf, and attaches only on success (Ruling E-A).
  Reading a result is built on both grammars (`*t.name`, `for e in t`; docs/ergoCensus.md). New: the captured piece
  would be a field, where captureSpan and mintLabel assume a text span. Note `*t["name"]` ends at exit 139 on
  kantGrammar (ergoCensus IE-25): the spelling that stopped drawImage today.
- **A kant action that rejects a match** (macros open question 1; features 21). Not required for structural matching
  (has this attribute, has members of this shape). Required as soon as a guard compares a value.
- **The first customer, the guard of pour two** (docs/sourcePourRecon.md): a flat record, attributes by name and their
  values; no members, no order, no repetition. So it needs only the attribute-by-name half plus value tests: the half
  that needs the rejecting action, and not the cursor.

### C: what it would involve

MEDIUM for the pour-two guard alone; LARGE for general rules on fields (members in order, repetition, nesting,
backtracking over a cursor). Mostly C++: a second input kind beside the mark, field-side leaf tests beside the 14 text
leaves, a capture that holds a field, guard and skip switched off for that input. Kant: the customers and the
rejecting actions. Must exist first: the kant rejection for any value test; the `*held["name"]` crash cured if results
are read by subscript. NOT DETERMINED: whether GroupItem::parse can be driven with no text source; how the new-road
reader and the compiled rule door would see a field input. Nothing in part C was run.
For Tony, one question each:
1. Is the first cut the flat record only (for pour two), with members in order left for later?
2. Does a term naming an absent attribute fail the rule, or is it optional as a min of 0 is in a text rule?
3. Is a value test a rejecting kant action (features 21 first), or a literal on the term compared by the engine?

## Seen across all three

The `*held["name"]` crash on the new road came up three times in one day: drawImage (full monty group 1), ergoCensus
IE-25, and reading a match result by subscript. And the new road's `+=` does not reach the per-kind arms. Both are
new-road gaps that sit under more than one of these plans.
