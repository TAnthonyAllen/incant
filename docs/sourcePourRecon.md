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
  (`incant/pop/heldFieldEndT`). delimitedData's `#end` line and its `#end` test are no longer needed: a copy without
  the line reads both records and ends cleanly.
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

## Open for the exercise
- How pour two finds its targets: a scan of every field, or a `Topics/fieldIndex` lookup.
- The syntax of query fields.
- How delimitedData splits into a source.

## Where things are
`IncantForms/WorkingOn/delimitedData` (Tony's, working: two records of four named fields from `Tests/delimitTest`,
three columns skipped); `incant/attic/heldFieldEndLosesFile` (retired, cured); pour in `incant/utilities` (pourPlan, fillDownAcross,
pourWrite); `docs/popupsRecon.md` section 6 (the return link); `Topics/features` 31 and 34 (the data topic, text poured
into a form); `Topics/fieldIndex`.
