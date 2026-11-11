# features -- the parking list (HWF, not scheduled)

Features is a parking list, not a session topic (Tony, 2026-11-11, SEQ 612 R0).
Nothing here is ruled or scheduled. An item leaves this file by becoming a plan in another topic's file; when it does, its line is replaced by a pointer to that plan.
One line per item: the idea, then where it is written down and its date. Tony rules the list line by line.

## The list as dispatched (Tony, 2026-11-10; recorded under seal 437)

1. Parse-then-fire, possibly finished by the back door: the new road builds, testOP fires. (docs/ptfReread.md, ptfStep1Plan.md, ptfStep2Plan.md, 2026-10-02)
2. The kant mirror of setParse / compile / processCode.
3. The containers idea. (docs/containersRecon.md, 2026-10-06)
4. rStuff folding into the instance. (docs/objectModel.md, 2026-09-28)
5. Component flavors, fewer bitfields. (docs/fieldFlavors.md, 2026-09-30)
6. The listener and $, firing on command. (IncantForms/WorkingOn/macros, THE LISTENER, 2026-11-05)
7. Multi-processing and a web channel -- possibly one shape: processes exchanging fields as messages, dispatch() as the sender. (docs/webchannelAttack.md, docs/webchannel-step0-recon.md, 2026-07-02)
8. EXPRESSIOn as operators: each Operators entry becomes a grammar rule whose operands are expressions, so the grammar that parses expressions is built from the operators it parses. Tiers become nested repetition (a sum is a product, then any number of + product) -- never left recursion, which a top-down parse loops on. SEQ 578's recon: an infix-only EXPRESSIOn keeps about two-thirds of today's shape; prefix runs leave. The natural next campaign once the control rules are done. (docs/ruleAsOperator.md, 2026-11-09)

## Harvested from the md files and the notes (SEQ 612, 2026-11-11)

Found by a marker search and by reading the files nothing cites; not a line-by-line read of every file. Each was never scheduled or ruled, and is not in the list above.

9. A local, editable wiki for the documentation, served by the web channel's first step. (docs/wiki-recon.md, 2026-06-30)
10. Claude as a field: isCLAUDE beside isSTRING and isGROUP -- the AI is a field in kant, not a tool called from it. (projectBible.md, "Claude is a GroupItem"; docs/vision-recon-inventory.md, 2026-06-28)
11. Fields that run anywhere and message each other across devices, location transparent. (wiki/WhatIsIncant.md, 2026-06-16) -- the far end of item 7.
12. fieldNav: a path and visitor vocabulary for walking field trees. (docs/fieldnav-design.md, 2026-06-29)
13. Delimited-file parsing with column projection, taken from old PLG (CSV and TSV read with no action code). (docs/plg-delimited-file-recon-2026-05-29.md)
14. field += a field definition: adding to a definition after the fact. Has one ruling (its section 3a); nothing built. (docs/fieldAddsDefinition.md, 2026-09-18)
15. Long comments leave the .twk and live in a directives store. The gating probe passed; nothing built. (docs/commentDirectives.md, 2026-09-18)
16. A relevance minion: an agent that checks whether comment prose still matches the code under it. Draft, parked. (docs/relevanceMinion.md, 2026-09-08)
17. A minion's deliverable is a directives file, not a diff. (docs/minionModel.md, 2026-09-15) -- input to the minion-ready shape of the topic files.
18. vigram: a verification grammar, the harness rules written as kant definitions. Stub round only. (docs/vigram.md, 2026-08-09)
19. Foreign binding: Core Graphics methods held in kant fields with a declared signature, so no hand-written C++ wrapper per drawing command. (docs/bindingmethods.md, 2026-08-21; IncantForms/WorkingOn/drawing) -- the forms plan's A5 is the same idea; it leaves this list when forms takes it.
20. checkSKIP as a kant rule: the skip and indent machinery written in kant. Where it runs is ruled (SEQ 512); the build is parked behind the jitter walk. (docs/checkSKIP.md, 2026-09-17; IncantForms/WorkingOn/checkSKIP)
21. A kant rule action that can reject a match. (TODO.md, SEQ 462 R3, 2026-10-29)
22. EXPRESSIOn's pending slots as one tier-ordered list closed by one loop. Banked until the grammar settles; item 8 may replace it. (TODO.md, SEQ 448 R6, 2026-10-28)
23. Parse error handling: a failed statement abandons the rest of the file at exit 0. No design. (projectBible.md, "HWF Session 6", 2026-05)
24. Locals as frames, with recursion as the forcing case: where a recursive frame's storage comes from in a language with no declarations. (docs/jitDesign.md, recorded 2026-07-31, "not scheduled")
25. An incant-to-HTML transpiler as a bridge to non-Apple platforms. (docs/layout-recon.md, docs/gui.md, 2026-06-22)
26. Generating C or C++ from kant as an alternative to interpreting. (IncantForms/Controls/dev, 2026-06-14) -- the jitter may have overtaken it.
27. An editor: pins as invisible fields, used as breakpoints and as goto marks. (IncantForms/Notions/editor, 2026-06-14)
28. The fungi model: every group a node with a listener, each reacting in its own thread. (IncantForms/Notions/fungits, 2026-06-14) -- items 6 and 7 seen together.
29. Data sources with indexed attributes, feeding repeated rows. (IncantForms/Notions/display, 2026-06-14) -- the withdrawn data recon in the forms notes is the same ground.
30. A language designed to evolve; "create" as an imaginary operator. (IncantForms/Notions/HWF, 2026-06-14) -- a musing, kept because the file is named for this list.

## Not harvested, and why

The typesetting language and the small drawing language are in the forms notes and belong to the forms topic. The collector freeing nothing (KE-5) is a known error with a recon (docs/gcRecon.md), not an idea. The cross-platform shell-out question is in Clod's memory only, not in a tracked file.
