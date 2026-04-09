class GroupItem;
class Stak;
/******************************************************************************
    A class that implements a path iterator
******************************************************************************/

class PathIterator
{
public:
GroupItem *initialPath;
GroupItem *initialBlock;
GroupItem *iteratePath;
GroupItem *iterateBlock;
GroupItem *target;
GroupItem *targetPath;
Stak *iterateStack;
struct 
	{
	unsigned int debugPath:2;
	unsigned int endPath:1;
	unsigned int hitBottom:1;
	unsigned int pathError:3;
	};
#define debugBlock(button) (button == 1)
#define debugAll(button) (button == 2)
#define methodFailed(button) (button == 1)
#define noAttributes(button) (button == 2)
#define notDeepEnough(button) (button == 3)
#define noMatch(button) (button == 4)
PathIterator(GroupItem *p, GroupItem *s);
int attributesMatch();
void checkForActions(GroupItem *path);
void displayError();
GroupItem *next();
void setInitialBlock(GroupItem *source);
void setInitialPath(GroupItem *path);
GroupItem *walkPath();
};
