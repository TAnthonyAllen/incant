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
void setWindow(GroupItem *block);
};
extern "C" int containsPoint(GroupItem *grup, NSPoint p);
extern "C" GroupItem *displayFillRT(GroupItem *field);
extern "C" NSRect getFrame(GroupItem *item);
extern "C" NSTextView *getTextView(GroupItem *field);
extern "C" GroupItem *makeDisplay(GroupItem *field);
extern "C" GroupItem *pixelAt(GroupItem *field);
char *toString(NSPoint p);
char *toString(NSRect f);
