class GroupItem;
class Stylish;
@class Layout;
@class NSEvent;
@class NSTextView;
/*******************************************************************************
	Display details for a GroupItem
*******************************************************************************/

class Details
{
public:
GroupItem *wig;
id object;
SEL draw;
NSRect innerBox;
NSRect frame;
Stylish *style;
Layout *view;
NSEvent *event;
double high;
double length;
double positionAt;
int level;
int offset;
int stretched;
struct 
	{
	unsigned int attributed:1;
	unsigned int collapsed:1;
	unsigned int content:3;
	unsigned int deferDraw:1;
	unsigned int editable:1;
	unsigned int editing:1;
	unsigned int fitted:1;
	unsigned int fixHeight:1;
	unsigned int fixWidth:1;
	unsigned int fixX:1;
	unsigned int fixY:1;
	unsigned int hasBox:1;
	unsigned int hasOnLayout:1;
	unsigned int hasReactions:1;
	unsigned int imageSized:1;
	unsigned int isDisplayable:1;
	unsigned int isNext:1;
	unsigned int isTab:1;
	unsigned int isToggled:1;
	unsigned int keyField:1;
	unsigned int noData:1;
	unsigned int noScroll:1;
	unsigned int orient:3;
	unsigned int pane:3;
	unsigned int reacting:1;
	unsigned int refit:1;
	unsigned int scrollableX:1;
	unsigned int scrollableY:1;
	unsigned int selectable:1;
	unsigned int showBlank:1;
	unsigned int sizeToFit:3;
	unsigned int sourced:1;
	unsigned int subbed:1;
	unsigned int trait:1;
	unsigned int useTagForLabel:1;
	unsigned int wasReset:1;
	};
void changeText();
void checkFit();
void checkStretch();
void clear();
int contains(NSPoint p);
void dump();
void dumpDetails();
void getFitSettings();
int initialize(GroupItem *w);
void processAttributes();
void processMethods();
void processReaction();
void scrollContent(int scrollAmount);
void setFrame();
void setInnerBox();
NSTextView *setPage(NSRect indented);
void setScroll(int step, int goAcross);
void setStyle();
};
GroupItem *blockContaining(GroupItem *base, NSPoint p);
GroupItem *findScrollable(GroupItem *group);
Details *getAncestor(GroupItem *item);
char *getCellText(GroupItem *item);
Details *getDetail(GroupItem *item);
void scrollBlock(GroupItem *group, int length, int isVertical);
void scrollCards(GroupItem *block, int up);
void scrollSource(GroupItem *item, int length);
Details *setDetail(GroupItem *item);
void setNoRoom(GroupItem *item, int flag);
