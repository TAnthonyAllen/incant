#include <Cocoa/Cocoa.h>
#include <string.h>
#include <stdio.h>
#include <Foundation/Foundation.h>
#include "OCroutines.h"
#include "GroupItem.h"
#include "Buffer.h"
#include "GroupRules.h"
#include "GroupControl.h"
#include "GroupBody.h"
#include "PLGset.h"
#include "Stylish.h"
#include "GroupDraw.h"

/*******************************************************************************
	Return the lowest descendent block that contains the point passed in.
    Assumes the base passed in contains the point.
*******************************************************************************/
extern "C" GroupItem *blockContaining(GroupItem *base, NSPoint p)
{
GroupItem 	*item = 0;
GroupItem 	*grup = 0;
Stylish 	*style = 0;
	if ( base )
		{
		//if detail = base.other cout "blockContaining",base.tag,frame,"Point:",p.x,p.y:;
		while ( item = base->nextMember(item) )
			{
			style = ::getStyle(item);
			if ( ::contains(item,p) )
				if ( item->groupBody->flags.hasMembers || !item->groupBody->flags.noPrint )
					if ( !style->selectable )
						continue;
					else	break;
			}
		if ( item && item->groupBody->flags.hasMembers )
			if ( grup = ::blockContaining(item,p) )
				return grup;
		}
	return item;
}

/*****************************************************************************
	Check if point is in the field frame
*****************************************************************************/
extern "C" int contains(GroupItem *field, NSPoint p)
{
NSRect 	frame = ::getFrame(field);
double 	top = 0;
double 	right = 0;
	//cout "Checking " wig.tag "\n";
	if ( p.y > frame.origin.y && p.x > frame.origin.x )
		{
		top = frame.origin.y + frame.size.height;
		right = frame.origin.x + frame.size.width;
		return p.y <= top && p.x <= right;
		}
	return 0;
}

/*******************************************************************************
    Look up the color in the cOLOr registry, set its color object if needed and
    return the color object.
*******************************************************************************/
extern "C" NSColor *getColor(char *name)
{
NSColor 	*color = 0;
GroupItem 	*item = GroupControl::groupController->locate(name);
	if ( item )
		if ( !isOBJECT(item->groupBody->flags.data) )
			::setColor(item);
	if ( !(color = (NSColor*)item->getObject()) )
		::fprintf(stderr,"getColor: ERROR could not get color %s\n",name);
	return color;
}

/***************************************************************************
	Return the style for the field passed in. If the field has no style
    attribute, it walks the parent hierarchy and returns the first style
    it finds.
***************************************************************************/
extern "C" Stylish *getStyle(GroupItem *field)
{
GroupItem 	*style = 0;
GroupItem 	*grup = field;
Stylish 	*styled = 0;
	if ( !style )
		while ( grup = grup->parent )
			if ( style = grup->get("style") )
				break;
	if ( style )
		styled = (Stylish*)style->getPointer();
	else	styled = ::makeStyleFor(field);
	return styled;
}

/*******************************************************************************
	The indentFrame methods resize and reposition a frame. POP required to
    make sure they do what is intended wrt frame position. Named indentFrame*
    (not indent/indentWH) — those names collide at C linkage with the
    unrelated debug-print indent() in the shared support StringRoutines.C.
*******************************************************************************/
extern "C" NSRect indentFrame(NSRect f, double b)
{
	return ::NSMakeRect(f.origin.x + b,f.origin.y + b,f.size.width - 2 * b,f.size.height - 2 * b);
}

extern "C" NSRect indentFrameWH(NSRect f, double w, double h)
{
	return ::NSMakeRect(f.origin.x + w,f.origin.y + h,f.size.width - 2 * w,f.size.height - 2 * h);
}

/*******************************************************************************
	Assign a style to the field passed in, which is expected to be a style
    attribute. Looks up styles in sTYLEs registry that does not exist yet.
*******************************************************************************/
extern "C" Stylish *makeStyleFor(GroupItem *field)
{
char 		*name = field->getText();
GroupItem 	*styles = GroupControl::groupController->groupRules->registries->get("sTYLEs");
GroupItem 	*styleItem = 0;
Stylish 	*style = 0;
	if ( !styles )
		{
		::fprintf(stderr,"makeStyleFor %s ERROR: could not find sTYLEs registry\n",styleItem->groupBody->tag);
		return style;
		}
	if ( !name )
		{
		::fprintf(stderr,"makeStyleFor %s ERROR: style attribute has to have text to specify a name\n",styleItem->groupBody->tag);
		return style;
		}
	if ( styleItem = styles->get(name) )
		style = (Stylish*)styleItem->getPointer();
	else {
		style = new Stylish(name);
		styleItem = new GroupItem(name);
		styleItem->setPointer((void*)style);
		styles->addMember(styleItem);
		}
	styleItem = new GroupItem("style");
	styleItem->setPointer((void*)style);
	field->addAttribute(styleItem);
	return style;
}

/*******************************************************************************
	Process shadow. This compiles but design required plus POP to make sure
    shadow and shadowField are set right and in sync.
*******************************************************************************/
extern "C" void sHADOW(GroupItem *field)
{
Stylish 	*shadowStyle = ::getStyle(field);
	if ( !shadowStyle->shadow )
		{
		shadowStyle->shadow = [[NSShadow alloc] init];
		::CFRetain((void*)shadowStyle->shadow);
		}
	if ( shadowStyle->shadowField )
		{
		GroupItem 	*shadowBlur = shadowStyle->shadowField->get("blur");
		GroupItem 	*shadowColor = shadowStyle->shadowField->get("color");
		GroupItem 	*xOffset = shadowStyle->shadowField->get("x");
		GroupItem 	*yOffset = shadowStyle->shadowField->get("y");
		shadowStyle = ::getStyle(shadowStyle->shadowField);
		if ( shadowBlur )
			[shadowStyle->shadow setShadowBlurRadius:shadowBlur->getNumber()];
		else	[shadowStyle->shadow setShadowBlurRadius:3.0];
		if ( shadowColor && shadowColor->groupBody->flags.isPointer )
			{
			NSColor 	*coloric = (NSColor*)shadowColor->getPointer();
			[shadowStyle->shadow setShadowColor:coloric];
			}
		else	[shadowStyle->shadow setShadowColor:[[NSColor blackColor] colorWithAlphaComponent:0.3]];
		if ( xOffset && yOffset )
			[shadowStyle->shadow setShadowOffset:NSMakeSize(xOffset->getNumber(),yOffset->getNumber())];
		else	[shadowStyle->shadow setShadowOffset:NSMakeSize(2.0,-2.0)];
		}
}

/***************************************************************************
	Converts a color hex code into a color object
    Note: cOLORs registry stores color hex as a string like "rrggbb"
***************************************************************************/
extern "C" void setColor(GroupItem *field)
{
char 			*atPart = field->getText();
GroupItem 		*hexSet = GroupControl::groupController->groupRules->properties->get("hexSet");
PLGset 			*set = hexSet->getCharacterSet();
unsigned int 	red = 0;
unsigned int 	blue = 0;
unsigned int 	green = 0;
	red = set->contains(atPart);
	if ( !red || ::strlen(atPart) != 6 )
		::printf("ERROR: expected a valid six character hex string not:%s\n",atPart);
	else {
		NSColor 	*color = 0;
		GroupControl::groupController->groupRules->stringBUFFER->reset();
		GroupControl::groupController->groupRules->stringBUFFER->appendString(atPart,0,0);
		atPart = GroupControl::groupController->groupRules->stringBUFFER->start + 4;
		::sscanf(atPart,"%x",&green);
		*atPart = 0;
		atPart = GroupControl::groupController->groupRules->stringBUFFER->start + 2;
		::sscanf(atPart,"%x",&blue);
		*atPart = 0;
		atPart = GroupControl::groupController->groupRules->stringBUFFER->start;
		::sscanf(atPart,"%x",&red);
		GroupControl::groupController->groupRules->stringBUFFER->reset();
		color = [NSColor colorWithCalibratedRed:(double)red green:(double)blue blue:(double)green alpha:1.0];
		field->setObject((NSObject*)color);
		}
}

/***************************************************************************
	Sets font object based on font attributes. May require revision after
    font design session.
***************************************************************************/
extern "C" void setFont(GroupItem *field)
{
GroupItem 		*family = field->get("family");
GroupItem 		*size = field->get("size");
GroupItem 		*bold = field->get("bold");
GroupItem 		*italic = field->get("italic");
NSString 		*name = [NSString stringWithCString:family->getText() encoding:NSASCIIStringEncoding];
int 			mask = 0;
unsigned int 	boldMask = 0;
unsigned int 	italicMask = 0;
NSFont 			*font = 0;
	font = [NSFont fontWithName:name size:size->getNumber()];
	if ( bold )
		{
		boldMask = bold->getCount();
		mask &= boldMask;
		}
	if ( italic )
		{
		italicMask = italic->getCount();
		mask &= italicMask;
		}
	::CFRetain((void*)font);
	field->setObject((NSObject*)font);
}

Stylish::Stylish(GroupItem *item)
{
	shadow = 0;
	borderWidth = 0;
	radius = 0;
	transparency = 0;
	bgColor = 0;
	fillColor = 0;
	font = 0;
	shadowBlur = 0;
	shadowOffset = 0;
	shadowX = 0;
	shadowY = 0;
	shadowColor = 0;
	formatter = 0;
	editable = 0;
	selected = 0;
	selectable = 0;
	subbed = 0;
	shadowField = 0;
	strokeColor = [NSColor blackColor];
	textColor = [NSColor blackColor];
	styling = item->groupBody->tag;
	// This just zeros out everything
}

Stylish::Stylish(GroupItem *item, Stylish *source)
{
	*this = *source;
	styling = item->groupBody->tag;
}

Stylish::Stylish(char *name)
{
	shadow = 0;
	borderWidth = 0;
	radius = 0;
	transparency = 0;
	bgColor = 0;
	fillColor = 0;
	font = 0;
	shadowBlur = 0;
	shadowOffset = 0;
	shadowX = 0;
	shadowY = 0;
	shadowColor = 0;
	formatter = 0;
	editable = 0;
	selected = 0;
	selectable = 0;
	subbed = 0;
	shadowField = 0;
	strokeColor = [NSColor blackColor];
	textColor = [NSColor blackColor];
	styling = name;
}
