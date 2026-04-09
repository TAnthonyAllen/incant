class GroupItem;
@class Layout;
@class NSTextView;
/*******************************************************************************
	A class that contains drawing data and methods
*******************************************************************************/

class GroupDraw
{
public:
GroupItem *drawRegistry;
Layout *layout;
static GroupDraw *drawer;
void setWindow(GroupItem *block);
};
extern "C" GroupItem *blockContaining(GroupItem *grup, NSPoint p);
extern "C" int containsPoint(GroupItem *grup, NSPoint p);
extern "C" NSRect getFrame(GroupItem *item);
extern "C" NSTextView *getTextView(GroupItem *field);
char *toString(NSPoint p);
char *toString(NSRect f);
