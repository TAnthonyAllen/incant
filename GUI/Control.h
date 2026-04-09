class GroupItem;
@class Layout;
@class Delegate;
class BaseHash;
class Tape;
class Details;
@class NSDate;
class Buffer;
class Bwana;
class PLGitem;
@class NSWindow;
/*******************************************************************************
	Controller for Group GUI
*******************************************************************************/

class Control
{
public:
GroupItem *baseURL;
GroupItem *classList;
GroupItem *loadedItem;
GroupItem *root;
Layout *activeView;
Delegate *delegator;
BaseHash *flexLayoutStash;
Tape *detailTape;
Details *attributeDetail;
NSDate *timer;
Buffer *buffer;
struct 
	{
	unsigned int convertWindowToPanel:1;
	unsigned int showWarnings:1;
	};
static Bwana *bwana;
static GroupItem *fontRegistry;
static GroupItem *colorRegistry;
Buffer *controlBuffer;
Control();
GroupItem *addPara(GroupItem *block, char *s);
void dump(GroupItem *group);
void fillFrame(GroupItem *item);
void fitSize();
void fitSize(GroupItem *item);
void flexLayout(GroupItem *group);
void layout(GroupItem *base);
void load(char *name);
void load(GroupItem *item);
PLGitem *makeCSSline(GroupItem *block);
GroupItem *makeCanvas(GroupItem *group);
PLGitem *makeDiv(GroupItem *block);
GroupItem *makeHTML(GroupItem *group);
void processActionTrack(GroupItem *action);
void resetVariableContent(GroupItem *group);
Details *setDetails(GroupItem *item);
GroupItem *setFlexDetails(GroupItem *group);
void setLayout(GroupItem *item, Layout *lay);
void setup();
void start(NSWindow *window);
int toCSS(GroupItem *group);
};
void jsDraw(GroupItem *block, Buffer *buffer);
GroupItem *walkVisible(GroupItem *base, GroupItem *item);
