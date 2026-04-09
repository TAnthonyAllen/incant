class PLGset;
class Stylish;
class GroupItem;
class DrawPoint;
class PLGitem;
/*****************************************************************************
	Groups class definition
*****************************************************************************/

class Groups : public PLGparse
{
public:
PLGset *operateSet;
PLGset *alphaSet;
PLGset *hexSet;
PLGset *nameSet;
PLGset *notSpace;
PLGset *pathOpSet;
PLGset *curveOpSet;
int curving;
Stylish *style;
GroupItem *currentColor;
GroupItem *drawingBlock;
GroupItem *trait;
DrawPoint *currentDP;
PLGitem *fillColor;
PLGitem *strokeColor;
struct 
	{
	unsigned int asPercentOfFrame:1;
	unsigned int closeOut:1;
	unsigned int gotoPoint:1;
	unsigned int itsAllRelative:1;
	unsigned int nested:1;
	unsigned int saveGraphicState:1;
	unsigned int translated:1;
	};
int notBlock;
Groups();
void border(GroupItem *t, Stylish *s);
DrawPoint ***buildPath(GroupItem *item);
int colorize(GroupItem *trait);
int processKeySpec(GroupItem *keyTrait);
PLGitem *run(char *name);
PLGitem *run(char *rule, GroupItem *item);
void setRules();
};
int AmountGroupsNow(PLGitem *iTEM);
int DrawOperator3GroupsNow(PLGitem *iTEM);
int DrawOperator4GroupsNow(PLGitem *iTEM);
int DrawOperatorGroupsNow(PLGitem *iTEM);
int HexGroupsNow(PLGitem *iTEM);
int KeyStrokeGroupsNow(PLGitem *iTEM);
int KeyStruck2GroupsNow(PLGitem *iTEM);
int KeyStruckGroupsNow(PLGitem *iTEM);
int Number2GroupsNow(PLGitem *iTEM);
int NumberGroupsNow(PLGitem *iTEM);
int PathListGroupsNow(PLGitem *iTEM);
int PointGroupsNow(PLGitem *iTEM);
int PointOpGroupsNow(PLGitem *iTEM);
int RGBvalue2GroupsNow(PLGitem *iTEM);
int RGBvalueGroupsNow(PLGitem *iTEM);
int SetNotBlockGroupsNow(PLGitem *iTEM);
