class GroupItem;
/*******************************************************************************
	RuleStuff is used to stash data used by the parse

    parentLabel (genParseShape S1.2) -- the `into` a generated parse method
    attaches to, made direct and named. NOT new state: parse() already reached
    the same value two hops away through parentStuff.label in its attachment
    block. The single writer is parse()'s S1.3 fork, which writes it on the
    callee's OWN rStuff immediately before calling; the callee lifts it into a
    stack local at ENTRY, before descending, which is what closes the recursion
    window (same reasoning as genParseRuleAccess S1.5's act()).

    termCount (Clay SEQ 26 S3) -- how many REAL terms genParse emitted indices
    against, recorded by the parseTerms binding attribute and checked by the
    parseMethod one before it installs anything. Every emitted rule[n] bets the
    list only ever mutates BEHIND the real terms; the cached BlocK appearing
    after a rule's first parse proves the list does mutate at runtime, and
    nothing else enforces the bet. 0 means unrecorded, which binds with a
    warning rather than refusing -- a silent trap would be worse than an
    unguarded one.

    parseMethod (genParseShape S1.1) -- ONE argument, and it is the rule. kant
    methods take one argument, so a two-argument parse method could never
    survive the kant handover; `into` is derived from parentLabel instead of
    passed. Widening or narrowing this signature is a LAYOUT change (bear-trap
    #10: groups.ext sync + tokall + rebuild), not an edit.

    jitMethod (Clay SEQ 27 v2, 2026-08-04) -- THE COMPILED BODY OF A FIELD'S
    METHOD, and it is parseMethod's shape transplanted rather than a new idea.
    Same three properties, for the same reasons:
      - it rides the SHAPE struct, not the GroupBody, so adding it costs one
        pointer on the nodes that carry rule shape and nothing on the rest;
      - DISPATCH IS ONLY EVER THROUGH THE POINTER. The `JiT` attribute beside
        CodE and BlocK is the compiled artifact's RECORD -- persistence and
        inspection. Nothing reconstructs this pointer from it;
      - nothing reaches it by name. SEQ 38 stands: locate is prohibited, not
        provided. The one named dispatch site receives the field as its first
        parameter and walks pointers from there.
    ⚠ NULLARY ON PURPOSE, and it is the one place this diverges from
    parseMethod's signature: jitRunAction emits `i32 ()`. Fields are reached
    through BAKED ADDRESSES in the emitted IR, never through an argument, so
    there is nothing for a parameter to carry. Adding one later is a LAYOUT
    change, exactly as it is above.
    ⚠ THE NAMED SEAM, recorded 2026-08-05 so it arrives as a plan and not a
    surprise: THIS SLOT'S NULLARY SIGNATURE HOLDS ONLY WHILE THE CALLER IS
    EMITTED CODE. Two calling routes exist and they want different things:
      - A SELF-CALL INSIDE JITTED CODE takes the FIELD ROUTE (ruled 2026-08-05).
        The callee's body reads its argument through the `argument` field, which
        is where every reference in it already looks, so jitBindArgRT binds the
        field at run time and the call stays nullary. A real parameter here would
        carry something nobody reads.
      - POINTER-SLOT DISPATCH FROM C++ takes a REAL PARAMETER, and it is forced.
        When a generated parse method is jitted, its caller is not emitted code
        reading a field -- it is parse() forking on rStuff.parseMethod and calling
        through a one-argument function-pointer signature that C++ owns. The
        caller cannot be taught the field route, so the compiled function must
        present the parameter.
    That second case is decided the day the first generated method is jitted, and
    widening this signature then is a LAYOUT change exactly as above. Named seam,
    not debt.

    ⚠ AND IT IS LAZY WHERE parseMethod IS DELIBERATELY NOT. parse()'s comment
    forbids `if !parseMethod genParse(rule)` because generation there means
    emitting text and running a BUILD from inside a parse. JIT compilation is
    in-process and costs a compile, so compile-on-first-fire is the ruling
    (Clay SEQ 27 v2). The prohibition and this divergence are about two
    different costs, not two readings of one rule.
*******************************************************************************/

class RuleStuff
{
public:
char *ruleName;
char *hereAt;
char *failedAt;
GroupItem *label;
GroupItem *onFail;
GroupItem *onGroup;
GroupItem *parentLabel;
GroupItem *sourceLine;
GroupItem *rule;
int kount;
int max;
int min;
int termCount;
RuleStuff *parentStuff;
int (*testMatch)(GroupItem *);
GroupItem *(*actionMethod)(GroupItem *);
GroupItem *(*parseMethod)(GroupItem *);
int (*jitMethod)();
struct 
	{
	unsigned int banged:1;
	unsigned int doNothing:1;
	unsigned int followed:1;
	unsigned int guardOK:1;
	unsigned int guardFAIL:1;
	unsigned int hasMacro:1;
	unsigned int inProcess:1;
	unsigned int isOK:1;
	unsigned int isOption:1;
	unsigned int isTarget:1;
	unsigned int limitsSet:1;
	unsigned int noAdvance:1;
	unsigned int noLabel:1;
	unsigned int noSkip:1;
	unsigned int notifyFail:1;
	unsigned int overTo:2;
	unsigned int sukcess:1;
	};
#define upTo(button) (button == 1)
#define upToOver(button) (button == 2)
RuleStuff(GroupItem *grup);
RuleStuff(RuleStuff *r);
int checkGuard(GroupItem *field);
int checkInput();
GroupItem *followingMember();
void getWhatFollows();
void setTestMatch();
};
extern "C" int containerTo(GroupItem *term, GroupItem *into, char *slot);
extern "C" int inGuard(GroupItem *field, char *chars, char ch);
extern "C" GroupItem *leaveAlt(GroupItem *rule, char *from, int ok);
extern "C" GroupItem *leaveRule(GroupItem *rule, GroupItem *into, GroupItem *label, char *from, int ok);
extern "C" int lit(GroupItem *field, char *str);
extern "C" int litOption(GroupItem *field, GroupItem *into, char *str);
extern "C" int manyJSONblockFields(GroupItem *label, GroupItem *term);
extern "C" int manyJSONlistItems(GroupItem *label, GroupItem *term);
extern "C" GroupItem *parseGeneric(GroupItem *into, char *ruleName);
extern "C" GroupItem *parseJSONarray(GroupItem *rule);
extern "C" GroupItem *parseJSONblock(GroupItem *rule);
extern "C" GroupItem *parseJSONfield(GroupItem *rule);
extern "C" GroupItem *parseJSONitem(GroupItem *rule);
extern "C" GroupItem *parseJSONlist(GroupItem *rule);
extern "C" GroupItem *parseJSONtoken(GroupItem *rule);
extern "C" GroupItem *parseJSONvalue(GroupItem *rule);
extern "C" GroupItem *parseR(GroupItem *term, GroupItem *into);
extern "C" int setMacroValue(GroupItem *field);
extern "C" int testAction(GroupItem *field);
extern "C" int testAny(GroupItem *field);
extern "C" int testAttributes(RuleStuff *stuff);
extern "C" int testCharacter(GroupItem *field);
extern "C" int testCondition(GroupItem *field);
extern "C" int testContainer(GroupItem *field);
extern "C" int testOptions(RuleStuff *stuff);
extern "C" int testSet(GroupItem *field);
extern "C" int testString(GroupItem *field);
extern "C" int testUpTo(GroupItem *field);
