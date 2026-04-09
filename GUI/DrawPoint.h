class GroupItem;
class PLGitem;
class Buffer;
/*******************************************************************************
	The DrawPoint class encapsulates a point and associated drawing directives
    used when parsing drawing instructions (see Groups parser).
*******************************************************************************/

class DrawPoint
{
public:
NSPoint point;
char xOperator;
char yOperator;
DrawPoint *control1;
DrawPoint *control2;
GroupItem *drawPathBlock;
PLGitem *fillColor;
PLGitem *strokeColor;
struct 
	{
	unsigned int closeIt:1;
	unsigned int direction:4;
	unsigned int fillPath:1;
	unsigned int hasOperator:1;
	unsigned int middle:1;
	unsigned int move:1;
	unsigned int percent:1;
	unsigned int relative:1;
	unsigned int shape:3;
	unsigned int strokePath:1;
	unsigned int translate:4;
	};
static GroupItem *drawGroup;
static NSPoint priorPoint;
static NSPoint targetPoint;
DrawPoint();
DrawPoint(PLGitem *x, PLGitem *y);
DrawPoint(NSPoint p);
void draw(Buffer *buffer);
void drawBlock(GroupItem *item, Buffer *buffer);
NSPoint get(NSRect frame);
NSPoint getPoint(NSRect frame, NSPoint pp);
void movePath(NSPoint p, Buffer *buffer);
void reset();
char *toString();
};
void drawPath(GroupItem *item);
