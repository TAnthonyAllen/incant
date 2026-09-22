# The fleet's RED LIST — banked by name, not by count

**Clay's SEQ 172 amendment 4, 2026-09-20.** A count cannot be diffed. This file exists because
the 2026-09-20 wakeup found green matching the seal exactly at 426 and red reading **60**
against a stated **61** — with Tony's edits and the new rows both controlled for — and there was
**no list to diff against**, so the one-row difference could be stated and never explained.

**Regenerate at every seal:** `./genLadder/pop.sh | grep '^  FAIL' | sed 's/^  FAIL  //'`, and
diff this file. A row that leaves without a sentence is the thing this is here to catch.

⚠ **AND IT COVERS `decodePop` AND `ddPop` TOO, BECAUSE THE SAME HOLE WAS THERE.** The 09-19
seal recorded decodePop at *14 green / 6 red* and the 09-20 seal recorded *14* with no red count
at all; today it reads **14 green / 9 red** and there is nothing to diff it against. One
instrument's missing list is an accident; two is the convention being too narrow.

⚠⚠ **RUN THESE TWO WITH `bash`, NOT AS `./genLadder/<name>.sh`.** `decodePop.sh` and
`formsPop.sh` are **not executable** (`pop.sh` and `ddPop.sh` are), so the bare invocation is
*permission denied* -- and a wrapper can swallow that. Measured this seal: a
`perl -e 'alarm N; exec @ARGV'` wrapper returns **exit 0 when the exec itself fails**, so both
read as a clean pass with an EMPTY output file. An empty capture at exit 0 is not a green; check
that an instrument printed something before believing its status.

## 2026-09-22, midday seal — 433 green / 64 red / 2 parked

**Diff against the 09-21 list below, and it closes exactly: 63 + 1 = 64.**
- **`modSeamT MS-3` JOINED** — born red 2026-09-22, by design. `optT("a")` on the new road
  reports WIN while its mark has not moved off the drive string's base: **consumed 0, want 1.**
  It is the anti-vacuity pair to MS-1, which reads the same verdict on the old road and a mark
  that has LEFT the drive string. SEQ 192.
- **Nothing else moved**, row for row, across two landings — the SEQ 191 `attachLabel`
  conversion and the SEQ 192 specimen. Both were diffed against a capture banked before the
  first edit.
- ⚠ **`chainTruthT` CT2/CT3/CT4 ARE STILL HERE AND NEARLY LEFT.** `sukcess = truthOf(result)`
  takes all three green and takes **CT1 red** plus `parserTest` to 2 of 4 roots; reverted whole,
  F-95 attempt 3. **If these three ever leave without CT1 staying green, that is the same trade
  being banked rather than a fix.**

```
holderT 1 direct    .parenT = htWindow -- got: holderT 1 direct    .parenT = htU want htWindow 
holderT 2 identity  .taG    = htInside -- got: holderT 2 identity  .taG    = htKid want htInside 
holderT 3 holder    .parenT = htWindow -- got: holderT 3 holder    .parenT = htP want htWindow 
spacingT A tight-1  = spA -- missing
spacingT B tight-2  = spB -- missing
spacingT C spaced   = spC -- missing
spacingT D tight-3  = spD -- missing
spacingT E survived -- missing
spacingT '*' named refusal missing -- its guard stopped naming it
spacingT '+' named refusal missing -- its guard stopped naming it
spacingT '-' named refusal missing -- its guard stopped naming it
spacingT '>' named refusal missing -- its guard stopped naming it
spacingT '<' named refusal missing -- its guard stopped naming it
spacingT '==' named refusal missing -- its guard stopped naming it
spacingT '>=' named refusal missing -- its guard stopped naming it
spacingT '<=' named refusal missing -- its guard stopped naming it
spacingT F marker missing -- the operator rows did not run
spacingT G a + **b  = spG -- got: 
spacingT G2 a + *b  = spG2 -- got: 
spacingT H a +* b   = 1 -- got: 
spacingT I a+*b     = 1 -- got: 
starT S1  *x   one-deep   = stA -- moved
starT S3a **x  ONE-deep   = stD -- moved
starT S6  a.b     holder   = stH -- moved
pointerT F2 null operand = 0 -- moved
pointerT X witness MISSING -- the star no longer binds to ptBagP
pointerT L3 witness MISSING -- the = -then-star refusal changed
pointerT F2 witness MISSING -- +* no longer names its refused operand
pointerT L4e -- body=#2 not on the line after its label
pointerT L5b -- isCopy=0 not on the line after its label
pointerT L6a -- field=#10 not on the line after its label
pointerT L6b -- field=#10 not on the line after its label
pointerT L6c -- field=#6 not on the line after its label
pointerT L6d -- field=#11 not on the line after its label
ADDROF faSrc field=#3 body=#2 -- moved
faceT F2 flags FORWARD  = 1 -- moved
faceT F3 flags REVERSE  = 1 -- moved
rung7.target
parseClass.target (setParse classification)
fires=NEVER roster MOVED
anyOrNumT census moved -- the isGROUP poison is back or generation changed
anyOrNum.target (generated bodies + the parsed answer)
chainTruthT CT2 "search list" -> match=1, want 0
chainTruthT CT3 "search ;" -> match=1, want 0
chainTruthT CT4 "search" -> match=1, want 0
searchNewParseT SNP term `SemI` did NOT dispatch -- F-90 is back.
spell.target (emitLeaf: 5 kinds x 2 sinks; emitter's own refusal NOT covered)
bindSeamB -- no promote=0 Braced attach; the cross-file bind is NOT being read,
displayForm baseline (interpreter pin)
starIdiomT row 2 -- the star did not refuse a null by name. Either the
doWhileNameT runs (exit 139)
doWhileNameT sentinel -- THE RUN TRUNCATED. A row stopped parsing and every
doWhileNameT DW-6 dwN == <absent>, want 2 -- BORN RED 2026-09-21.
doWhileNameT DW-8 the DW-5 window NEVER CLOSED -- its RETURNED marker is
modSeamT MS-3 NEW road consumed 0, want 1 -- BORN RED 2026-09-22.
carrierT CT-3 sumGrup still in list CodE -- the action BODY survived, by its own local -- MOVED. Wanted: sumGrup
carrierT CT-5 the label gap is GONE. If label population landed, that is
firstUseT FU-2  isCodeD 1 -- the flag read reaches a real node (non-zero sibling) -- MOVED. Actual:
oneTest baseline
countPop headline moved
trigDO arm 1 -- the good input did not parse and attach. Actual:
trigDO arm 2 -- a broken term did NOT fail the parse. Actual:
trigDO attached under DO 0 times, want exactly 1
walkRefT row 3 = wrHeld -- THE FLIP HAS LANDED, or the binary is
```

## 2026-09-21, midday seal — 429 green / 63 red / 2 parked

**Diff against the 09-20 list below, and it closes exactly: 62 - 1 + 2 = 63.**
- **`jsonTest baseline` LEFT** — parked by Tony's ruling, not fixed. F-99.
- **`doWhileNameT DW-6` and `DW-8` JOINED** — born red 2026-09-21, by design, and
  they now read REAL VALUES rather than truncation artifacts.
- **Nothing else moved.** Every other row is the same row it was at the 09-20 shutdown.

```
ADDROF faSrc field=#3 body=#2 -- moved
anyOrNum.target (generated bodies + the parsed answer)
anyOrNumT census moved -- the isGROUP poison is back or generation changed
bindSeamB -- no promote=0 Braced attach; the cross-file bind is NOT being read,
carrierT CT-3 sumGrup still in list CodE -- the action BODY survived, by its own local -- MOVED. Wanted: sumGrup
carrierT CT-5 the label gap is GONE. If label population landed, that is
chainTruthT CT2 "search list" -> match=1, want 0
chainTruthT CT3 "search ;" -> match=1, want 0
chainTruthT CT4 "search" -> match=1, want 0
countPop headline moved
displayForm baseline (interpreter pin)
doWhileNameT DW-6 dwN == <absent>, want 2 -- BORN RED 2026-09-21.
doWhileNameT DW-8 the DW-5 window NEVER CLOSED -- its RETURNED marker is
doWhileNameT runs (exit 139)
doWhileNameT sentinel -- THE RUN TRUNCATED. A row stopped parsing and every
faceT F2 flags FORWARD  = 1 -- moved
faceT F3 flags REVERSE  = 1 -- moved
fires=NEVER roster MOVED
firstUseT FU-2  isCodeD 1 -- the flag read reaches a real node (non-zero sibling) -- MOVED. Actual:
holderT 1 direct    .parenT = htWindow -- got: holderT 1 direct    .parenT = htU want htWindow 
holderT 2 identity  .taG    = htInside -- got: holderT 2 identity  .taG    = htKid want htInside 
holderT 3 holder    .parenT = htWindow -- got: holderT 3 holder    .parenT = htP want htWindow 
oneTest baseline
parseClass.target (setParse classification)
pointerT F2 null operand = 0 -- moved
pointerT F2 witness MISSING -- +* no longer names its refused operand
pointerT L3 witness MISSING -- the = -then-star refusal changed
pointerT L4e -- body=#2 not on the line after its label
pointerT L5b -- isCopy=0 not on the line after its label
pointerT L6a -- field=#10 not on the line after its label
pointerT L6b -- field=#10 not on the line after its label
pointerT L6c -- field=#6 not on the line after its label
pointerT L6d -- field=#11 not on the line after its label
pointerT X witness MISSING -- the star no longer binds to ptBagP
rung7.target
searchNewParseT SNP term `SemI` did NOT dispatch -- F-90 is back.
spacingT '-' named refusal missing -- its guard stopped naming it
spacingT '*' named refusal missing -- its guard stopped naming it
spacingT '+' named refusal missing -- its guard stopped naming it
spacingT '<' named refusal missing -- its guard stopped naming it
spacingT '<=' named refusal missing -- its guard stopped naming it
spacingT '==' named refusal missing -- its guard stopped naming it
spacingT '>' named refusal missing -- its guard stopped naming it
spacingT '>=' named refusal missing -- its guard stopped naming it
spacingT A tight-1  = spA -- missing
spacingT B tight-2  = spB -- missing
spacingT C spaced   = spC -- missing
spacingT D tight-3  = spD -- missing
spacingT E survived -- missing
spacingT F marker missing -- the operator rows did not run
spacingT G a + **b  = spG -- got: 
spacingT G2 a + *b  = spG2 -- got: 
spacingT H a +* b   = 1 -- got: 
spacingT I a+*b     = 1 -- got: 
spell.target (emitLeaf: 5 kinds x 2 sinks; emitter's own refusal NOT covered)
starIdiomT row 2 -- the star did not refuse a null by name. Either the
starT S1  *x   one-deep   = stA -- moved
starT S3a **x  ONE-deep   = stD -- moved
starT S6  a.b     holder   = stH -- moved
trigDO arm 1 -- the good input did not parse and attach. Actual:
trigDO arm 2 -- a broken term did NOT fail the parse. Actual:
trigDO attached under DO 0 times, want exactly 1
walkRefT row 3 = wrHeld -- THE FLIP HAS LANDED, or the binary is
```

## 2026-09-20, shutdown — 428 green / 62 red

```
ADDROF faSrc field=#3 body=#2 -- moved
anyOrNum.target (generated bodies + the parsed answer)
anyOrNumT census moved -- the isGROUP poison is back or generation changed
bindSeamB -- no promote=0 Braced attach; the cross-file bind is NOT being read,
carrierT CT-3 sumGrup still in list CodE -- the action BODY survived, by its own local -- MOVED. Wanted: sumGrup
carrierT CT-5 the label gap is GONE. If label population landed, that is
chainTruthT CT2 "search list" -> match=1, want 0
chainTruthT CT3 "search ;" -> match=1, want 0
chainTruthT CT4 "search" -> match=1, want 0
countPop headline moved
displayForm baseline (interpreter pin)
doWhileNameT runs (exit 139)
doWhileNameT sentinel -- THE RUN TRUNCATED. A row stopped parsing and every
faceT F2 flags FORWARD  = 1 -- moved
faceT F3 flags REVERSE  = 1 -- moved
fires=NEVER roster MOVED
firstUseT FU-2  isCodeD 1 -- the flag read reaches a real node (non-zero sibling) -- MOVED. Actual:
holderT 1 direct    .parenT = htWindow -- got: holderT 1 direct    .parenT = htU want htWindow 
holderT 2 identity  .taG    = htInside -- got: holderT 2 identity  .taG    = htKid want htInside 
holderT 3 holder    .parenT = htWindow -- got: holderT 3 holder    .parenT = htP want htWindow 
jsonTest baseline
oneTest baseline
parseClass.target (setParse classification)
pointerT F2 null operand = 0 -- moved
pointerT F2 witness MISSING -- +* no longer names its refused operand
pointerT L3 witness MISSING -- the = -then-star refusal changed
pointerT L4e -- body=#2 not on the line after its label
pointerT L5b -- isCopy=0 not on the line after its label
pointerT L6a -- field=#10 not on the line after its label
pointerT L6b -- field=#10 not on the line after its label
pointerT L6c -- field=#6 not on the line after its label
pointerT L6d -- field=#11 not on the line after its label
pointerT X witness MISSING -- the star no longer binds to ptBagP
rung7.target
searchNewParseT SNP term `SemI` did NOT dispatch -- F-90 is back.
spacingT '-' named refusal missing -- its guard stopped naming it
spacingT '*' named refusal missing -- its guard stopped naming it
spacingT '+' named refusal missing -- its guard stopped naming it
spacingT '<' named refusal missing -- its guard stopped naming it
spacingT '<=' named refusal missing -- its guard stopped naming it
spacingT '==' named refusal missing -- its guard stopped naming it
spacingT '>' named refusal missing -- its guard stopped naming it
spacingT '>=' named refusal missing -- its guard stopped naming it
spacingT A tight-1  = spA -- missing
spacingT B tight-2  = spB -- missing
spacingT C spaced   = spC -- missing
spacingT D tight-3  = spD -- missing
spacingT E survived -- missing
spacingT F marker missing -- the operator rows did not run
spacingT G a + **b  = spG -- got: 
spacingT G2 a + *b  = spG2 -- got: 
spacingT H a +* b   = 1 -- got: 
spacingT I a+*b     = 1 -- got: 
spell.target (emitLeaf: 5 kinds x 2 sinks; emitter's own refusal NOT covered)
starIdiomT row 2 -- the star did not refuse a null by name. Either the
starT S1  *x   one-deep   = stA -- moved
starT S3a **x  ONE-deep   = stD -- moved
starT S6  a.b     holder   = stH -- moved
trigDO arm 1 -- the good input did not parse and attach. Actual:
trigDO arm 2 -- a broken term did NOT fail the parse. Actual:
trigDO attached under DO 0 times, want exactly 1
walkRefT row 3 = wrHeld -- THE FLIP HAS LANDED, or the binary is
```

### decodePop -- 14 green / 9 red

```
  82 of them carry a definition (got '0', want '82')
  every term is defined (got '0', want '82')
  decodeT recorded 5 green checks (got '4', want '5')
  decodeT self-cert green -- expected line not produced: SELF-CERT ok
  undefined term fails loud, by name -- expected line not produced: decode UNDEFINED TERM  notATermAnybodyMinted
  decode line served H4 by its own words -- expected line not produced: never absence-of-message
  decode line served H7 by its own words -- expected line not produced: measured, not inferred
  decode line served blastRadius by its own words -- expected line not produced: every stream diffed
  SELF-CERTIFICATION: only 14 green checks recorded, expected
```

### ddPop -- 5 green / 1 red

```
trim gate violations 32
```
