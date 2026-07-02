@class NSShadow;
@class NSColor;
@class NSFont;
class GroupItem;
@class NSNumberFormatter;
/*******************************************************************************
	Defined as class but just a structure really to encapsulate style attributes
*******************************************************************************/

class Stylish
{
public:
char *styling;
NSShadow *shadow;
double borderWidth;
double radius;
double transparency;
NSColor *bgColor;
NSColor *fillColor;
NSColor *strokeColor;
NSColor *textColor;
NSFont *font;
GroupItem *shadowBlur;
GroupItem *shadowOffset;
GroupItem *shadowX;
GroupItem *shadowY;
GroupItem *shadowColor;
NSNumberFormatter *formatter;
struct 
	{
	unsigned int editable:1;
	unsigned int selected:1;
	unsigned int selectable:1;
	unsigned int subbed:1;
	};
GroupItem *shadowField;
Stylish(GroupItem *item);
Stylish(GroupItem *item, Stylish *source);
Stylish(char *name);
};
extern "C" GroupItem *blockContaining(GroupItem *base, NSPoint p);
extern "C" int contains(GroupItem *field, NSPoint p);
extern "C" void dumpColorRGB(GroupItem *field);
extern "C" NSColor *getColor(char *name);
extern "C" Stylish *getStyle(GroupItem *field);
extern "C" NSRect indentFrame(NSRect f, double b);
extern "C" NSRect indentFrameWH(NSRect f, double w, double h);
extern "C" Stylish *makeStyleFor(GroupItem *field);
extern "C" void sHADOW(GroupItem *field);
extern "C" void setColor(GroupItem *field);
extern "C" void setFont(GroupItem *field);
