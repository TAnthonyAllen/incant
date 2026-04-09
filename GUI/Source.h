class GroupItem;
class DoubleLinkList;
/*******************************************************************************
	Data source wrapper for a GroupItem. Maintains a copy of member list as
	an array.
*******************************************************************************/

class Source
{
public:
GroupItem **list;
GroupItem *sourceItem;
DoubleLinkList *listeners;
int current;
int priorStart;
struct 
	{
	unsigned int exhausted:1;
	unsigned int noNext:1;
	unsigned int resetOnResize:1;
	unsigned int sourceSelected:1;
	unsigned int sorted:1;
	unsigned int sourceAttributes:1;
	};
int length;
Source();
Source(GroupItem *item);
void addListener(GroupItem *item);
void dump();
GroupItem *get(int index);
GroupItem *next();
int pageShift(int length);
void reset();
void setList();
void setSourceItem(GroupItem *item);
void sort(GroupItem *compare);
void sort(char *name);
void updateListeners();
};
