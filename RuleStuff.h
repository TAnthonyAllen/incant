class GroupItem;
/*******************************************************************************
	RuleStuff is used to stash data used by the parse
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
GroupItem *sourceLine;
GroupItem *rule;
int kount;
int max;
int min;
RuleStuff *parentStuff;
int (*testMatch)(GroupItem *);
GroupItem *(*parseMethod)(GroupItem *, GroupItem *);
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
extern "C" GroupItem *leaveAlt(GroupItem *field, char *from, int ok);
extern "C" GroupItem *leaveRule(GroupItem *field, GroupItem *into, GroupItem *label, char *from, int ok);
extern "C" int lit(GroupItem *field, char *str);
extern "C" int litOption(GroupItem *field, GroupItem *into, char *str);
extern "C" int manyJSONblockFields(GroupItem *label);
extern "C" int manyJSONlistItems(GroupItem *label);
extern "C" GroupItem *parseGeneric(GroupItem *into, char *ruleName);
extern "C" GroupItem *parseJSONarray(GroupItem *into);
extern "C" GroupItem *parseJSONblock(GroupItem *into);
extern "C" GroupItem *parseJSONfield(GroupItem *into);
extern "C" GroupItem *parseJSONitem(GroupItem *into);
extern "C" GroupItem *parseJSONlist(GroupItem *into);
extern "C" GroupItem *parseJSONtoken(GroupItem *into);
extern "C" GroupItem *parseJSONvalue(GroupItem *into);
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
