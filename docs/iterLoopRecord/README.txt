iterLoopRecord -- the scratch record of the iterate ++g on x recon (Tony, 2026-11-06; SEQ 550 R0). A record, not a fixture: no harness reads this directory, and nothing here is in the fleet.

The plan and the rulings are in IncantForms/WorkingOn/macros, section NEXT MORNING SESSION. This holds what that section summarises.

patch.py.txt: the grammar line and action of the new-road prototype. Applied to a scratch COPY of incant/kantGrammar; kant only, no C++. Run as python3 patch.py.txt <path to kantGrammar>.
probes/: each probe source, with its stdout (.o.txt) and stderr (.e.txt). rows.txt and pre.txt are the driver's row list and preamble. n.* run the new form on the patched copy, N.* and O.* the new-road and old-road controls (N/O.resumeAfterBreak is the two-line resume), x.* the extras, j.* the jitter parity, rd* the printDefinition recurse question. iter.txt and iter2.txt are the census output.
captures/: pop.sh on two scratch copies of the tree, binary built 11:48. pop.base is unpatched, pop.patched has the grammar lines. Every .out, .o and .e was renamed .txt because the repo ignores those suffixes.

THE 61st FAIL ROW IN pop.base (SEQ 550 R1): flagNearT the corpus. It walks git ls-files, and the scratch copies are not git repositories, so the corpus was empty: got [] want [IncantForms/Windows/tabs=1 ]. An artefact of the copy; every other FAIL row matches the seal's 60 by name.
