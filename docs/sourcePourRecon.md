# Source, pour, destination: the agreed shape (banked 2026-11-25)

Tony's offline note of 2026-11-25 (after `IncantForms/WorkingOn/delimitedData` worked), his two follow-ups the same day,
Clod's reactions, and Clay's dispatch (Tony's ruling R2). **This is a banked shape for a design exercise, not a build
plan.** Nothing here is built. The exercise is Tony's and Clay's; the build follows in strokes ruled at its end.

## Why
delimitedData does too much: it reads fields, names them, decides which to keep and stores the records. The source
should hand over data and decide nothing; the destination (the form) says what it wants; the pour carries one to the other.

## The source
- `getRecord()` hands back ONE record field, reused for every record and tagged `record`, so no new tags are minted.
  Its data is the record count. Its attributes are named once, from a header row or by field number, and are emptied
  at the start of each record (a reused attribute would otherwise show the last record's value).
- `getField(n)` skips n fields and fills the next attribute. The pour works out n from the names its form fields ask
  for. A skip still scans for the delimiter; it saves the minting and the copy.
- The source signals "ended". CURED 2026-11-25 (SEQ 779, on branch held-field-end until bought): a field pushed with
  pushInputField is its own floor, so a rule that reads it to its very end fails there and the calling file goes on
  (`incant/pop/heldFieldEndT`). delimitedData's `#end` line and its `#end` test came out 2026-11-25 (SEQ 781): it reads
  both records and ends cleanly.
- A row with too few fields is refused, naming the record count. A row longer than the first, so with no name for its
  extra fields, is refused too.
- A file source is read-only. A registry source takes writes (popups stroke 4b's link: pourWrite).
- Today's pour already has a source: `pour:=aRegistry` walks a registry and each member is a record. A registry and a
  delimited file are two sources behind one small contract.

## The pour
- Pour one (what exists): feeds the form field by field, the next source field into the next form field that wants one.
- Pour two: every form field sees every record, as a guard (does this record match?) plus an action (what the field
  does with it: add a salary, count one). A field that keeps a running total gets a "pour ended" signal.
- The pour builds its field list from the destination form's fields; no one types it by hand (Tony, 2026-11-25).
- The two stay separate: in one the form consumes the source; in the other the source is shown to every field.
- Reading a record during the pour is free. Keeping one means `copyDeep`, done by the pour on behalf of a collection
  form: `copyOf` shares the original's attributes by design (Tony, 2026-11-25), and the record is reused.

## The destination
Display forms, collection forms (building a list) and query forms (a few fields that are all pour-two targets), and
combinations of them through embedded forms.

## Extensions (Tony, 2026-11-25, worked through with ChatGPT; his full text is below the stop() in IncantForms/WorkingOn/delimitedData)
Banked by Clay's dispatch (ruled by Tony, SEQ 781). Still a shape, not a build plan.

**Listening and the middleman.** B listens to A and hears every change; listening is not filtered. A middleman is not
a new kind of object, just a field with an action: it hears every change and changes its own data (so its own
listeners fire) only when it decides to. A pour can be both a customer and a provider: source -> pour -> pour -> field.
A chain moves data by push (listening) or by pull (the customer asks for the next record); the customer decides which.
A field listening to several fields, and knowing which one fired it: HPDL.

**A pour need not know about forms.** A pour is invoked from a field, which may or may not be a form field. Two kinds
of customer: a form (the pour holds the field list, built from the form's fields, as ruled above) and a lone field.

Refinements:
- A pour pours a field; the receiving field decides what to do with it. With no action, the default: take the
  attribute whose tag matches the receiving field's tag; if the poured field has no attributes, take it as is.
- Advancing: a field receiving a pour may say "next record" (in a form, usually its last field). Any field may be
  poured into and decides when to advance; in `iterate grup on aPour`, the `++` is the advance. Redisplay never
  advances a source (a resize must not count a record twice).
- Source data and source instance: "next" belongs to the instance, so two instances read the same data independently,
  as two iterators on one list already do.

**Measured 2026-11-25 (SEQ 781, read-only; scratch probes, kant top level and action bodies on the old road):**
- Listening lives in `listenTo` (Commands.rtn), `updateListeners` / `runNotified` (GroupItem.twk) and the operators'
  writes (Instruct.rtn); `incant/pop/listenT` and `notifyT` pin it. A listener fires on every value write to its
  notifier, including a write of the value it already holds. A write to one of the notifier's attributes fires nothing.
- The middleman works today: B's action ran once per write to A, and C fired only on the writes where B changed its
  own value (B written from a computed value, `mB = mB + 1`).
- One defect in the way, F-170 (`docs/fixIts.md`): a middleman that writes `B = A`, with A listened to, takes A's
  listener list in place of its own. C never fires again, and A's listeners then fire on writes to B.
- `incant/grammar`'s IterSource is `UnaryOPS? ANYtoken`: one name, optionally starred, not an expression. So
  `iterate grup on aPour` parses in action bodies and forms, but its action (aCTionIterate) walks a list the source
  already holds; nothing fetches a record on demand. kantGrammar's ITERATe takes an EXPRESSIOn, with the same limit.

## Open for the exercise
- How pour two finds its targets: a scan of every field, or a `Topics/fieldIndex` lookup.
- The syntax of query fields.
- How delimitedData splits into a source.
- Two fields saying "next" in one pass (Clay's lean: the first counts, later ones warn).
- No field saying "next": the pour stays on the record; not an error.
- How customers hear "pour ended".
- The default action when no attribute matches the receiving field's tag.

## Where things are
`IncantForms/WorkingOn/delimitedData` (Tony's, working: two records of four named fields from `Tests/delimitTest`,
three columns skipped); `incant/attic/heldFieldEndLosesFile` (retired, cured); pour in `incant/utilities` (pourPlan, fillDownAcross,
pourWrite); `docs/popupsRecon.md` section 6 (the return link); `Topics/features` 31 and 34 (the data topic, text poured
into a form); `Topics/fieldIndex`.
