# groups.ext — the out-of-repo build dependency, and what we have put in it

*Bear-trap #11: `~/Dropbox/data/InProcess/Include/groups.ext` is a real build
dependency, is pulled in via `groupIncludes`, and is **NOT tracked in this repo**.
Edits to it never appear in `git status` or in any commit here. This file is the
commit trail it does not have.*

**Why it matters:** tok resolves cross-file member access and extern signatures
against `groups.ext`, not against the class. A missing or stale entry does not
fail loudly — it produces a tok parse error that **cascades and wipes the entire
extern block** from the regenerated `.h` (bear-trap #10). The canary is the
extern count in `GroupRules.h`.

**It also merges rather than regenerates** (bear-trap #16): removing a field from
a `.twk` class does NOT remove it from the generated `.h` until the matching
`external` block here is edited too.

---

## Entries added by this arc, newest first

| date | added | why |
|---|---|---|
| 2026-07-29 | `auditMissingRules`, `auditMissingTerms`, `auditSpurious` (`external GroupRules.h`) | the rStuff auditor's three walks |
| 2026-07-29 | `auditRStuff` | the `audit` incant command's extern. **Named `auditRStuff`, not `audit`** — macOS declares a system `audit(2)` and `extern "C"` strips overload resolution, so `audit` collides and the build dies with *conflicting types*. Bear-trap #12 against a SYSTEM symbol. |
| 2026-07-29 | `isIterator`, `iterateOnAttributes`, `iterateOnMembers` (`external GroupItem`) | Tony's iterator flags — he did this sync himself |
| earlier | `parentLabel`, one-arg `parseMethod`, `parseTrace`, `parseR`, `parseRuleMethod`, `traceParse`, `dumpRuleTerms`, `termCount`, `definingRule`, `countRuleTerms`, `parseTermCount`, `parseScafA`/`parseScafB`, renamed `leaveRule`/`leaveAlt` params, one-arg JSON parse decls; `runScaf`/`runScaf2`/`runJSONblock` REMOVED | the genParse ladder |

## The standing rule

**Any change that touches `groups.ext` gets a line here, in the same commit that
needs it.** Otherwise the only record is in a file outside the repo, and a fresh
reader has no way to know why the build works on this machine and nowhere else.
