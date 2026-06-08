# Generating-machinery orientation

*One read to get oriented on how incant source becomes bytecode. Bones only —
what things are and where they live. Assumes you've read CLAUDE.md's "Phase
Bytecode" section (the pipeline overview + settled design) and don't repeat it.*

**Cross-refs (already documented elsewhere — go there, not here):**
- Pipeline overview, op identity, two registries, two-step dispatch idiom → `CLAUDE.md` (Phase Bytecode).
- "bytecode = GroupItem, tag = opcode, `interpret` inherited by tag"; `emitBC`; bare labels → `docs/gIF-bytecode-status-2026-05-30.md`.
- How an op's handler actually gets *invoked* (`interpret` child, `runByteFn`, the poochifier) → `docs/bytecode-dispatch-plan.md`.
- The `bytecodE` *attribute* + gating hook (GroupRules.mm:786) + JIT plan → `jit.md`.

This doc fills the operational gaps those leave.

---

## 1. Two passes, and the `generating` flag (NOT `bytecodE`)

`generateCode(field)` (`Commands.rtn`) runs **two passes**:

```
generating = true;
processCode(field);          // PASS 1 — runs the action's code
generating = false;
... runAction(BlocK, generate);   // PASS 2 — generatE walks the statements
```

- **`generating`** is a `GroupRules` bool flag. It is the gate the *rule actions*
  check (`aCTionExpressioN`, etc.) to decide "am I building bytecode right now?"
  It is **not** the same thing as the `bytecodE` *attribute* on a statement
  (that's the runtime gating hook in `jit.md`). When you mean "are we in codegen,"
  you mean `generating`.

- **Pass 1 (`processCode`, `generating=true`):** the action's statements *execute*.
  Executing an `if` evaluates its condition; that fires the condition's rule action
  (`aCTionExpressioN`) which — seeing `generating` true — takes its **generating
  branch** and **builds + stashes** a `revisedList` (see §2). So Pass 1 is when the
  per-expression bytecode fragments get built, as a side effect of the statements
  running.

- **Pass 2 (`generatE` → `runGenerated` → `gXX`):** walks the parsed statements and
  dispatches each to its generator handler (§4), which reads the stashed `revisedList`s
  and assembles the final `bcLIST`.

**Trap:** a statement only gets its operands built in Pass 1 if Pass 1 actually
*executes* it. `if`/`for` execute their bodies, so their sub-expressions get built.
A bare `print` does not get executed that way — which is why the print path needed
the thunk (§6), not the build-and-stash path.

---

## 2. Build-and-stash — `aCTionExpressioN` is the canonical model

`aCTionExpressioN` (`ruleActions.rtn`) is the model every generator-aware rule action
follows. Its generating branch:

```
if generating {
    revisedList = new("revisedList");
    ... walk the expression's tokens, append the bytecode-shaped members ...
    xpList.clear();              // empties the ExpressioN's own list
    xpList.group = revisedList;  // STASH: the revisedList becomes the node's group
    return xpList; }
```

So after Pass 1, the `ExpressioN` node is hollow except that **`.group` points to the
revisedList** holding its bytecode fragment. The generator handler later retrieves it
(gIF does `stXP := st["revisedList"]`).

**Two sharp edges (both cost time — see this dir's recon notes / git history):**
- The RPN walk **only emits when it completes an operator + target**. An
  *operator-less* sequence (e.g. the bare print operands `"hello" name`) emits
  **nothing**, then `clear()` destroys the tokens → an **empty revisedList**. The
  fix landed in `aCTionExpressioN`: detect no-operator, *leave `xpList` intact* and
  set `isLIST` instead of stashing an empty list.
- The stash is `node.group = revisedList`. `gXpress`/`appendGroup` consume **members**,
  not `.group` — so you can't hand them the bare wrapper; you reach the revisedList via
  the node's group (incant `["revisedList"]` search does NOT follow `.group`; `unWrap`
  peels exactly one group level).

---

## 3. `revisedList` shape and contract

- It's a plain `GroupItem` tagged `"revisedList"`, whose **members** (groupList) are the
  bytecode-shaped fragment in emission order: operands and op GroupItems for `gXpress`
  to walk, or store ops (`copyOf(bcOPs["bcStoreField"])` carrying a `target` child) for `=`.
- Members are added with `+=`/`addMember` so they're members (what `gXpress`'s
  `for child in tmp; members` walk sees).
- An **empty** revisedList means the builder dropped the tokens (see §2 first edge) —
  treat an empty revisedList as a bug signal, not a valid "nothing to emit."

---

## 4. Tag → dispatch: deferred actions make the tags, `runGenerated` hashes on them

- A statement's **generator tag** (`gIF`, `gFOR`, `gPrinT`, `gXpress`, `gExpressioN`,
  `gBlocK`, `gDeclare`, `gWhilE`, `gDO`) is set by the **deferred rule-action mechanism**
  at parse time — the parsed statement node carries that tag.
- **`runGenerated(stmt)`** (`incant/generate`) does `action := generator[stmt]` — a hash
  lookup in the **`generator` registry** keyed by the statement's tag — and invokes it.
  No handler ⇒ it falls back to printing the statement literally.
- The **`generator` registry members ARE the extension points.** To support a new
  statement form in bytecode, you fill in (or add) its `gXX` member in `incant/generate`.
  Several are stubs / legacy C++-emit holdovers — `generateAction` and its callers were
  built when generate emitted C++ source, and are being reworked for bytecode; don't treat
  that dispatch layer as settled.

---

## 5. `gXpress` contract

`gXpress(argument)` (`incant/generate`): walks `argument`'s **members** and for each child:
- `child.isOperatoR` (and tag ≠ `"="`) → `emitBC(child)` — the op GroupItem itself (its
  `interpret`/`operateMethod` ride along; do NOT unwrap an operator).
- in `bcOPs` registry → `emitBC(child)`.
- `child.isLiteraL` → `emitBC(bcPushLit=child)` (snapshots the value as data).
- else → `emitBC(bcPushField=child)`.

So `gXpress` needs **leaf tokens as members** (literals / fields / operators). Hand it a
wrapper (an `ExpressioN` whose payload is in `.group`, or a non-leaf) and it emits nothing
useful. It does NOT walk `.group` and does NOT recurse — flatten/unwrap before calling it.
(`gXpress` is the operand-emitter; `gIF` etc. call it on their condition/branch revisedLists.)

---

## 6. Worked example: the `aCTionPrinT` thunk — when NOT to decompose

`print "hello" name:` lands as a `bcPrint` that, at interpret time, **re-runs the print
action** rather than pushing each operand:

- `gPrinT` (passthrough): `op = copyOf(bcOPs["bcPrint"]); op +% argument; emitBC(op)` —
  one `bcPrint` carrying the statement at `[2]`.
- `runPrint` (`Bytecode.twk`): `aCTionPrinT(instr[2])` — fires the existing print action.
- Operand order preserved by the `reversePrint` flag (`GroupBody`) that `appendGroup` reads.

**The lesson:** full operand-level bytecode (each operand → `bcPushLit`/`bcPushField`) was
the *wrong first instinct* here. The operands were already destroyed/awkward to reach in
generate, and decomposing bought nothing the interpreter doesn't already do. The thunk
prints correctly via the bytecode *dispatch* and does **not** disturb the IR shape the JIT
will consume — real decomposition is a deliberate later step, not a prerequisite. Reach for
a thunk (dispatch to the existing action) when the decomposition is fighting the structure;
reach for real push-ops when the operands are clean expressions (`if`/assignment style).

---

## 7. Lane boundaries in generator work

- **Tony (architect):** owns design intent, the `.twk`/GroupBody/core-class changes, and
  the Xcode build seat. Changing GroupBody flags ⇒ **re-tok every class** (his
  tok-everything script) or inter-class links go stale.
- **Clay (design):** writes the implementing brief / chooses the approach; arbitrates
  "thunk vs full bytecode," "fix-the-root vs route-around."
- **Clod (execution):** edits source, runs `tok`, reads the regenerated `.mm` to verify
  codegen, runs `incant oneTest`, reports findings. **`incant/generate` (and the other
  `incant/*` files) are interpreted — edits take effect on the next run, no rebuild.**
  `.rtn`/`.twk` changes need a re-tok + Xcode rebuild (Tony's seat).

**The two costly tok traps for generator work specifically:**
- **`//` comments in `.rtn`/`.twk` method bodies cascade field-resolution bleed** across
  *every following function* (`stuff:` → wrong receiver → undefined-symbol errors fanning
  out). Keep comments above the function or in `/* */` outside the body.
- **Bare field refs (`noPrint`, `FormaT:`) resolve to the last-mentioned field.** A local
  declared before a loop hijacks them; pin with `use grup` or qualify explicitly. Verify by
  reading the regenerated `.mm` — the receiver is right there.
