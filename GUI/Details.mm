#include <Cocoa/Cocoa.h>
#include <Foundation/Foundation.h>
#include <WebKit/WebKit.h>
#include <string.h>
#include <stdio.h>
#include "GroupItem.h"
#include "OCroutines.h"
#include "StringRoutines.h"
#include "Control.h"
#include "GroupControl.h"
#include "PLGparse.h"
#include "Details.h"
#include "Bwana.h"
#include "Stak.h"
#include "Tape.h"
#include "ParseXML.h"
#include "DoubleLink.h"
#include "BaseHash.h"
#include "Source.h"
#include "Layout.h"
#include "Stylish.h"

/*******************************************************************************
	Return the lowest descendent block that contains the point passed in.
    Assumes the base passed in contains the point.
*******************************************************************************/
GroupItem *blockContaining(GroupItem *base, NSPoint p)
{
Details 	*detail = ::getDetail(base);
GroupItem 	*item = 0;
GroupItem 	*group = 0;
	if ( base )
		{
		//cout "blockContaining starting at",base.tag,base.index,"Point:",p.x,p.y:;
		base->reset();
		while ( item = base->nextMember() )
			{
			//String value; if item.isGroup value = item.group.getCellText(); if !value value = "no Value";
			if ( item->isTarget )
				continue;
			detail = ::getDetail(item);
			if ( !detail )
				{
				//cout `"blockContaining NO detail",item.tag,value:;
				if ( item && item->hasMembers )
					{
					group = ::blockContaining(item,p);
					if ( item = group )
						break;
					}
				continue;
				}
			//cout `"blockContaining",item.tag,value,frame:;
			if ( detail->contains(p) )
				{
				//cout ``"block Contained":;
				if ( item && item->hasMembers )
					{
					group = ::blockContaining(item,p);
					item = group;
					}
				break;
				}
			}
		}
	return item;
}

/*******************************************************************************
	Find a scrollable block
*******************************************************************************/
GroupItem *findScrollable(GroupItem *group)
{
GroupItem 	*block = 0;
Details 	*detail = 0;
	if ( block = group )
		for ( block = group; block; block = block->parent )
			if ( detail = ::getDetail(block) )
				if ( !detail->noScroll && ((block->noAnchor || block->skipOverMatch || (detail->orient == 3)) || (detail->scrollableX || detail->scrollableY)) )
					break;
	return block;
}

/******************************************************************************
	Return the detail of the first ancestor to have detail
******************************************************************************/
Details *getAncestor(GroupItem *item)
{
Details 	*ancestor = 0;
GroupItem 	*group = item->parent;
	if ( group )
		group = group->findAttribute("dETAILs");
	if ( group )
		ancestor = (Details*)group->getPointer();
	return ancestor;
}

/*******************************************************************************
    Get the text to be displayed in a cell. Deals with case where value is
    a group (so the data type is not obvious).
*******************************************************************************/
char *getCellText(GroupItem *item)
{
GroupItem 	*group = 0;
char 		*text = 0;
int 		dataType = item->getDataType();
Details 	*detail = ::getDetail(item);
	if ( !detail )
		{
		text = ::concat(2,"getCellText: no detail for ",item->tag);
		goto endGetCellText;
		}
	if ( detail->style && !detail->showBlank )
		if ( detail->style->formatItem && (dataType == 1 || dataType == 5) )
			if ( detail->style->formatter )
				{
				NSNumber 	*number = 0;
				if ( dataType == 1 )
					number = [[NSNumber alloc] initWithInt:item->getCount()];
				else	number = [[NSNumber alloc] initWithDouble:item->getNumber()];
				text = ::toString([detail->style->formatter stringFromNumber:number]);
				}
			else {
				char 	*formatText = detail->style->formatItem->getText();
				if ( dataType == 1 )
					::asprintf(&text,formatText,item->getCount());
				else
				if ( dataType == 5 )
					::asprintf(&text,formatText,item->getNumber());
				}
		else
		if ( group = item->getGroup() )
			if ( !detail->useTagForLabel )
				text = group->getText();
			else	text = group->resolvedTag();
		else
		if ( !detail->useTagForLabel )
			text = item->getText();
	if ( detail->style && detail->style->zeroItem && (((item->data == 3) && !item->getCount()) || ((item->data == 4) && !item->getNumber())) )
		text = detail->style->zeroItem->getText();
	else
	if ( !text )
		if ( detail->style && detail->style->blankItem )
			text = detail->style->blankItem->getText();
		else
		if ( detail->editable )
			text = "";
endGetCellText:
	return text;
}

/*******************************************************************************
	Return the detail associated with the item passed in (this extends GroupItem).
*******************************************************************************/
Details *getDetail(GroupItem *item)
{
	if ( (item->affiliation == 1) )
		if ( item->parent )
			item = item->parent;
		else {
			::fprintf(stderr,"getDetail: failed to get detail for %s\n",item->tag);
			return 0;
			}
	if ( item->hasDetails )
		{
		GroupItem 	*details = item->getAttribute("dETAILs");
		if ( details )
			{
			Details 	*detail = (Details*)details->getPointer();
			if ( detail )
				return detail;
			}
		}
	return 0;
}

/*******************************************************************************
	Scroll a block (assuming it is scrollable).
*******************************************************************************/
void scrollBlock(GroupItem *group, int length, int isVertical)
{
GroupItem 	*scroller = 0;
GroupItem 	*block = 0;
Details 	*blockDetail = 0;
	::printf("scrollBlock: %s %d\n",group->tag,group->index);
	if ( block = ::findScrollable(group) )
		{
		::printf("\tscrollable is %s %d\n",block->tag,block->index);
if ( blockDetail = ::getDetail(block) )
			{
			if ( block->noAnchor )
				blockDetail->scrollContent(length);
			else
			if ( (blockDetail->orient == 3) )
				::scrollCards(block,length);
			else
			if ( blockDetail->scrollableY && isVertical )
				blockDetail->setScroll(length,0);
			else
			if ( blockDetail->scrollableX )
				blockDetail->setScroll(length,1);
			else
			if ( block->skipOverMatch )
				::scrollSource(block,length);
			else	return;
			}
		if ( scroller = block->getAttribute("scrollWith") )
			if ( (scroller->data == 5) )
				{
				block = scroller->getGroup();
if ( blockDetail = ::getDetail(block) )
					{
					if ( block->noAnchor )
						blockDetail->scrollContent(length);
					else
					if ( (blockDetail->orient == 3) )
						::scrollCards(block,length);
					else
					if ( blockDetail->scrollableY && isVertical )
						blockDetail->setScroll(length,0);
					else
					if ( blockDetail->scrollableX )
						blockDetail->setScroll(length,1);
					else
					if ( block->skipOverMatch )
						::scrollSource(block,length);
					else	return;
					}
				}
			else {
				block = 0;
				while ( block = scroller->nextMember(block) )
					if ( blockDetail = ::getDetail(block) )
						{
						if ( block->noAnchor )
							blockDetail->scrollContent(length);
						else
						if ( (blockDetail->orient == 3) )
							::scrollCards(block,length);
						else
						if ( blockDetail->scrollableY && isVertical )
							blockDetail->setScroll(length,0);
						else
						if ( blockDetail->scrollableX )
							blockDetail->setScroll(length,1);
						else
						if ( block->skipOverMatch )
							::scrollSource(block,length);
						else	return;
						}
				}
		}
}

/*******************************************************************************
	Scroll a card stack (one card at a time).
*******************************************************************************/
void scrollCards(GroupItem *block, int up)
{
Details 	*detail = 0;
GroupItem 	*page = 0;
GroupItem 	*group = 0;
	if ( block )
		page = block->getGroup();
	if ( page )
		{
		block = page->parent;
		if ( block )
			{
			if ( up > 0 )
				group = block->priorMember(page);
			else	group = block->nextMember(page);
			if ( group )
				{
				detail = ::getDetail(group);
				if ( group->parent )
					group->parent->setGroup(group);
				::setNoRoom(page,(unsigned int)1);
				::setNoRoom(group,(unsigned int)0);
				detail->view->selection = group;
				}
			}
		}
}

/*******************************************************************************
	Scroll the source associated with the block passed in.
*******************************************************************************/
void scrollSource(GroupItem *item, int length)
{
Details 	*detail = ::getDetail(item);
GroupItem 	*pageLength = 0;
GroupItem 	*group = 0;
Source 		*source = 0;
	if ( item )
		if ( group = item->getAttribute("sRCe") )
			if ( source = (Source*)group->getPointer() )
				{
				if ( detail->view->paging )
					if ( pageLength = item->getAttribute("pAGElength") )
						length *= pageLength->getCount();
				return;
				}
	::fprintf(stderr,"scrollSource: unable to scroll%s for %d\n",item->tag,length);
}

/*******************************************************************************
	Return the detail associated with the item passed in (this extends GroupItem).
*******************************************************************************/
Details *setDetail(GroupItem *item)
{
Details 	*detail = 0;
	if ( item->hasDetails )
		{
		GroupItem 	*details = item->getAttribute("dETAILs");
		if ( details )
			detail = (Details*)details->getPointer();
		}
	else {
		detail = (Details*)Control::bwana->controller->detailTape->getStrip();
		GroupItem *group = GroupControl::groupController->itemFactory("dETAILs");
		group->noPrint = 1;
		item->hasDetails = 1;
		group->setPointer((void*)detail);
		group->affiliation = 1;
		item->addGroup(group);
		detail->wig = item;
		//cout "setDetail: detail attribute created for",item.tag:;
		}
	return detail;
}

/*******************************************************************************
	Set the noRoom flag for this block NOTE: isTarget aliased to noRoom and
    you cannot assign to noRoom here or you end up recursively calling this
    (That is why the assignment is made to item.isTarget instead).
*******************************************************************************/
void setNoRoom(GroupItem *item, int flag)
{
Details 	*detail = ::getDetail(item);
	//cout "Setting no room for",item.tag,flag:;
	item->isTarget = flag;
	if ( flag && item->processUpTo )
		[detail->view deselect];
}

/*******************************************************************************
	Reset text (assumes object is a TextView).
*******************************************************************************/
void Details::changeText()
{
NSString 			*atText = 0;
NSAttributedString 	*aString = 0;
NSTextView 			*editor = object;
NSTextStorage 		*store = 0;
char 				*atStart = 0;
GroupItem 			*block = 0;
	if ( !editor )
		return;
	noData = 0;
	if ( !wig->data )
		if ( !trait )
			atStart = wig->tag;
		else {
			noData = 1;
			return;
			}
	else
	if ( (wig->data == 5) )
		{
		block = wig->getGroup();
		if ( block )
			atStart = block->getText();
		}
	else	atStart = wig->getText();
	offset = 0;
	store = [editor textStorage];
	atText = [NSString stringWithCString:atStart encoding:NSASCIIStringEncoding];
	aString = [[NSAttributedString alloc] initWithString:atText];
	[store setAttributedString:aString];
}

/******************************************************************************
	Checks if this detail is visible and sets noRoom
******************************************************************************/
void Details::checkFit()
{
Details 	*ancestor = wig->parent ? ::getDetail(wig->parent) : (Details*)0;
	if ( ancestor && ancestor->wig->isTarget )
		return;
	if ( wig->isTarget && (noData || isToggled || (ancestor->orient == 3)) )
		return;
	::setNoRoom(wig,(unsigned int)0);
	//cout `"checkFit:",wig.tag:;
	if ( ancestor )
		{
		if ( frame.origin.x != ancestor->innerBox.origin.x )
			if ( frame.origin.x >= ancestor->innerBox.origin.x + ancestor->innerBox.size.width || frame.origin.x + frame.size.width <= ancestor->innerBox.origin.x )
				{
				::setNoRoom(wig,(unsigned int)1);
				ancestor->scrollableX = 1;
				}
			else
			if ( frame.origin.x < ancestor->innerBox.origin.x || frame.origin.x + frame.size.width > ancestor->innerBox.origin.x + ancestor->innerBox.size.width )
				ancestor->scrollableX = 1;
		if ( frame.origin.y != ancestor->innerBox.origin.y )
			if ( frame.origin.y >= ancestor->innerBox.origin.y + ancestor->innerBox.size.height || frame.origin.y + frame.size.height <= ancestor->innerBox.origin.y )
				{
				::setNoRoom(wig,(unsigned int)1);
				ancestor->scrollableY = 1;
				}
			else
			if ( frame.origin.y < ancestor->innerBox.origin.y || frame.origin.y + frame.size.height > ancestor->innerBox.origin.y + ancestor->innerBox.size.height )
				ancestor->scrollableY = 1;
		if ( !wig->isTarget )
			{
			if ( !ancestor->scrollableX && frame.origin.x < ancestor->innerBox.origin.x )
				ancestor->scrollableX = 1;
			if ( !ancestor->scrollableY && frame.origin.y < ancestor->innerBox.origin.y )
				ancestor->scrollableY = 1;
			}
		}
	if ( wig->noAnchor )
		if ( (orient == 1) )
			scrollableY = 1;
		else	scrollableX = 1;
}

/******************************************************************************
	Checks for unspecified width or height.
******************************************************************************/
void Details::checkStretch()
{
int 		fixed = 0;
GroupItem 	*item = 0;
GroupItem 	*group = 0;
	stretched = 0;
	if ( (orient == 1) )
		length = innerBox.size.height;
	else
	if ( (orient == 2) )
		length = innerBox.size.width;
	if ( !length )
		return;
	/***************************************************************************
	Deal w/percent specifications in descendents. length gets further
	adjustment in layout() after this returns.
	***************************************************************************/
	if ( wig->hasMembers )
		{
		while ( item = wig->nextMember(item) )
			if ( !item->isComment )
				{
				Details 	*detail = ::getDetail(item);
				if ( (orient == 1) )
					{
					group = item->get("height");
					if ( !(detail->sizeToFit == 2) && !(detail->sizeToFit == 3) )
						if ( !group )
							stretched++;
						else
						if ( group->isPercent )
							fixed += detail->frame.size.height * group->getNumber() / 100;
						else	fixed += group->getNumber();
					else	fixed += detail->frame.size.height;
					}
				else
				if ( (orient == 2) )
					{
					group = item->get("width");
					if ( !(detail->sizeToFit == 1) && !(detail->sizeToFit == 3) )
						if ( !group )
							stretched++;
						else
						if ( group->isPercent )
							fixed += detail->frame.size.width * group->getNumber() / 100;
						else	fixed += group->getNumber();
					else	fixed += detail->frame.size.width;
					}
				}
		}
	if ( !stretched )
		length = 0;
	else
	if ( fixed )
		length -= fixed;
}

/*****************************************************************************
	Wipes detail clean
*****************************************************************************/
void Details::clear()
{
void 	*strip = (void*)this;
	::memset(strip,0,sizeof(Details));
}

/*****************************************************************************
	Check if point is in the frame defined here
*****************************************************************************/
int Details::contains(NSPoint p)
{
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

/******************************************************************************
	Debugging dump of frame
******************************************************************************/
void Details::dump()
{
int 		i = 0;
char 		*text = 0;
GroupItem 	*group = 0;
	for ( i = level; i > 0; i-- )
		::printf("\t");
	if ( sourced || trait )
		group = wig->getGroup();
	if ( group )
		if ( trait )
			text = ::concat(3,wig->tag," ",group->getText());
		else	text = ::concat(3,wig->tag," ",group->tag);
	else	text = wig->tag;
	::printf("%s %s edge: %g bottom: %g ",text,::toString(frame),frame.origin.x + frame.size.width,frame.origin.y + frame.size.height);
	if ( wig->parent )
		::printf("%s ",wig->parent->tag);
	if ( !selectable )
		::printf("!selectable ");
	if ( style )
		{
		::printf("styled ");
		if ( "stroked" )
			::printf("stroked ");
		}
	if ( wig->processUpTo )
		::printf("selected");
	if ( wig->noPrint )
		::printf(" noPrint");
	if ( wig->isTarget )
		::printf(" noRoom");
	::printf(" %d\n",wig->index);
	//wig.dump(level,0);
}

/******************************************************************************
	Debugging dump of details used when debugging frame setting
******************************************************************************/
void Details::dumpDetails()
{
char 		*room = 0;
char 		*text = 0;
GroupItem 	*group = 0;
	if ( sourced || trait )
		group = wig->getGroup();
	if ( group )
		if ( trait )
			text = ::concat(3,wig->tag," ",group->getText());
		else	text = ::concat(3,wig->tag," ",group->tag);
	else	text = wig->tag;
	if ( wig->isTarget )
		room = " No room";
	::printf("\t\t%s %s\t\tlength %g\t\tposition at %g %d",text,::toString(frame),length,positionAt,stretched);
	if ( wig->noPrint )
		::printf(" noPrint");
	if ( room )
		::printf("%s",room);
	::printf(" %d\n",wig->index);
	//wig.dump(level,0);
}

/*******************************************************************************
	Get the fit settings.
*******************************************************************************/
void Details::getFitSettings()
{
GroupItem 	*fit = wig->getAttribute("fit");
char 		way = 0;
char 		*fitting = 0;
	sizeToFit = 0;
	if ( !fit )
		return;
	fitting = fit->getText();
	if ( fitting )
		way = *fitting;
	if ( way == 't' )
		sizeToFit = 4;
	else
	if ( way == 'b' )
		sizeToFit = 3;
	else
	if ( way == 'w' || way == 'a' || (!way && (orient == 2)) )
		sizeToFit = 1;
	else
	if ( way == 'h' || way == 'd' || (!way && (orient == 1)) )
		sizeToFit = 2;
}

/*******************************************************************************
	Initializes display details for the GroupItem passed in
*******************************************************************************/
int Details::initialize(GroupItem *w)
{
GroupItem 	*item = 0;
char 		*text = 0;
int 		repeat = 1;
int 		flexed = 0;
Details 	*ancestor = 0;
	wig = w;
	if ( !wig )
		return 0;
	//cout "Details initialize:",wig.tag:;
	ancestor = wig->parent ? ::getDetail(wig->parent) : (Details*)0;
	text = wig->tag;
	orient = 0;
	if ( wig->isTarget && !(noData || isToggled || (ancestor->orient == 3)) )
		::setNoRoom(wig,(unsigned int)0);
	wig->noAnchor = 0;
	if ( wig->get("flex") )
		{
		flexed = 1;
		orient = 2;
		}
	if ( item = wig->get("across") )
		{
		orient = 2;
		if ( (item->data == 3) )
			repeat = item->getCount();
		else
		if ( item->data )
			wig->noAnchor = 1;
		}
	else
	if ( item = wig->get("down") )
		{
		orient = 1;
		if ( flexed )
			wig->addAttrString("flexDirection","column");
		if ( (item->data == 3) )
			repeat = item->getCount();
		else
		if ( item->data )
			wig->noAnchor = 1;
		}
	else
	if ( wig->get("cards") )
		orient = 3;
	else
	if ( wig->get("layers") )
		orient = 4;
	else
	if ( wig->get("overlay") )
		orient = 5;
	else
	if ( !flexed )
		orient = 1;
	if ( wig->get("panel") )
		pane = 3;
	else
	if ( wig->get("window") )
		if ( Control::bwana->controller->convertWindowToPanel )
			pane = 3;
		else	pane = 6;
	subbed = fixX = fixY = fixHeight = fixWidth = 0;
	wig->isPercent = 0;
	if ( item = wig->get("height") )
		{
		frame.size.height = item->getNumber();
		fixHeight = 1;
		if ( item->isPercent )
			wig->isPercent = 1;
		}
	else	frame.size.height = 0;
	if ( item = wig->get("width") )
		{
		frame.size.width = item->getNumber();
		fixWidth = 1;
		if ( item->isPercent )
			wig->isPercent = 1;
		}
	else	frame.size.width = 0;
	if ( (pane == 3) || (pane == 6) )
		{
		Control::bwana->windows->add(wig->tag,(void*)wig);
		if ( !Control::bwana->controller->root )
			Control::bwana->controller->root = wig;
		// Make sure layout based on current frame as opposed to initial dimensions
		if ( view && view->resized )
			wasReset = 1;
		if ( wasReset )
			frame = [view frame];
		}
	else {
		if ( item = wig->get("x") )
			{
			frame.origin.x = item->getNumber();
			fixX = 1;
			}
		else	frame.origin.x = 0;
		if ( item = wig->get("y") )
			{
			frame.origin.y = item->getNumber();
			fixY = 1;
			}
		else	frame.origin.y = 0;
		}
	getFitSettings();
	return repeat > 0 ? repeat : 1;
}

/*******************************************************************************
	Fire attribute methods (the first time the associated detail gets laid out
	and when some user action happens, like scrolling or hitting a button).
    Attributed actions are only fired the first time thru after which attributed
    flag is set. Reactions are attribute methods that are fired every time
    (in which case, the attribute has react flag set).
*******************************************************************************/
void Details::processAttributes()
{
Details 	*saveDetail = Control::bwana->controller->attributeDetail;
	if ( !attributed )
		{
		selectable = 1;
		processMethods();
		attributed = 1;
		}
	Control::bwana->controller->attributeDetail = saveDetail;
}

/*******************************************************************************
	Fire layout methods. Note the parent of attributes gets reset just to make sure.
*******************************************************************************/
void Details::processMethods()
{
GroupItem 	*item = 0;
GroupItem 	*trait = 0;
	Control::bwana->controller->attributeDetail = this;
	wig->reset();
	while ( item = wig->nextAttribute(item) )
		{
		if ( (item->methodType == 2) )
			continue;
		item->parent = wig;
		// some attributes are shared
		if ( item->gMethod )
			trait = item;
		else	trait = GroupControl::groupController->properties->get(item->tag);
		if ( !trait && item->registry )
			trait = GroupControl::groupController->properties->get(item->registry->tag);
		if ( trait )
			trait->parent = wig;
		if ( !trait && !attributed && item->noMerge && item->hasAttributes )
			{
			GroupItem 	*group = 0;
			trait = item;
			trait->parent = wig;
			trait->reset();
			while ( group = trait->nextAttribute() )
				if ( (group->methodType == 1) || (group->methodType == 5) )
					::fprintf(stderr,"%s in %s ignored\n",group->tag,trait->tag);
				else
				if ( group->gMethod )
					{
					group->parent = trait;
					group->gMethod(group);
					group->hasActions = 1;
					}
			}
		if ( trait )
			{
			/*******************************************************************
			If the item has a value, it will have the same name as the trait
			but will not have its method, so we copy it over.
			*******************************************************************/
			if ( trait->gMethod && !item->gMethod )
				item->setMethod(trait->gMethod);
			if ( trait->modified )
				Control::bwana->delayActions->push(item);
			else {
				if ( !attributed && (trait->methodType == 1) && wig->gMethod != trait->gMethod )
					wig->hasActions = 1;
				if ( (trait->methodType == 1) || (trait->methodType == 5) || (attributed && hasOnLayout) )
					continue;
				if ( trait->gMethod )
					{
					//cout "processMethods:",wig.tag,trait.tag:;
					trait->gMethod(item);
					}
				}
			}
		}
	/***************************************************************************
	Delayed actions are flagged by modified to happen after all other actions
	are processed. The modified flag gets set in Bwana when the action
	trait is created.
	***************************************************************************/
	if ( Control::bwana->delayActions->length )
		while ( item = (GroupItem*)Control::bwana->delayActions->pop() )
			if ( trait = GroupControl::groupController->properties->get(item->tag) )
				{
				trait->parent = wig;
				if ( trait->gMethod )
					trait->gMethod(item);
				}
			else	::fprintf(stderr,"processMethods: could not find %s in properties\n",item->tag);
	Control::bwana->controller->attributeDetail = 0;
}

/*******************************************************************************
	Fire layout method as a reaction
*******************************************************************************/
void Details::processReaction()
{
GroupItem 	*item = 0;
GroupItem 	*trait = 0;
	Control::bwana->controller->attributeDetail = this;
	reacting = 1;
	wig->reset();
	while ( item = wig->nextAttribute(item) )
		{
		if ( !item->reacts )
			continue;
		//cout "processReaction:" wig.tag,wig.index,item.tag:;
		item->parent = wig;
		// some attributes are shared
		trait = GroupControl::groupController->properties->get(item->tag);
		if ( !trait && item->registry )
			trait = GroupControl::groupController->properties->get(item->registry->tag);
		if ( trait && trait->gMethod )
			trait->gMethod(item);
		else
		if ( item->gMethod )
			item->gMethod(item);
		}
	Control::bwana->controller->attributeDetail = 0;
	reacting = 0;
}

/*******************************************************************************
	Scroll contents when contents are variable. Length is the amount to scroll
    (in number of source records, 1 if driven by arrow keys, potentially more
    than 1 is driven by scroll wheel) positive length is down, negative is up).
    Paging set by page up or page down keys.
*******************************************************************************/
void Details::scrollContent(int scrollAmount)
{
GroupItem 	*group = 0;
GroupItem 	*item = 0;
Source 		*source = 0;
Details 	*detail = 0;
int 		pageSize = 0;
	wig->reset();
	while ( item = wig->nextMember() )
		{
		if ( !source )
			{
			detail = ::getDetail(item);
			if ( group = item->findAttribute("sRCe") )
				source = (Source*)group->getPointer();
			}
		if ( item->isTarget )
			break;
		pageSize++;
		}
	if ( view->paging )
		scrollAmount *= pageSize;
	if ( source )
		if ( source->pageShift(scrollAmount) )
			{
			//cout "scrollContent",wig.tag,scrollAmount:;
			source->updateListeners();
			::setModified(wig);
			}
}

/*******************************************************************************
	Sets frame dimensions
*******************************************************************************/
void Details::setFrame()
{
GroupItem 	*item = 0;
Details 	*ancestor = ::getAncestor(wig);
	//cout "Setting frame for " wig.tag,wig.index:;
	if ( ancestor )
		{
		/***********************************************************************
		If this is the first member of ancestor, reset ancestor positionAt.
		Because of flexible layout, may not be reset properly otherwise
		***********************************************************************/
		if ( wig == wig->parent->firstMember() )
			ancestor->positionAt = 0;
		switch (ancestor->orient)
			{
			case 1:
				if ( !fixX )
					frame.origin.x = ancestor->innerBox.origin.x;
				if ( !fixY )
					frame.origin.y = ancestor->innerBox.origin.y + ancestor->positionAt;
				if ( !fixWidth && !(sizeToFit == 3) )
					frame.size.width = ancestor->innerBox.size.width;
				if ( !(sizeToFit == 2) || (sizeToFit == 3) )
					if ( !fixHeight )
						if ( ancestor->stretched )
							frame.size.height = ancestor->length / ancestor->stretched;
						else	frame.size.height = ancestor->innerBox.size.height;
					else
					if ( wig->isPercent )
						frame.size.height = ancestor->innerBox.size.height * frame.size.height / 100;
				if ( frame.size.height )
					ancestor->positionAt += frame.size.height;
				break;
			case 2:
				if ( !fixX )
					frame.origin.x = ancestor->innerBox.origin.x + ancestor->positionAt;
				if ( !fixY )
					frame.origin.y = ancestor->innerBox.origin.y;
				if ( !fixHeight || (sizeToFit == 3) )
					frame.size.height = ancestor->innerBox.size.height;
				if ( !(sizeToFit == 1) || (sizeToFit == 3) )
					if ( !fixWidth )
						if ( ancestor->stretched )
							frame.size.width = ancestor->length / ancestor->stretched;
						else	frame.size.width = ancestor->innerBox.size.width;
					else
					if ( wig->isPercent )
						frame.size.width = ancestor->innerBox.size.width * frame.size.width / 100;
				if ( frame.size.width )
					ancestor->positionAt += frame.size.width;
				break;
			case 3:
			case 4:
				if ( !(ancestor->orient == 3) && wig != wig->parent->nextMember(item) )
					pane = 5;
			case 5:
			default:
				if ( !fixWidth )
					frame.size.width = ancestor->innerBox.size.width;
				if ( !fixHeight )
					frame.size.height = ancestor->innerBox.size.height;
				if ( !fixX )
					frame.origin.x = ancestor->innerBox.origin.x;
				if ( !fixY )
					frame.origin.y = ancestor->innerBox.origin.y;
			}
		}
	if ( frame.origin.x != 0 && frame.origin.x > -0.001 && frame.origin.x < 0.001 )
		frame.origin.x = 0;
	if ( frame.origin.y != 0 && frame.origin.y > -0.001 && frame.origin.y < 0.001 )
		frame.origin.y = 0;
	item = 0;
	/***************************************************************************
	Now set the innerBox
	***************************************************************************/
	setInnerBox();
}

/*******************************************************************************
	Set the inner box that defines the location and dimensions of the container
    for descendents after adjusting for margins, borders, and padding.
*******************************************************************************/
void Details::setInnerBox()
{
GroupItem 	*group = wig;
GroupItem 	*item = 0;
double 		number = 0;
double 		bottom = 0;
double 		left = 0;
double 		right = 0;
double 		top = 0;
	/***************************************************************************
	Check for padding attributes
	***************************************************************************/
	if ( item = group->getAttribute("pad") )
		{
		bottom = item->data ? item->getNumber() : 1.0;
		left = right = top = bottom;
		}
	if ( item = group->get("padBottom") )
		bottom = item->data ? item->getNumber() : 1.0;
	if ( item = group->get("padLeft") )
		left = item->data ? item->getNumber() : 1.0;
	if ( item = group->get("padRight") )
		right = item->data ? item->getNumber() : 1.0;
	if ( item = group->get("padTop") )
		top = item->data ? item->getNumber() : 1.0;
	/***************************************************************************
	Check for margins
	***************************************************************************/
	if ( item = group->getAttribute("margin") )
		{
		number = item->data ? item->getNumber() : 1.0;
		left += number;
		right += number;
		top += number;
		bottom += number;
		}
	if ( item = group->get("mBottom") )
		bottom += item->data ? item->getNumber() : 1.0;
	if ( item = group->get("mLeft") )
		left += item->data ? item->getNumber() : 1.0;
	if ( item = group->get("mRight") )
		right += item->data ? item->getNumber() : 1.0;
	if ( item = group->get("mTop") )
		top += item->data ? item->getNumber() : 1.0;
	/***************************************************************************
	border check
	***************************************************************************/
	if ( item = group->getAttribute("border") )
		{
		number = item->data ? item->getNumber() : 1.0;
		left += number;
		right += number;
		top += number;
		bottom += number;
		}
	/***************************************************************************
	Set the innerBox
	***************************************************************************/
	innerBox.origin.x = frame.origin.x + left;
	innerBox.origin.y = frame.origin.y + top;
	innerBox.size.width = frame.size.width - (right + left);
	innerBox.size.height = frame.size.height - (top + bottom);
	//cout `"setInnerBox: ",group.tag,"frame",frame " box",innerBox:;
}

/*******************************************************************************
	Sets the content for and returns TextView based on frame w/text
    supplied by associated GroupItem
*******************************************************************************/
NSTextView *Details::setPage(NSRect indented)
{
NSTextContainer 	*box = 0;
NSLayoutManager 	*manager = 0;
NSString 			*atText = 0;
NSAttributedString 	*aString = 0;
NSTextStorage 		*store = 0;
NSTextView 			*editor = 0;
char 				*wigText = wig->getText();
	//cout "Setting page for " wig.tag:;
	noData = 0;
	if ( !wigText )
		if ( !trait )
			wigText = wig->tag;
		else	noData = 1;
	/***************************************************************************
	wig.isGroup is true if the text block is linked to another text block
	(in which case we do not set text because already did that).
	***************************************************************************/
	if ( (wig->data == 5) )
		{
		GroupItem 	*group = wig->getGroup();
		Details 	*sourceDetail = ::getDetail(group);
		editor = sourceDetail->object;
		manager = [editor layoutManager];
		box = [[NSTextContainer alloc] initWithContainerSize:indented.size];
		[manager addTextContainer:box];
		editor = [[NSTextView alloc] initWithFrame:indented textContainer:box];
		}
	else {
		offset = 0;
		editor = [[NSTextView alloc] initWithFrame:indented];
		if ( wigText )
			{
			atText = [NSString stringWithCString:wigText encoding:NSASCIIStringEncoding];
			store = [editor textStorage];
			aString = [[NSAttributedString alloc] initWithString:atText];
			[store setAttributedString:aString];
			}
		}
	return editor;
}

/*******************************************************************************
	Scroll if x or y scroll amount set - right now scrolls horizontal or vertical
    not both. For 2D scroll, break into two parts.
*******************************************************************************/
void Details::setScroll(int step, int goAcross)
{
	::printf("setScroll has to be rewritten\n");
}

/******************************************************************************
	Return the style in effect (which may be a copy of ancestor style).
******************************************************************************/
void Details::setStyle()
{
Details 	*ancestor = wig->parent ? ::getDetail(wig->parent) : (Details*)0;
	if ( style )
		return;
	if ( ancestor && ancestor->style )
		style = new Stylish(wig,ancestor->style);
	else	style = new Stylish(wig);
	/***************************************************************************
	Set filler and selectFill.
	***************************************************************************/
GroupItem 	*group = wig->findAttribute("fill");
char 		*name = 0;
	if ( group )
		{
		if ( name = group->getText() )
			if ( *name != '#' )
				{
				style->filler = GroupControl::groupController->groupParser->locate(name);
				if ( !style->filler )
					::fprintf(stderr,"setStyle could not find fill: %s\n",name);
				else	group->setText(style->filler->getText());
				}
		style->filler = group;
		}
	if ( group = wig->getAttribute("selectFill") )
		{
		if ( name = group->getText() )
			if ( *name != '#' )
				{
				style->selectFill = GroupControl::groupController->groupParser->locate(name);
				if ( !style->selectFill )
					::fprintf(stderr,"setStyle could not find selectFill: %s\n",name);
				else	group->setText(style->selectFill->getText());
				}
		style->selectFill = group;
		}
}
