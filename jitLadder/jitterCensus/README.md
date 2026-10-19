# jitterCensus -- the forced-jit census (SEQ 383 R2b, re-run SEQ 384)

A measuring instrument, not a fleet member: nothing here runs at a seal. It answers "what would a jitter command meet"
by jitting EVERY action at its first call and comparing each fixture against its tap-off run.
Results and clusters: `docs/jitterRecon.md` (SEQ 383) and `docs/noSideEffects.md` (SEQ 384).

**Run it ONLY in a branch-build clone** (CLAUDE.md's clone recipe), never the live tree: the taps edit engine source.

## The taps (applied to the clone's source, retokked, built; REVERTED md5-identical afterwards)

- `tap383.py` -- **jit at first call.** In runAction's interpreted arm, gated by `INCANT_JIT_ALL=<tally file>`: an
  action's first call compiles it (compile output silenced, its stderr appended to `<tally>.err`), and every call fires
  the compiled function inside runAction's save/restore bracket. A refused compile runs interpreted, not retried.
  `INCANT_JIT_ALL_AFTER=parser` arms it only after the first `parser(...)` returns (the generator stays interpreted).
  Tally lines: `begin <action>`, `compile <action> rc=<n> degrade=<n>`, `fire <action>`.
- `tap3.py` -- **count build-time execution** (needs jitOpEmits, i.e. trunk after 950c64c). Gated by
  `INCANT_BUILDEXEC=<file>`: a line per sink, command call, or operator dispatch that ran during the emit walk without
  emitting. The SEQ 384 certificate's "0 statements executed at build" is this tap over pop.sh and jitLadder.

Apply: `cd $CLONE/InProcess/Groups; md5 -q GroupActions.rtn ruleActions.rtn jitEmitters.rtn GroupRules.mm GroupRules.h > pre.md5;
python3 <path>/tap383.py; tok GroupRules.twk;` then build with `-derivedDataPath $CLONE/dd`.
Revert: `git checkout -- GroupActions.rtn ruleActions.rtn jitEmitters.rtn; tok GroupRules.twk`, compare md5s, rebuild.
(`tap3.py` patches GroupActions.rtn, ruleActions.rtn and jitEmitters.rtn; `tap383.py` only GroupActions.rtn.)

## The census

    export CLONE=<clone root> OUT=<results dir>
    ./census.sh old  > $OUT/census.old.txt     # every incant/pop + pop/jit file: tap off twice, on once, 60 s cap
    ./census.sh new  > $OUT/census.new.txt     # the same on a scratch twin with parser(Start) after its last search
    cp results/genlist2 $OUT/                  # the old-road files that call parser() themselves
    ./censusGX.sh old > $OUT/census.oldgx.txt  # those re-run with the generator excluded
    ./classify.sh old > $OUT/cls.old; ./classify.sh new > $OUT/cls.new
    ./classifyGX.sh old > $OUT/cls.oldgx       # then merge: cls.old minus genlist2's names, plus cls.oldgx

Classes per fixture: agree / DISAGREE / EXIT-during-compile / CRASH-at-compile / CRASH-at-run / HANG / untouched.
Streams are split and addresses masked; the second tap-off run marks noisy fixtures. About a minute per road.
`results/` holds the SEQ 383 and SEQ 384 classifications for diffing the next run against.
