# Forms M5, colours and fonts: recon (2026-11-05, trunk binary)

**RULED (Tony, 2026-11-05, R2):** setColor skips a leading `#`. Fonts are written as attributes. One new file, IncantForms/Controls/styles, holds the 14 colours and 7 fonts. It is NOT on the default search list until defineCapture B2 lands, because a write-through such as `red=5` is that defect's family; tests load it explicitly. `fill=purple` is fixed when sample comes up for repair. The "owed" list below is closed.

**BUILT, branch m5-styles:** the # skip in setColor; `fontReport`, a small witness, because nothing else could read a realised font from kant; `styles`, registered in fILEs and loaded by no one by default; `incant/pop/stylesT`, every colour by pixel and every font by what NSFont reports.
**`EBgaramondFont`'s family is not installed on this machine**: it realises as the system font, not bold, at size 18, with no message. Its row pins the size only.
**ST-5, measured:** with cOLOr searched, an attribute `red=5` writes red to the count 5. That is the write-through, now a pinned row rather than a read.
**Left for M3:** setColor caches on the field, so changing wall's hex keeps the old colour until that is dealt with; Tony's dark / light example needs it.

## Measured (kant)
| case | result |
|---|---|
| `dsRed = "ff0000"`, style `fillColor="dsRed"` (incant/pop/dsFill, the control) | pixel r255 g0 b0 a255 |
| the same with `dsRed = #ff0000`, the form-file spelling | `getColor: ERROR could not get color`, fill refuses, pixel unchanged |
| `wall=#f7e8aa` in a searched `cOLOr` registry, read back | kind 14, value `#f7e8aa`, WITH the `#` |
| the same, cOLOr not on the search list | `wall` in an action body is a fresh local, tag echo |

So a colour in the spelling Tony's explanation and the old forms use does not realise: setColor (Stylish.twk:131) wants exactly six hex characters. Its complaint goes to `cout`.

## Read, not run
- **cOLOr and fONTs load today only if a file defines them.** Nothing does. `IncantForms/Controls/attributes` holds 14 colours and 7 fonts in XML-era text; no form file loads it.
- **setFont reads `family`, `size`, `bold`, `italic`, `smallCaps` attributes.** Six of the seven old fonts are CSS strings (`font='bold 24.0px Palatino'`), which it does not read. Size falls back to 12 and the family to system, silently.
- **getColor takes a NAME** and locates it. With `fill:=wall` (R1) the attribute holds the field, so M3 needs to realise a field directly. setColor already takes a field, and caches on it: a change to wall's hex would keep the old colour unless the cache is dropped. That is M3's question, and Tony's dark / light example needs it answered.
- **A searched colour name is capturable.** An attribute spelled `red=5` in a define would write through to the colour (defineCapture's family, M8). `sample` uses `fill=purple`, and purple is not among the 14.
- `gradient` and `angle` are on the drop list, so `radialGreen` comes over as plain `afd378`.

## Owed from Tony
1. **The `#`.** Recommended: setColor skips a leading `#`, one line, so `wall=#f7e8aa` works as written and the bare form stays. The alternative is a quoted bare hex in every form.
2. **The font spelling.** Recommended: attributes, as setFont reads them: `titleFont family='Palatino' size=24 bold;`. The CSS strings would need a parser, for no reader that wants one.
3. **Where they live.** Recommended: one new file, `IncantForms/Controls/styles`, registries `cOLOr` and `fONTs`, registered in `fILEs`, carrying the 14 + 7 translated. Whether it is on the search list by default is the capture question above.
