# Generate.rtn parse* siblings — behaviour census

Read-only, 2026-09-24, at `dc1dd53`. Tony asked for it after this family diverged twice: the 08-19 template audit, then `keepTheMatch` (F-114 site 2). **Nothing here is fixed.** A cell names what the method does; `—` means the behaviour doesn't apply.

| behaviour | Action | Any | Character | Condition | Container | Loop | Rule | Set | String | UpTo |
|---|---|---|---|---|---|---|---|---|---|---|
| clears `sukcess` before the gate | yes | yes | yes | assigns from `min` | yes | **never writes it** | yes | yes | yes | yes |
| `checkInput` gate | **no** | yes | yes | **no** | yes | **no** (its leaves do) | yes | yes | yes | yes |
| clears `sukcess` again after a gate pass (`gateIsNotAMatch`) | — | yes | yes | — | yes | — | **no**: overwritten by `truthOf(result)` only when a body runs; the `reportNoBody` path keeps the gate's TRUE, so **a bodiless rule succeeds** | yes | yes | yes |
| clears the label only on failure (`keepTheMatch`) | **no: clears unconditionally after a successful `actionMethod`** | yes | yes | — | yes | — | — | yes | yes | yes |
| writes the match into the label | `label = actionMethod(...)` | `setToken` | `setToken` | no | `label.group = entry` | no | **no**: `myLabel` is minted and goes nowhere (CT-5) | `setToken` | `label.text` | via `testUpTo`, **only when the match length > 0**: a zero-length match succeeds with no label text |
| min gate | — | `counter && counter >= min`, so **a zero count never succeeds, even at min 0** (F-115) | same | `min` only | none | `kount >= min` | none | same as Any | none | none |
| reaching max | — | `reportMaxLimit`, and **the term FAILS** unless `limitsSet` or max 1 (the else-if) | same | — | none | stops silently | — | same | — | — |
| advances the mark | — | directly | directly | no | only if `!noAdvance` (**its own check**, on top of `exitFromParse`'s) | through its leaves | through its body | directly | `matches(&)`, by reference | `testUpTo` |
| rewinds on failure | through `exitFromParse` | same | same | same | same, except the no-rStuff branch, which rewinds itself | **no rewind**: a run below min keeps what it consumed and never reaches `exitFromParse` | same as Action | same | same | same |
| exits through `exitFromParse` | yes, except the refuse path | yes | yes | yes | yes, except the no-rStuff branch | **no** | yes | yes | yes | yes |
| re-resolves the face (`currentMETHOD.get(tag)`) | no | no | no | no | yes | yes | yes | no | no | no |
| repairs `parentStuff` from `currentMETHOD` | no | no | no | no | yes (`binParentRepair`) | no | yes (`parentRepair`) | no | no | no |
| runs `getWhatFollows` (`isTarget`, `onFail`, `onGroup`, `hasMacro`) | **no** | **no** | **no** | **no** | **no** | **no** | **no** | **no** | **no** | **no** — only the OLD road's `GroupItem::parse`, through `getStuff`. **This is F-114 site 3.** |
| reads `sukcess` as a verdict after its work | — | — | — | — | — | **yes**: `if sukcess return trueResult` sits above the count check, although its own comment (`countNotFlag`) says to read the count | — | — | — | — |

Checked, not reproduced: the zero-length `testUpTo` case does not crash an empty quote. Natively, `""` and `print "";` both return.

## Reachability of parseAction, measured 2026-09-24 (after c7c9e6c)

**No face on the new road uses it.** Walked from the Grokking registry after `parser(DO)`: 372 nodes, and none has `rStuff.parseMethod == parseAction`. That population is where one would show up, because `setParseWalk` installs a parse method on every face it walks, and it walks from DO, which is inside Grokking.

`PRINTing` is the only rule the grammar names with `parseAction=`, and it's reachable through PrinT, CerR and CouT. But `parseAction=processFlags` binds **`processFlags` itself** as its parse method and `gMethod` (the addresses are identical), and `setParseWalk` skips the face as already installed. So `Generate.rtn`'s `parseAction`, and its clear-after-success, never run. No row can go red on it until something routes a face there.

## parseLoop reads the flag before the count: never decisive, measured 2026-09-24 (after 692acab)

SEQ 195 added `if kount >= min return trueResult;` **below** the existing `if sukcess return trueResult;` and left the flag read in place. The two answers differ only when `sukcess` is true and `kount < min`. In every other case both return true, or both fall through to `return 0`. When a loop ends by reaching max, `kount == max >= min`, so the count agrees.

**Probe:** a temporary, uncommitted build printed `LOOPFLAGDIFF` in exactly that case, unconditionally.

**Population:** all 171 `pop.sh` captures (kept by a scratch copy of the harness, because pop.sh deletes `$T` at exit, and the first run was void for that reason), `jitLadder/ladder.sh`, and 52 station-2 drives (`jitLadder/station2/f114site1` plus the seven accepting controls).

**Result:** zero, everywhere. The fleet was unchanged at 517 and the ladder PASSED.

**Caveat (H16):** the probe was never seen to fire. It is compiled in, but nothing known triggers it. The only mechanism I can name is a stale `sukcess` on the face, left by an attempt that returned 0 without writing it (for example a refusal inside `runLeafParse`); the stale flag would then turn a short run into a success.

**Not changed.** No row can go red on it today. The probe was removed; the tree is back at `692acab`.
