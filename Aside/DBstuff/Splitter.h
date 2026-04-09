class ParseXML;
class PLGitem;
class GroupItem;
class GroupList;
/***************************************************************************
	Split an XML parse
***************************************************************************/

class Splitter
{
public:
ParseXML **splits;
PLGitem *input;
int count;
Splitter(int i);
void cleanup(GroupItem *b, GroupItem *match);
void dump();
GroupItem *findMatchingBlock(GroupItem *b, char *name);
PLGitem *getEndItem(char *text, int size);
void handleEndTags(GroupItem *block);
GroupItem *map(GroupList *list);
void matchEndTags(GroupItem *block, PLGitem *stuff);
void parse();
GroupItem *run(char *filename);
int split(char *filename);
GroupItem *unsplit();
void useLocalLinkTape(GroupList *list);
};
ParseXML **splits;
PLGitem *input;
int count;
int newIndex;
Stak *stack;
GroupItem *block;
GroupItem *item;
GroupItem **atGroup;
GroupItem *group;
GroupList *list;
GroupItem *priorBlock;
GroupItem *top;
ParseXML **atParser;
ParseXML *priorParser;
ParseXML *parser;
PLGitem *followItem;
PLGitem *blockItem;
void cleanup(GroupItem *b, GroupItem *match);
void dump();
GroupItem *findMatchingBlock(GroupItem *b, char *name);
PLGitem *getEndItem(char *text, int size);
void handleEndTags(GroupItem *block);
GroupItem *map(GroupList *list);
void parse();
GroupItem *run(char *filename);
int split(char *filename);
GroupItem *unsplit();
