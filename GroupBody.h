class GroupList;
class GroupItem;
class PLGset;
class Buffer;
class PLGitem;
class BitMAP;
@class NSObject;
class PLGrgx;
class Stak;
struct bools
	{
	unsigned int isRule:1;
	unsigned int isLabel:1;
	unsigned int noPrint:1;
	unsigned int data:5;
	unsigned int actionType:2;
	unsigned int binType:3;
	unsigned int fileType:2;
	unsigned int guarding:2;
	unsigned int instructType:2;
	unsigned int isBranch:2;
	unsigned int isSorted:2;
	unsigned int methodType:2;
	unsigned int altered:1;
	unsigned int debugged:1;
	unsigned int debugGuard:1;
	unsigned int deferred:1;
	unsigned int fLAG:1;
	unsigned int hasAttributes:1;
	unsigned int hasListeners:1;
	unsigned int hasMembers:1;
	unsigned int invoke:1;
	unsigned int isArgument:1;
	unsigned int isAssign:1;
	unsigned int isCondition:1;
	unsigned int isIndexed:1;
	unsigned int isInitialized:1;
	unsigned int isLiteral:1;
	unsigned int isLocal:1;
	unsigned int isMacro:1;
	unsigned int isPercent:1;
	unsigned int isPointer:1;
	unsigned int isShortcut:1;
	unsigned int isSingleton:1;
	unsigned int isToggle:1;
	unsigned int isUnary:1;
	unsigned int isVirtual:1;
	unsigned int mergeOn:1;
	unsigned int negate:1;
	unsigned int tokened:1;
	};
#define isGROUP(button) (button == 6)
#define isANY(button) (button == 1)
#define isSTAK(button) (button == 12)
#define isCHAR(button) (button == 2)
#define isSET(button) (button == 3)
#define isBUFFER(button) (button == 4)
#define isBIN(button) (button == 1)
#define isCOUNT(button) (button == 5)
#define isITEM(button) (button == 7)
#define isMAP(button) (button == 8)
#define isNUMBER(button) (button == 9)
#define isOBJECT(button) (button == 10)
#define isREGEX(button) (button == 11)
#define isSTRING(button) (button == 13)
#define isTOKEN(button) (button == 14)
#define isAction(button) (button == 1)
#define isCoded(button) (button == 2)
#define isCLASS(button) (button == 2)
#define isLIST(button) (button == 3)
#define isREGISTRY(button) (button == 4)
#define isDirectory(button) (button == 1)
#define isExec(button) (button == 2)
#define isFile(button) (button == 3)
#define guarded(button) (button == 1)
#define unGuarded(button) (button == 2)
#define guardInProcess(button) (button == 3)
#define isMethod(button) (button == 1)
#define isOperator(button) (button == 2)
#define isBreak(button) (button == 1)
#define isContinue(button) (button == 2)
#define isReturn(button) (button == 3)
#define sortAscending(button) (button == 1)
#define parseACTION(button) (button == 2)
#define immediateACTION(button) (button == 1)
#define sortDescending(button) (button == 2)

/*******************************************************************************
	The body of a GroupItem containing its data
*******************************************************************************/

class GroupBody : public gc
{
public:
char *tag;
GroupList *groupList;
GroupItem *registry;
PLGset *guardSet;
union 
	{
	GroupItem *(*gMethod)(GroupItem *);
	GroupItem *(*gOp)(GroupItem *, GroupItem *);
	};
union 
	{
	char *gText;
	void *gPointer;
	};
union 
	{
	Buffer *gBuffer;
	char gCharacter;
	PLGset *gCharacterSet;
	int gCount;
	GroupItem *gGroup;
	PLGitem *gItem;
	BitMAP *gMap;
	double gNumber;
	NSObject *gObject;
	PLGrgx *gRegex;
	Stak *gStak;
	};
bools flags;
GroupBody();
GroupBody(char *s);
};
