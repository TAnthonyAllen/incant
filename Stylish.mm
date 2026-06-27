#include <Cocoa/Cocoa.h>
#include <string.h>
#include <stdio.h>
#include <Foundation/Foundation.h>
#include "OCroutines.h"
#include "GroupItem.h"
#include "CharSet.h"
#include "Buffer.h"
#include "GroupRules.h"
#include "GroupControl.h"
#include "GroupBody.h"
#include "PLGset.h"
#include "GroupDraw.h"
#include "Stylish.h"

/***************************************************************************
	Converts a color hex code into a color object
***************************************************************************/
extern "C" GroupItem *setColor(GroupItem *input)
{
GroupRules 		*ruler = GroupControl::groupController->groupRules;
char 			*atPart = input->getText();
unsigned int 	red = 0;
unsigned int 	blue = 0;
unsigned int 	green = 0;
NSColor 		*color = 0;
GroupItem 		*hexSet = ruler->properties->get("hexSet");
CharSet 		*set = hexSet->getCharacterSet();
	if ( atPart && *atPart == '#' )
		atPart++;
	// cOLOr registry stores #rrggbb; skip the '#'
	red = set->contains(atPart);
	if ( !red || ::strlen(atPart) != 6 )
		::printf("ERROR: expected a valid six character hex string not:%s\n",atPart);
	else {
		ruler->stringBUFFER->reset();
		ruler->stringBUFFER->appendString(atPart,0,0);
		atPart = ruler->stringBUFFER->start + 4;
		::sscanf(atPart,"%x",&green);
		*atPart = 0;
		atPart = ruler->stringBUFFER->start + 2;
		::sscanf(atPart,"%x",&blue);
		*atPart = 0;
		atPart = ruler->stringBUFFER->start;
		::sscanf(atPart,"%x",&red);
		ruler->stringBUFFER->reset();
		color = [NSColor colorWithCalibratedRed:(double)red green:(double)blue blue:(double)green alpha:1.0];
		hexSet->setObject((NSObject*)color);
		}
	return input;
}

Stylish::Stylish(GroupItem *item)
{
	shadow = 0;
	formatter = 0;
	borderWidth = 0;
	radius = 0;
	transparency = 0;
	blankItem = 0;
	commaItem = 0;
	filler = 0;
	fontItem = 0;
	formatItem = 0;
	selectFill = 0;
	selectStroke = 0;
	stroker = 0;
	zeroItem = 0;
	align = 0;
	bottomBorder = 0;
	fontModified = 0;
	leftBorder = 0;
	rightBorder = 0;
	rounded = 0;
	squared = 0;
	topBorder = 0;
	texter =  ERROR FieldBody: could not find colorRegister;
	styling = item->groupBody->tag;
	createdBy = item;
	// This just zeros out everything
}

Stylish::Stylish(GroupItem *item, Stylish *source)
{
	*this = *source;
	styling = item->groupBody->tag;
	createdBy = item;
}

Stylish::Stylish(char *name)
{
	shadow = 0;
	formatter = 0;
	borderWidth = 0;
	radius = 0;
	transparency = 0;
	blankItem = 0;
	commaItem = 0;
	createdBy = 0;
	filler = 0;
	fontItem = 0;
	formatItem = 0;
	selectFill = 0;
	selectStroke = 0;
	stroker = 0;
	zeroItem = 0;
	align = 0;
	bottomBorder = 0;
	fontModified = 0;
	leftBorder = 0;
	rightBorder = 0;
	rounded = 0;
	squared = 0;
	topBorder = 0;
	texter =  ERROR FieldBody: could not find colorRegister;
	styling = name;
}
