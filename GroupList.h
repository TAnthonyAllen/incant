#include "gc/gc_cpp.h"

class GroupItem;
class GroupStak;
/*******************************************************************************
	A skeleton class containing a group list (used in GroupBody)
*******************************************************************************/

class GroupList : public gc
{
public:
GroupItem *firstInList;
GroupItem *lastInList;
int listLength;
GroupStak *stakked;
GroupList();
GroupList(GroupItem *item);
void clear();
};
