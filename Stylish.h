@class NSShadow;
@class NSNumberFormatter;
class GroupItem;
/*******************************************************************************
	Defined as class but just a structure really to encapsulate style attributes
*******************************************************************************/

class Stylish
{
public:
char *styling;
NSShadow *shadow;
NSNumberFormatter *formatter;
double borderWidth;
double radius;
double transparency;
GroupItem *blankItem;
GroupItem *commaItem;
GroupItem *createdBy;
GroupItem *filler;
GroupItem *fontItem;
GroupItem *formatItem;
GroupItem *selectFill;
GroupItem *selectStroke;
GroupItem *stroker;
GroupItem *texter;
GroupItem *zeroItem;
struct 
	{
	unsigned int align:3;
	unsigned int bottomBorder:1;
	unsigned int fontModified:1;
	unsigned int leftBorder:1;
	unsigned int rightBorder:1;
	unsigned int rounded:1;
	unsigned int squared:1;
	unsigned int topBorder:1;
	};
#define center(button) (button == 1)
#define left(button) (button == 2)
#define right(button) (button == 3)
#define justify(button) (button == 4)
Stylish(GroupItem *item);
Stylish(GroupItem *item, Stylish *source);
Stylish(char *name);
};
extern "C" GroupItem *setColor(GroupItem *input);
