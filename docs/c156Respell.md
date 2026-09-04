# C-156 — ITEM 4: THE `*argument` RESPELL — STEP 0 + STEP 1

**Branch `flip-argument`, cut 2026-09-04. Step 1 landed; C-156a applied.**
**Every number below states its arm in its section heading, never per row.**

---

## §1 SURPRISES FIRST

### ⚠⚠ S1 — THE RESPELL IS ARM-INDEPENDENT. THE DISPATCH'S PREMISE FOR CLASS (a) IS FALSIFIED.

C-156 says the respell *"is byte-identical under the flip and refuses bare, so it rides
with the flip and does not land on main from this stroke."* **It is byte-identical under the
flip AND byte-identical bare.**

```
  arm FLIP ON   before 128 green / 67 red      after 128 / 67        moved-set EMPTY
  arm BARE      before 191 / 1 parked / 3 red  after 191 / 1 / 3     moved-set EMPTY
  arm BARE, targeted run of the site under a 60s alarm:
                exit 0, prints all three members, sentinel present
```

The pre-registration said *"silent is the failure, refusal is the expectation."* **Neither
happened — it worked.** The mechanism is the 09-03 two-wraps split, already written down and
not re-derived: the parse hop is peeled **unconditionally**, and only the holder-follow is
gated on `gNoUnwrap`, so an iterate source's star is handled by `aCTionIterate` rather than by
the generic unary star that refuses on an already-unwrapped operand. **That is why this class
does not behave like C-154's `*x` in assign position**, and it is the whole reason the two
strokes read differently.

**Consequence, reported and not acted on: the (a)/iterate class may be landable on `main`,
which would remove the need for a flip branch for that class entirely.** Claimed for the one
site measured, not for all 113.

### ⚠⚠ S2 — THE SCOPE WAS UNDERSTATED BY 55%: CLASS (a) IS 113 SITES, NOT 73.

The 09-03 census was scoped to `incant/`. Over C-156's scope it is half again as large, and
the extra sites are exactly the ones the dispatch warned about (*"the first iterate respell
missed four"*).

| scope | class (a) `on argument` | class (d) other name |
|---|---|---|
| `incant/` | 74 | 26 |
| `minionWork/` | **35** | **17** |
| `genLadder/` | **4** | **1** |
| **total** | **113** | **44** |

### ⚠ S3 — MY FIRST CENSUS PATTERN OVERCOUNTED, AND THE CONTROL CAUGHT IT (H9)

A loose `iterate .* on ` gave **101** sites at `1932aaa` where that commit reports **98**.
The three extras are **prose mentioning the idiom**, not code. Requiring the line's first
non-whitespace token to be `iterate` reproduces **98 / 73 / 25 / 40** exactly, including the
26 plain / 27 members / 20 attributes split. **A delta computed with a different instrument
than its baseline is not a delta**, so the count below is on the corrected pattern for both
dates.

### ⚠⚠ S4 — `main` IS 648 COMMITS AND TWO MONTHS STALE, AND MY OWN RULING POINTED AT IT

C-156 says *"fresh branch from main."* **`main`'s tip is `b411ffa`, dated 2026-06-30, 648
commits behind HEAD, and it carries no `gNoUnwrap` at all** — so a branch cut there cannot
host step 1's flip-on before-capture. The branch was cut from the working trunk
`jit-unified-emit-wip` instead.

⚠ **And this falsified a ruling I had committed one commit earlier**, from C-154's closeout:
*"future try-and-buy branches are cut from `main` per stroke, so a branch is never older than
the question it is answering."* Cutting from `main` today yields a branch **two months older**
than its question — the ruling committing the exact failure it was written to prevent.
Corrected in both registers to name the working trunk. **The check was one
`git rev-list --count`, and nobody had run it** — the same family as bear-trap #3 and the
`ipc/` gitignore row.

---

## §2 THE CENSUS — corrected pattern, both dates, arm-independent (a static read)

| | 09-03 `1932aaa` | 09-04 HEAD | delta |
|---|---|---|---|
| total iterate-on sites, `incant/` | 98 | 100 | +2 |
| on bare `argument` (class a) | 73 | 74 | +1 |
| on another bare name (class d) | 25 | 26 | +1 |
| files | 40 | 41 | +1 |

**The entire delta is one file: `incant/iterRefuseT`**, minted 2026-09-03 with the iterate
re-rule and joined to the fleet in that seal. Per-file counts are otherwise identical.
H11 control declared before reading and satisfied: `incant/utilities:132` appears, exactly
where the 09-03 census said it would.

## §3 THE FOUR CLASSES, over the full C-156 scope

| class | what it is | count | disposition |
|---|---|---|---|
| **(a)** reaches the source | `iterate … on argument` | **113** | respell — 1 done, 112 owed |
| **(b)** asks the holder about itself | `argument.<prop>`, presence tests | **162** | READ AND LISTED, none respelled |
| **(c)** writes and binds | `:=` 30, `<-` 12, `argument =` 10 | **52** | listed with operator, none respelled |
| **(d)** other-name sites | `iterate … on <local>` | **44** | READ AND LISTED, none respelled |

### §3a Class (b) — the reads nobody has done, by property

```
  argument.taG          53      <- the big one; under the flip a holder answers with
                                   its OWN tag, so every one of these changes meaning
  argument.listLengtH   14
  argument.claims       11
  argument.datA          8
  argument.hasAttributeS 7
  argument.texT          3
  argument.isRulE        3
```

⚠ **These are not a respell population and must not be treated as one.** Each one has to be
read for what it is actually asking — *the holder* or *the source* — and grep cannot answer
that, which is the same refusal the 09-03 census made about class (d) and for the same reason.

## §4 STEP 1 — `incant/utilities`, landed as `53b107d`

**Arm: both, stated once — the sub-stroke was measured on the flip and on bare.**

One site, and it is the whole blast radius because every fixture includes utilities:
`incant/utilities:132`, `iterate grup on argument;` → `on *argument;`.

Also present in that file and **deliberately untouched**: 4 class-(b) sites
(`:10` `if argument.listLengtH;` · `:67` `argument.taG` · `:184` `.dIRECTion` · `:185`
`.tARGET`) and 4 class-(c) sites (`:184`/`:185` `:=`, `:386`/`:432` `<-`). No class-(d) sites.

Certificate: moved-set **empty on both arms**; canary **332**; no extern, no `groups.ext`
edit; `gNoUnwrap` 0 in the commit and verified **down behaviourally**, not by mtime.

## §5 C-156a APPLIED

Branch renamed **`flip-argument`**. `gNoUnwrap = 1` committed in source as its own one-line
commit `69f8148`; binary rebuilt to match and **verified up behaviourally** (a two-deep chain
prints `fcSrc`, a tag, where bare prints `SRC`, a value). `main` untouched at 0.

⚠ **Tony: an Xcode build from this branch produces a flipped binary**, so the parser runs
flipped while it is checked out. The shipped binary is whichever was built last — check
behaviourally.

**C-156a's buy criteria are unaffected by S1** — they grade a *reporting practice* (arm
attribution), not whether the respell needs the flip. Counter so far: **0 arm-attribution
errors, 0 voided controls, 1 scheduled bare run** (step 1's, taken under the original rule
before the amendment took effect).

## §6 WHAT IS OWED

- **112 class-(a) sites**, in file groups, one commit each — and S1 means the flip may not be
  needed for them at all. **That is a ruling worth taking before the next sub-stroke**, since
  it decides whether this work lands on `main` or waits on the flip.
- **Classes (b), (c), (d) are read-and-report and none has been read yet** beyond the counts
  above and utilities' own eight sites. The dispatch says this is where the stroke earns its
  keep, and it is untouched work.
- The repo-wide drift row (old-form class-(a) sites at 0) is **not yet buildable** — 112 sites
  remain, so it would pin 112 and fail by design.
