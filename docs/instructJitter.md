# Instructions and the Jitter

Brief for Clay, 2026-10-31. Clod's reaction to Tony's offline note of the same day: kantGrammar builds instructs everywhere, and an instruct looks like LLVM IR. Should there be one instruction rule, and could a jitter incantation redefine it so kant emits IR itself?

Facts below were read off trunk at seal 290 (`0a8f83ec`). Anything marked *proposal* or *sketch* has not been run.

## The one decision this asks of Tony

**Should the jitter be a walk over the finished instruct chain, or a redefined build rule that emits IR while the parse runs?**

Clod recommends the walk. The reasons are in section 4. Everything else here follows from that choice.

## 1. In one line

One instruction-building action is worth doing now, just to shorten kantGrammar. A jitter that walks the chain those actions build fits the language better than today's JIT, and its first version can be correct on day one. It comes after rung 5, and the IR should not be built while the parse runs.

## 2. Tony's observation, measured

Every control rule's kant action does the same thing: collect the children's instructs, refuse if one is missing, pick an op from `Operators`, mint the operand list, wrap it, hand it up. Counted above `bail()` in `incant/kantGrammar`:

| repeated line | copies |
|---|---|
| `instruct.methoD = "testOP";` | 17 |
| `cerr "REFUSED …"` arm (then `clear`, `return`) | 16 |
| `target := copyOf(instruct);` and the clear-and-return tail | 15 |

The tail every builder ends with today:

```
op := Operators["whileLoop"];
armsMint    := copyOf(whileArms);
instruct    +% *op;
instruct    +% *armsMint;
instruct.methoD = "testOP";
target      := copyOf(instruct);
clear(instruct);
*argument   := *target;
return  *argument;
```

That is one action with two inputs, the op name and the operand list. The macros file already says "a kant action works fine as a macro", so this can be a plain kant action called from each rule; it does not need to be a grammar rule. Besides shorter code, it gives the language **one place that decides what an instruct is**. Today that decision is spread over 17 sites.

## 3. How the JIT works today

The JIT is entirely C++: `jitEmitters.rtn`, 4,609 lines, about 130 externs, 205 IRBuilder calls. The flow, in order:

1. **`jitter;`** sets the global `gJitter`. From then on, the first call of an action by name is diverted from `runAction`'s interpreted arm to `jitRunAction`.
2. **`jitRunAction`** checks the cache (compile once, reuse forever, SEQ 385), then creates an LLVM context and module and enters the build loop.
3. **`jitBuildFunction`** creates the function, an IRBuilder, the entry and epilogue blocks, and a prologue with stack slots for the argument and locals.
4. **The walk.** It sets `jitting=1` and walks the action's cached *old-road* BlocK through the interpreter's own dispatch (`aCTionBlocK`, then statements, then `runOP…`). Each gated operator or handler emits IR instead of computing. A statement it cannot emit is rolled back and replaced by a run-time call that runs it interpreted (`jitStmtRT`). An inlined callee that calls itself forces a restart: the partial function is discarded, the callee is built, and the walk runs again.
5. **Finish.** `verifyFunction`, then mem2reg, then ORC LLJIT; look up the symbol, cache it, call `fn(argument)`. Any failure marks the action NOT JITTABLE: announced once by name, interpreted from then on, never retried.
6. **Values.** Field slots are baked absolute addresses; anything GroupItem-shaped goes through `…RT` helper calls. Each operand's kind (i32, double, string) is decided at build from what the field holds then. Most of the measured hazards live here (`docs/jitter.md`, sites S1 to S12).

**The fact that matters here:** the JIT knows nothing about the new road's instruct chain. `jitEmitters.rtn` has zero references to `testOP`, `opSeq`, `opIf`, `opWhile` or `printList`. It walks the old road's BlocK. Under `jitter;` the new road's instructs are handed to run time, and the macros file lists jitting the chain as rung 6, "later".

## 4. Where the jitter dress should go

Tony is right that an instruct is three-address code: op, target and argument map onto `%r = op target, arg`. The question is when the IR gets written.

**Tony's sketch: redefine the build rule.** A jitter incantation reopens the instruction rule so each rule emits IR as the parse builds it.
- *Order is wrong.* Children build first, so an `if`'s arms exist before the `if`. Straight-line emission puts arm code ahead of the branch. Open question 6 (a `break` cannot name its loop) is the same fact.
- *Time is wrong.* SEQ 386 ruled jit at first call because that is when field kinds are known. At parse time the fields may not exist. It also mixes the two phases the plan keeps apart.

**Recommended: walk the finished chain.** The instruction action builds the chain exactly as now. At first call, a jitter incantation walks it top-down and writes IR.
- *Order is right.* A loop already exists when its `break` is reached, so open question 6 goes away at jit time.
- *Time is right.* Kinds are readable at first call, and compiling has no side effects. One structure, two consumers: `testOP` interprets, the jitter compiles. That is the 2026-06-17 decision restated.

### The shape of the walk (proposal)

```
parse, build time:   kant rule actions call one instruction action
                     -> the instruct chain, cached on the label
                              |
            +-----------------+------------------+
            |                                    |
   interpreted: testOP walks         jitted, first call: the jitter incantation
   the chain on every run            walks the chain once, writes IR text into a
                                     buffer; dispatch per op:
                                       handler = op.emitteR; handler(instruct);
                                                 |
                                     one C++ extern, compileIR(buffer):
                                     parse, verify, ORC, look up, cache
```

Each `Operators` entry carries its IR spelling as data (for example `irOp=add`), so adding an op to the jitter is mostly an attribute. Control ops get a small kant emitter each:

| instruct op | what the jitter writes |
|---|---|
| `+ target arg`, kinds known | `%t7 = add i32 %t5, %t6` |
| `+ target arg`, kinds unknown | a call to the op's run-time helper |
| `seq` | its statements, in order, in the current block |
| `ifThen` | three blocks and `br i1 %c, label %then, label %else` |
| `whileLoop`, `doLoop` | condition block, body, back-edge |
| `branchSignal` (break, continue) | `br` to the enclosing loop's exit or condition |
| anything not yet supported | `call ptr @testOP(ptr <that instruct>)` |

### The fallback is free and always correct

The last row is the important one. An instruct the jitter cannot emit yet becomes a call to `testOP` on that instruct, so the first jitter can emit every statement that way and still run correctly. Then ops move off the fallback one rung at a time, each rung comparing jitted output against the interpreted run, the same pattern the kant rungs already use. It also keeps the SEQ 384 ruling that compiling has no side effects.

## 5. What kant needs in order to write IR itself

`docs/jit.md` §0 already makes the point: "a text emitter can be kant; an IRBuilder one never can." So the route where kant writes the IR is textual IR, with C++ only compiling it. Missing today:

1. **`compileIR(buffer)`**, one C++ extern: parse the IR text, verify, add to ORC, look up, cache against the action. Most of it already exists inside `jitRunAction`.
2. **Unique names** (`%t7`, `%L3`). A count and string concatenation in kant can already do this.
3. **A field's real address as text**, for `inttoptr (i64 N to ptr)` or a helper argument. `addrOf` prints field and body index numbers, not addresses, so this probably needs a new accessor.
4. **Kinds at emit time.** The hard part, and the same hard part the C++ JIT has. Accessors like `datA` can read a field's kind, but only at first call, never at parse time.
5. **Run-time helpers declared in the module text.** The `…RT` externs already exist to be called.

## 6. Risks to measure before building

- **IR text inside kant strings.** IR is full of `%`, `@`, `{ }` and `;`, and `;` starts an IR comment. How kant literals carry these is unmeasured.
- **Baked instruct pointers and the collector.** JIT code memory is not a Boehm root. A `testOP` fallback that bakes an instruct's address is safe only while the chain stays attached to its label. Probably true, since the chain is cached, but it should be checked, not assumed.
- **The kind problem does not go away.** Kant gets to decide types, but the information arrives at the same moment it does for the C++ JIT. The helper-call row exists so a first cut never has to guess.

## 7. Proposed order

1. **The instruction action, now.** Cheap, shrinks kantGrammar, and fixes the one place the jitter will key on.
2. **Rung 5.** The jitter compiles actions, and the new road cannot yet build an action call with its frame and `return`.
3. **A recon.** Does a kant buffer carry IR text intact, and does `parseAssemblyString` accept it?
4. **Rung 6, first cut:** a jitter that emits every statement as a `testOP` call, then moves ops off the fallback one rung at a time.
