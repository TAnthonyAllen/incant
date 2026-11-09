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
extern "C" GroupItem *closePDF(GroupItem *request);
extern "C" GroupItem *displayBorder(GroupItem *field);
extern "C" GroupItem *displayFillRT(GroupItem *field);
GroupItem *displayOf(GroupItem *field);
extern "C" GroupItem *displayText(GroupItem *request);
extern "C" NSRect getFrame(GroupItem *item);
void handDisplay(GroupItem *field, GroupItem *top);
extern "C" GroupItem *makeDisplay(GroupItem *field);
extern "C" GroupItem *openPDF(GroupItem *request);
extern "C" GroupItem *pixelAt(GroupItem *field);
extern "C" GroupItem *readPDF(GroupItem *request);
extern "C" GroupItem *styleComponent(GroupItem *field, char *component);
char *toString(NSPoint p);
char *toString(NSRect f);
