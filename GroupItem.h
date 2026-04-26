#include <gc/gc_cpp.h>

class GroupBody;
class RuleStuff;
class Buffer;
class PLGset;
class PLGitem;
@class NSObject;
class PLGrgx;
class Stak;
class BitMAP;
struct GroupOptions
	{
	unsigned int affiliation:2;
	unsigned int recursive:1;
	unsigned int isCopy:1;
	};
#define isAttribute(button) (button == 1)
#define isMember(button) (button == 2)
#define isEmbedded(button) (button == 3)

/******************************************************************************
	A group.
******************************************************************************/

class GroupItem : public gc
{
public:
GroupBody *groupBody;
GroupItem *parent;
GroupItem *nextInParent;
GroupItem *priorInParent;
RuleStuff *rStuff;
GroupOptions options;
GroupItem();
GroupItem(GroupItem *grup);
GroupItem(char *c);
GroupItem *addAttribute(GroupItem *grup);
GroupItem *addGroup(GroupItem *group);
GroupItem *addMember(GroupItem *grup);
void addRuleStuff();
GroupItem *addString(char *n);
void append(GroupItem *grup);
void clear();
void clearData();
void clearList();
int contents();
void copyData(GroupItem *item);
void copyListFrom(GroupItem *grup);
void copyListTo(GroupItem *grup);
GroupItem *dQ();
void dispatch();
GroupItem *findAttribute(char *name);
GroupItem *findParent(char *name);
GroupItem *firstComponent(char *name);
GroupItem *followingEntry();
GroupItem *get(char *name);
GroupItem *get(int offset);
GroupItem *getAttribute(char *name);
Buffer *getBuffer();
char getCharacter();
PLGset *getCharacterSet();
int getCount();
int getDataType();
GroupItem *getFromList(char *name);
GroupItem *getGroup();
PLGset *getGuard();
PLGitem *getItem();
GroupItem *getLabelGroup(char *name);
GroupItem *getMember(char *name);
double getNumber();
NSObject *getObject();
void *getPointer();
PLGrgx *getRegex();
Stak *getStak();
RuleStuff *getStuff(RuleStuff *pStuff);
char *getText();
GroupItem *insertGroup(GroupItem *grup);
void makeRegistry();
int matches(GroupItem *arg);
char *matches(char *&atString);
void merge(GroupItem *group);
void mergeAttributes(GroupItem *group, int mergeFlag);
void moveTo(GroupItem *item);
GroupItem *next(GroupItem *current);
GroupItem *nextAttribute(GroupItem *current);
GroupItem *nextGroup(GroupItem *grup);
GroupItem *nextMember(GroupItem *current);
GroupItem *parse(RuleStuff *pStuff);
GroupItem *pop();
void prepend(GroupItem *grup);
GroupItem *prior(GroupItem *grup);
GroupItem *push(GroupItem *grup);
void put(GroupItem *grup);
GroupItem *remove();
GroupItem *remove(char *name);
GroupItem *replace(GroupItem *argument);
char *resolvedTag();
void setBuffer(Buffer *b);
void setCharacter(char c);
void setCharacterSet(PLGset *set);
void setContent(GroupItem *item);
void setCount(int i);
void setGroup(GroupItem *g);
void setItem(PLGitem *i);
void setMap(BitMAP *i);
void setMethod(GroupItem *(*m)(GroupItem *));
void setNumber(double d);
void setObject(NSObject *v);
void setOperat(GroupItem *(*m)(GroupItem *, GroupItem *));
void setPointer(void *v);
void setRegex(PLGrgx *v);
void setRuleStuff();
void setStak(Stak *s);
void setText(char *s);
void setToken(char *s, int length);
void sort(int (*comparisor)(GroupItem *, GroupItem *));
void sortByAttribute(char *attributeName);
void updateContentFlags();
void updateListeners();
GroupItem *walk(GroupItem *item);
};
int compareAttribute(GroupItem *group1, GroupItem *group2);
int compareTags(GroupItem *group1, GroupItem *group2);
int compareValues(GroupItem *group1, GroupItem *group2);
