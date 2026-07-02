# webChannel — Plan of Attack
*Clay, 2026-07-02. Successor to HWF mode. Inputs: wakeup.md (2026-06-30 LATE),
docs/bot-recon.md verdict, docs/wiki-recon.md (verdicts as summarized in wakeup;
items marked VERIFY should be cross-checked against the recon docs themselves).*
*Self-contained; written to survive a month of hibernation.*

---
## RATIFIED AMENDMENTS (2026-07-02, post step-0 recon — Tony-ratified; supersede where they conflict)
*`docs/webchannel-step0-recon.md` refuted three assumptions this plan leaned on, and Clay's review
added three v1-correctness items. Read this block first; the plan body is otherwise intact.*

**D2 correction — there is NO persistent runloop to "hook into."** `main()` (`groups.mm`) is
CLI-only; a Cocoa runloop spins up only on demand via `openWindow()` (`guiHost.mm`) → `[app run]`.
For the pilot use **CFSocket + `CFRunLoopRun()` directly** (no NSApplication assumed). This is also
more correct across runloop modes, not just simpler — see the mode trap below.

**D3/Step 1 correction — do NOT mirror `setFileOp`.** It's not a general callable extern; it's
bound to a single global operator slot (`modedOP`, via `operateMethod=`), invoked with special
binary-operator syntax. `setSocketOp` should instead mirror **`openWindow`'s plain-extern +
`immediateAction=` registration** pattern. The `guiHost.mm` tok-bypass pattern (for CF/socket
headers tok can't parse) is confirmed and has `openWindow` as a working precedent to copy.

**D4 correction — the BotClient salvage is vapor.** `BotClient.run()` never parses text (hardcoded
stub); the cited `parseString` helper lives only in gitignored `Aside/` legacy, not the live build.
The real proven text→GroupItem mechanism is the **JSON parser's push/pop input-diversion path**
(`docs/json.md`). Model `/eval` on that.

**v1-correctness items to fold in EARLY (not Step-6 hardening):**
- **`Connection: close` belongs in Step 2, not deferred.** Browsers keep-alive by default; a
  held-open connection under one-request-per-pump reads as a hang at the very first browser POP.
- **accept-drain per pump.** Browsers open several parallel connections per page (assets, favicon);
  loop `accept()` until `EWOULDBLOCK` each pump, or the page stalls across ticks — the exact POP
  you're judged on in Steps 2/5.
- **Runloop-mode trap (elevate Step-0 from VERIFY to decision).** A default-mode NSTimer does NOT
  fire during `NSEventTrackingRunLoopMode` — so a timer-based pump dies while the user drags/resizes
  a window or a sheet is up (exactly what the parallel GUI work builds). Add the source/timer to
  `NSRunLoopCommonModes`, or take the CFSocket path (preferred, per D2).

**Forward note — `/eval` mutating the live tree.** `/eval` runs arbitrary incant on the tree-owning
thread (quiescent by construction at v1, good) but a handler can delete a field Layout holds a
pointer into. A reconcile/redraw after `/eval` may be needed; ties into guiDesign.md's reconcile
pass. Bank now, address when the GUI reconcile lands.

**THE CONVERGENCE (highest-leverage recon for next session).** Step 1's open question — does a
top-level parse entry for arbitrary incant already exist (analogous to `JSONblock`'s divert), or does
`/eval` need its own rule — is the **same knot** as bear-trap #15 (bare top-level `x = new(...)`
fails; the colors/fonts live-render POPs are stuck on it) and sits beside the JSON array-of-objects
fix. All three point at the JSON input-diversion mechanism (`docs/json.md`). One focused recon on
the parse-entry/diversion path unblocks: the colors+fonts POPs, `/eval` (this Step 1), and the JSON
fix. Do that recon FIRST next session; it's three threads off the rocks for one investigation.

---

## Mission
A browser can talk to a running incant process: send text, incant evaluates it
against the live tree, browser gets the result. First cash-out: wiki pages served
from incant to a browser. The channel is the doorway for everything later
(remote minions, live inspection, web UI).

## Standing verdicts (from recon — do not re-derive)
- **Bot/ subsystem is dead for this.** It's Distributed Objects RPC
  (NSConnection, Mach ports) — Apple-proprietary, wrong layer for a browser.
  Do not resurrect. The ONE reusable idea is BotClient's shape:
  **text in → GroupItem → evaluate → result GroupItem → text out.**
- **Build a minimal socket listener from scratch**: `setSocketOp`, analogous to
  `setFileOp`. Socket plumbing is C++ translator work; request HANDLING is incant.

## Design decisions (made here; each cheap to reverse)

### D1. Protocol: minimal HTTP/1.1, not raw sockets, not WebSocket (yet)
Browsers speak HTTP natively; HTTP gives request framing for free
(Content-Length), curl gives a POP tool for free, and a static-response server
is ~40 lines. Raw TCP would force us to invent framing; WebSocket adds a
handshake + frame protocol we don't need until the channel is push-based.
WebSocket is the designated v2 when incant needs to PUSH (live updates); the
listener structure below doesn't preclude it.
Subset to implement: parse request line (method, path) + headers until blank
line + Content-Length body for POST. Emit status line + Content-Type +
Content-Length + body. Ignore everything else. That IS the whole v1 protocol.

### D2. Threading: NONE. Single-threaded, pumped from the existing runloop.
This is the load-bearing decision. A listener thread touching the GroupItem
tree means BDWGC thread registration + tree locking — the exact GC-blinding
bear-trap class already paid for once (GC_add_roots). Instead:
- non-blocking listen socket (`O_NONBLOCK`), bound to **127.0.0.1 only**
- pumped from the main runloop: preferred = CFSocket/dispatch-source callback
  on the main queue; fallback = an NSTimer tick calling `socketPump()` at 20–50ms
  (VERIFY which integrates cleaner with how the GUI app runs its NSApplication
  loop — recon the main() / app-start path first, step 0 below)
- one request serviced to completion per pump (requests are tiny; blocking
  reads with a short SO_RCVTIMEO are acceptable at v1)
Consequence: zero locks, zero GC registration, incant evaluation happens on the
same thread that owns the tree. Correct by construction. Throughput is
irrelevant at this stage.

### D3. The seam: C++ owns bytes, incant owns meaning
setSocketOp / accept / read / write / HTTP parse-and-frame live in the C++
translator (guiHost.mm-style host file if Apple runloop APIs are used —
VERIFY tok limitations here, same reason guiHost.mm exists). The parsed request
is handed to incant as a GroupItem:
```
request method=POST path="/eval" body=<text>
```
Incant's handler returns a response GroupItem:
```
response status=200 type="text/html" body=<text>
```
C++ serializes that back to HTTP bytes. Incant never sees a socket; C++ never
sees a route. This mirrors handleEvent in the GUI event design (guiDesign.md §7)
— same one-entry-point seam discipline: `handleRequest(request)`.

### D4. Evaluation shape (the BotClient salvage)
`/eval` POST body = incant text → text→GroupItem (the existing parse path that
BotClient used — VERIFY the exact entry: whatever `incant <file>` uses to parse
top-level text, minus the file read) → processCode/evaluate → result GroupItem →
serialized via dumpContents-style text (v1: plain text; v2: JSON — we have a
JSON parser, a JSON *emitter* is a later small task).
SECURITY: /eval is arbitrary code execution by design. Acceptable ONLY because
of the 127.0.0.1 bind (D2). Never widen the bind while /eval exists unguarded.

### D5. Routing lives in incant
A rOUTEs registry, same pattern as cOLORs/fONTs:
```
register(rOUTEs);
define
    evalRoute path="/eval" action=evalHandler;
    wikiRoute path="/wiki" action=wikiHandler;
    ;
```
handleRequest looks up path in rOUTEs, dispatches to the action, 404s on miss.
New routes = incant edits, zero C++ recompiles. This is the payoff of D3.

## The plan — minion-sized steps, each: build → POP → commit

**Step 0 — runloop recon (30 min, gates D2's callback-vs-timer choice).**
How does the running app pump? Where does main() hand off to NSApplication?
Output: 5-line note in this doc's margin; pick CFSocket path or timer path.

**Step 1 — `setSocketOp`: listen + accept + echo.**
Extern following setFileOp's pattern (VERIFY setFileOp's exact shape and copy
its idioms): create socket, bind 127.0.0.1:PORT (define port in an incant
define, e.g. `webPort=8848`), listen, non-block, register pump.
POP: `curl telnet://127.0.0.1:8848` (or nc) — send a line, get it echoed.
GREEN = sockets work inside the runloop without wedging the GUI.

**Step 2 — HTTP subset: parse + static response.**
Request-line/headers/body parse; canned response.
POP: `curl http://127.0.0.1:8848/anything` → 200 + "incant lives\n".
Browser POP: Safari/Chrome shows the string. GREEN = a browser has spoken to
incant. (This is the toe-dip moment — small ceremony appropriate.)

**Step 3 — request→GroupItem→incant→response round trip.**
Build request GroupItem, call `handleRequest`, serialize response GroupItem.
Incant side: rOUTEs registry + a trivial handler returning static text.
POP: curl a path defined only in incant; edit the incant handler text; re-run
WITHOUT rebuild; response changes. GREEN = routing is incant-owned (D5 proven).

**Step 4 — /eval: the BotClient shape, resurrected on HTTP.**
Body text → parse → evaluate → dumpContents-text back.
POP: `curl -d 'maximus = 13 + 13;' http://127.0.0.1:8848/eval` → response
contains 26. (Deliberate echo of oneTest's magic number — instantly familiar.)
GREEN = the channel is a live incant terminal. **This is v1 victory.**

**Step 5 — /wiki: serve a wiki page.**
wikiHandler: path suffix → wiki .md file → body. v1: raw markdown as
text/plain. v1.5: wrap in minimal HTML + a CDN markdown renderer so it's
readable. POP: browser shows a real wiki page from the live process.
GREEN = first user-visible cash-out.

**Step 6 — hardening pass (fast follow, one sitting).**
Content-Length edge cases, connection close semantics, request size cap,
malformed-request 400, port-in-use error message. POP: torture with bad curls.

## POP ladder summary (the full-monty check)
echo → static 200 → incant-routed 200 → eval(13+13)=26 → wiki page in browser.
Each rung is one commit; any rung red = stop, previous rung is the fallback.

## Explicitly deferred (named so they don't creep)
- WebSocket / server push (v2, when live-update UX exists to need it)
- JSON response emitter (small task, when a consumer wants structure)
- Any bind beyond 127.0.0.1, auth, TLS (not before /eval is gated)
- Concurrency (only if a real workload ever embarrasses the pump)
- Serving the wiki with styling/nav (after Step 5 proves the pipe)

## Bear watch
- **BDWGC vs sockets:** heap buffers for socket IO should be plain malloc/free
  or stack — do NOT hand GC-invisible pointers to GroupItem-land or vice versa
  without hold(); the GC_add_roots lesson generalizes.
- **Blocking read wedging the GUI:** SO_RCVTIMEO short (250ms) at v1; a slow
  client stalls a paint at worst, not the app.
- **tok vs sockets/CF APIs:** if tok chokes on the headers, that's what the
  guiHost.mm pattern (host .mm outside tok) is for — decide at Step 1, don't
  fight it.
- **`//` bear-trap #4** applies to all new .rtn code: comments only where a
  statement is allowed.
