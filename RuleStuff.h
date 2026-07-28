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

    parseMethod (genParseShape S1.1) -- ONE argument, and it is the rule. kant
    methods take one argument, so a two-argument parse method could never
    survive the kant handover; `into` is derived from parentLabel instead of
    passed. Widening or narrowing this signature is a LAYOUT change (bear-trap
    #10: groups.ext sync + tokall + rebuild), not an edit.
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
RuleStuff *parentStuff;
int (*testMatch)(GroupItem *);
GroupItem *(*parseMethod)(GroupItem *);
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
