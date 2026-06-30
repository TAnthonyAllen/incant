# Bot Subsystem Recon (2026-06-30)

*Tonto recon. Target: `/Users/anthony/Dropbox/data/InProcess/Bot/` — an old (2017–2021) two-process
experiment (`BotServer` + `BotClient`, driven by `RunBot`). Question: is this a usable head start for
the parked **webChannel pilot** ("get incant talking over a socket / wire")? Complements
`docs/wiki-recon.md` (the webChannel toe-dip, 2026-06-30), which grepped the *Groups* tree for
socket/HTTP/listen code and found none. This recon covers the *Bot* tree, which lives outside Groups.*

## TL;DR

Bot's channel is **Cocoa Distributed Objects (`NSConnection`/`NSDistantObject`)**, not a raw socket —
proxy-object RPC over Mach ports (same-host, as actually invoked here), with an opaque/built-in wire
format (Objective-C archiving), not bytes or text you control. It is **not** a "socket skeleton in
Apple gift wrap" so much as a full RPC layer that happens to be capable of running over sockets
(`NSSocketPort`) if explicitly configured to — which this code never does. No incant/GroupItem data
crosses the wire today; `BotClient.run()` has a literal TODO comment saying so. **Build state: broken
as committed** — `botIncludes` references two `.ext` files absent from the active include path (both
survive in `~/data/support/Include/BackupIncludes/`, so it's a copy-back fix, not a rewrite), and
nothing in the current source tree actually calls `runServer`/`runClient` end-to-end. **Verdict: reference only,
not a transport skeleton to resurrect** — wrong layer (DO, not sockets/HTTP) for a browser-facing
webChannel; the wiki-recon's "minimal incant socket listener" (`setSocketOp`) remains the right first
step, built from scratch.

---

## 1. Transport — exactly what carries the bytes

**Mechanism: Cocoa Distributed Objects via `NSConnection`, not a hand-rolled socket.**

The actual wrapper class is `Bot`, and it does **not** live in the `Bot/` directory — its source is in
the separate `Frame/` support tree (symlinked into many projects):
- `/Users/anthony/Library/CloudStorage/Dropbox/data/InProcess/Frame/Bot.h`
- `/Users/anthony/Library/CloudStorage/Dropbox/data/InProcess/Frame/Bot.mm`
- `/Users/anthony/Library/CloudStorage/Dropbox/data/InProcess/Frame/Bot.twk` (the `.twk` source; `.h`/`.mm` are its tok output)

```cpp
// Frame/Bot.mm:11-15  (server side: vend a root object)
Bot::Bot(NSObject *object)
{
    contact = [[NSConnection alloc] init];
    [contact setRootObject:object];
}
// Frame/Bot.mm:20-29  (register a discoverable name)
int Bot::registerAs(char *name)
{
    if ( ![contact registerName:[NSString stringWithCString:name encoding:NSASCIIStringEncoding]] )
        { ... return 0; }
    return 1;
}
```

`contact` is an `NSConnection*` (`Bot.h:1,10`). `Bot` in incant terms is "essentially a wrapper for
Connector" (comment at `Bot/BotServer.twk:4`), and `Connector` is incant's alias for `NSConnection`,
declared in `/Users/anthony/Dropbox/data/InProcess/Include/OCframe:103,368-380`:

```
Connector       NSConnection                                    // OCframe:103
external Connector extends Object {
    Connector           connectWithRegisteredName(NSString host);
    int                 registerName(NSString s);
    void                setRootObject(Object o);
    static Proxy        rootProxyForConnectionWithRegisteredName(NSString name,NSString host);
    static Connector    serviceConnectionWithName(NSString name,id rootObject);
    static Connector    serviceConnectionWithName(NSString name,id rootObject,PortServer usingNameServer);
}                                                                  // OCframe:368-380
```

Client side, `BotServer.mm:14-23` (compiled from `Bot/BotServer.twk:45-58`):
```objc
proxy = [NSConnection rootProxyForConnectionWithRegisteredName:
            [NSString stringWithCString:server encoding:NSASCIIStringEncoding] host:0];
[proxy setProtocolForProxy:@protocol(BotProtocol)];
botProxy = proxy;
...
if ( text = [botProxy get] ) ...   // a literal Objective-C message send across the proxy
```

**Sharpening the "socket under Apple gift wrap" hypothesis — verdict: no raw socket is present or
reachable in this code.** I grepped `Bot/`, `Frame/Bot.*`, and `OCframe` for `socket`, `NSStream`,
`NSFileHandle`, `NSPort`, `CFSocket`, `NSSocketPort`, `bind(`, `listen(`, `accept(`, `connect(` — the
only hits are two English-language comments (`BotClient.twk:25-26`, see §4) that say "socket," not
code. There is no `NSFileHandle` (no `fileHandleWithConnectedSocket`/`acceptConnectionInBackground`),
no `NSStream`/`NSInputStream`/`NSOutputStream`, no `CFSocket`/`CFStream`, and no hand-rolled BSD
`socket()`/`bind()`/`listen()`/`accept()` anywhere in this lineage. `OCframe:132-133` does alias
`Port`→`NSPort` and `PortServer`→`NSPortNameServer`, and `Connector.getConnection` (
`serviceConnectionWithName`) has a 3-arg overload taking a `PortServer` (`OCframe:375`) — but **Bot
never calls that overload**; it uses the bare `registerName:`/`rootProxyForConnectionWithRegisteredName:
...host:0` path (`BotServer.mm:18,22`; `Bot.mm:22`), with `host` passed as `0`/nil.

Concretely, that means: **same-host registration through Apple's local Distributed Objects nameserver,
backed by Mach ports** (the platform default when no host/port-type is specified) — not TCP, not a
socket you can `nc` into, not bytes you can sniff with Wireshark. `NSConnection` *can* be backed by
`NSSocketPort` for cross-host operation, which is presumably the seed of "this is a socket wrapped in
Apple stuff" — but that configuration is never exercised in the code that exists. If it were (e.g. via
`serviceConnectionWithName:rootObject:usingNameServer:` plus an explicit `NSSocketPort`), the wire
would still be Objective-C's built-in DO archiving (`NSPortCoder`), not a protocol incant controls.

**Gift-wrap thickness — assessment for the pilot:** thick, and welded to Cocoa, but not to the *GUI* in
the AppKit sense. The dependency is Foundation-level (`NSConnection`, `NSRunLoop`, `NSDate`), not
AppKit/Bwana/Layout — see §6. The thing that *is* welded in is the **run loop**: `BotServer.runServer`
explicitly notes "the current run loop has to be running before the bot will do anything" (`Bot.mm:8-9`
comment; mirrored in `Bot/BotServer.twk:30-43`) and spins one itself —
```objc
// BotServer.mm:39,47  (Bot/BotServer.twk:33,41)
NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
...
[runLoop runUntilDate:ending];      // blocks this thread for `duration` seconds (hardcoded 60s, RunBot.mm:232)
```
This is DO's normal contract (NSConnection delivers proxy calls as run-loop events) — it is *not* an
AppKot/window run loop, and `RunBot.mm:225-235` does drive it from a background queue (`DispatchQ`) so
it needn't be the main thread's run loop. So: no AppKit/GUI coupling, but yes, a spinning `NSRunLoop`
(notification/event-driven) is structurally required — same category of "needs a loop pumping" as
`NSFileHandle`'s notification style would have been, just via DO's internal port-handling instead of
`NSFileHandleConnectionAcceptedNotification`. A headless CLI build is plausible (Foundation runs
without AppKit) but it must keep a thread alive pumping a run loop, same as any DO server.

## 2. Wire protocol — what's actually sent, and how

There is **no custom framing or message format** here at all — that's the point of Distributed
Objects: method calls on `botProxy` (an `id` typed as `@protocol(BotProtocol)`, `BotServer.h:2-5`,
`Bot/BotServer.twk:11-15`) are transparently forwarded across the connection and serialized by
Objective-C's built-in DO machinery (`NSPortCoder`), invisible to this code. The "protocol" is just an
Objective-C `@protocol`:
```objc
// BotServer.h:1-5  (Bot/BotServer.twk:11-15)
@protocol BotProtocol
- (char*)get;
- (int)run:(char*)text;
@end
```
A "request" is a normal-looking Objective-C message send (`[botProxy get]`, `BotServer.mm:24`); a
"response" is its ordinary return value (a `char*`/C string, marshaled by DO). There is no JSON, no
length-prefixed frame, no line protocol, nothing incant-visible — it's whatever NSConnection/NSPortCoder
does internally for plain C types and `id`/object arguments.

## 3. The RunBot test — what it actually wires up

`RunBot` (`Bot/RunBot.twk`, compiled `RunBot.mm`/`.h`) is a `ParseXML` subclass — primarily a tiny
command-grammar parser (`Block`/`Instruct`, keywords `Check Delete File Insert Message Query Start
Terminate Update` — `RunBot.twk:23-31`), *not* primarily a Bot driver. It has one Bot-relevant method:
```cpp
// RunBot.mm:225-235  (Bot/RunBot.twk:56-66, RunBot.rtn:19-29)
void RunBot::startServer(char *name)
{
    DispatchQ *q = new DispatchQ();
    void (^block)() = ^{
        BotServer *service = [[BotServer alloc] init];
        ::printf("Starting Service %s\n", name);
        [service runServer:name duration:60];
    };
    q->run(block);
}
```
This launches a `BotServer` (server role, `registerAs(name)` + 60-second run-loop spin) on a
`DispatchQ` background queue — **same process, separate thread/queue**, not two OS processes. It is
NOT two processes communicating; it's one process registering a DO service under a name and (if a
client existed) being reachable by any process on the same host that asks for that name.

**Critical finding: nothing currently calls `startServer`, and nothing calls `BotServer.runClient`
either.** I grepped the whole `Bot/` tree for call sites (not just declarations) of `startServer`,
`runServer`, `runClient` (`grep -rn "startServer\|runClient\|runServer\b" Bot/`) — every hit is a
*declaration or definition*, none is an invocation from `main()`, from `Control`, from `Bwana`, or from
the `InstructRunBotNow` rule action. The rule action that should plausibly call it
(`Bot/RunBot.twk:191-200`, the `Instruct!` action, case `'S'` for "Start") is a bare `break;` with only
a comment: `// Start a server in a separate thread` (`RunBot.act:57-58`). The wiring described as
"invoked as a test" is **not present as automatic/wired code in this snapshot** — either it lived
somewhere not preserved (a manual debugger invocation, a deleted call site, an earlier `main()`), or it
was driven interactively. **I cannot confirm "two processes talking" actually ran successfully from
this source as it stands; I can only confirm the pieces (`BotServer.runServer` + `.runClient`) exist
and are individually coherent.** This should be treated as an open question, not assumed fact.

Compounding this: the current `main()` in `RunBot.twk:206-222`/`RunBot.g:48-64` doesn't reference Bot
at all — it calls `Control control = new; control.load(argv[1]); control.start();`, which is the
**GUI window-loading driver** (same `Control` class used by `Bwana`/`Layout`/`PDF` elsewhere in this
directory), with the actual `RunBot`-parser-based main fully commented out (`//parser.process(argv[1]);`).
So as committed, running the `RunBot` binary does not exercise Bot at all — it loads a GUI control
file. (`Bot/RunBot.twk:1` mtime is **2023-06-30** — about two years newer than `RunBot.mm`/`.h`
[2021-01-26/03-20], so the `.mm`/`.h` may be stale relative to the `.twk`; I did not byte-diff to
confirm drift, just flagging the mtime gap.)

A successful run, if it had been wired and worked, would observably be: server process/thread prints
`"Bot registration of <name> successful"` (`Bot.mm:27`) and `"Running server: <name>"`
(`BotServer.mm:45`/`Bot/BotServer.twk:39`), then a client calling `runClient` prints `"The returned
string: BotClient test string"` (`BotServer.mm:25` receiving `BotClient.get()`'s literal return value,
`Bot/BotClient.twk:15`/`BotClient.mm:15`).

## 4. Does incant cross the wire? (the question that matters most for the pilot)

**No — not today, and the code says so explicitly.** `BotClient.run(String text)`
(`Bot/BotClient.twk:18-30`, `BotClient.mm:18-30`) is the one method that *could* carry incant/GML
content:
```cpp
// Bot/BotClient.twk:18-29
int run(String text)
{
    if !parser { parser = new; ... }
    //  The text passed in should include name of socket to write back to
    //  and ParseXML needs to be extended to divert output to the socket
    item = parseString(text);
    cout "This is the proxy talking":item;
    return true;
}
```
It does parse `text` into a `GroupItem` tree via `parseString` (so *if* this method were ever called
across the proxy, GML/XML text would cross DO as a plain `char*` and get turned into a real GroupItem
on the receiving side) — but **the two-line comment is a literal, unresolved TODO**: there is no code
to divert the parsed result back across the socket/connection to the caller; the result is just
printed locally (`cout`). And critically, `run` is **never actually invoked** anywhere in this
snapshot — `runClient`'s call to it is commented out (`Bot/BotServer.twk:59-65`, `BotServer.mm:27-33`,
the whole `if filename ...` block is `/* ... */`-fenced). Only `get()` is live, and `get()` returns a
hardcoded literal string (`"BotClient test string"`, `BotClient.twk:15`) — no GroupItem, no incant
content, nothing dynamic.

There is **no GroupItem (de)serialization** anywhere in Bot — no `toString`/`fromString` pair used for
wire transfer, no buffer-pack/unpack. The only "serialization" in play is Objective-C DO's own opaque
argument marshaling of plain C types (`char*`, `int`, `double`), which incant/GroupItem data never
touches.

**What it would take to put incant on this wire:** finish the TODO (route `BotClient.run`'s parsed
`item` back through the connection to the caller, likely by exposing a return value from `run` instead
of just printing), and decide on a real serialization format for `GroupItem` (none exists today, here
or — per `docs/wiki-recon.md` — anywhere else in the tree). But see §7: this is moot for the webChannel
pilot specifically, because DO isn't the right channel for a browser-facing service regardless.

**Sibling lineage, for disambiguation (per the task brief's pointer):**
`/Users/anthony/Library/CloudStorage/Dropbox/data/OLDtawkDoNotTouch/Frame/URLservice.twk` (an even
older, `DoNotTouch`-flagged tree; not in the live Groups/Bot lineage) wraps `NSURLConnection` — an
**async HTTP client** (`send(String url)` → `connectionDidFinishLoading`/`didReceiveData` delegate
methods, `URLservice.twk:21-58`). Despite the similar naming (`URLconnect` vs. `Connector`), this is
an unrelated technology: outbound HTTP requests, not DO RPC, and not a server. It's worth knowing it
exists as precedent for "incant doing real network I/O," but it doesn't help the *server/listen* side
the webChannel pilot needs, and it isn't part of the live `Bot/` lineage — it's a separate, older,
explicitly-quarantined experiment. Not pursued further here per the brief's "reference only" scope.

## 5. Build/run state — buildable today, or bit-rotted?

**Bit-rotted at the include-manifest level — will not `tok` cleanly as committed.**
`Bot/botIncludes`:
```
include /Users/anthony/Tests/TokTests/Links/Externals/groupIncludes
include /Users/anthony/Dropbox/data/InProcess/Include/pdf.ext
include /Users/anthony/Dropbox/data/InProcess/Include/BOT.ext
```
- Line 1 resolves fine: `/Users/anthony/Tests/TokTests/Links/Externals/groupIncludes` is a working
  symlink to `Groups/groupIncludes` (verified), which in turn pulls in `globals`, `frame`, `maps`,
  `OCframe`, `Groups/jitExterns`, `groups.ext`, `PLGrevision` — all present and recently maintained
  (e.g. `groups.ext` mtime 2026-06-27, `frame` mtime 2026-06-14).
- **Line 2 (`pdf.ext`) and line 3 (`BOT.ext`) are absent from the *active* include path**
  (`~/Dropbox/data/InProcess/Include/`), so the build **is** broken as committed. BUT they are **not gone
  from disk** — both survive in the support tree at `~/data/support/Include/BackupIncludes/pdf.ext` and
  `~/data/support/Include/BackupIncludes/BOT.ext` (the original `find` missed them because it searched
  only `~/Dropbox/data/InProcess`, not the `~/data/support` symlinked support tree). So resurrection is a
  **copy-from-backup**, not a reconstruct-from-nothing. (Diff the backups against current `groups.ext`
  before trusting them — they're old snapshots.) Given `BotServer.twk` and `BotClient.twk` declare
  `Bot`/`BotProtocol`/`id`/`BotClient` inline as `external`s themselves (`BotServer.twk:6-22`), `BOT.ext`
  may have been redundant/superseded rather than load-bearing for *these two files specifically* — but
  other `.twk` files in the same directory (`Bwana.twk`, `Control.twk`, `Details.twk`, etc., which all
  also `include botIncludes`) may depend on whatever it declared. This can't be resolved without either
  finding a backup copy or reconstructing it.

**No evidence of a working build target for Bot/RunBot specifically.** The directory is not its own
git repo (`git status` in `Bot/` → "not a git repository") and isn't tracked inside the Groups repo
either. There's a build-artifacts trail at
`/Users/anthony/Dropbox/data/InProcess/TOK/build/TOK.build/Debug/Groups.build/Objects-normal/{arm64,x86_64}/Bot.o`
(plus matching `.d`/`.dia`), dated **2026-05-23** — recent — but its dependency file points to
`Frame/Bot.mm`/`Bot.h` (the wrapper class), *not* anything under `Bot/`. So `Bot.o` is almost certainly
being pulled into the live Groups Xcode build incidentally (because `Frame/` is shared support code
included elsewhere), not because the `Bot/` directory's `RunBot`/`BotServer`/`BotClient` target is
being built. I found **no `BotServer.o`, `BotClient.o`, or `RunBot.o`** anywhere under
`TOK/build/`. There's also a stale `TOK/Bot/` directory (empty, mtime 2017) and a `Bot.xcscheme` in the
Xcode user data — remnants of a once-real build target, not evidence it builds today.

**Symlinks**: `Bot/Groups -> ../Groups`, `Bot/groupIncludes -> Groups/groupIncludes`,
`Bot/GUI -> Groups/GUI`, `Bot/GUIincludes -> botIncludes` — all four resolve correctly (verified with
`readlink`/`ls -la`). The symlink layer itself is healthy; the rot is in the two missing `.ext` files.

**Verdict on this question:** not buildable as-is — the active include path is missing `pdf.ext` and
`BOT.ext` — but both exist in `~/data/support/Include/BackupIncludes/`, so the fix is to copy them back
into `~/Dropbox/data/InProcess/Include/` (then diff against current `groups.ext` for drift). Per Bear
Trap #11 in this repo's `CLAUDE.md`, these `.ext` files are exactly the kind of build dependency that
lives outside any git repo and silently rots — this is a second instance of that pattern, in a
different directory.

## 6. Dependencies & coupling — GUI baggage or separable?

**The BotServer/BotClient/Bot triad itself is Foundation-only, not AppKit/GUI-coupled.** Its direct
pulls: `ParseXML`/`GroupItem` (the core parse engine — already a Groups dependency, not GUI), `Connector`
(`NSConnection`), `RunLoop`/`Date` (`NSRunLoop`/`NSDate`, both Foundation), `DispatchQ` (GCD wrapper,
used only by `RunBot.startServer`). None of `Control`/`Layout`/`DrawPoint`/`PDF`/`Bwana`/`Stylish`/
`Details` (the AppKit-heavy GUI classes that share the `Bot/` directory) are referenced by
`BotClient.twk`, `BotServer.twk`, or the Bot-relevant parts of `RunBot.twk` — confirmed by grep
(`grep -n "bot\|runServer\|runClient\|startServer" Control.twk Bwana.twk Map.rtn` → no hits). They
just happen to live in the same physical directory because `Bot/` was apparently a shared scratch/demo
workspace for the whole GUI-arc experiment, not because Bot depends on the GUI.

**The one coupling that does exist**: `RunBot`'s *current* `main()` calls `Control.load`/`.start()`
(the GUI loader) instead of the Bot-test path (§3) — but that's main()-level dead code, not a structural
dependency of the Bot classes themselves. If resurrecting, the Bot classes (`BotClient`, `BotServer`,
`Frame/Bot`) could be lifted with their direct includes (`groupIncludes` chain) and left behind by the
GUI classes entirely.

## 7. Reuse verdict for the webChannel pilot

**Verdict: reference/cautionary-tale only — not a transport skeleton to resurrect for the webChannel
pilot.** Three independent reasons converge:

1. **Wrong layer.** DO/`NSConnection` is a same-host (as used here), Apple-proprietary RPC mechanism
   with opaque built-in marshaling. It cannot be browsed (`docs/wiki-recon.md`'s stated target is
   `http://localhost:8080/...`), doesn't speak HTTP, and isn't reachable from anything other than
   another Cocoa process using the matching `@protocol`. None of that composes with "serve a wiki page
   to a browser."
2. **Incomplete even on its own terms.** Per §3-4: nothing currently calls `runServer`/`runClient`
   end-to-end, `BotClient.run`'s response path back to the caller is an unfinished TODO, and
   `main()` doesn't even route to the Bot path. There's no working, observable "successful run" to
   point to in the current source — only individually-plausible pieces.
3. **Build is broken as committed** (§5) — two missing `.ext` includes — so even "run it to see what
   it actually does" isn't currently possible without resurrection work first.

**What it *is* good for:** a clean, small (≈100 lines total across `BotClient.twk`/`BotServer.twk`)
worked example of *registering a named, discoverable service and a client looking it up* — useful as a
naming/discovery pattern reference if a future design needs that, and as a concrete illustration of
"text in, GroupItem out" via `parseString` (`BotClient.twk:27`) for whenever incant content does need
to cross a real wire. It is **not** a head start on sockets, framing, or HTTP — none of that exists
anywhere in this lineage.

**Smallest first step this enables:** none, directly, for the webChannel pilot. The
`docs/wiki-recon.md` recommendation stands unchanged: build a minimal incant socket listener
(`setSocketOp`, analogous to the existing `setFileOp` file-write operator) from scratch — bind/listen/
accept/recv/send behind an incant operator. If anything from Bot is worth carrying forward
conceptually, it's the **"register a name, look it up, get a proxy/handle back"** discovery idiom — but
implemented over real sockets, not retrofitted onto DO.

---

## Open questions / unresolved (flagged, not guessed)

- Contents of `pdf.ext` and `BOT.ext` — RECOVERED: both exist at `~/data/support/Include/BackupIncludes/`
  (the original search missed the `~/data/support` tree). Treat as old snapshots — diff against current
  `groups.ext`/usage before trusting. No Time Machine recovery needed.
- Whether `BotServer`/`BotClient`/`RunBot` ever actually ran successfully end-to-end as two live
  endpoints — the source pieces are individually coherent but I found no live call site wiring them
  together in this snapshot, and no test output/log artifact to confirm a past successful run.
- Whether `RunBot.mm`/`.h` (tok output, 2021 mtimes) are stale relative to `RunBot.twk` (2023 mtime) —
  flagged via mtime gap only; not byte-diffed.
