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

**Measured 2026-11-06 on merged trunk, a scratch copy of the draft against sample, with Clay's two read lines added.** The room is right: wrap and two go from 175 to 100 each, (400 - 200) / 2, and three's x moves from 650 to 500. But the draft writes back only for a field with no width, so three keeps its declared 50 and has no computed width anywhere: its frame still reads 50, not 200. The placement loop re-reads the declared 50 too (), so a sibling after a percent field would be placed wrong. printDefinition prints 50 with the bit set; dumpContents prints 50%.
