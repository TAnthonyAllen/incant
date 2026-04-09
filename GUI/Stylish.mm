#include <Cocoa/Cocoa.h>
#include <Foundation/Foundation.h>
#include <WebKit/WebKit.h>
#include <string.h>
#include <stdio.h>
#include "GroupItem.h"
#include "OCroutines.h"
#include "GroupControl.h"
#include "Details.h"
#include "Bwana.h"
#include "Stylish.h"

/*******************************************************************************
	Assign the style named in the item passed in as the current style. If there
	is no named style, create one.
*******************************************************************************/
GroupItem *sTYLE(GroupItem *item)
{
Details 	*detail = ::getDetail(item);
char 		*name = item->getText();
GroupItem 	*styles = GroupControl::registries->get("sTYLEs");
GroupItem 	*styleItem = 0;
	if ( !styles )
		{
		::fprintf(stderr,"ERROR in %s: could not find sTYLEs registry\n",detail->wig->tag);
		return 0;
		}
	if ( !name )
		{
		::fprintf(stderr,"ERROR in %s: style attribute has to specify a name\n",detail->wig->tag);
		return 0;
		}
	if ( styleItem = styles->get(name) )
		{
		if ( !styleItem->getPointer() )
			{
			if ( detail->style )
				detail->style = new Stylish(detail->wig,detail->style);
			else	detail->style = new Stylish(name);
			styleItem->setPointer((void*)detail->style);
			}
		else	detail->style = (Stylish*)styleItem->getPointer();
		return 0;
		}
	detail->setStyle();
	detail->style->styling = name;
	styleItem = GroupControl::groupController->itemFactory(name);
	styleItem->setPointer((void*)detail->style);
	styles->addGroup(styleItem);
	return 0;
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
	texter = GroupControl::groupController->colorRegister->get("black");
	styling = item->tag;
	createdBy = item;
	// This just zeros out everything
}

Stylish::Stylish(GroupItem *item, Stylish *source)
{
	*this = *source;
	styling = item->tag;
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
	texter = GroupControl::groupController->colorRegister->get("black");
	styling = name;
}
