class GroupItem;
/*****************************************************************************
	A simple stack that will resize if it runs out of room.
    The array comes from operator new, never calloc (GC stroke 2, R4, SEQ 589):
    gcThreads.mm's new makes it uncollectable on the main thread, so the
    collector scans it and a node held only here stays alive.
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
