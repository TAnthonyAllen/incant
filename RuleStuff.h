class GroupItem;
// fields RuleStuff is the per-node parse state; parseMethod and jitMethod are LAYOUT -- widening either is groups.ext + tokall (bear-trap #10)

class RuleStuff
{
public:
char *ruleName;
GroupItem *onGroup;
int max;
int maxRepeat;
int min;
int (*testMatch)(GroupItem *);
GroupItem *(*actionMethod)(GroupItem *);
GroupItem *(*parseMethod)(GroupItem *);
int (*jitMethod)(GroupItem *);
struct 
	{
	unsigned int followed:1;
	unsigned int isTarget:1;
	unsigned int modPercent:1;
	unsigned int modPointer:1;
	unsigned int modUnGuarded:1;
	unsigned int noAdvance:1;
	unsigned int noLabel:1;
	unsigned int noSkip:1;
	unsigned int notifyFail:1;
	unsigned int overTo:2;
	unsigned int ruleTerm:1;
	};
#define upTo(button) (button == 1)
#define upToOver(button) (button == 2)
RuleStuff(GroupItem *grup);
RuleStuff(RuleStuff *r);
int checkGuard(GroupItem *field);
int checkInput(GroupItem *field, int guardPassed, char *inAt);
void getWhatFollows(GroupItem *field);
char *inputAt();
GroupItem *mintLabel(GroupItem *field);
void setTestMatch(GroupItem *field);
};
extern "C" GroupItem *parseR(GroupItem *term, GroupItem *into);
extern "C" int testAction(GroupItem *field);
extern "C" int testAny(GroupItem *field);
extern "C" int testAttributes(RuleStuff *stuff, GroupItem *field);
extern "C" int testCharacter(GroupItem *field);
extern "C" int testCondition(GroupItem *field);
extern "C" int testContainer(GroupItem *field);
extern "C" int testOptions(RuleStuff *stuff, GroupItem *field);
extern "C" int testSet(GroupItem *field);
extern "C" int testString(GroupItem *field);
extern "C" int testUpTo(GroupItem *field);
extern "C" int upToMatch(GroupItem *field, GroupItem *upLab);
