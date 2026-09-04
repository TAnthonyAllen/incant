class GroupItem;
//
//  measure.twk -- the measuring instruments.
//
//  Minted 2026-09-04, cleanup arc stroke 3. Home for the externs that MEASURE
//  the tree rather than run it: censuses, audits, probes, address and body
//  readers, and the report verbs a fixture drives from kant. They were spread
//  across GroupActions.rtn, Generate.rtn and Commands.rtn and had no home.
//
//  WHAT BELONGS HERE. A method whose job is to ANSWER A QUESTION ABOUT the
//  tree, not to change it. Most are registered as incant commands in
//  incant/setup and are reached only from kant text -- a fixture, a probe, a
//  frontier station -- with no C++ caller at all. If a method is on the parse
//  or execution path, it belongs where its callers are.
//
//  ⚠ IT COMPILES TO ITS OWN measure.mm AND IS NOT IN THE GroupRules INCLUDE
//  CHAIN. So a method here is in a DIFFERENT TRANSLATION UNIT from everything
//  in the eight chain rtn files. That costs nothing for a kant-reached command
//  -- the incant command machinery dlsyms the symbol out of the binary and
//  needs no declaration -- but a C++ caller across the boundary needs a line in
//  groups.ext, which lives OUTSIDE this repo (bear-trap #11).
//
//  Methods go in ALPHABETICAL order (Tony's standing rule, 2026-08-15);
//  genLadder/alphaLint.sh reports drift.
//
//  Long WHY comments live in incant/designDocs under TokFiles -> measure;
//  what stays here is the one claim a reader at the edit site must not miss.
//

// Dummy class so tok emits measure.mm (the output is named after the class).
// The real content is the extern methods below.
//
// ⚠ THE GroupItem LOCAL IN run() IS LOAD-BEARING, NOT DEBRIS. tok picks the
// output extension from `currentClass.isOC || makeOCfile` (Tokf/Tawk.act:1408),
// and makeOCfile is only raised once the file USES an Objective-C-flavoured
// type. With a genuinely empty body tok writes measure.C, not measure.mm --
// measured 2026-09-04. Either builds, but the extension would then FLIP to .mm
// the moment the first real method landed, leaving the Xcode entry pointed at a
// measure.C that tok no longer writes and the compiler still happily builds.
// One line here fixes the extension before anything depends on it.

class measure
{
public:
int dummy;
void run();
};
extern "C" GroupItem *addrOf(GroupItem *field);
extern "C" int auditMissingRules(GroupItem *registry);
extern "C" int auditMissingTerms(GroupItem *registry);
extern "C" GroupItem *auditRStuff(GroupItem *argument);
extern "C" int auditSpurious(GroupItem *registry);
extern "C" int auditUnconsumed(GroupItem *registry);
extern "C" GroupItem *bodyCensus(GroupItem *ignored);
extern "C" GroupItem *canonOf(GroupItem *argument);
extern "C" GroupItem *chanReport(GroupItem *input);
extern "C" GroupItem *evictAction(GroupItem *field);
extern "C" GroupItem *frameProbe(GroupItem *field, GroupItem *rule);
extern "C" int labelMinters(GroupItem *rule);
extern "C" GroupItem *parseClassify(GroupItem *field);
extern "C" GroupItem *probeNode(GroupItem *argument);
extern "C" GroupItem *showBody(GroupItem *field);
