# Define-time name search escapes scope — RECON

*Clod, 2026-08-01, against Clay's relay "RECON ONLY: define-time name search escapes scope".
**No fix, no proposal adopted.** Tony rules on the semantics. Everything below was RUN; every
claim is marked measured or inferred, and the one causal claim that did not survive its own
check is marked as such.*

---

## 0. THE FINDING, CONFIRMED — and the attribution is single-variable

Tony's attribution is correct. Defining

```
testForC argument second=56 third="WTF?" code={ … }        incant/unitTests:153
```

writes 56 and `"WTF?"` into **`sample`'s own `second` and `third`** (`incant/unitTests:96-104`)
instead of minting fresh attributes on `testForC`.

**Measured by A/B against a copy differing in EXACTLY ONE LINE** (`incant/scopeUnits`, testForC's
two attributes removed, nothing else). Walking `sample` under each:

| include | `sample`'s `second` | `sample`'s `third` |
|---|---|---|
| `unitTests` | **`56`** | **`WTF?`** |
| `scopeUnits` | `second` (unset) | `third` (unset) |

One line in, one line out, two different answers. That is the whole attribution and it needs no
further argument.

**Driver** (both runs, exit 0, sentinel present):

```
Start();
register(fILEs);  define scopeUnits File='incant/scopeUnits'; ;   /* B side only */
include(unitTests);          /* or include(scopeUnits) */
search reset stack Grokking;
search UnitTests list;
register(ABprobe);
define walkSample code={ iterate abIter on sample; while ++abIter; print + `taG abIter:; }; ;
walkSample();
print "AB SENTINEL":;
stop();
```

⚠ `include(X)` resolves through the **`fILEs` registry** (`incant/setup:262-272`), not the
filesystem — a copy is unreachable until it is registered. `getFile` opens `File.text` if the
entry has a `File` attribute and otherwise opens the bare tag relative to cwd
(`Commands.rtn`, `getFile`). Registering it in the probe file avoids touching `setup`.

---

## 1. THE WALK, ANNOTATED

Three functions, and the whole defect is visible in them.

### 1.1 `aCTionNamE` — `ruleActions.rtn:617`, where the wrong find is CONSUMED

```
extern GroupItem aCTionNamE(GroupItem input)
{
GroupItem   action = currentMETHOD;
GroupItem   grup;
GroupItem   result;
String      arg = input.text;
    result  = locateInMethod(arg);                          // (a) THE WRONG FIND
    if defining && result && result.isVirtual  result = copyOf(result);
    grup    = new(arg);                                     // (b) fresh node, minted ALWAYS
    if alphaSet.contains(*arg) && processingCode            // (c) ⚠ THE FORK, gated on
        if !result || (!isArgument && !isLocal)             //     processingCode
            if !(result && registry == opFields)
                if result
                    if action.isRule && isRule {
                        result  = action +% grup;
                        isLocal = true; }
                    else    result = action +% result;
                else {
                    result  = action +% grup;
                    isLocal = true; }
    if !result  result = grup;                              // (d) create-if-missing
    input.group = result;                                   // (e) binds the STRANGER
    return input;
}
```

**Read (b)→(e) in order and the answer to Clay's question 2 falls out:**

- The fresh node is minted at **(b) unconditionally** — so a fresh node always exists.
- **Every path that ATTACHES it lives inside (c), which is gated on `processingCode`.** During a
  definition `processingCode` is false, so the entire block is skipped.
- (d) is the only other route to using it, and it fires **only when the lookup found nothing**.
- Therefore: **a successful lookup at (a) causes the freshly-minted node at (b) to be silently
  discarded, and (e) binds the definition to the stranger.**

**This is exactly the shape Clay asked about — "a create-if-missing path that never runs because
the find succeeds first" — and it is confirmed at `ruleActions.rtn:617` ff.** The language has no
create-fresh path for definition context at all; it has one for *code* context and one for
*not-found*, and a definition that collides is neither.

⚠ **`defining` is ALREADY IN SCOPE, one line below the lookup** (the `isVirtual` line). A
definition-context fence is one condition away *syntactically*. The hard part is entirely
semantic — see §3.

### 1.2 `locateInMethod` — `GroupControl.twk:123`, where method scope is SKIPPED

```
GroupItem locateInMethod(String name)
{
GroupItem   action = currentMETHOD, result;
    if processingCode   result = action % name;      // method-local — SKIPPED at define time
    if !result          result = locate(name);       // global — ALWAYS reached at define time
    return  result;
}
```

**The local arm is gated on `processingCode` too.** So at define time this function is not
"method scope, then global" — it is **global only**. Its name overstates what it does in the one
context that matters here.

### 1.3 `locate(String)` — `GroupControl.twk`, the list that is actually walked

```
GroupItem locate(String name)
{
GroupItem   registri, group = registries[name];
    if !group && currentRegistry    group = currentRegistry[name];   // ← step 2
    if group                        return group;
    while registri = searchList.next(registri)                       // ← step 3
        if group = registri[name]   return group;
    while registri = baseRegistryList.next(registri)                 // ← step 4
        if group = registri[name]   return group;
    if name eq registries.tag       group = registries;
    return group;
}
```

Order: **1** the registry-of-registries · **2** `currentRegistry` · **3** every registry on
`searchList`, in order · **4** every registry on `baseRegistryList` · **5** the `registries` tag.

**Both step 2 and step 3 are live in this defect, and that distinction decides which fixes work
— see §3.4.**

### 1.4 How `sample`'s `second` got onto that walk — MEASURED, and it is the piece that makes
### the whole thing possible

**`define`'s indented sub-fields are ALSO flat entries in the registry, not merely members of
their parent.** Measured directly — after `include(unitTests)`, bare names resolve:

```
bare second = 56        bare fourth = 77        bare fifth = 88
```

`second` is not reachable *only* as `sample.second`; it is a first-class entry in `UnitTests`.
So `locate("second")` hits at **step 2** — `currentRegistry["second"]` — because `sample` and
`testForC` are both under `register(UnitTests)` in the same file.

**This is the root enabler.** Every sub-field name in every definition is a global-ish name.

---

## 2. CONTAINMENT — the answer is NONE, and it is the strong version

Clay asked whether the leak crosses action/file boundaries or only adjacent definitions in one
script. Measured (`incant/scopeProbe`, exit 0, sentinel present):

| the defining site | the victim | result |
|---|---|---|
| same registry, same file (`testForC`) | `sample.second`, `sample.third` | **leaks** — 56, `WTF?` |
| **different registry, different file**, an ACTION (`actQQ argument fourth=77` in `ScopeC`) | `sample.fourth` | **leaks** — 77 |
| **different registry, different file**, a PLAIN GROUP (`hostQ fifth=88` in `ScopeD`) | `sample.fifth` | **leaks** — 88 |

**The registry is not a fence. The search list is the road.** Row 2 reaches `UnitTests` from
`ScopeC` through `locate`'s step 3.

**And answering question 3: it is NOT specific to argument-attribute syntax.** Row 3 is a plain
group definition — no `argument`, no `code={}` — and it leaks identically. `aCTionNamE` is *the*
name rule action, so **every `name=value` in every definition is exposed**, in any registry
reachable from the current search list.

So the reach is: *any definition, anywhere, whose attribute name matches any entry in any
registry on the current search list, binds to and writes into that stranger.*

⚠ **One side-observation, not chased:** `iterate` over a node whose sole attribute was aliased
away crashed (exit 139). That is the null-`groupList` iterator hole reported separately today,
surfacing here rather than a new defect — but it is worth knowing that the aliasing can leave a
node in a shape the iterator cannot walk.

---

## 3. CANDIDATE SEAMS, with blast radius

*Named, not recommended. Each is where a fence COULD go; §3.4 is included precisely because it
looks like a fix and is not.*

### 3.1 `aCTionNamE`'s (c) gate — `ruleActions.rtn:617`
**The narrowest structural change, and the place the missing fork belongs.** Extend the
create-fresh block to fire in definition context, so `grup` is attached to the defining parent
instead of the stranger being adopted.

**Blast radius: HIGH, and unavoidable at this location.** `aCTionNamE` fires for *every name
token in the language*. The block's inner conditions (`!isArgument && !isLocal`, the `opFields`
exemption, the `action.isRule && isRule` split) are all tuned for code context and have no
define-context equivalents yet — each would need one. This is where the fix goes, and it cannot
be small.

### 3.2 `locateInMethod`'s `defining` fork — `GroupControl.twk:123`
Refuse the `locate()` fall-through while `defining`.

**Blast radius: LANGUAGE-WIDE, and it breaks working code.** A definition legitimately needs to
resolve names on the *value* side — `hasGroup=simple;` (`incant/unitTests:105`) must find
`simple`. **`aCTionNamE` sees only a name, never its position**, so this seam cannot distinguish
a declaration from a reference. A blanket refusal here converts a silent-wrong-write into a
silent-unresolved-reference. Not viable without §3.3.

### 3.3 The missing distinction — declaration position vs reference position
**Neither seam above can work without it, and it is the real open design question.** The parser
knows which side of the `=` a name is on and which slot of a definition it occupies;
`aCTionNamE` does not. Whatever fence Tony chooses, something has to carry that fact down to the
lookup — a definition-context flag set by the defining rule, a distinct rule action for
declaration position, or a positional argument to `locateInMethod`.

**Blast radius: design, not code.** Cheapest to decide before either §3.1 or §3.2 is touched,
and expensive to retrofit after.

### 3.4 ⚠ Scoping `locate()`'s search — LOOKS LIKE A FIX, IS NOT
Narrowing `locate()` to `currentRegistry` while defining (dropping steps 3-4) contains the
**cross-registry** half — my rows 2 and 3.

**It does nothing for the reported case.** `sample` and `testForC` are both in `UnitTests`, so
that hit lands at **step 2, `currentRegistry`**, which this change keeps. It would make the
defect harder to reproduce from a scratch file while leaving it fully live in the file where it
was found — the worst possible outcome for a defect that is already silent.

**Recorded so nobody adopts it as the cheap win.**

---

## 4. WHAT IS MEASURED vs WHAT IS INFERRED

*Stated explicitly because this codebase's structural claims hold and its causal claims fail at
roughly a coin flip (`CLAUDE.md`), and a recon that blurs the two is worth less than one that
reports less.*

**MEASURED, all with exit 0 and a sentinel:**
- the A/B attribution (§0) — single-variable
- sub-field names are flat registry entries (§1.4)
- all three containment rows, including cross-registry and cross-file (§2)
- non-specificity to action-attribute syntax (§2, row 3)

**READ FROM SOURCE, not executed** — the control-flow account in §1.1-1.3. It is a structural
reading of straight-line code with no dispatch in it, so it is about as safe as a source read
gets, but no instrumentation was placed on the walk to confirm *which step of `locate` fired for
`testForC` specifically*. The inference that it is step 2 rests on `sample` and `testForC` both
being in `UnitTests`; step 3 is independently proven live by row 2.

**NOT ATTEMPTED:** any fix, and any experiment mutating state beyond the containment runs (which
are per-process and touch only names minted for the purpose).

---

## 5. ARTEFACTS

| file | what it is |
|---|---|
| `incant/scopeProbe` | the containment fixture — three rows plus bare-name reach, self-contained |
| `incant/scopeUnits` | the A/B oracle: `unitTests` minus testForC's two attributes, **one line**, headed |
| `docs/nameScopeRecon.md` | this file |

Re-running the whole recon is two commands:

```
<binary> incant/scopeProbe                 # containment + bare-name reach
<binary> <the §0 driver, both sides>       # the single-variable attribution
```
