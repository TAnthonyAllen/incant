# GC recon — what collection would see, and miss (SEQ 586, 2026-11-10)

Read-only. Nothing built; one scratch tok probe in the scratchpad (not the repo); two fixture runs with
existing environment switches (`GC_PRINT_STATS`, `GCTHREADS_REPORT`) on today's `~/bin/incant`.
Road: **tok** source and the C++ it generates, unless a line says otherwise.

## ONE PLAIN LINE

`class GroupItem extends gc` alone would free almost nothing. Every GroupBody, GroupList and RuleStuff
would stay uncollectable, and the collector treats uncollectable blocks as roots, so they would keep
every GroupItem they point at alive. The try needs the whole node graph made collectable together.
When that happens, the dangerous roots are the JIT's baked addresses, the `Stak` / `GroupStak` arrays
(calloc'd, never scanned) and Objective-C objects holding our pointers.

## 0. The state today, measured

- `~/bin/incant` links the static `Groups/lib/libgc.a` (bdw-gc 8.3.0, headers `Groups/include/gc`). It
  is built **without thread support**: 0 `GC_pthread_create` / `GC_register_my_thread` symbols in it.
  The collector scans the main thread's stack and nothing else.
- Global `operator new` is `gcThreads.mm` (F-152): on the main thread `GC_malloc_uncollectable`, off it
  `malloc`. `otool -tV` on `__Znwm` shows the call to `gcThreadsAlloc`.
- `GC_PRINT_STATS=1`, 2026-11-10:

  | fixture | collections | freed per collection | heap at exit |
  |---|---|---|---|
  | `incant/pop/oneTest` | 0 | — | 1.6 MB, 96% in use |
  | `incant/pop/firstPdfT` | 18 | 0 or negative, every one | 16.5 MB, 98% in use, all "pointers" |

  So the collector runs and frees nothing, which is KE-5 (docs/knownErrors.md, the collector entry)
  measured again.
  ⚠ **The KE-5 name was taken twice in docs/knownErrors.md** (the `&&` truth table and the collector).
  **Ruled SEQ 588 R5: the collector keeps KE-5; the `&&` entry is KE-7.**
- `GCTHREADS_REPORT=1` on `firstPdfT`: off-main new 1847, off-main delete 1571, collector blocks leaked
  0, main delete of a system block 275. On `oneTest`: all 0. Off-main allocation only happens once
  Apple's PDF and Core Text code runs.

## 1. What allocates

Counts are allocation **sites** in the generated `.mm` (grep), not runtime counts. A runtime count
needs a tap in `gcThreads.mm`, which means a build, so it was not taken (STOP rule).

| what | allocator | collectable today | holds GroupItem pointers? |
|---|---|---|---|
| **GroupItem** (155 `new GroupItem` sites: GroupRules 89, GroupMain 39, GroupControl 13, GroupItem 9, others 5) | global new → `GC_malloc_uncollectable` | no | yes: `parent`, `nextInParent`, `priorInParent`, `labelOf`, `ruleOf`, plus `groupBody`, `rStuff`, `jitData` |
| **GroupBody** (3 sites) | global new | no | yes: `registry`, `gGroup`, `groupList`/`propertyList` → GroupList |
| **GroupList** (5 sites) | global new | no | yes: `firstInList`, `lastInList`, `stakked` |
| **RuleStuff** (11 sites) | global new | no | yes: `onGroup` |
| **JitData** (16 sites) | global new | no | read `jitContext.h:758` before the try |
| **GroupStak** (1 site, `GroupRules.mm:1296`) | object: global new. **Its array: `calloc`** (`GroupStak.mm:26`) | object no; array **invisible** | the array is `GroupItem**` |
| **Stak** (Frame; 5 sites: `recurseSTAK`, `blockSTAK`, `bufferSTAK`, `inputSTAK`, a field's `setStak`) | object: global new. **Its array: `calloc`/`reallocf`** (`Frame/Stak.C:15,25,122`) | array **invisible** | `void**`, holding GroupItems when the stack holds fields |
| **ParseActivation** | **0 heap sites**: the C stack (main thread, scanned) | n/a | yes, scanned with the stack |
| **Buffer**, **PLGset**, **BitMAP** (12 / 28 / 1 sites) | global new | no | not believed to; check Buffer before the try |
| **strings**: `tag`, `gText`, set text | `malloc` / `calloc` / `strdup` (`copyString`, `Frame/StringRoutines.C:271`; 10 `strdup`, 9 `malloc`, 3 `calloc` sites) or pointers into buffers and literals | invisible to the collector | no. They are plain characters, so being unscanned is harmless; they are never freed, so they leak |
| registry hashes (Frame `HashList`, `Hasher`, `DoubleLinkList`) | global new; they `delete` their own links | no | yes, they hold registered fields |
| **LLVM** (Module, IR, LLJIT's own objects) | global new on main → uncollectable, **scanned** | no | the IR's `ConstantInt`s carry baked addresses inline (§3a) |
| **JIT code memory** | LLVM's own `mmap` | not GC memory | yes, as instruction immediates (§3a) |
| **Objective-C / CF / CG** (`NSWindow`, `Layout`, CGContext, CTFont) | Apple's allocators (malloc zones) | invisible | `Layout->base` holds a GroupItem (§3b) |

**THE FINDING THAT DECIDES THE SHAPE OF THE TRY.** libgc marks from every uncollectable block on
every collection: those blocks are roots. If only GroupItem becomes collectable, every GroupBody ever
made is still a root. Each GroupBody's GroupList points at its first and last member, and the members
chain through `nextInParent`, so **every list member stays alive for as long as its parent's body
exists, which is forever.** The same goes for `gGroup`, `registry` and `RuleStuff.onGroup`. What could
still be freed is a GroupItem that never went into a list or a slot, plus the shell of a face (a face
shares its body). So R3's "count of what is actually freed" would read small, and the small number
would look like GC not helping when the real cause is the scope of the try.
**So the try should give the base to GroupItem, GroupBody, GroupList, RuleStuff and JitData together.**
GroupStak, Stak and Buffer can stay uncollectable: they are roots, which keeps things alive, so that is
the safe direction. Their **calloc'd arrays** are the opposite problem (§3c).

## 2. What `extends gc` means here

- **The tok spelling works**, re-probed today in the scratchpad (`~/bin/tok`, exit 0):
  `external class gc no.h;` with `class Probe extends gc` generates `class Probe : public gc`.
  ⚠ **It emits no `#include` for gc**, because `no.h` says not to and a retok drops includes anyway
  (bear-trap #5). `gc_cpp.h` therefore has to be in scope before any generated `.h` that says
  `: public gc`: through `groupIncludes`, a hand-written header, or the `.mm`'s include order.
  The banked fleet row (R3: pin GroupItem.h's class line) should also pin that the include arrives,
  since a missing `gc` declaration gives an empty header at exit 0.
- **What gc_cpp's `class gc` does** (`Groups/include/gc/gc_cpp.h`): class-level `operator new` →
  `GC_MALLOC` (collectable, scanned); `operator delete` → `GC_FREE`; placement forms
  `new (NoGC)` / `new (PointerFreeGC)`. It runs **no destructor** (that is `gc_cleanup`), so
  collecting a GroupItem never frees its malloc'd strings or releases a CGContext it holds. Those leak,
  and that is safe.
- **Beside `gcThreads.mm`**: a class-level `operator new` replaces the global one for that class only.
  Everything else still goes through `gcThreads.mm` as today.
  ⚠ **gc_cpp's `gc::operator new` has no thread check.** If an engine object is ever constructed off
  the main thread, it calls `GC_MALLOC` from that thread, and that is F-152's race on the unlocked
  free list again. Today nothing is known to construct engine objects off-main (the only GCD door,
  `GroupItem::dispatch()`, has no callers; see §3c), but nothing enforces it either.
  **So I'd recommend a base of our own** in `gcThreads.mm`'s style: `GC_MALLOC` on the main thread,
  refuse loudly by name off it. tok would spell it the same way (`external class gcEngine no.h;` and
  `extends gcEngine`). That is a ruling, not taken here.

## 3. Roots the collector cannot see

### 3a. The JIT (Tony's priority)

- **Baked addresses.** About 95 `CreateIntToPtr(ConstantInt::get(i64, (uint64_t)…))` sites, plus 57
  calls through local bake helpers (`bake` 40, `ubake` 8, `bake64` 4, `retBake` 3, `tbake` 2).
  - **Function addresses** (`&jitTermCallRT`, `&opPrint`, `&displayFillRT` …, about 45) are code, so
    they are safe.
  - **Registry and parse-tree nodes**: `op` (an Operators entry), the `target`/`argument`/`operand` of
    a cached statement, `FormaT`, `token`, `field`. These are alive by reachability **as long as the
    action stays defined**, because the cached BlocK hangs off the action, which hangs off the
    registry. The exposure is an action that is evicted or redefined while its compiled function is
    still in `gJitCache`.
  - **Emit-time mints**: nodes made while emitting and baked, which only the code then refers to.
    `result` in `jitEmitIterStep` (`GroupRules.mm:5381`, `:5419`), `gJitReturnLabel`, and whatever the
    `bake` lambdas are handed. **This is the real hazard**: once LLVM drops the Module, the immediate
    in the machine code is the only reference, and the collector does not scan it. Each of the 152
    sites has to be put into one of these three classes before the try is believed; that census is
    step 1 of the plan, not done here.
  - ⚠ **The hazard only shows up late.** While the IR Module exists, its `ConstantInt` objects sit in
    uncollectable memory and hold the address inline, so the node is kept alive. The danger starts
    when LLJIT finishes codegen and frees the Module, which is when the compiled function begins to
    be **fired from `gJitCache`**. A test that compiles and fires once can stay green. The witnesses
    have to fire again after a collection.
- **`gJitCache`** (`jitContext.h:584`, `std::vector<JitCacheSlot>{GroupBody*, name, fn}`), plus
  `gJitFnMap`, `gJitterRules`, `gJitterTally`, `gJitLocalKind` (keyed by `GroupBody*`), `gJitSeeded`,
  `gJitInlining`. The vectors' storage is allocated by global new, so it is uncollectable and scanned:
  **these keep their bodies alive**, which is the safe direction. One consequence: a body that is a key
  there can never be collected, so a long session that keeps redefining actions grows them.
- **Raw-pointer JIT globals** (`gJitLastAction`, `gJitCurrentAction`, `gJitArgOrigin`,
  `gJitDotSeeded`, `gJitProbeCarrier`, `gChanPendGroup`, `gChanStkGroup[]`): these live in the main
  image's `__DATA`, which is scanned **until a window opens** (§3c).
- **LLJIT itself** is a function-local `static std::unique_ptr` (`GroupRules.mm:6364`). Its objects are
  uncollectable and scanned, and they point at code, not at our fields.
- **Mitigation shapes, for the ruling and not chosen:** (i) every bake goes through one helper that
  also appends the address to a per-function `std::vector<GroupItem*>` stored beside the `gJitCache`
  slot. That vector is uncollectable, so it keeps the baked nodes alive for as long as the function
  is cached. It is one funnel, and bear-trap #10's no-baked-offsets argument does not apply because
  it is a list of addresses, not a struct layout. (ii) The IR loads its addresses from a root table
  instead of using immediates (more runtime cost, more work). (i) is cheap, keeps today's IR, and
  matches the bake lambdas that already exist.

### 3b. Pointers held in malloc'd or Apple-owned memory

- **`Layout->base`** (`Layout.h:15`), an ivar of an Objective-C object, so in malloc memory: it holds
  the form. **This one has already happened.** `guiHost.mm:28-36`'s comment, written while GroupItem
  still had its `gc` base (April-May), says the form "gets collected mid-run and drawRect derefs freed
  memory". The fix in place is `GC_add_roots` on `GroupControl::groupController`, which works only if
  the form is reachable from the controller. **Re-check that for every form `openWindow` is handed**
  (a form built in a local and passed straight in is the case to test).
- **The pointer slot** (`gPointer`, union with `gText`): `setPointer(ctx)` at `GroupDraw.mm:453, 497,
  572` stores a CGContext / PDF context there. The pointer goes from us to Apple, so collection is
  safe; collecting a top that holds a live context leaks the context (no destructor). `gObject`
  (NSObject*) is the same direction.
- **`CFRetain(font)`** (`Stylish.mm:248`): again us pointing at Apple, so collection leaks the font
  rather than breaking anything.
- **Blocks and observers in `openWindow`**: the close-notification block captures nothing of ours.
  Safe.
- **Off-main threads** (1847 allocations in `firstPdfT`): Apple's own, through `malloc`. Not believed
  to hold our pointers (the collector never scanned them, and nothing has broken since F-152's cure).

### 3c. Everything else

- **`Stak` and `GroupStak` arrays: calloc'd, so invisible.** A GroupItem held **only** by a stack would
  be freed while still on it. `inputSTAK` and `bufferSTAK` hold buffers and inputs; `blockSTAK` and
  `recurseSTAK` hold parse-time fields; a field of data type STAK holds whatever kant pushes. Whether
  any of those entries is held **only** by the stack is the question to measure (step 3 of the plan).
  The direct cure is to allocate those arrays with `GC_MALLOC_UNCOLLECTABLE`, a two-file change in
  Frame (support repo) and `GroupStak.twk`, which makes them roots like every other C++ array here.
  `GroupRules.mm:12799`'s census arrays (`seen`, `bodyRoot`) are a measurement tool's scratch. Note
  them; they hold nothing that must survive.
- **Statics**: `GroupControl::groupController` reaches the whole world. All other `static` /
  `inline` globals are scanned **only while data segments are registered**, and **`openWindow` turns
  that off for every image** (`GC_set_no_dls(1)`, `guiHost.mm:28`) to dodge AppKit's root-set limit.
  After a window opens, every raw-pointer global except the controller is invisible: the JIT globals
  above, and `gParseActive` too, unless its frames are on the stack, which they are. Today no window
  opens while the JIT runs. Under relayout (the GC road's own reason, R2) both will happen together.
- **Thread stacks other than main**: not scanned (single-threaded libgc). Safe only while no engine
  code runs off-main, the same condition as §2. `GroupItem::dispatch()` (`GroupItem.mm:757`) hands
  `this` to a GCD queue and **has no callers**. ~~It is on the cleanup list (2026-11-10), not touched.~~
  **Parked, not dead (Tony, SEQ 588 R0)**: a feature he has used and will use again. Its header in
  `GroupItem.twk` now says a revival must keep engine allocation on the main thread.
- **The collector's own blind spot for interior and disguised pointers**: tok code that keeps an
  address as an `int` or `long`, or as `char*` into a node. Only the bake sites were found; not
  searched further.

## 4. What relies on `delete`

- **Engine objects: none.** `delete` of a GroupItem, GroupBody, GroupList, RuleStuff or JitData: 0
  sites in the generated `.mm` (the two grep hits at `GroupRules.mm:447` and `:521` are prose).
  `GC_free` / `GC_FREE` outside `gcThreads.mm`: 0. **No class in Groups or Frame has a destructor**
  (`~X()`: 0 in every `.h`).
- **Frame support objects**: `Hasher.C:71,122`, `HashList.C:136` and `DoubleLinkList.C:162` delete
  their own link nodes; `PLGset.C:407` deletes its Buffer. These go through `gcThreads.mm` (`GC_free`
  on main) and are unaffected unless those classes get the base too. They are not proposed for it.
- **`delete f.exitBB`** (`GroupRules.mm:6763`) is an LLVM BasicBlock. Unaffected.
- **`free()` of strings** (`GroupItem.mm:2189, 2200` methodName; `GroupRules.mm:12438, 12464` `why`;
  `:12826` a scratch stack): malloc'd, unaffected.
- **So nothing depends on a destructor running**, and `gc` (not `gc_cleanup`) is the right base: no
  finalizers, no ordering questions.

## 5. Measurement plan (not run)

The aim is a missed root that crashes **near its cause** instead of later at random.

1. **Census the bakes** (no build): classify all 152 sites as function, live tree node, or emit-time
   mint. The third class is the list the JIT mitigation has to cover.
2. **A stress switch in `gcThreads.mm`, the house pattern** (an environment variable, inert when
   unset, so no fixture's output moves): `GCSTRESS=N` calls `GC_gcollect()` on the main thread every
   N allocations. With N=1 a collection runs at every allocation point, which is where a missed root
   breaks.
3. **A poison, so a freed node is loud**: under `GCSTRESS`, the base's `operator new` registers a
   finalizer that fills the object with a known pattern when it becomes unreachable. A missed root
   then reads `groupBody = 0xdededede…` and faults at the first use, and lldb names the stale holder.
   Without it, a freed block is reused and the symptom is a wrong value somewhere else entirely.
4. **A `collect` command** (kant, `immediateAction`) so a fixture can force a collection between two
   chosen statements. The JIT rows need this: collect **after** a compile and **before** a refire.
5. **Witnesses, in this order:**
   - **`jitLadder/ladder.sh` first** (Tony's priority), under `GCSTRESS` and with a `collect` between
     `testing()` and `jitRefire()` in the rungs that refire cached code: JR, JD, JC, JXT, and the
     iterator rungs (`iterNode` is an emit-time mint).
   - **`formsPop.sh`** (PDF contexts, off-main threads, the drawing walk) and `firstPdfT`.
   - **`pop.sh` whole**, row for row against the bank.
   - **A window run** (`openWindow` on a form held only by a local), for `Layout->base` and the
     no-dls blind spot. It is not on any checklist, so it is run by hand.
   - **The freeing count**: KE-5's control loop (`m := copyOf(v);`, 200,000 passes) and setFrame's
     relayout loop under `GC_PRINT_STATS=1`. Today they read **freed 0 or negative** (this recon,
     `firstPdfT`), so a real "freed N" is the value that shows the try took (H4: presence with value).
6. **H7, in three parts:**
   - **The mechanism**: remove the base (the two tok lines), and the freed count returns to ≤0 on the
     control loop.
   - **The witness can see a missed root** (H16: validate the probe against a known-bad first): plant
     a GroupItem held **only** in a calloc'd `Stak` array, collect, read it. Under the poison it must
     fault, by name. If it stays green, the witness certifies nothing.
   - **The JIT mitigation, if built**: remove the pin list, and a refire after `collect` must fault on
     an emit-time mint.
7. **Scope as the try's step 0** (§1): give the base to GroupItem **and** GroupBody, GroupList,
   RuleStuff, JitData. Measure the freed count for GroupItem alone as well, and record it, so the
   finding in §1 is measured and not just reasoned.

## For Tony

1. **Scope**: the try covers the five node classes, not GroupItem alone (§1). That changes R1 as
   banked.
2. **Base**: gc_cpp's `gc`, or a `gcEngine` of our own that refuses off-main (§2).
3. **JIT**: pin baked addresses per cached function (i), or load them from a root table (ii) (§3a).
4. **Stacks**: allocate the `Stak` / `GroupStak` arrays uncollectable (Frame is the support repo) (§3c).
5. ~~**KE-5 is two entries** in knownErrors.md; which one keeps the name.~~ Ruled (SEQ 588 R5): the collector keeps KE-5, the `&&` entry is KE-7.

## The stroke-2 dispatch, as forwarded (Tony, 2026-11-10) -- the next session opens here

Recorded verbatim at the shutdown of seal 420, so the fresh session takes it from the tree. SEQ is Clod's to assign (589).

```
DISPATCH -- SEQ (Clod assigns) -- GC STROKE 2: THE FIVE NODE CLASSES COLLECTABLE, ON A BRANCH. NOT MERGED.

RULINGS (Tony, 2026-11-10; R1-R4 as ruled on docs/gcRecon.md)
R1  GroupItem, GroupBody, GroupList, RuleStuff, ParseActivation become collectable together.
R2  Through a base class of ours, gcThreads.mm's style: collectable on the main thread, refuses by name off it.
    The gc_cpp.h include must reach every header that needs it; the class-line row checks the include too.
R3  Each gJitCache slot keeps the list of nodes its code bakes in.
R4  Stak and GroupStak arrays allocated uncollectable (support Frame/Stak.C; GroupStak.twk here).
R5  KE-3 and KE-4's duplicate names get fixed the way KE-5's was, citations repointed. Docs only.
R6  Windows: Layout->base and openWindow's static-scan switch are named in the report -- fixed if small,
    otherwise docketed. Windows is not yet a target; do not certify a window run.

THE ORDER, on branch gc-collect, each part its own commit:
1. R4 and R3 first. Both are inert while nothing is collectable: fleet and ladder row for row.
2. R2 and R1 last: the part that moves rows.

CERTIFICATE (pre-registered from stroke 1's rows):
- gcT GC-1 moves off 0 (the copy loop frees). GC-2 reads stakKept. GC-3 stays 16 of 16.
- JGC: the count moves; the cached answers stay 9 and 9.
- Fleet and ladder row for row but those, with GCSTRESS unset AND at GCSTRESS=1000 (address lines aside).
  Any other mover is a finding: report it, do not re-pin it.
- H7s: Stak arrays back to calloc -> GC-2 fails (0xDE or a crash); the pinned-node list removed -> JGC
  fails. For R2's off-main refusal, say how it is witnessed, or why no row can reach it.

The buy is Tony's.
```

Notes for the opener, from strokes 1 and the recon (not rulings):
- ParseActivation has 0 heap sites today (it lives on the C stack), so R1 for it means the base class on the struct
  in GroupRules.twk; bear-trap #58 and SEQ 235/237 (a ParseActivation change carries a full bare-tokall diff) apply.
- tok writes `: public X` for `extends X` but no #include (scratch probe, recon section 2); the base must be in scope
  before every generated .h that names it.
- The poison registers only while GCSTRESS is set; gcT and JGC run under GCSTRESS=0 for that reason.
- The stroke-1 baseline: pop.sh 3353 green, FAIL rows = docs/sealCaptures/pop.fails.txt (72); jitLadder exit 0.
