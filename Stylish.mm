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
#include "GroupDraw.h"
#include "Stylish.h"

/*******************************************************************************
	Return the lowest descendent block that contains the point passed in.
    Assumes the base passed in contains the point.
*******************************************************************************/
extern "C" GroupItem *blockContaining(GroupItem *base, NSPoint p)
{
GroupItem 	*item = 0;
GroupItem 	*grup = 0;
	if ( base )
		{
		//if detail = base.other cout "blockContaining",base.tag,frame,"Point:",p.x,p.y:;
		while ( item = base->nextMember(item) )
			{
			if ( ::contains(item,p) )
				if ( item->groupBody->flags.hasMembers || !item->groupBody->flags.noPrint )
					break;
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
	Debug: setColor a field then print its resulting RGB components (0.0-1.0),
    to verify setColor's hex parse + scale. POP tool, not called from
    production paths.
*******************************************************************************/
extern "C" void dumpColorRGB(GroupItem *field)
{
	::setColor(field);
	
	NSColor *c = (NSColor*)field->getObject();
	if (c) {
	CGFloat r = 0, g = 0, b = 0, a = 0;
	[c getRed:&r green:&g blue:&b alpha:&a];
	fprintf(stderr,"dumpColorRGB %s: r=%.3f g=%.3f b=%.3f a=%.3f\n", field->getText(), r, g, b, a);
	} else fprintf(stderr,"dumpColorRGB %s: NULL\n", field->getText());
	
}

/*******************************************************************************
	Debug: setFont a field then print its resulting NSFont's displayName +
    bold/italic traits. POP tool, not called from production paths.
*******************************************************************************/
extern "C" void dumpFontInfo(GroupItem *field)
{
	::setFont(field);
	
	NSFont *f = (NSFont*)field->getObject();
	if (f) {
	NSFontSymbolicTraits t = f.fontDescriptor.symbolicTraits;
	fprintf(stderr,"dumpFontInfo %s: displayName='%s' size=%.1f bold=%d italic=%d\n",
	field->resolvedTag(), [f.displayName UTF8String], f.pointSize,
	(t & NSFontDescriptorTraitBold) != 0, (t & NSFontDescriptorTraitItalic) != 0);
	} else fprintf(stderr,"dumpFontInfo %s: NULL\n", field->resolvedTag());
	
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
		{
		if ( !isOBJECT(item->groupBody->flags.data) )
			::setColor(item);
		if ( !(color = (NSColor*)item->getObject()) )
			::fprintf(stderr,"getColor: ERROR could not get color %s\n",name);
		}
	else	::fprintf(stderr,"getColor: ERROR could not find %s\n",name);
	return color;
}

/*******************************************************************************
	Lazy font lookup, symmetric to getColor: realize (setFont) on first miss,
    return the boxed NSFont. field is expected to carry family/size/bold/
    italic/smallCaps attributes (a fONTs registry entry).
*******************************************************************************/
extern "C" NSFont *getFont(GroupItem *field)
{
NSFont 	*font = 0;
	if ( field )
		{
		if ( !isOBJECT(field->groupBody->flags.data) )
			::setFont(field);
		if ( !(font = (NSFont*)field->getObject()) )
			::fprintf(stderr,"getFont: ERROR could not get font %s\n",field->groupBody->tag);
		}
	else	::fprintf(stderr,"getFont: ERROR null field\n");
	return font;
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
unsigned int 	isValid = 0;
unsigned int 	red = 0;
unsigned int 	green = 0;
unsigned int 	blue = 0;
	isValid = set->contains(atPart);
	if ( !isValid || ::strlen(atPart) != 6 )
		::printf("ERROR: expected a valid six character hex string not:%s\n",atPart);
	else {
		NSColor 	*color = 0;
		GroupControl::groupController->groupRules->stringBUFFER->reset();
		GroupControl::groupController->groupRules->stringBUFFER->appendString(atPart,0,0);
		atPart = GroupControl::groupController->groupRules->stringBUFFER->start + 4;
		::sscanf(atPart,"%x",&blue);
		*atPart = 0;
		atPart = GroupControl::groupController->groupRules->stringBUFFER->start + 2;
		::sscanf(atPart,"%x",&green);
		*atPart = 0;
		atPart = GroupControl::groupController->groupRules->stringBUFFER->start;
		::sscanf(atPart,"%x",&red);
		GroupControl::groupController->groupRules->stringBUFFER->reset();
		color = [NSColor colorWithCalibratedRed:(double)red / 255.0 green:(double)green / 255.0 blue:(double)blue / 255.0 alpha:1.0];
		field->setObject((NSObject*)color);
		}
}

/***************************************************************************
	Sets font object based on font attributes, via NSFontDescriptor (family +
    symbolic traits + feature settings) so bold/italic/smallCaps all realize
    through one Apple mechanism. Fallback chain on failure: descriptor+family
    -> fontWithName -> systemFontOfSize. Missing size attribute defaults to
    12.0. Never leaves font null.
***************************************************************************/
extern "C" void setFont(GroupItem *field)
{
NSFont 	*font = 0;
	
	GroupItem       *familyField = field->get("family");
	GroupItem       *sizeField = field->get("size");
	GroupItem       *boldField = field->get("bold");
	GroupItem       *italicField = field->get("italic");
	GroupItem       *smallCapsField = field->get("smallCaps");
	NSString        *name = familyField
	? [NSString stringWithCString:familyField->getText() encoding:NSASCIIStringEncoding]
	: @"Helvetica";
	double          pointSize = sizeField ? sizeField->getNumber() : 12.0;
	NSFontSymbolicTraits    traits = 0;
	// presence-based by design (Tony): field exists => trait on. Do NOT switch to a
	// value-check (bold=0 means off) without first POPping how a bare flag (no value,
	// e.g. plain "bold") reports .number/.count -- a bare flag has no data and would
	// read as off, breaking the common "bold;" case.
	if ( boldField )    traits |= NSFontDescriptorTraitBold;
	if ( italicField )  traits |= NSFontDescriptorTraitItalic;
	NSDictionary    *attrs = @{ NSFontFamilyAttribute: name };
	if ( smallCapsField )
	{
	NSDictionary    *feature = @{
	NSFontFeatureTypeIdentifierKey: @(kLowerCaseType),
	NSFontFeatureSelectorIdentifierKey: @(kLowerCaseSmallCapsSelector) };
	attrs = @{ NSFontFamilyAttribute: name, NSFontFeatureSettingsAttribute: @[ feature ] };
	}
	NSFontDescriptor    *desc = [NSFontDescriptor fontDescriptorWithFontAttributes:attrs];
	if ( traits )   desc = [desc fontDescriptorWithSymbolicTraits:traits];
	font = [NSFont fontWithDescriptor:desc size:pointSize];
	if ( !font )
	{
	::fprintf(stderr,"setFont: descriptor failed for family '%s', trying fontWithName\n",[name UTF8String]);
	font = [NSFont fontWithName:name size:pointSize];
	}
	if ( !font )
	{
	::fprintf(stderr,"setFont: fontWithName failed for family '%s', falling back to systemFont\n",[name UTF8String]);
	font = [NSFont systemFontOfSize:pointSize];
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
	shadowField = 0;
	formatter = 0;
	editable = 0;
	selected = 0;
	selectable = 0;
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
	shadowField = 0;
	formatter = 0;
	editable = 0;
	selected = 0;
	selectable = 0;
	strokeColor = [NSColor blackColor];
	textColor = [NSColor blackColor];
	styling = name;
}
