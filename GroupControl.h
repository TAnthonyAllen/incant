class GroupRules;
class PLGset;
class DispatchQ;
class GroupItem;
/******************************************************************************
	An extendable list of GroupItems.
******************************************************************************/

class GroupControl
{
public:
GroupRules *groupRules;
PLGset *cdataSet;
PLGset *endNameSet;
PLGset *mustQuoteSet;
DispatchQ *dispatchQ;
static GroupControl *groupController;
GroupControl(int i);
void addBaseRegistry(GroupItem *r);
GroupItem *copyOf(GroupItem *grup);
void dumpSearchList();
GroupItem *getRegistry(char *c);
GroupItem *locate(char *name);
GroupItem *locate(GroupItem *item);
GroupItem *locateInMethod(char *name);
void setBaseRegistries();
};
