# PLG Delimited-File Parsing Recon — 2026-05-29

**Scope.** Follow-on to `plg-file-manipulation-recon-2026-05-29.md` (which
concluded "the delimited-file capability isn't in `Parse/BeforeRefactor/`").
Tony surfaced that PLG generated a class called `ParseXML` that did the
work; archived copies exist in `OLDtawkDoNotTouch/Groups/` and
`InProcess/Groups/Aside/BeforeSimple/`. Recon target:
`Aside/BeforeSimple/ParseXML.{g,act,rtn}` plus `Delimited.{g,act}` (which
ParseXML.g includes).

## Bottom line

The mechanism is small (~500 lines total across grammar + actions +
runtime) and elegantly parameterized. Port to incant is **3 files of
modest size** plus one PLG idiom (the `delimitSet` parametric-grammar
trick). And it brings JSON parsing along for the ride — same field-spec
machinery serves both.

The user-facing surface from `playlist.xml`:

```
<phone list heading delimiter="\t" endRecord="\r" fields=playListFields file="stuff.txt"/>
```

decomposes into:

- **The grammar** (`Delimited.g`, ~70 lines): tokenizes delimited fields by
  type (Date / Number / Text / Empty), with a `Heading` rule for the
  optional first-row column-names and a `List` rule for the body.
- **The actions** (`Delimited.act`, ~75 lines for the delimited half):
  per-rule callbacks that build GroupItems and decide what to keep.
- **The runtime** (`ParseXML.rtn` lines 308-508 + 748-794): `loadDelimited`
  (entry), `loadFieldSpecs` (the projection mapper), `processDelimitField`
  (per-field consumer).

## The mechanism

### 1. Entry: `loadDelimited(specs)`
`ParseXML.rtn:308`. Reads the `<phone .../>` attributes from `specs`:

| Attribute | Effect |
|---|---|
| `file="..."` | source path (also accepts URLs via `isURL` / `getURLintoBuffer`) |
| `heading` | flag: first row is column names |
| `noSkip` | flag: don't apply default whitespace-skip |
| `delimiter="..."` | field separator char (default `,`) |
| `endRecord="..."` | record terminator char (default `\n`) |
| `skip="..."` | name for skipped placeholder columns |
| `into=...` | destination registry/group for output records |
| `fields=...` | reference to the field-projection spec (e.g. `playListFields`) |

It then primes the global `delimitSet` PLGset with the two delimiter
characters (this is the parameterization trick — see below), slurps the
file via `divertInput(getStringFromFile(inputFile))`, optionally parses the
heading row, applies the field-projection via `loadFieldSpecs`, then runs
the `List` rule to consume the body. `revertInput()` at the end.

### 2. The `delimitSet` parametric-grammar trick

`Delimited.g:17` declares `Set delimitSet [,\n]`. Every rule in the
grammar (`DelimitText`, `DelimitNumber`, `Heading`, `DelimitFieldName`,
etc.) references `delimitSet` as the field-end marker.

At runtime, `loadDelimited` does:

```
delimitSet.clear();
delimitSet.set(delimiter);
delimitSet.set(endRecord);
```

…which re-primes the same set with the user's actual delimiter and
endRecord chars. **The grammar doesn't know it's TSV vs CSV vs anything
else** — it just knows "the set of chars that ends a field." One
declaration, infinite formats, via mutable shared set.

**Single-load-at-a-time invariant** drops out of this: you can't have two
concurrent delimited loads with different delimiters because they'd
clobber each other's `delimitSet`.

### 3. The grammar (`Delimited.g`)

Tiny — `~70` lines:

```
DelimitField  :  item = DelimitDate
              |  item = DelimitNumber
              |  item = DelimitText
              |  item = DelimitEmpty;

Heading       :  DelimitFieldName+;

Skipping      :  skip = SkipGuard
                 data = delimitSet};

FieldItem     :  skips = Skipping*
                 item  = DelimitField;

List          :  FieldItem+;
```

`DelimitField` is a tagged-union — first-match-wins ordering: try date,
then number, then text, then empty. Typed columns get typed
automatically in the resulting GroupItems.

`FieldItem` wraps each value with optional `Skipping*` — the skip
mechanism for columns the user doesn't want.

### 4. Field projection: `loadFieldSpecs(fieldSpecs)`

`ParseXML.rtn:434`. This is the column-pick. For each entry in the spec
(`playListFields` in our example):

```
playListFields
    Name=song
    Artist=artist
    Album=album
    Genre=genre
    Year=year
    Time=time
    Location
```

- `item.tag` is the **column name** as it appears in the file (`Name`,
  `Artist`, etc.) — matched against `fieldRegistry`.
- `item.text` is the **rename target** (`song`, `artist`, etc.) — assigned
  to `field.text` on the matched registry entry.
- Matched fields get `fLAG = true` — that's the "keep this column" signal.
- Entries tagged `skip` create placeholder slots. `skip=3` skips 3 columns
  in a row.
- Field attributes recognized at projection time: `key` (use as record
  tag), `noMerge` (don't merge into target record), `mdy` / `ymd` (date
  hints — currently commented out, see Tar Babies).

If `specs["fields"]` is absent, all known columns get flagged ("take
everything"). If the file has a heading row, `fieldRegistry` was already
populated from those column names; projection just flags subsets.

### 5. Per-field consumption: `processDelimitField(item)`

`ParseXML.rtn:748`. Fires from `FieldItem!` action. For each parsed field:

- If the field's `fLAG` is set (column is wanted), `runDeferred()` builds
  the field's value into `block`.
- If the column was marked `isTarget` (`key` attribute), the field becomes
  the record's tag.
- On reaching `endRecord` (the record-terminator delimiter), the
  accumulated `record` gets pushed into `list` (the output destination).
- Skipped fields just advance past.

### 6. `SkipGuard!` action

`Delimited.act:76`. Checks `fieldRegistry.nextMember(0).fLAG` — if the
current column position isn't flagged for keep, returns `false` (which
in PLG action-land means "skip this match"). That's how the projection
filters in the grammar layer.

## Tar babies

Things worth flagging while we're in this neighborhood:

1. **JSON parses through the same machinery.** `Delimited.g` defines
   `JSONblock`, `JSONpair`, `JSONlist`, `JSONrepeat`, etc. immediately
   below the delimited rules. `loadJSON()` (`ParseXML.rtn:514`) reuses the
   same `loadFieldSpecs` for field-renaming. **Porting delimited brings
   JSON for free** — the projection and registry machinery is shared.
2. **URL load support.** `loadDelimited` checks `isURL(inputFile)` and
   falls back to `getURLintoBuffer` if so. Old PLG could load a TSV
   straight off a URL. Worth noting we lost that too.
3. **Date typing is disabled.** Lines 482-497 are commented out: original
   PLG could detect MDY/YMD-format date columns via `field["mdy"]` /
   `field["ymd"]` attributes and parse them into structured date objects.
   Field types were rich. If we port, decide whether to revive.
4. **`fieldRegistry` is the `LoadFields` registry.** Single global —
   reused across `loadDelimited` and `loadJSON`. Implies one load at a
   time; concurrent loads would corrupt each other's column state.
5. **`into=registry` attribute.** Not in the playlist example but
   supported: pipes records into a named registry rather than the
   default. Lets you chain loads into specific data containers.
6. **Heading auto-discovers columns.** `hasHeading=true` + no `fields=`
   spec = take all columns named in the first row. Nice ergonomic for
   exploratory loading.

## Findings (no fixes)

- **Procedural side-effecty style.** `processDelimitField` mutates a lot
  of file-scope state (`record`, `block`, `list`, `delimitSet`,
  `fieldRegistry`). Single-threaded by design. Porting to incant should
  decide whether to keep that or restructure.
- **`delimitSet` as a global is the reason for the single-load
  constraint.** Multi-format streams (a TSV containing embedded CSV
  fragments) wouldn't work. Fine for the common case.
- **Date logic commented out, not deleted.** Someone backed it out for a
  specific reason; the code is preserved in case of revival. The "//" is
  a soft delete.
- **Comment at `ParseXML.rtn:822` reads "isPath IS NEVER SET".** Marked
  dead-code in the path-processing logic. Not delimited-related but
  worth noting as recon-incidental.

## Port-to-incant feasibility

**Size**: ~500 LOC across three files. Small.

**Translation effort**:

1. **`Delimited.g` → incant rules.** Straightforward — the rule shapes
   match incant's existing rule syntax. `DelimitField` is a `|`-alternative,
   `Heading` is a `+`-list, `List` is a `+`-list of `FieldItem`. The PLG
   `~.` (any char) idiom would need an incant equivalent — most of these
   probably already exist.
2. **`Delimited.act` → incant actions.** All small per-rule callbacks;
   each becomes an incant action or extern. The `SkipGuard!` "return
   false" semantics (rule rejects the match) needs to map to incant's
   guard mechanism.
3. **`loadDelimited` / `loadFieldSpecs` / `processDelimitField` → incant
   externs.** These are C++ already; they could be written either as
   incant externs (in a new `.rtn` file alongside `Commands.rtn`) or as
   pure incant actions if we want to dogfood. Recommend externs to start —
   matches the spirit of `Commands.rtn`.
4. **`delimitSet` parameterization.** Incant has `PLGset` (via Maps) and
   the existing grammar uses Set declarations. The same shared-mutable
   pattern should translate directly.
5. **`divertInput` / `revertInput`.** Incant already has equivalents
   (`pushInput` / `popInput`). One-line maps.
6. **`getStringFromFile`.** `getFile` in incant (the C extern in
   `Commands.rtn`) loads a file into a buffer. Close fit; may need a
   string-form variant.
7. **`getURLintoBuffer` / `isURL`.** Not yet in incant. Defer or stub.

**Bonus capability**: porting brings JSON loading along for free since
`loadFieldSpecs` and `LoadFields` registry are shared. `JSONblock` /
`JSONpair` etc. are all in the same `Delimited.g` — just include the
whole grammar.

## Recommendation

When Tony's ready for the file-manipulation arc:

1. Port `Delimited.g` → `incant/delimited` (rules file, no extension).
2. Port `Delimited.act` actions → mix of incant action definitions and
   externs in a new runtime file (call it `Loading.rtn` to bracket
   `Commands.rtn`?).
3. Port `loadDelimited` / `loadFieldSpecs` / `processDelimitField` as
   externs in the same file.
4. Decide on `delimitSet` parameterization — same global-mutable
   approach is simplest; alternative is rule-with-set-param if incant
   eventually wants concurrency.
5. **Tar baby decisions to make at port time**: date typing (port or
   skip), URL loading (port or stub), `into=` destination
   (port — it's used in the spec), heading auto-discovery (port — small).
6. JSON parsing comes along for the ride.

The "playlist.xml" use case is the canonical test fixture — once the port
is done, that file should load `stuff.txt` and produce a `phone` group with
records selected and renamed via `playListFields`.
