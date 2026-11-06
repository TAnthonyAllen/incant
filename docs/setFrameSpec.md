# setFrame redesign: working spec (Clay, for Tony's session with Clod, 2026-11-06)

Recorded as Clay wrote it. Not a build dispatch; setFrame is Tony's. Its RULINGS are Tony's where it says so; the rest is Clay's proposal until the session rules it.

**Order.** The % stroke (SEQ 552) is bought first. No setFrame work starts before it.

**Probe first.** Does `clear(argument); argument = newStuff;` in fillDownAcross deliver newStuff's members, or leave argument empty, given that `=` copies data only? This may be why sumple frames nothing today. Measure it before any change.

**Rulings carried in (Tony, 2026-11-06):**
- A % is a percent of the parent's size, not of the remaining room.
- A resize re-runs setFrame from scratch on the top field with its resized width, height, x and y.
- Declared values (`width=50%`) survive a run. setFrame writes computed sizes somewhere other than the declared attributes. Where they go is the first design question for the session. Candidates: separate frame attributes on each field, or one frame property.

**Both directions on one field.** The direction that isn't `*` goes on the outside: a new group carrying that direction holds the original member, and the `*` direction works inside each cell. setFrame's existing recursion does the rest. sumple: `across=2` outside, so 2 columns of 125 by 200; `down=*` inside each, so 4 crossings of 50. PARKED: both `*`, and both numbers. No form uses either.

**fillDownAcross fixes:**
- `down=3` with several members repeats the whole set, in source order (a b a b a b). valueCount is reset for each pass.
- A % in fillDownAcross is a percent of the parent's size, not an absolute count. Today 50% reads as 50.

**setFrame fixes:**
- upOut and sideOut are each used as a list and as a count. Split each into a list and a separate count, unless Tony's offline fix already does.

**Certificate (rows born red on trunk):**
- `width=50%` under a 200-wide parent reads 100. This row moves here from SEQ 552.
- A resize to 400 reads 200, and the declared 50% is still there.
- sumple reads 8 cells of 125 by 50.
- `down=3` with two members gives six in source order.
- simple and sample still frame every child, by Tony's glance at the trace.
- H7 on each half: the split, the reset, the % read, and declared-survives.

**Parked:** jitting setFrame (`=:` makes it NOT JITTABLE today, docs/percentRecon.md R4), and the ties above.

**Clod's note, 2026-11-06, for the session.** Once percent-unit is bought, `=:grup width height;` brings the unit across, so a bare `width.isPercenT` reads 1; through `:` it must be `*width.isPercenT`. A computed value written with `=` from a plain number clears the bit, so declared-survives depends on writing somewhere else, as this spec says.

**Measured 2026-11-06 on merged trunk, a scratch copy of the draft against sample, with Clay's two read lines added.** The room is right: wrap and two go from 175 to 100 each, (400 - 200) / 2, and three's x moves from 650 to 500. But the draft writes back only for a field with no width, so three keeps its declared 50 and has no computed width anywhere: its frame still reads 50, not 200. The placement loop re-reads the declared 50 too (`=:grup width height x y`), so a sibling after a percent field would be placed wrong. printDefinition prints 50 with the bit set; dumpContents prints 50%.

**Measured 2026-11-06, merged trunk, sample through the draft.** Every frame adds up but one: the three heights with no value share 188, and 188 / 3 rounds to 63, so 63 + 63 + 12 + 63 = 201 against sample's 200, and fifth ends at y 651, one past the bottom. Widths in third add up exactly. (Settled the same evening; see the foot.)

**A field with children and no direction (Tony, 2026-11-06, and GUI/Details.twk, read).** A lone child mirrors its parent's frame (Tony). The old GUI's default orient was down (`or !flexed down = true`, :326), so siblings with no direction stack down: each without a height gets `ancestor.length/ancestor.stretched`, what's left after fixed and percent sizes divided evenly, and a lone child gets all of it. Its percent is of `ancestor.innerBox`, the parent's size, as ruled here. The draft's sizing loop already treats no across as down; only its recursion gate stops it, `if across.datA != 0 || down.datA != 0`. On a scratch copy, recursing on any field with members gave one wrap's frame (100 by 63 at 300, 513) and stuff three's (200 by 63 at 500, 513), and changed nothing else in sample.

**Speed, measured 2026-11-06 (kant, interpreter, Debug -O0 binary, printing off; docs/setFrameProbes, a counter proves setFrame ran).** One layout: sample about 55 microseconds; a 110-field form (10 rows of 10) about 650 microseconds, 4% of a 16.7ms frame. No drawing is included, and after the first run no % is computed.
**BUT IT GROWS.** That form, wall clock and peak memory: 200 layouts 0.16s, 96MB; 1000 1.06s, 340MB; 5000 14.5s, 1560MB; about 16,500 in 170s, 4.2GB, killed by the alarm. So about 300KB a layout, never given back, and a layout slows as it runs. **Cause not found.** Not fillDownAcross (without it: 0.50s and 229MB at 1000, 5.08s and 1003MB at 5000), not upOut or sideOut (empty after the first layout). Each of a call, :% of a copyOf, copyOf, an =: in a call and a for walk, alone in a 200,000-pass loop, stayed between 72MB and 145MB, so no single one reads as the leak. Not tried: them together on a real tree, recursion, a member's own lists.

**The collector runs and frees almost nothing (Tony asked; measured 2026-11-06 with GC_PRINT_STATS=1 on the 110-field form).** 53 collections by 1000 layouts, 201 by 5000, roughly one per 8MB allocated, and the heap reads 99% in use: 1.5GB of live data at 5000. The holder is not found was the first reading; **the cause is below it, and setFrame is not to blame.** The binary's global operator new calls GC_malloc_uncollectable (otool on __Znwm), GroupItem and GroupBody have no gc base class, and a plain `m := copyOf(v);` in a loop frees nothing either (2,000,000 passes, 415MB, 62 collections, none freeing). So every plain new is never freed, whatever reaches it, and every collection scans it all, which fits a layout slowing as it runs (fits, not shown). Making them collectable is a ruling, not a repair: docs/knownErrors.md.

**Built in tester, 2026-11-06, Tony and Clod (not in utilities, not in the fleet).** Clay's probe: `argument = newStuff` delivers the members, so it was not why sumple framed wrong; down=* then across=2 ran one after the other in one line. Now: bothDirections puts the number outside and the * in a dirCell, and setFrame's recursion does the rest. sumple reads 2 cells of 125 by 200 at x 100 and 225, each with 4 crossings of 125 by 50: 8 in all. across=* down=2 reads the mirror of it. down=3 with two members gives six in source order. A % under across=* is of the parent: 25% of 200 gives 4 cells of 50. sample and somple do not move. Both * or both numbers print a line by name and then frame as before, which is wrong and parked. upOut and sideOut stay one field, a list and a count: Tony, 2026-11-06, "I thought the upOut issue was a feature. If it causes a problem we fix otherwise bam: its a feature."

**A second run is wrong, as expected until computed sizes live elsewhere (measured, same day).** setFrame twice on sumple gives 4 dirCells, running out to x 475 past a 250-wide parent; twice on somple gives 12 crossings and "can only have one member". The fill re-runs on members it already made. So a resize waits on the first design question, and the answer must say where the original member set is kept, as well as the computed sizes.

**noRoom in the old GUI (read 2026-11-06, GUI/Details.twk checkFit :96, GUI/Control.twk :321; not run; a candidate for the session, not ruled).** A separate pass after layout, on each field that is not already noRoom, against its parent's inner box. A field wholly outside on either axis: noRoom, and the parent is scrollable on that axis. A field partly outside: drawn, and the parent is scrollable. A child of a noRoom parent is left alone. It does not bail or shrink anything. Readers: drawing and the walk skip a noRoom field (Control :321, :475, :705, :1031), a click skips it (Details.rtn :18), a page counts up to the first one (Details.twk :512), and selection drops it (Details.rtn setNoRoom). Other writers use the same flag to hide: cards (Actions :78, Details.rtn :208), toggles (Actions :378), a panel (Delegate :42), show= with no data (Map :927); checkFit leaves those hidden. So it carried two facts on one flag: does not fit, and hidden on purpose. No fit test exists in today's draft. Note: sample's fifth ends at y 651 of 650, so the rounding pixel would mark sample scrollable.

**The remainder, settled in tester, 2026-11-06 (Tony's yes, running edges).** Each share is `room * n / count` less where the last one ended, so the sum is exact and no two differ by more than one. sample: 63, 62, 12, 63 = 200, fifth ends at 650. 250 across 3: 83, 84, 83. 100 across 7: 14 15 14 14 14 15 14. A * count now rounds down so the cells fit: 50s in 190 gives 3, in 200 gives 4; 60s in 250 gives 4. What is left of a * stays unused. **The locals must be set to 0 first:** a first assignment to an empty local takes the fraction as it is, and only a count rounds (the cast rule). That cost one run, and it reads as a kant trap worth a row: measured here, not checked elsewhere.

