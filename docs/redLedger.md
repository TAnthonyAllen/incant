# What is still wrong, ranked -- 2026-11-04 (SEQ 527 R3)

Every pinned red row and docket item from today. Silent wrong answers first, then crashes, then echo or kind. Size is a guess: small / stroke / campaign. "Pinned" names the fleet row;
"unpinned" means no row would notice. Nothing in the table has a cure in flight.

| # | what is wrong | pinned | size |
|---|---|---|---|
| **Silent wrong answers** | | | |
| 1 | **The two roads' interpreted recursion disagree.** `r = f(argument - 1); return r;` returning "s" reads `r` on the new road, `s` on the old. Language level, no jit involved; ahead of every jitter item. Measured once, not diagnosed | unpinned | stroke |
| 2 | `v = u + 1` on an unwritten local: compiled reads 1, interpreted refuses. Waits on row 11 for its intended value | UA | stroke |
| 3 | `v = u` on an unwritten local: compiled copies 0, interpreted copies the tag's text. Same cure as row 2: a statement branches on the written mark and falls back | UC | stroke |
| 4 | An old-road self-call returning a non-count: compiled reads 1, interpreted `s` or `1.5`. The build would have to know the callee's return kind | RS | stroke |
| 5 | A handed-over new-road writer of unknown kind outside any arm gives no kind, so a later native writer decides the slot. Read from the code, not measured | unpinned | small to pin, stroke to cure |
| 6 | A for body's writers ignore its if arms when choosing a kind, so walk order can pick the wrong first writer. Read from the code, not measured | unpinned | small |
| **Crashes** | | | |
| 7 | An old-road action calling a new-road action under `jitter;` segfaults at compile: inlining runs the callee's chain with jitting on. Likely a guard that hands the call over | oldCallsNewT | small |
| **Loud refusals** | | | |
| 8 | `m6 += 5` on the new road refuses "Operator += failed", where the old road adds | newPlusEqT | stroke |
| **Echo or kind** | | | |
| 9 | `r = 0.0; r = 7`, printed: value right, but an old-road compiled action reads r's kind as 0. `.datA` reads the field before the slot is flushed. The slot itself is a number | kindZeroT | small |
| 10 | gen26 reads 24 / 2 here against 26 / 0 in the SEQ 418 results file. Measured: every differing line in paReachT and zeroWidthT is the `SHORTCUTFIRE` trace, which is newer than the instrument's mask. An instrument gap, not a value | unpinned | small |
| **For Tony to rule, not a defect** | | | |
| 11 | Typeless local in arithmetic: count by default, or refuse until typed. UA's intended value (row 2) waits on it | -- | ruling |

**Not wrong, for the record:** `for` and `iterate` are still handed over (S4's certificate covers compiling around them). A format, deref, call, dot or compare in a print hands that print over (S5).
