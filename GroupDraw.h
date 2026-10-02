class GroupItem;
@class Layout;
/*******************************************************************************
	A class that contains drawing data and methods
*******************************************************************************/

class GroupDraw
{
public:
GroupItem *drawRegistry;
Layout *layout;
};
extern "C" GroupItem *displayFillRT(GroupItem *field);
extern "C" NSRect getFrame(GroupItem *item);
extern "C" GroupItem *makeDisplay(GroupItem *field);
extern "C" GroupItem *pixelAt(GroupItem *field);
extern "C" GroupItem *styleComponent(GroupItem *field, char *component);
char *toString(NSPoint p);
char *toString(NSRect f);
