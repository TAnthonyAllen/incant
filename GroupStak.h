class GroupItem;
/*****************************************************************************
	A simple stack that will resize if it runs out of room.
*****************************************************************************/

class GroupStak
{
public:
int length;
int size;
GroupItem *stakSource;
GroupItem **end;
GroupItem **entry;
GroupItem **start;
GroupStak(GroupItem *g);
void clearStak();
GroupItem *getFromStak(char *name);
GroupItem *getFromStak(int indx);
void listStakked();
GroupItem *next();
GroupItem *pop();
GroupItem *prior();
void push(GroupItem *grup);
void resetStak();
void resize();
};
