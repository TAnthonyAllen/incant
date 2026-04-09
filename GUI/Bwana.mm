#include <Cocoa/Cocoa.h>
#include <WebKit/WebKit.h>
#include <Foundation/Foundation.h>
#include <string.h>
#include <stdio.h>
#include "GroupItem.h"
#include "OCroutines.h"
#include "StringRoutines.h"
#include "GroupList.h"
#include "GroupRules.h"
#include "DrawPoint.h"
#include "Buffer.h"
#include "Control.h"
#include "GroupControl.h"
#include "PLGparse.h"
#include "Details.h"
#include "Stak.h"
#include "ParseXML.h"
#include "DoubleLinkList.h"
#include "DoubleLink.h"
#include "PLGitem.h"
#include "BaseHash.h"
#include "Source.h"
#include "Groups.h"
#include "Layout.h"
#include "Stylish.h"
#include "Actions.h"
#include "Bwana.h"

/*******************************************************************************
	set an action
*******************************************************************************/
GroupItem *aCTION(GroupItem *item)
{
Details 	*detail = ::getDetail(item);
char 		*name = item->getText();
	if ( !detail->wig )
		::fprintf(stderr,"ERROR no parent found when assigning action for %s\n",item->getTagXML());
	else
	if ( name )
		{
		// Note: this sets action on the attribute not the parent
		::setAction(item,name);
		return 0;
		}
	else	::fprintf(stderr,"ERROR could not find action in %s\n",detail->wig->getTagXML());
	return 0;
}

/*******************************************************************************
	Build a bigify layout block. This is an immediate action that gets run
    upon load.
*******************************************************************************/
GroupItem *bIGIFY(GroupItem *trait)
{
GroupItem 	*group = 0;
GroupItem 	*attr = 0;
GroupItem 	*bigify = trait->parent;
if ( !bigify )
		{
		::fprintf(stderr,"bIGIFY ERROR: bigify does not exist\n");
		return 0;
		}
GroupItem 	*bigColumns = bigify->getAttribute("bigColumns");
GroupItem 	*bigRows = bigify->getAttribute("bigRows");
GroupItem 	*columns = bigify->getAttribute("columns");
GroupItem 	*rows = bigify->getAttribute("rows");
GroupItem 	*bigItem = GroupControl::groupController->groupParser->locate("bigItem");
GroupItem 	*regularItem = GroupControl::groupController->groupParser->locate("regularItem");
GroupItem 	*regularRow = GroupControl::groupController->groupParser->locate("regularRow");
GroupItem 	*bigColumn = GroupControl::groupController->groupParser->locate("bigColumn");
GroupItem 	*biggie = 0;
GroupItem 	*bigRow = 0;
	/***************************************************************************
	Sanity checks
	***************************************************************************/
if ( !bigColumn )
		{
		::fprintf(stderr,"bIGIFY ERROR: bigColumn does not exist\n");
		return 0;
		}
if ( !bigItem )
		{
		::fprintf(stderr,"bIGIFY ERROR: bigItem does not exist\n");
		return 0;
		}
if ( !regularItem )
		{
		::fprintf(stderr,"bIGIFY ERROR: regularItem does not exist\n");
		return 0;
		}
if ( !bigColumns )
		{
		::fprintf(stderr,"bIGIFY ERROR: bigColumns does not exist\n");
		return 0;
		}
if ( !bigRows )
		{
		::fprintf(stderr,"bIGIFY ERROR: bigRows does not exist\n");
		return 0;
		}
if ( !columns )
		{
		::fprintf(stderr,"bIGIFY ERROR: columns does not exist\n");
		return 0;
		}
if ( !regularRow )
		{
		::fprintf(stderr,"bIGIFY ERROR: regularRow does not exist\n");
		return 0;
		}
if ( !rows )
		{
		::fprintf(stderr,"bIGIFY ERROR: rows does not exist\n");
		return 0;
		}
int 		regularRows = rows->getCount() - bigRows->getCount();
int 		regularColumns = columns->getCount() - bigColumns->getCount();
int 		totalItems = 1 + regularRows * columns->getCount() + regularColumns * (rows->getCount() - regularRows);
int 		j = 0;
int 		col = 0;
int 		current = 0;
char 		*name = 0;
	/***************************************************************************
	Bigification starts here
	***************************************************************************/
	while ( current < totalItems )
		{
		if ( bigRow )
			goto processRow;
		/***********************************************************************
		Create big row wrapper
		***********************************************************************/
		if ( !bigRow )
			{
			bigRow = GroupControl::groupController->groupParser->locate("bigRow");
if ( !bigRow )
				{
				::fprintf(stderr,"bIGIFY ERROR: bigRow does not exist\n");
				return 0;
				}
			bigRow = bigify->addGroup(bigRow);
			group = bigRow->getAttribute("height");
			group->setCount(100 * bigRows->getCount() / rows->getCount());
			group->isPercent = 1;
			}
		/***********************************************************************
		Fill big row w/component columns
		***********************************************************************/
		while ( col < regularColumns )
			{
			GroupItem 	*columny = bigRow->addGroup(bigColumn);
			//cout "bIGIFY: processing big column",current:;
			name = ::concat(2,"column",::toStringFromInt(current));
			j = bigRows->getCount();
			columny->tag = name;
			while ( j-- )
				{
				attr = columny->addGroup(regularItem);
				current++;
				}
			col++;
			}
		if ( !biggie )
			{
			//cout "bIGIFY: processing big item",current:;
			biggie = bigRow->addGroup(bigItem);
			biggie = biggie->getAttribute("width");
			biggie->setCount(100 * bigColumns->getCount() / columns->getCount());
			biggie->isPercent = 1;
			current++;
			}
		continue;
		/***********************************************************************
		Build a regular row
		***********************************************************************/
processRow:
		//cout "bIGIFY: processing regular row",current:;
		name = ::concat(2,"row",::toStringFromInt(current));
		group = bigify->addGroup(regularRow);
		group->tag = name;
		j = columns->getCount();
		// regularItem gets copied when it is added
		while ( j-- )
			{
			attr = group->addGroup(regularItem);
			current++;
			}
		}
	return 0;
}

/*******************************************************************************
	Make parent a buffer block
*******************************************************************************/
GroupItem *bUFFER(GroupItem *item)
{
	item->noPrint = 1;
	if ( item->parent )
		{
		Buffer 	*buffet = ::bufferFactory1();
		item->parent->setBuffer(buffet);
		}
	return 0;
}

/*******************************************************************************
	Make block a canvas
*******************************************************************************/
GroupItem *cANVAS(GroupItem *item)
{
	item->setText(item->parent->tag);
	item->tag = "id";
	item->copied = 0;
	item->registry = 0;
	item->parent->tag = "canvas";
	return 0;
}

/*******************************************************************************
	Collapse a previously expanded row of a matrix
*******************************************************************************/
GroupItem *cOLLAPSErow(GroupItem *item)
{
Details 	*wrapDetail = 0;
Details 	*detail = ::getDetail(item);
GroupItem 	*group = 0;
GroupItem 	*firstItem = 0;
GroupItem 	*wrapper = 0;
if ( !item->expanded )
		{
		::fprintf(stderr,"cOLLAPSErow ERROR: Cannot collapse row. It was not expanded.\n");
		return 0;
		}
	item->expanded = 0;
	for ( wrapper = detail->wig; wrapper; wrapper = wrapper->parent )
		if ( ::compare(wrapper->tag,"wrapper") == 0 )
			break;
	// Note the avoidance of commas in the 3rd argument below
if ( !wrapper )
		{
		::fprintf(stderr,"cOLLAPSErow ERROR: Could not find expand block for %s %s\n",detail->wig->tag,detail->wig->getText());
		return 0;
		}
	/***************************************************************************
	Default case, totals first
	***************************************************************************/
	firstItem = wrapper->nextMember(firstItem);
	wrapper->remove(firstItem);
	group = wrapper->parent;
	wrapper->replaceWith(firstItem);
	wrapDetail = ::getDetail(wrapper);
	wrapDetail->wig = wrapper;
	wrapper = wrapper->parent;
	// Check case where totals last or no totals
	return 0;
}

/*******************************************************************************
	This is an onLoad method that gets added to the pROPERTIEs registry to link
    properties that have css equivalents.
*******************************************************************************/
GroupItem *cssOnLoad(GroupItem *item)
{
GroupItem 	*cssGroup = 0;
char 		*cssName = item->getText();
	if ( cssName )
		if ( cssGroup = GroupControl::groupController->cssRegister->getMember(cssName) )
			item->setGroup(cssGroup);
	return item;
}

/*******************************************************************************
	Set the text of item parent to the description of the last selection.
*******************************************************************************/
GroupItem *dESCRIBE(GroupItem *item)
{
Details 	*selectDetail = 0;
Details 	*detail = ::getDetail(item);
GroupItem 	*last = 0;
GroupItem 	*group = 0;
char 		*blurb = 0;
char 		*name = item->getText();
	detail->setStyle();
	if ( detail->wig->getAttribute("text") )
		::fprintf(stderr,"Warning at block: %s\n\tDo not need (or want) text attribute if describe specified\n",detail->wig->tag);
	else {
		GroupControl::groupController->groupParser->jsonType = 1;
		detail->isDisplayable = 1;
		detail->editable = 0;
		}
	if ( !name && !GroupControl::groupController->groupParser->lastSelect )
		name = detail->wig->tag;
	detail->wig->setText("");
	/***************************************************************************
	First time thru: if there is a descriptions registry add a reaction to
	this block to fire this method when any block gets selected.
	Every other time thru: look up the selection in the descriptions registry
	and if found, set text for this block and its display to the
	description text.
	***************************************************************************/
	if ( Control::bwana->descriptions && Control::bwana->descriptions->parts->length )
		{
		if ( !detail->attributed )
			{
			detail->hasReactions = 1;
			item->reacts = 1;
			Control::bwana->selectSource->addListener(detail->wig);
			}
		group = detail->wig->getAttribute("describeAny");
		/***********************************************************************
		The following statement checks to make sure we are only describing
		things that apply to the current view.
		***********************************************************************/
		if ( GroupControl::groupController->groupParser->lastSelect && !group )
			if ( selectDetail = ::getDetail(GroupControl::groupController->groupParser->lastSelect) )
				if ( detail->attributed && selectDetail->view != detail->view )
					return 0;
		/***********************************************************************
		The check of attributed is to make sure things happen properly on
		selection (once attributed) and also on first time thru
		***********************************************************************/
		if ( detail->attributed )
			for ( last = GroupControl::groupController->groupParser->lastSelect; last; last = last->parent )
				{
				name = last->tag;
				if ( group = Control::bwana->descriptions->get(name) )
					break;
				}
		else
		if ( name = item->getText() )
			;
		else	name = detail->wig->tag;
		if ( name )
			group = Control::bwana->descriptions->get(name);
		if ( group )
			{
			blurb = group->getText();
			if ( !blurb )
				{
				GroupItem 	*description = group->get("description");
				if ( description )
					group = description;
				}
			}
		else
		if ( !last )
			group = Control::bwana->descriptions->get(name);
		/***********************************************************************
		At this point group should be block to be described
		***********************************************************************/
		if ( group )
			{
			if ( (group->data == 6) )
				detail->wig->setItem(group->getItem());
			else
			if ( blurb )
				detail->wig->setText(blurb);
			}
		else	detail->wig->setText(name);
		::setModified(detail->wig);
		}
	//cout `"Setting description of " name " for " wig.tag,"to":``blurb:;
	return 0;
}

/*******************************************************************************
	Load a delimited list file into the current block. In the following method,
    the block that load returns is wig populated w/records from the list file.
*******************************************************************************/
GroupItem *delimitFILE(GroupItem *item)
{
Details 	*detail = ::getDetail(item);
GroupItem 	*block = 0;
	block = GroupControl::groupController->groupParser->loadDelimited(detail->wig);
	::printf("Loading delimited file into %s\n",detail->wig->tag);
if ( !block )
		{
		::fprintf(stderr,"delimitFILE ERROR: Failed to load file for %s\n",detail->wig->tag);
		return 0;
		}
	return 0;
}

/*******************************************************************************
	Expand a tree after it has been collapsed.
*******************************************************************************/
GroupItem *expandTREE(GroupItem *item)
{
GroupItem 	*branch = 0;
GroupItem 	*expandedRow = 0;
GroupItem 	*part = 0;
GroupItem 	*group = 0;
GroupItem 	*row = 0;
int 		indentWidth = 0;
	/***************************************************************************
	Figure out the indent
	***************************************************************************/
	if ( group = item->findAttribute("indentIncrement") )
		indentWidth = group->getCount();
	else	indentWidth = 10;
	if ( part = item->getMember("indent") )
		if ( part = part->getAttribute("width") )
			indentWidth += part->getCount();
	/***************************************************************************
	Embed item in a wrapper and expand
	***************************************************************************/
	expandedRow = GroupControl::groupController->itemFactory(item);
	item->tag = "wrapper";
	item->parts->clear();
	item->mergeIfFound("matrixRowWrapper");
	item->addAttrString("border","off");
	item->addGroup(expandedRow);
	group = item->getGroup();
if ( !group )
		{
		::fprintf(stderr,"expandTREE ERROR: leaf expand group not found\n");
		return 0;
		}
	while ( branch = group->nextMember(branch) )
		{
		row = GroupControl::groupController->itemFactory(expandedRow->tag);
		row->merge(expandedRow);
		row->setGroup(branch);
		item->addGroup(row);
		if ( part = row->getMember("indent") )
			{
			part->clearAttributes();
			part->addAttrInt("width",indentWidth);
			}
		if ( part = row->getMember("entry") )
			part->setGroup(branch);
		}
	//cout :"expandTREE":item:;
	expandedRow->expanded = 1;
	return 0;
}

/*******************************************************************************
	Turn on detail flags
*******************************************************************************/
GroupItem *flagFIELD(GroupItem *item)
{
Details 	*detail = ::getDetail(item);
char 		*text = item->getText();
	detail->setStyle();
	switch (*item->tag)
		{
		case 'b':
			detail->style->blankItem = item;
			break;
		case 'c':
			detail->style->commaItem = item;
			if ( detail->style->formatter && text )
				{
				[detail->style->formatter setHasThousandSeparators:(BOOL)1];
				[detail->style->formatter setThousandSeparator:[NSString stringWithCString:text encoding:NSASCIIStringEncoding]];
				}
			break;
		case 'd':
			detail->noScroll = 1;
			break;
		case 'e':
			detail->editable = 1;
			break;
		case 'k':
			// key (used in sorted lists when deciding to show repeated attributes)
			if (::compare(item->tag,"keyAction") == 0)
				item->keyAction = 1;
			else	detail->keyField = 1;
			break;
		case 'n':
			// do not set selectSource
			detail->view->noSelectSource = 1;
			break;
		case 's':
			// selectable
			if ( ::compare(item->tag,"selectable") == 0 )
				if ( item->getText() )
					{
					if ( !detail->wig->parent )
						detail->view->notSelectable = 1;
					detail->selectable = 0;
					}
				else	detail->selectable = 1;
			break;
		case 'z':
			detail->style->zeroItem = item;
		}
	return 0;
}

/*******************************************************************************
	process an image attribute and set the default image action
*******************************************************************************/
GroupItem *iMAGE(GroupItem *item)
{
char 		*fileName = 0;
Details 	*detail = ::getDetail(item);
GroupItem 	*group = 0;
GroupItem 	*file = 0;
GroupItem 	*directory = 0;
	//cout "iMAGE: processing",wig.tag:;
	detail->content = 3;
	detail->imageSized = 1;
	/***************************************************************************
	If image has text, assume it is the name of the file containing the image.
	Otherwise, look for directory and file attributes and if found, construct
	the file name containing the image.
	***************************************************************************/
	if ( detail->sourced )
		{
		if ( group = detail->wig->getGroup() )
			if ( group->data )
				fileName = group->getText();
			else
			if ( file = group->get("file") )
				if ( directory = group->get("directory") )
					fileName = ::concat(3,directory->getText(),"/",file->getText());
				else	fileName = file->getText();
		}
	else
	if ( item->data )
		fileName = item->getText();
	else
	if ( file = detail->wig->findAttribute("file") )
		if ( directory = detail->wig->findAttribute("directory") )
			fileName = ::concat(3,directory->getText(),"/",file->getText());
		else	fileName = file->getText();
	if ( !fileName )
		::fprintf(stderr,"iMAGE: file name not found for %s\n",detail->wig->getTagXML());
	item->setText(fileName);
	// image creation moved to Layout displayImage()
	detail->view->displayStack->push((void*)item);
	// draw = @displayImage;
	::setModified(detail->wig);
	::setAction(item,"iMAGEwork");
	return 0;
}

NSRect indent(NSRect f, double b)
{
	return ::NSMakeRect(f.origin.x + b,f.origin.y + b,f.size.width - 2 * b,f.size.height - 2 * b);
}

NSRect indent(NSRect f, double v, double h)
{
	return ::NSMakeRect(f.origin.x + v,f.origin.y + h,f.size.width - 2 * v,f.size.height - 2 * h);
}

/*******************************************************************************
	Convenience method to get a key code entered in the block passed in. Need
    this because Objective-C calls not working in jit (and unlike the
    event keyCode method this does not crap out if event not a key event.
*******************************************************************************/
char *keyCode(GroupItem *item)
{
Details 	*detail = ::getDetail(item);
char 		*text = 0;
	if ( detail->event && [detail->event type] == 11 )
		{
		text = ::toString([detail->event charactersIgnoringModifiers]);
		if ( !::strlen(text) )
			text = ::toStringFromInt([detail->event keyCode]);
		}
	return text;
}

/*******************************************************************************
    Process key stroke specification
*******************************************************************************/
GroupItem *keySTROKE(GroupItem *item)
{
Details 	*detail = ::getDetail(item);
	if ( !item->keyAction )
		if ( Control::bwana->extendParser->processKeySpec(item) )
			{
			item->parent->keyAction = 1;
			detail->wig->keyAction = 1;
			}
	return 0;
}

/*******************************************************************************
    Returns true if the event key stroke matches the parameter item key stroke.
*******************************************************************************/
int keyStrokeMatch(GroupItem *item)
{
Details 	*detail = ::getDetail(item);
char 		*keyText = ::toString([detail->event charactersIgnoringModifiers]);
GroupItem 	*group = item->findAttribute("keyStroke");
	if ( !group->modified || ([detail->event modifierFlags] & 1 << 19) )
		if ( !group->indexed || ([detail->event modifierFlags] & 1 << 18) )
			if ( !group->mustIndent || ([detail->event modifierFlags] & 1 << 20) )
				if ( !group->noAnchor || ([detail->event modifierFlags] & 1 << 17) )
					if ( group->getItem()->compare(keyText) == 0 )
						return 1;
	return 0;
}

/*******************************************************************************
	Trigger an override merge with source. The source attributes override (so
    they take effect when used in conjunction with a next attribute).
*******************************************************************************/
GroupItem *mERGE(GroupItem *item)
{
Details 	*detail = ::getDetail(item);
GroupItem 	*sourceAttribute = 0;
GroupItem 	*block = detail->wig;
Source 		*source = 0;
	while ( block )
		{
		if ( sourceAttribute = block->get("sRCe") )
			{
			source = (Source*)sourceAttribute->getPointer();
			if ( block = block->getGroup() )
				{
				//cout "Merging",block.tag,"into",wig.tag,wig.index:;
				detail->wig->mergeAttributes(block,1);
				if ( !detail->reacting )
					{
					detail->wig->merge(block);
					source->addListener(detail->wig);
					detail->hasReactions = 1;
					item->reacts = 1;
					}
				}
			break;
			}
		else	block = block->parent;
		}
	return 0;
}

/*******************************************************************************
	Sets minimum width or height.
*******************************************************************************/
GroupItem *mINIMUM(GroupItem *item)
{
	if ( ::compare(item->tag,"minimumHeight") == 0 )
		{
		Control::bwana->minimumHeight = item->getNumber();
		}
	else	Control::bwana->minimumWidth = item->getNumber();
	return 0;
}

/*******************************************************************************
	Set wig data to the next source item, if there is one.
*******************************************************************************/
GroupItem *nEXT(GroupItem *item)
{
Details 	*contentDetails = 0;
Details 	*detail = ::getDetail(item);
Source 		*source = 0;
GroupItem 	*content = 0;
GroupItem 	*sourceAttribute = 0;
GroupItem 	*block = 0;
char 		*name = 0;
	//cout ``"nEXT test1:",wig.tag,attributed,wig.index:;
	if ( name = item->getText() )
		{
		if ( block = detail->wig->findParent(name) )
			if ( sourceAttribute = block->getAttribute("sRCe") )
				source = (Source*)sourceAttribute->getPointer();
		if ( source )
			{
			if ( !detail->sourced )
				{
				// source attribute may have been copied and we need a new one
				if ( sourceAttribute = detail->wig->getAttribute("sRCe") )
					detail->wig->remove(sourceAttribute);
				sourceAttribute = detail->wig->addAttrValue("sRCe",(void*)source);
				detail->sourced = 1;
				content = item;
				/***************************************************************
				The variable content parent gets added as a source listener
				and this item gets added to its down or across attribute
				(which has * value) and the attribute has setFLEXcontent
				set as its action method. When you scroll, the source fires
				the listeners, setFLEXcontent runs, which ends up running
				this nEXT method to update the displayed value.
				***************************************************************/
				while ( content = content->parent )
					if ( content->noAnchor )
						{
						source->resetOnResize = 1;
						if ( (block = content->get("across")) || (block = content->get("down")) )
							{
							if ( !content->getAttribute("sRCe") )
								content->addGroup(sourceAttribute);
							if ( !content->indexed )
								{
								source->addListener(content);
								// indexed flags variable content block as source listener
								content->indexed = 1;
								if ( contentDetails = ::getDetail(content) )
									contentDetails->hasReactions = 1;
								block->reacts = 1;
								block->setMethod(::setFLEXcontent);
								}
							}
						break;
						}
				}
			block = source->next();
			detail->isNext = 1;
			if ( !block )
				{
				detail->wig->setGroup((GroupItem*)0);
				detail->noData = 1;
				::setNoRoom(detail->wig,(unsigned int)1);
				//cout ``"nEXT: no data " wig.tag,wig.index:;
				}
			else {
				detail->wig->setGroup(block);
				detail->noData = 0;
				::setNoRoom(detail->wig,(unsigned int)0);
				if ( detail->wig->getAttribute("setTag") )
					detail->wig->tag = block->tag;
				//cout ``"nEXT: " wig.tag,wig.index,source.current,block.getTagXML():;
				}
			}
		}
	else	::fprintf(stderr,"%s: source block not specified for next\n",detail->wig->tag);
	return 0;
}

/*******************************************************************************
	Process path attribute. A path list can consist of multiple paths. Each path
    is a list of draw points that get stored in a drawingPath. The drawingPaths
    are then stored in a pathSet (created in Groups buildPath method). Both
    pathSet and drawingPath are null terminated double indirection pointers
    (so the pathSet field below is a triple indirection pointer).
*******************************************************************************/
void pATH(GroupItem *item)
{
Details 	*detail = ::getDetail(item);
Buffer 		*buffer = ::bufferFactory1();
	if ( detail )
		{
		DrawPoint 	***pathSet = 0;
		item->setText(detail->wig->getText());
		Control::bwana->extendParser->drawingBlock = detail->wig;
		detail->wig->remove("boDY");
		detail->wig->hasBodyText = 0;
		if ( pathSet = Control::bwana->extendParser->buildPath(item) )
			{
			detail->wig->setBuffer(buffer);
			item->setPointer((void*)pathSet);
			detail->content = 4;
			detail->isDisplayable = 1;
			::drawPath(item);
			}
		}
	//setModified(wig);
}

/*******************************************************************************
	Set the pop up action.
*******************************************************************************/
GroupItem *popUP(GroupItem *item)
{
	::setAction(item,"display");
	return 0;
}

/*******************************************************************************
	Set up pull down block
*******************************************************************************/
GroupItem *pullDOWN(GroupItem *item)
{
GroupItem 	*menu = 0;
Details 	*detail = ::getDetail(item);
char 		*name = item->getText();
	::setAction(item,"menu");
	if ( name )
		{
		if ( menu = GroupControl::groupController->groupParser->locate(name) )
			{
			item->setGroup(menu);
			menu->addAttrGroup("pULLdOWN",detail->wig);
			}
		}
	else	::fprintf(stderr,"No pull down block found\n");
	return 0;
}

/*******************************************************************************
	Reset the root of a tree (should not need this if jit can read a boolean).
*******************************************************************************/
GroupItem *resetTREE(GroupItem *item)
{
Details 	*detail = ::getDetail(item);
	detail->sourced = 0;
	tREE(item);
	return 0;
}

/*******************************************************************************
	associate current action w/right mouse button
*******************************************************************************/
GroupItem *rightCLICK(GroupItem *item)
{
Details 	*detail = ::getDetail(item);
char 		*name = item->getText();
	if ( detail->wig )
		{
		if ( name )
			::setAction(item,name);
		detail->wig->rightClick = 1;
		}
	else	::fprintf(stderr,"ERROR no parent found when assigning right click action for %s\n",item->getTagXML());
	return 0;
}

/*******************************************************************************
	Set source to the selection (two flavors, one for attributes, one for
    members depending on whether or not there is an attributes attribute.
    The parent of item is set to listen to the selected source.
*******************************************************************************/
GroupItem *sELECTsource(GroupItem *item)
{
Details 	*detail = ::getDetail(item);
Source 		*source = 0;
GroupItem 	*group = 0;
	source = Control::bwana->selectSource;
	group = detail->wig->addAttrValue("sRCe",(void*)source);
	group->noPrint = 1;
	detail->sourced = 1;
	source->addListener(detail->wig);
	return 0;
}

/*******************************************************************************
	Display the parent of the item passed in as argument if the group identified
    by the item text has data (for example, if the item passed in is the attribute
    show=something, something is the group that either has or does not have data
    to be displayed). If the group has data to display, the noRoom flag of the
    item parent, is set false, otherwise it is set to true.
*******************************************************************************/
GroupItem *sHOW(GroupItem *item)
{
GroupItem 	*sourceAttribute = 0;
GroupItem 	*block = 0;
GroupItem 	*group = 0;
Source 		*source = 0;
Details 	*detail = ::getDetail(item);
int 		flag = 1;
char 		*name = item->getText();
	if ( !detail )
		return 0;
	sourceAttribute = detail->wig->findAttribute("sRCe");
	//checkError(sHOW,!sourceAttribute,"could not find source for " wig.getTagXML());
	if ( !sourceAttribute )
		{
		::fprintf(stderr,"sHOW could not find source for %s\n",detail->wig->getTagXML());
		return 0;
		}
	if ( !detail->attributed )
		{
		source = (Source*)sourceAttribute->getPointer();
		if ( !detail->sourced )
			{
			source->addListener(detail->wig);
			detail->sourced = 1;
			}
		detail->hasReactions = 1;
		item->reacts = 1;
		}
	if ( block = sourceAttribute->parent )
		block = block->getGroup();
	if ( name )
		group = detail->wig->get(name);
	else	group = detail->wig;
	if ( block && !(group->getAttribute("value") && !block->getText()) )
		flag = 0;
	::setNoRoom(detail->wig,(unsigned int)flag);
	//cout "Show: " wig.tag,block ? block.text : "no text",flag:;
	return 0;
}

/*******************************************************************************
	Locate the block named by the item passed in and set the wig sRCe attribute
    to point to the source derived from that bloc.
*******************************************************************************/
GroupItem *sOURCE(GroupItem *item)
{
GroupItem 	*block = 0;
GroupItem 	*entry = item->parent;
GroupItem 	*group = 0;
GroupItem 	*nextBlock = 0;
GroupItem 	*oldAttribute = 0;
GroupItem 	*sourceBlock = 0;
GroupItem 	*sourceRegister = 0;
GroupItem 	*useNext = 0;
Source 		*source = 0;
char 		*name = item->getText();
Details 	*blockDetail = 0;
Details 	*detail = ::getDetail(item);
int 		isNext = 0;
	//cout `"sOURCE: test1" wig.tag,item:;
	if ( name )
		{
		if ( ::compare(name,"selected") == 0 )
			{
			::sELECTsource(item);
			return 0;
			}
		if ( sourceRegister = GroupControl::registries->get(name) )
			block = sourceRegister;
		else	block = GroupControl::groupController->groupParser->locate(item);
		if ( block )
			{
			blockDetail = ::getDetail(block);
			sourceBlock = block->getAttribute("sRCe");
			if ( blockDetail )
				isNext = blockDetail->isNext;
			if ( sourceBlock && !isNext )
				source = (Source*)sourceBlock->getPointer();
			else {
				useNext = entry->get("useNext");
				if ( isNext && useNext )
					nextBlock = block->getGroup();
				/***************************************************************
				There is no source associated with the named block so
				create one for the block. If source is not loaded, load it.
				***************************************************************/
				if ( block->get("list") && !block->loaded )
					Control::bwana->controller->load(block);
				if ( useNext )
					if ( nextBlock )
						source = new Source(nextBlock);
					else	source = Control::bwana->emptySource;
				else	source = new Source(block);
				if ( entry->getAttribute("useAttributes") )
					source->sourceAttributes = 1;
				/***************************************************************
				If there is a sRCe attribute, it is a copy and we have to
				remove it or we will screw up the source in the copy
				***************************************************************/
				if ( oldAttribute = entry->getAttribute("sRCe") )
					entry->remove(oldAttribute);
				group = entry->addAttrValue("sRCe",(void*)source);
				group->noPrint = 1;
				if ( detail )
					{
					detail->sourced = 1;
					if ( !Control::bwana->sourceList )
						Control::bwana->sourceList = new DoubleLinkList();
					Control::bwana->sourceList->add(source);
					}
				//cout "Source " entry.tag,entry.index,sourceItem.tag:;
				}
			}
		else	::fprintf(stderr,"Could not find a source named %s\n",name);
		}
	else {
		/***********************************************************************
		Source name not specified so set source to entry (parent of item).
		***********************************************************************/
		source = new Source(entry);
		if ( entry->getAttribute("useAttributes") )
			source->sourceAttributes = 1;
		group = entry->addAttrValue("sRCe",(void*)source);
		group->noPrint = 1;
		if ( detail )
			detail->sourced = 1;
		}
	return 0;
}

/*******************************************************************************
	Associates groups that get scrolled along with this one.
*******************************************************************************/
GroupItem *scrollWITH(GroupItem *item)
{
GroupItem 	*scroller = 0;
GroupItem 	*target = 0;
GroupItem 	*scrollBlock = item->parent;
char 		*name = item->getText();
	if ( scrollBlock )
		{
		/***********************************************************************
		scrollWith attribute identifies the block it scrolls with in its text.
		It looks for the block using the simplePath method first and if that
		does not work it tries the locate method that looks thru the
		current registry and then thru the registry search list.
		At the end of this, each scrollWith attribute is set to point to
		the other scrollWith parent;
		***********************************************************************/
		scrollBlock->doNotChangeParent = 1;
		if ( !(target = GroupControl::groupController->groupParser->simplePath(item)) )
			target = GroupControl::groupController->groupParser->locate(name);
		if ( target )
			{
			if ( !(scroller = target->getAttribute("scrollWith")) )
				{
				scroller = target->addString("scrollWith");
				scroller->setGroup(item);
				}
			// add this block to the scroll list
			scroller->addGroup(scrollBlock);
			item->setGroup(scroller);
			}
		else	::fprintf(stderr,"scrollWith could not locate %s\n",name);
		scrollBlock->doNotChangeParent = 0;
		}
	else	::fprintf(stderr,"scrollWith: missing scroll block\n");
	return 0;
}

/*******************************************************************************
	Set the initial card. In Details setFrame it is set to the first card,
    however, if the cards attribute has a value, that value is taken to be the
    name of the card that should be initially displayed and that is set here.
*******************************************************************************/
GroupItem *setCARD(GroupItem *item)
{
Details 	*detail = ::getDetail(item);
GroupItem 	*deck = item->parent;
GroupItem 	*group = 0;
GroupItem 	*page = 0;
char 		*name = item->getText();
	//cout "setCARD:",item:;
	detail->pane = 1;
	/***************************************************************************
	If item, the cards attribute, has no text, we bail and the first card is
	kept as the default. If item has text, we assume it is the name of the
	card to be shown initially and set things accordingly.
	***************************************************************************/
if ( !deck )
		{
		::fprintf(stderr,"setCARD ERROR: invalid deck passed in\n");
		return 0;
		}
	if ( !name )
		{
		page = deck->firstMember();
if ( !page )
			{
			::fprintf(stderr,"setCARD ERROR: could not set card\n");
			return 0;
			}
		}
	else {
		page = deck->get(name);
if ( !page )
			{
			::fprintf(stderr,"setCARD ERROR: could not find card %s\n",name);
			return 0;
			}
		}
	/***************************************************************************
	All the cards except page get turned off
	page is the new current card being turned on
	***************************************************************************/
	while ( group = deck->nextMember(group) )
		::setNoRoom(group,(unsigned int)1);
	item->setGroup(page);
	::setNoRoom(page,(unsigned int)0);
	return 0;
}

/*******************************************************************************
	Sets the expander indicator for trees.
*******************************************************************************/
GroupItem *setExpander(GroupItem *item)
{
GroupItem 	*expander = 0;
GroupItem 	*group = 0;
GroupItem 	*leaf = 0;
GroupItem 	*source = 0;
GroupItem 	*templates = 0;
	if ( GroupControl::registries )
		templates = GroupControl::registries->get("tEMPLATEs");
	if ( templates )
		while ( group = item->walk(group) )
			if ( ::compare(group->tag,"expander") == 0 )
				if ( leaf = group->findAttribute("leaf") )
					if ( leaf = leaf->parent )
						if ( source = leaf->getGroup() )
							{
							if ( source->hasMembers )
								if ( leaf->expanded )
									expander = templates->getMember("expanded");
								else	expander = templates->getMember("expandable");
							if ( expander )
								group->setGroup(expander);
							else	group->setText("");
							expander = 0;
							}
	return 0;
}

/*******************************************************************************
	Set modified for the block passed in and mark its view as not drawn
*******************************************************************************/
void setModified(GroupItem *block)
{
Details 	*detail = ::getDetail(block);
	if ( detail )
		{
		//cout "setModified: for",wig.tag:;
		detail->view->laidout = 0;
		detail->view->drawn = 0;
		block->modified = 1;
		[detail->view setNeedsDisplay:1];
		}
}

/*******************************************************************************
	Set sort parameters and add sort action
*******************************************************************************/
GroupItem *setSORT(GroupItem *item)
{
	if ( item->data )
		{
		item->addString(item->getText());
		//cout "sort " item.getTagXML():;
		::setAction(item,"sORT");
		}
	else	::fprintf(stderr,"sort attribute not specified\n");
	return 0;
}

/*******************************************************************************
    Set the source associated with group to the item passed in
*******************************************************************************/
GroupItem *setSourceTo(GroupItem *group, GroupItem *item)
{
GroupItem 	*sourceAttribute = group->getAttribute("sRCe");
GroupItem 	*sourceBlock = (item->data == 5) ? item->getGroup() : item;
Source 		*source = 0;
Details 	*detail = ::getDetail(item);
if ( !group )
		{
		::fprintf(stderr,"setSourceTo ERROR: no group provided\n");
		return 0;
		}
if ( !sourceBlock )
		{
		::fprintf(stderr,"setSourceTo ERROR: no source target provided\n");
		return 0;
		}
	if ( sourceAttribute )
		source = (Source*)sourceAttribute->getPointer();
	else {
		source = new Source(sourceBlock);
		group->addAttrValue("sRCe",(void*)source);
		if ( detail )
			detail->sourced = 1;
		}
	source->setSourceItem(sourceBlock);
	::setModified(item);
	return 0;
}

/*******************************************************************************
	Set the selected tab and associated tab body on initial layout.
*******************************************************************************/
GroupItem *tABS(GroupItem *item)
{
GroupItem 	*selectTab = 0;
GroupItem 	*tab = 0;
GroupItem 	*tabBody = 0;
GroupItem 	*tabBlock = 0;
char 		*name = 0;
Details 	*detail = ::getDetail(item);
	detail->pane = 4;
	if (name = item->getText())
		selectTab = detail->wig->getMember(name);
	if ( !selectTab )
		selectTab = detail->wig->nextMember(tabBlock);
	if ( !selectTab )
		{
		::fprintf(stderr,"Could not find first tab for %s\n",detail->wig->tag);
		return 0;
		}
	detail->wig->setPointer((void*)selectTab);
	detail->view->selection = selectTab;
	selectTab->processUpTo = 1;
	if ( !GroupControl::groupController->groupParser->currentRegistry )
		{
		::fprintf(stderr,"Registry not set\n\tTab body blocks must be registered\n");
		return 0;
		}
	// Loop thru tabs setting pointer to tab body
	while ( tabBlock = detail->wig->nextMember(tabBlock) )
		{
		GroupItem 	*card = 0;
		if ( tabBody = tabBlock->getAttribute("tabBODY") )
			if (name = tabBody->getText())
				{
				card = GroupControl::groupController->groupParser->currentRegistry->get(name);
				if ( tabBlock == selectTab )
					tab = card;
				}
		if ( !card )
			{
			::fprintf(stderr,"Could not find body for tag %s\n",card->tag);
			return 0;
			}
		tabBody->setGroup(card);
		}
	// set the cards attribute for tab bodies
	if ( tabBody = tab->parent )
		if ( tabBlock = tabBody->get("cards") )
			tabBlock->setText(tab->tag);
		else	tabBody->addAttrString("cards",tab->tag);
	else	::fprintf(stderr,"tABS: could not set cards for tab body block\n");
	detail = ::getDetail(selectTab);
	detail->setStyle();
	if ( detail->style && (detail->style->selectFill || detail->style->selectStroke) )
		{
if ( detail->style->filler && detail->style->selectFill )
			{
			detail->view->storage->setDataFrom(detail->style->filler);
			detail->style->filler->setDataFrom(detail->style->selectFill);
			detail->style->selectFill->setDataFrom(detail->view->storage);
			}
if ( detail->style->stroker && detail->style->selectStroke )
			{
			detail->view->storage->setDataFrom(detail->style->stroker);
			detail->style->stroker->setDataFrom(detail->style->selectStroke);
			detail->style->selectStroke->setDataFrom(detail->view->storage);
			}
		//cout "tABS:" filler.getTagXML():;
		}
	return 0;
}

/*******************************************************************************
	Set the detail tag to the tag of the source. Used to access the tag or value
    of sourced content (as opposed to accessing an attribute - see tRAIT).
*******************************************************************************/
GroupItem *tAG(GroupItem *item)
{
Details 	*sourceDetail = 0;
Details 	*detail = ::getDetail(item);
GroupItem 	*sourceAttribute = 0;
GroupItem 	*block = 0;
Source 		*source = 0;
	//cout "tAG: " wig.index, wig.getTagXML():;
	if ( sourceAttribute = item->findAttribute("sRCe") )
		{
		source = (Source*)sourceAttribute->getPointer();
		if ( sourceAttribute->parent )
			{
			sourceDetail = ::getDetail(sourceAttribute->parent);
			if ( sourceDetail->noData )
				goto bailTAG;
			if ( block = sourceAttribute->parent->getGroup() )
				;
			else
			if ( GroupControl::groupController->groupParser->lastSelect )
				if ( block = GroupControl::groupController->groupParser->lastSelect->getGroup() )
					;
				else	block = GroupControl::groupController->groupParser->lastSelect;
			}
		}
	if ( block )
		{
		detail->wig->setText((char*)0);
		if (*item->tag == 't')
			detail->useTagForLabel = 1;
		detail->wig->setGroup(block);
		}
	else
	if ( source && source->sourceItem )
		detail->wig->setText(source->sourceItem->resolvedTag());
	else	detail->wig->setText("Nothing selected");
bailTAG:
	if ( !detail->attributed )
		{
		if ( source )
			source->addListener(detail->wig);
		detail->hasReactions = 1;
		item->reacts = 1;
		}
	return 0;
}

/*******************************************************************************
	Set the detail passed in as text. Note: text applies to blocks and modified
    gets set to false when a block gets drawn.
*******************************************************************************/
void tEXT(GroupItem *item)
{
GroupItem 	*block = 0;
Details 	*sourceDetail = 0;
Details 	*detail = ::getDetail(item);
char 		*name = *item->tag == 't' ? item->getText() : 0;
	if ( detail->attributed && detail->wig->modified )
		{
		detail->changeText();
		return;
		}
	if ( detail->hasReactions )
		item->reacts = 1;
	if ( detail && item )
		{
		detail->content = 5;
		detail->editable = 0;
		// default is not editable but how to change???
		detail->isDisplayable = 1;
		if ( name )
			{
			block = detail->wig->registry->get(name);
			if ( block )
				{
				sourceDetail = ::getDetail(block);
				detail->object = sourceDetail->object;
				detail->wig->setGroup(block);
				}
			else	::fprintf(stderr,"%s: could not find block in current registry: %s\n",detail->wig->tag,name);
			}
		else {
			NSRect 	indented = ::indent(detail->frame,5.0);
			detail->object = detail->setPage(indented);
			}
		}
	else	::fprintf(stderr,"Bogus parameter to tEXT\n");
	// need to call setPage to set TextView
}

/*******************************************************************************
	Determine toggle state and turn display of the parent block accordingly
    If the parent block has an off attribute it is turned off (noRoom set true).
*******************************************************************************/
GroupItem *tOGGLED(GroupItem *item)
{
GroupItem 	*group = item->parent;
GroupItem 	*off = group->getAttribute("off");
Details 	*detail = ::getDetail(item);
	detail->isToggled = 1;
	if ( off )
		::setNoRoom(group,(unsigned int)1);
	::setAction(group,"toggle");
	//cout "Set toggle for",group.tag,group.noRoom:;
	return 0;
}

/*******************************************************************************
	Sets detail value to value of the attribute (named by item) in its source.
*******************************************************************************/
GroupItem *tRAIT(GroupItem *item)
{
Details 	*sourceDetail = 0;
Details 	*detail = ::getDetail(item);
GroupItem 	*priorBlock = 0;
GroupItem 	*priorItem = 0;
GroupItem 	*sourceAttribute = 0;
GroupItem 	*sourceBlock = 0;
GroupItem 	*traitBlock = 0;
GroupItem 	*block = 0;
Source 		*source = 0;
	//cout "trait:",wig.getTagXML():;
	if ( sourceAttribute = item->findAttribute("sRCe") )
		{
		source = (Source*)sourceAttribute->getPointer();
		if ( sourceBlock = sourceAttribute->parent )
			{
			sourceDetail = ::getDetail(sourceBlock);
			block = sourceBlock->getGroup();
			if ( !block )
				detail->wig->setText("");
			else {
				char 	*itemText = item->getText();
				if ( !itemText )
					itemText = detail->wig->tag;
				if (::compare(itemText,"source") == 0)
					traitBlock = block;
				else {
					traitBlock = block->get(itemText);
					if ( traitBlock && detail->keyField )
						if ( block = sourceBlock->parent )
							if ( block = block->priorMember(sourceBlock) )
								if ( priorBlock = block->getGroup() )
									priorItem = priorBlock->get(itemText);
					}
				detail->wig->setGroup(traitBlock);
				/*******************************************************************
				showBlank is set for matching key fields already displayed
				*******************************************************************/
				if ( priorItem )
					detail->showBlank = priorItem && (::compare(traitBlock->getText(),priorItem->getText()) == 0);
				//cout "tRAIT:",wig.tag,; if traitBlock cout traitBlock,; else cout "No data",; if priorItem cout priorItem; else cout "No prior item"; cout " show blank:",showBlank:;
				}
			::setModified(detail->wig);
			}
		if ( !detail->attributed )
			{
			detail->trait = 1;
			if ( source )
				source->addListener(detail->wig);
			detail->hasReactions = 1;
			item->reacts = 1;
			}
		}
	//else cerr "Could not find source for " wig.tag " to set trait\n";
	return 0;
}

/*******************************************************************************
	Set tree source and tree action
*******************************************************************************/
GroupItem *tREE(GroupItem *item)
{
Details 	*detail = ::getDetail(item);
GroupItem 	*branch = 0;
GroupItem 	*leaf = 0;
GroupItem 	*group = 0;
	while ( branch = detail->wig->walk(branch) )
		if ( leaf = branch->getAttribute("leaf") )
			break;
	if ( !leaf )
		{
		::fprintf(stderr,"ERROR: tree must have a descendent block with a leaf attribute\n");
		return 0;
		}
	if ( item->data )
		if (::compare(item->getText(),"selected") == 0)
			{
			if ( !detail->hasReactions )
				{
				Control::bwana->selectSource->addListener(detail->wig);
				detail->hasReactions = 1;
				item->reacts = 1;
				}
			if ( group = GroupControl::groupController->groupParser->lastSelect )
				if ( branch->expanded )
					::cOLLAPSErow(leaf);
			}
		else
		if ( !detail->sourced )
			group = GroupControl::groupController->groupParser->locate(item);
		else	return 0;
	/***************************************************************************
	If group is set tree has not been set or must be set as a reaction
	to the last selection. The tree group is assigned to the first branch.
	***************************************************************************/
	if ( branch )
		if ( group )
			{
			branch->setGroup(group);
			if ( leaf = detail->wig->first("entry") )
				leaf->setGroup(group);
			else	::fprintf(stderr,"ERROR: tree could not find branch entry\n");
			::setExpander(branch);
			if ( !detail->sourced )
				detail->sourced = 1;
			}
		else
		if ( !detail->hasReactions )
			::fprintf(stderr,"ERROR: tree set up could not find %s\n",item->getText());
	return 0;
}

/*******************************************************************************
	Set the value of the type attribute to the name of its parents registry.
*******************************************************************************/
GroupItem *tYPE(GroupItem *item)
{
Details 	*detail = ::getDetail(item);
	if ( detail->wig->registry )
		item->setText(detail->wig->registry->tag);
	return 0;
}

/*******************************************************************************
	Print elapsed time from the date passed in and return the current time.
    The date passed in is presumably released via auto reference.
*******************************************************************************/
NSDate *timeEnd(NSDate *d)
{
NSDate 	*current = 0;
double 	seconds = -[d timeIntervalSinceNow];
	current = [d dateByAddingTimeInterval:seconds];
	::printf("Elapsed time: %g\n",seconds);
	return current;
}

char *toString(NSPoint p)
{
char 	*text = 0;
	text = ::concat(3,::toStringFromDouble(p.x),",",::toStringFromDouble(p.y));
	return text;
}

char *toString(NSRect f)
{
char 	*text = 0;
	text = ::concat(5,::toString(f.origin),",",::toStringFromDouble(f.size.width),",",::toStringFromDouble(f.size.height));
	return text;
}

/*******************************************************************************
	Set up a window or pane
*******************************************************************************/
GroupItem *wINDOW(GroupItem *item)
{
NSWindow 	*window = 0;
NSRect 		box;
GroupItem 	*block = 0;
GroupItem 	*windowBlock = 0;
char 		*name = 0;
int 		mask = 0;
Details 	*detail = ::getDetail(item);
Layout 		*layout = detail->view;
NSView 		*view = 0;
	if ( detail->attributed )
		return 0;
	[detail->view deselect];
	windowBlock = detail->wig;
	if ( windowBlock->get("closable") )
		mask |= NSClosableWindowMask;
	if ( windowBlock->get("title") )
		mask |= NSTitledWindowMask;
	if ( windowBlock->get("resize") )
		mask |= NSResizableWindowMask;
	if ( item->parent == Control::bwana->controller->root )
		window = Control::bwana->window;
	else
	if ( (detail->pane == 3) )
		{
		NSPanel 	*pane = (NSPanel*)[[NSWindow alloc] initWithContentRect:detail->frame styleMask:mask backing:NSBackingStoreBuffered defer:1];
		window = detail->object = pane;
		}
	else {
		window = [[NSWindow alloc] initWithContentRect:detail->frame styleMask:mask backing:NSBackingStoreBuffered defer:1];
		detail->object = window;
		}
	view = [window contentView];
	box = [window frame];
	if ( block = windowBlock->getAttribute("x") )
		box.origin.x = block->getNumber();
	if ( block = windowBlock->getAttribute("y") )
		box.origin.y = block->getNumber();
	box.size.width = detail->frame.size.width;
	box.size.height = detail->frame.size.height + box.size.height - [view frame].size.height;
	[window setFrame:box display:0];
	if ( block = windowBlock->getAttribute("title") )
		name = block->getText();
	if ( mask & NSTitledWindowMask )
		[window setTitle:[NSString stringWithCString:name encoding:NSASCIIStringEncoding]];
	//if windowBlock%hide noRoom = true;
	if ( !layout->webView )
		{
		WKWebViewConfiguration 	*configuration = [[WKWebViewConfiguration alloc] init];
		layout->webView = [[WKWebView alloc] initWithFrame:box configuration:configuration];
		[layout->webView setNavigationDelegate:(id)layout];
		//if navigationDelegate cout `"has navigation delegate":; else cout `"no navigation delegate":;
		}
	[view addSubview:layout->webView];
	[view addSubview:layout];
	[window makeFirstResponder:layout];
	layout->base = windowBlock;
	[view setNeedsDisplay:1];
	::setModified(detail->wig);
	return 0;
}

/*******************************************************************************
	Load an xml file. If the item passed in has a value, it is assumed to be
	a file name. If not, looks for file attribute in item parent. The block
    resulting from parsing the xml file gets merged into the current block.
*******************************************************************************/
GroupItem *xmlFILE(GroupItem *item)
{
Details 	*detail = ::getDetail(item);
GroupItem 	*block = 0;
GroupItem 	*saveRegistry = GroupControl::groupController->groupParser->currentRegistry;
	GroupControl::groupController->groupParser->currentRegistry = detail->wig->registry;
	if ( item->data )
		block = GroupControl::groupController->groupParser->parseFile(item->getText());
	else
	if ( item->parent )
		{
		block = item->parent->get("file");
		if ( block && block->data )
			block = GroupControl::groupController->groupParser->parseFile(block->getText());
		else	block = 0;
		}
	if ( !block )
		::fprintf(stderr,"%s Failed xml file load\n",detail->wig->tag);
	else	detail->wig->merge(block);
	GroupControl::groupController->groupParser->currentRegistry = saveRegistry;
	return 0;
}

Bwana::Bwana(Control *c)
{
	actions = 0;
	window = 0;
	expandables = 0;
	sourceList = 0;
	expandLabel = 0;
	minimumHeight = 0;
	minimumWidth = 0;
int i = sizeof(Source);
	::printf("Source size: %d\n",i);
	controller = c;
	GroupControl::registries->addString("doNotCopy");
	GroupControl::groupController->setBaseRegistries();
	extendParser = new Groups();
	Control::colorRegistry = GroupControl::groupController->getRegistry("cOLOr");
	Control::fontRegistry = GroupControl::groupController->getRegistry("fONt");
	GroupControl::groupController->properties->addString("hasOnLoadAction");
	GroupControl::groupController->properties->gMethod = ::cssOnLoad;
	types = GroupControl::groupController->getRegistry("tYPEs");
	windows = new BaseHash();
	descriptions = GroupControl::groupController->getRegistry("dESCRIPTIONs");
	fontManager = [NSFontManager sharedFontManager];
	delayActions = new Stak();
	GroupControl::groupController->groupParser->lastSelect = GroupControl::groupController->itemFactory("EmptySource");
	emptySource = new Source(GroupControl::groupController->groupParser->lastSelect);
	expandList = new DoubleLinkList();
	GroupControl::groupController->groupParser->lastSelect = 0;
	selectSource = new Source();
	bwanaBuffer = ::bufferFactory1();
}

/*******************************************************************************
	Map a method to an attribute registered in attributes and set it as a
    deferred action invoked on user input (as in a mouse click).
*******************************************************************************/
GroupItem *Bwana::mapAction(char *name, GroupItem *(*method)(GroupItem *))
{
GroupItem 	*item = 0;
	item = mapMethod(name,method);
	item->methodType = 1;
	return item;
}

/*******************************************************************************
	Map action and set to track parents as members of the attribute created
    by the mapAction method. Building the track is done in ParseXML each time
    the named attribute is parsed. Basically it tracks each block that has
    the named attribute.
*******************************************************************************/
GroupItem *Bwana::mapAndTrack(char *name, GroupItem *(*method)(GroupItem *))
{
GroupItem 	*item = mapMethod(name,method);
	item->methodType = 5;
	return item;
}

/*******************************************************************************
	Map a method to an attribute registered in attributes and set it as an
    immediate action invoked when first encountered on layout (and subsequently
    ignored).
*******************************************************************************/
GroupItem *Bwana::mapImmediate(char *name, GroupItem *(*method)(GroupItem *))
{
GroupItem 	*item = 0;
	item = mapAndTrack(name,method);
	item->methodType = 2;
	return item;
}

/*******************************************************************************
	Map a method to an attribute registered in attributes. The method will be
    invoked during layout.
*******************************************************************************/
GroupItem *Bwana::mapMethod(char *name, GroupItem *(*method)(GroupItem *))
{
GroupItem 	*item = GroupControl::groupController->itemFactory(name);
	item->isSingleton = 1;
	item->isClosed = 1;
	item->methodType = 3;
	item->setMethod(method);
	GroupControl::groupController->properties->addGroup(item);
	return item;
}

/*******************************************************************************
	Register methods for attributes. These are the methods that setup and display
	elements of a layout (buttons, images, fonts, etc.)
    
    Note: in some cases the order of attributes is important. They are listed
    below alphabetically, except in cases where that interferes with their
    functionality (that is, when they should be processed after the process of
    some other attribute appearing earlier in the alphabetic sequence).
*******************************************************************************/
void Bwana::registerMethods()
{
GroupItem 	*group = 0;
	actions = new Actions();
	/***************************************************************************
	The next three attributes have order dependencies and have to be
	processed before one or more of the attributes listed below.
	***************************************************************************/
	mapMethod("panel",::wINDOW);
	mapMethod("drawPath",::pATH);
	// has to preceed style and style related attributes
	mapMethod("window",::wINDOW);
	/***************************************************************************
	Flag settings
	***************************************************************************/
	mapMethod("blank",::flagFIELD);
	mapMethod("commas",::flagFIELD);
	mapMethod("doNotScroll",::flagFIELD);
	mapMethod("editable",::flagFIELD);
	mapMethod("key",::flagFIELD);
	mapMethod("keyAction",::flagFIELD);
	mapMethod("noSourceSelect",::flagFIELD);
	mapMethod("selectable",::flagFIELD);
	mapMethod("zero",::flagFIELD);
	/***************************************************************************
	Other layout attributes
	***************************************************************************/
	mapMethod("action",::aCTION);
	mapImmediate("bigify",::bIGIFY);
	mapImmediate("buffer",::bUFFER);
	mapImmediate("canvas",::cANVAS);
	mapMethod("cards",::setCARD);
	mapMethod("image",::iMAGE);
	mapMethod("keyStroke",::keySTROKE);
	mapMethod("list",::delimitFILE);
	mapMethod("merge",::mERGE);
	mapMethod("minimumHeight",::mINIMUM);
	mapMethod("minimumWidth",::mINIMUM);
	mapMethod("next",::nEXT);
	mapMethod("popup",::popUP);
	mapMethod("pullDown",::pullDOWN);
	mapImmediate("register",::rEGISTER);
	mapMethod("rightClick",::rightCLICK);
	mapMethod("scrollWith",::scrollWITH);
	mapMethod("sort",::setSORT);
	mapMethod("source",::sOURCE);
	mapMethod("tabs",::tABS);
	mapMethod("tag",::tAG);
	mapMethod("text",::tEXT);
	mapMethod("toggled",::tOGGLED);
	mapMethod("trait",::tRAIT);
	mapMethod("tree",::tREE);
	mapMethod("type",::tYPE);
	mapMethod("value",::tAG);
	mapMethod("xml",::xmlFILE);
	/***************************************************************************
	The following attributes have order dependencies and have to be processed
	after one or more of the attributes listed above. Entering in the registry
	at the end as is done here does not guarantee that. The only way
	is to make sure the attribute appears after any attribute
	that it is dependent on.
	
	Alternatively, setting the modified flag on the attribute will delay
	when the method is run in Details processMethods()
	***************************************************************************/
	mapMethod("describe",::dESCRIBE);
	group = mapMethod("show",::sHOW);
	// isShell is set so when members added to show, their parent is unchanged
	group->isShell = 1;
	group->modified = 1;
}
