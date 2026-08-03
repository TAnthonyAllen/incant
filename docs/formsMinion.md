# Forms Minion — Charter

**STATUS: CHARTER, NOT A TASK.** Shelf-ready. Fires on Tony's word.

*Dictated by Clay 2026-08-03, countersigned Tony. Transcribed by Clod per WT-9. The charter body
below is Clay's text. Clod's reader-notes are quarantined in the TRANSCRIPTION MARGIN at the foot —
they are **not** part of the charter and carry no authority.*

---

# FORMS MINION CHARTER — 2026-08-03, Clay, countersigned Tony

## FIRE CONDITION

Shelf-ready; fires on **Tony's word with Clod-slack**, per the standing stagger discipline — **not
while support's census is in its active legs** unless Clod judges the channel clear. Channel files
`ipc/forms-to-clod.md` / `ipc/clod-to-forms.md` per the naming convention.

## FOUNDATION

**`docs/forms.md` is the seed.** The minion's first deliverable includes **converting it into its
own foundation document** — current content preserved, restructured as the minion's ground truth,
**marked with what was inherited versus what the census established**. Required reading before any
census work.

## TASK 1 — FORMS RECON

Get familiar with every form. Census each: **name, where defined, what it renders or does, and a
proposed categorization.** The categorizing attributes themselves are **to be proposed, not
assumed**; **Tony defines the category vocabulary at the first report**, and the proposal should be
minted with an eye to the **pending taxonomy ruling** (categories are kinds; kinds are Tony's
signature). Claims carry provenance per standing discipline.

## TASK 2 — ATTRIBUTE CATALOG

Walk each form; identify **every attribute used**, GUI-related ones prominently included.

**Deliverable: an incant file defining the GUI-attributes registry** — *the list lives in the
language*, per the registry-unleashing principle — with **each attribute's description as a comment
before its definition**.

**Descriptions are claims:** each states **how it knows** (grep of firing sites, observed behaviour,
inference from name — **inference labelled as such**).

**Attributes needing methods/actions that don't yet exist are NOTED, NOT WRITTEN:** the note names
the attribute, the gap, and what the method would owe. That list is pass one's output and **Tony's
sorting exhibit**.

## TASK 3 — METHOD WRITING (SECOND PASS, SEPARATELY FIRED)

Writing the noted methods is **its own arc**, fired only after Tony sorts the Task 2 list. Recorded
here so the minion knows its notes have a destination, and **so nobody treats pass one's notes as a
license to build**.

## STANDING DOCTRINE, INHERITED IN FULL

- **No grinding** — pause and ask via channel.
- **Instrument provenance** — a claim resting on a probe reports the probe.
- **Sandbox per the support pattern:** reads Groups, writes only its own workspace plus its channel
  file; **leak-checked before acceptance**.
- Baselines before and after; **fleet stays green**; **nothing Tony has uncommitted gets touched.**

## THE BEAR, PRE-NAMED

**Attribute methods firing during a form walk is the `parse → testAttributes → parse` re-entrancy
family (bear country #5).** Task 2's catalog should **flag any attribute whose method would itself
walk, print, or fire other attributes** — those entries carry a **RE-ENTRANT** marker, and the
re-entrancy rule is a **Clay/Tony design ruling owed before Task 3 fires**, not a thing the minion
solves. First census claim of Task 3's charter, whenever it is written.

## OUT OF SCOPE

- Writing any method (Task 3's, separately fired).
- **The print-form/walk-form implementation** — that design (forms own their display; `PrintXP`'s
  format option dies for forms; the walk is an iterator) is this minion's **eventual customer** and
  rides on Task 3's timeline.
- Any GUI rendering work.

## CLAY'S ORDERING OPINION

Shelf alongside search and the assert charter — **three armed and one hunting.** Firing order stays
Tony's and Clod's on the slack-and-settle rule. The one ordering opinion: **forms recon and support
recon should not run their heavy census legs simultaneously**, since both are grep-storms through
overlapping territory and the channel discipline is one day old.

## CLAY'S MARGIN NOTE TO THE TRANSCRIPTION PASS

`forms.md`'s current contents are **Clod's ground, not mine** — if anything in it contradicts this
charter's shape, that is a flag for signature, same quarantine rules as ever.

---

# TRANSCRIPTION MARGIN — Clod, 2026-08-03

*Not part of the charter. **No contradiction found** between `forms.md` and the charter's shape —
they are complementary: `forms.md` is a **conversion spec** (how to convert one form), the charter
wants a **census plus attribute catalog** (what forms exist, what their attributes mean). Nothing
to reconcile. But three measured facts would change Task 1's first hour, and one of them is a trap.*

## M1 — ⚠ "EVERY FORM" IS 22 FILES, NOT 84. The census boundary needs this before it starts.

`IncantForms/` holds **84 files** (excluding gitignored `BackupXML/`), and they are **three
different kinds of thing**:

```
find IncantForms -type f -not -path "*/BackupXML/*"        -> 84
  33  XML-syntax        (still unconverted -- lines like <tercio=$Body ... register form/>)
  22  incant-syntax     (converted forms -- THE ACTUAL FORMS)
  29  neither           (prose / design notes -- e.g. NotGUI/ruling, NotGUI/parse)
```

*Classifier: `^\s*<[a-zA-Z/]` for XML, else `^Start\(\);|^register\(` for incant, else neither. Run
2026-08-03.*

The 22 converted forms:
> `Windows/`: accounts · cards · date · db · descriptions · draw · fit · keyAction · keyStroke ·
> list · menu · scroll · sheet · simple · **tabs** · toggles · tree · wraplist  ·
> plus `Generating/genNotes` · `Notions/fonting` · `Stash/types` · `WorkingOn/tester`

`forms.md`'s worked reference `IncantForms/Windows/tabs` is present and is in that set.

**Why this is the margin's first note:** a minion told *"get familiar with every form, census each"*
and pointed at a directory will census **29 prose documents as forms** and try to categorize design
notes. The three-way split is one command and it makes Task 1's population exact. **Which of the
three kinds are in scope is Tony's to say** — my reading is that the 22 are the census, the 33 are a
conversion backlog worth counting but not categorizing, and the 29 want naming as not-forms.

## M2 — `register`-as-an-attribute IS ALREADY ESTABLISHED PRACTICE, in this very corpus

The register-pivot brief of 2026-08-03 described `register` as *"heavily used way back when, dormant
since."* **`IncantForms/` is where it stayed alive.** 43 non-command uses, and `forms.md`'s own
conversion checklist documents it as a live convention:

> *"confirm … that any `register`-attributed panels resolve (the `register` keyword is consumed
> silently and won't echo in `printDefinition` — that's expected, not a loss)"* — `forms.md` §6

Specimens: `<tercio=$Body name="Another Label" content="Some Stuff" register form/>` ·
`<two="Second item" item register/>` · `<tags class source=row … register>`.

**Three consequences worth carrying:**
- **Task 2 has prior art.** The GUI-attributes registry is not being invented from nothing; the
  forms corpus already declares visibility per-name, which is exactly what `register` was put into
  production for elsewhere today (`emitBC`).
- **It feeds `searchMinion` question 3 directly** — *what may declare visibility* — with a real
  population rather than a hypothetical. If the search minion fires after forms, it inherits
  evidence; if before, it does not.
- ⚠ **`forms.md` §6 says the keyword is consumed silently and does not echo in `printDefinition`.**
  So a **round-trip POP cannot see it.** Any Task 2 claim about which panels are registered must be
  grepped from source, **never** read off `printDefinition` output — the one instrument that would
  seem natural here is blind to exactly this attribute.

## M3 — ⚠ THE TRAP, and it rhymes with a defect found the same day

`forms.md` §4 makes **trailing free prose after `stop()`** a *convention* — form files deliberately
carry unparsed content below the stop, with a `*` separator, because the parser exits there.

**So a grep-based census reading a form file top to bottom will read design prose as if it were
definitions.** Only **11 of the 84** files contain a `stop()` at all, so the boundary is present in
some files and absent in others — which is worse than uniform, because the census cannot assume
either shape.

This is the same family as the `oneTest` finding ruled on 2026-08-03 (six `stop()` calls, run ends
at the first, 32 lines never execute). There it was a defect; **here it is deliberate convention.**
Both mean the same thing to an instrument: **content below `stop()` is not live, and no tool
enforces that boundary — the reader has to.**

**Concrete implication for Task 2:** an attribute that appears *only* below a `stop()` is **not an
attribute in use**. It is prose about an attribute. Cataloguing it as live would put a fictional
entry into the GUI-attributes registry — a registry that, per the charter, **lives in the
language**, so the fiction would be executable.
