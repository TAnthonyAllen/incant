@class NSShadow;
@class NSColor;
@class NSFont;
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
double borderWidth;
double radius;
double transparency;
NSColor *bgColor;
NSColor *fillColor;
NSColor *strokeColor;
NSColor *textColor;
NSFont *font;
NSNumberFormatter *formatter;
struct 
	{
	unsigned int editable:1;
	unsigned int selected:1;
	unsigned int selectable:1;
	};
GroupItem *shadowField;
Stylish(GroupItem *item);
Stylish(GroupItem *item, Stylish *source);
Stylish(char *name);
};
extern "C" GroupItem *blockContaining(GroupItem *base, NSPoint p);
extern "C" int contains(GroupItem *field, NSPoint p);
extern "C" NSColor *getColor(char *name);
extern "C" NSFont *getFont(GroupItem *field);
extern "C" Stylish *getStyle(GroupItem *field);
extern "C" NSRect indentFrame(NSRect f, double b);
extern "C" Stylish *makeStyleFor(GroupItem *field);
extern "C" void setColor(GroupItem *field);
extern "C" void setFont(GroupItem *field);
