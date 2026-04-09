#include <Cocoa/Cocoa.h>
#include <stdlib.h>
#include <WebKit/WebKit.h>
#include <string.h>
#include <stdio.h>
#include "GroupItem.h"
#include "OCroutines.h"
#include "StringRoutines.h"
#include "GroupList.h"
#include "Control.h"
#include "GroupControl.h"
#include "PLGparse.h"
#include "Details.h"
#include "Bwana.h"
#include "ParseXML.h"
#include "BaseHash.h"
#include "Source.h"
#include "Layout.h"
#include "Actions.h"

/*******************************************************************************
	Display a pop up window
*******************************************************************************/
GroupItem *dISPLAY(GroupItem *item)
{
NSWindow 	*window = 0;
Details 	*detail = ::getDetail(item);
GroupItem 	*block = 0;
char 		*name = 0;
	[detail->view deselect];
	if ( block = detail->wig->get("popup") )
		if ( name = block->getText() )
			{
			block = (GroupItem*)Control::bwana->windows->get(name);
			if ( !block && detail->wig->get("file") )
				{
				Control::bwana->controller->convertWindowToPanel = 1;
				Control::bwana->controller->load(detail->wig);
				Control::bwana->controller->convertWindowToPanel = 0;
				block = (GroupItem*)Control::bwana->windows->get(name);
				}
			if ( block )
				detail = ::getDetail(block);
			}
	if ( !detail )
		{
		::fprintf(stderr,"Could not find window for: %s\n",item->tag);
		return 0;
		}
	if ( !block->getObject() )
		{
		::fprintf(stderr,"Could not find window for: %s\n",detail->wig->tag);
		return 0;
		}
	if ( block )
		{
		window = (NSWindow*)block->getObject();
		::setNoRoom(block,(unsigned int)0);
		::setModified(block);
		[window makeKeyAndOrderFront:window];
		/**********************************************************************
		reModified and redisplayed because otherwise pops up blank - WTF??
		**********************************************************************/
		::setModified(block);
		[window display];
		//dump(block);
		}
	return 0;
}

/*******************************************************************************
	Process button action
*******************************************************************************/
GroupItem *fIRE(GroupItem *item)
{
Details 	*detail = ::getDetail(item);
	::printf("Fire action for %s\n",detail->wig->tag);
	return 0;
}

/*******************************************************************************
    Set the current card associated with the item passed in to the card named in
    the text passed in.
*******************************************************************************/
GroupItem *gotoCARD(GroupItem *item)
{
char 		*cardName = item->getText();
GroupItem 	*card = item->find(cardName);
	if ( card )
		{
		GroupItem 	*cards = card->parent;
		Details 	*detail = ::getDetail(cards);
		if ( (detail->pane == 1) )
			{
			GroupItem 	*oldCard = cards->getGroup();
			::setNoRoom(oldCard,(unsigned int)1);
			cards->setGroup(card);
			::setNoRoom(card,(unsigned int)0);
			if ( detail->view->selection && detail->view->selection->getAttribute("setSource") )
				::setSourceTo(card,detail->view->selection);
			::setModified(detail->wig);
			}
		else	::fprintf(stderr,"gotoCARD: %s does not have cards attribute\n",cardName);
		}
	else	::fprintf(stderr,"gotoCARD: could not find %s\n",cardName);
	return 0;
}

/*******************************************************************************
	Process default image action
*******************************************************************************/
GroupItem *iMAGEwork(GroupItem *item)
{
Details 	*detail = ::getDetail(item);
NSImage 	*image = detail->object;
GroupItem 	*scale = detail->wig->get("sCALe");
GroupItem 	*offset = detail->wig->get("oFFSEt");
double 		factor = 0;
double 		newX = 0;
double 		newY = 0;
NSSize 		size;
NSPoint 	point;
NSPoint 	*atPoint = 0;
	if ( image )
		{
		size = [image size];
		if ( offset )
			atPoint = (NSPoint*)offset->getPointer();
		if ( scale )
			factor = scale->getNumber();
		if ([detail->event modifierFlags] & 1 << 18)
			{
			// at this point event should be set in detail
			point = [detail->view convertPoint:[detail->event locationInWindow] fromView:nil];
			newX = point.x - detail->frame.origin.x - detail->frame.size.width / 2;
			newY = point.y - detail->frame.origin.y - detail->frame.size.height / 2;
			if ( !atPoint )
				{
				atPoint = (NSPoint*)::calloc(1,sizeof(NSPoint));
				offset = detail->wig->addAttrValue("oFFSEt",(void*)atPoint);
				}
			atPoint->x += newX;
			atPoint->y += newY;
			offset->fLAG = 1;
			}
		else {
			if ( !factor )
				{
				factor = 1.0;
				detail->wig->addAttrDouble("sCALe",factor);
				scale = detail->wig->get("sCALe");
				}
			else
			if ( atPoint )
				{
				newX = atPoint->x / factor;
				newY = atPoint->y / factor;
				}
			factor += ([detail->event modifierFlags] & 1 << 17) ? -0.5 : 0.5;
			if ( atPoint )
				{
				atPoint->x = newX * factor;
				atPoint->y = newY * factor;
				}
			scale->setNumber(factor);
			}
		detail->imageSized = 1;
		::setModified(detail->wig);
		}
	return 0;
}

/*******************************************************************************
	Process menu action
*******************************************************************************/
GroupItem *mENU(GroupItem *item)
{
NSWindow 	*window = 0;
GroupItem 	*menu = 0;
GroupItem 	*attribute = 0;
GroupItem 	*offset = 0;
Details 	*baseDetail = 0;
Details 	*detail = ::getDetail(item);
double 		baseX = 0;
double 		baseY = 0;
double 		xOffset = 10;
double 		yOffset = 0;
NSRect 		baseFrame;
	/***************************************************************************
	Set baseX and baseY to the screen coordinates of the block invoking
	the menu (used to position the panel where you want the menu).
	***************************************************************************/
	if ( detail )
		{
		if ( attribute = detail->wig->get("pullDown") )
			menu = attribute->getGroup();
		window = [detail->view window];
		baseFrame = [window frame];
		baseX = baseFrame.origin.x + detail->frame.origin.x;
		baseY = baseFrame.origin.y + detail->frame.origin.y;
		}
	if ( !menu )
		{
		::fprintf(stderr,"Could not find menu\n");
		return 0;
		}
	//cout "Processing menu action\n";
	/***************************************************************************
	Set the panel frame
	***************************************************************************/
	detail = ::getDetail(menu);
	window = [detail->view window];
	baseDetail = ::getDetail(detail->view->base);
	if ( offset = menu->get("yOffset") )
		yOffset = offset->getNumber() + detail->frame.origin.y;
	detail = ::getDetail(menu);
	yOffset -= detail->frame.size.height;
	if ( offset = menu->get("xOffset") )
		xOffset = offset->getNumber() + detail->frame.origin.x;
	baseFrame = [detail->view frame];
	baseFrame.origin.x += baseX + xOffset;
	baseFrame.origin.y += baseY + yOffset;
	if ( baseFrame.origin.x < 0 )
		baseFrame.origin.x = 0;
	if ( baseFrame.origin.y < 0 )
		baseFrame.origin.y = 0;
	[window setFrame:baseFrame display:0];
	/***************************************************************************
	Menu should be already laid out
	***************************************************************************/
	detail->view->activeMenu = menu;
	::setNoRoom(menu,(unsigned int)0);
	Control::bwana->controller->activeView = detail->view;
	::setModified(offset);
	[window makeKeyAndOrderFront:window];
	/**************************************************************************
	reModified and redisplayed because otherwise it pops up blank - WTF??
	**************************************************************************/
	::setModified(offset);
	[window display];
	return 0;
}

/*******************************************************************************
	Process a selectBlock action. This sets the count of the bigify attribute to
    the position of the selected bloc and calls the bIGIFY method to redo the
    layout of the bigified item.
*******************************************************************************/
GroupItem *reBIGIFY(GroupItem *item)
{
GroupItem 	*bigify = item->findAttribute("bigify");
GroupItem 	*selected = Control::bwana->controller->activeView->selection;
GroupItem 	*wrapper = Control::bwana->controller->activeView->selection->parent;
GroupItem 	*bigItem = 0;
GroupItem 	*bigRow = 0;
GroupItem 	*group = 0;
char 		*selectTag = selected->tag;
	bigify = bigify->parent;
	if ( bigRow = bigify->getMember("bigRow") )
		while ( bigItem = bigRow->nextMember(bigItem) )
			if ( bigItem->get("width") )
				break;
	if ( *wrapper->tag == 'r' )
		bigRow->swap(wrapper);
	else	bigItem->swap(wrapper);
	if ( bigRow = bigify->getAttribute("sRCe") )
		{
		GroupItem 	*sourceItem = 0;
		Source 		*source = (Source*)bigRow->getPointer();
		source->current = source->priorStart;
		bigItem->tag = selected->tag;
		bigItem->setGroup(selected->getGroup());
		while ( group = bigify->walk(group) )
			if ( group->getAttribute("next") )
				{
				if ( group == bigItem )
					continue;
				sourceItem = source->next();
				if ( ::compare(sourceItem->tag,selectTag) == 0 )
					sourceItem = source->next();
				group->setGroup(sourceItem);
				group->tag = sourceItem->tag;
				}
		}
	::setModified(bigify);
	return 0;
}

/*******************************************************************************
	Selects tab named by item and stores the tab in the tab parent. A pointer
    to the body associated with the tab is stored in the tab.
*******************************************************************************/
GroupItem *sELECTtab(GroupItem *item)
{
GroupItem 	*body = 0;
GroupItem 	*tab = 0;
GroupItem 	*tabAttribute = 0;
GroupItem 	*tabs = 0;
Details 	*detail = ::getDetail(item);
	detail->setStyle();
	tabs = detail->wig->parent;
	if ( !tabs )
		{
		::fprintf(stderr,"%s: block associated w/tab select action must have a parent\n",detail->wig->tag);
		return 0;
		}
	/***************************************************************************
	Deselect prior tab and turn off tab body. The isTab flag in detail is set
	so that tab selection is not affected by any other random selection.
	***************************************************************************/
	detail->isTab = 1;
	if ( tab = tabs->getGroup() )
		{
		tab->processUpTo = 0;
		if ( tabAttribute = tab->getAttribute("tabBODY") )
			if ( body = tabAttribute->getGroup() )
				::setNoRoom(body,(unsigned int)1);
		//cout "sELECTtab: set no Room for",body.tag:;
		}
	tabs->setPointer((void*)detail->wig);
	// Here body is set to the body associated with this tab
	if ( tabAttribute = detail->wig->getAttribute("tabBODY") )
		if ( body = tabAttribute->getGroup() )
			{
			::setNoRoom(body,(unsigned int)0);
			body->parent->setPointer((void*)body);
			}
		else {
			::fprintf(stderr,"Could not find body of current tab\n");
			return 0;
			}
	detail->wig->processUpTo = 1;
	// makes the tag selected (in addition to its body)
	detail->view->selection = item;
	//cout "sELECTtab:",wig.tag,filler.getTagXML():;
	if ( tab = body->findAttribute("cards") )
		{
		tab->setText(body->tag);
		::setCARD(tab);
		}
	return 0;
}

/*******************************************************************************
	Sort by tag of item parent or item text depending upon whether or not the
    sort attribute has a value. If shift keyed, sort is descending.
*******************************************************************************/
GroupItem *sORT(GroupItem *item)
{
GroupItem 	*mask = 0;
GroupItem 	*group = 0;
Source 		*source = 0;
Details 	*detail = ::getDetail(item);
	group = item->findAttribute("sRCe");
	mask = detail->wig->get("sort");
	::printf("Sorting %s\n",detail->wig->tag);
	if ( group && mask )
		{
		if ( source = (Source*)group->getPointer() )
			{
			if ([detail->event modifierFlags] & 1 << 17)
				source->sourceItem->parts->isSorted = 2;
			else	source->sourceItem->parts->isSorted = 1;
			source->sourceItem->sort(mask->getText());
			}
		::setModified(detail->wig);
		}
	if ( !source )
		::fprintf(stderr,"ERROR sort: source or sort attribute missing for %s\n",detail->wig->tag);
	return 0;
}

/*******************************************************************************
	Run the next actions associated with the item passed in
*******************************************************************************/
GroupItem *setFLEXcontent(GroupItem *item)
{
GroupItem 	*flexed = item->parent;
GroupItem 	*stuff = 0;
GroupItem 	*group = 0;
	if ( flexed )
		{
		while ( group = flexed->nextMember(group) )
			if ( stuff = group->get("next") )
				{
				//cout "setFLEXcontent:",group.tag,group.index:;
				::nEXT(stuff);
				}
		}
	return 0;
}

/*******************************************************************************
	Toggle a block on or off.
*******************************************************************************/
GroupItem *tOGGLE(GroupItem *item)
{
GroupItem 	*toggle = 0;
GroupItem 	*wrapper = 0;
GroupItem 	*group = 0;
char 		*name = 0;
	toggle = item->getAttribute("toggled");
	if ( name = toggle->getText() )
		{
		//cout "Toggle: " group.getTagXML():;
		if ( wrapper = GroupControl::groupController->groupParser->locate(name) )
			{
			while ( group = wrapper->walk(group) )
				if ( toggle = group->getAttribute("toggled") )
					{
					if ( ::compare(name,toggle->getText()) == 0 )
						if ( group->isTarget )
							::setNoRoom(group,(unsigned int)0);
						else	::setNoRoom(group,(unsigned int)1);
					::printf("tOGGLE: changed toggle of %s to %u\n",group->tag,group->isTarget);
					}
			::setModified(wrapper);
			}
		else	::fprintf(stderr,"tOGGLE ERROR: could not find %s\n",name);
		}
	else {
		::fprintf(stderr,"tOGGLE ERROR: name does not exist\n");
		return 0;
		}
	return 0;
}

/*******************************************************************************
	Process expand action in support of trees. This differs from the matrix
    expand only in that there is no option for expanding columns and when you
    click on an expanded item it collapses. Also, uses regular clicks not right
    clicks.
*******************************************************************************/
GroupItem *xPAND(GroupItem *item)
{
Details 	*detail = ::getDetail(item);
GroupItem 	*group = detail->wig->findAttribute("leaf");
	if ( group )
		group = group->parent;
	[detail->view deselect];
	//cout "xpand " wig.tag,xpand.tag,xpand.index:;
	if ( !group )
		{
		::fprintf(stderr,"xPAND: could not find leaf to expand\n");
		return 0;
		}
	if ( group->expanded )
		cOLLAPSErow(group);
	else	expandTREE(group);
	::setExpander(group);
	::setModified(group);
	return 0;
}

Actions::Actions()
{
	Control::bwana->mapAction("card",::gotoCARD);
	Control::bwana->mapAction("display",::dISPLAY);
	Control::bwana->mapAction("expandTree",::xPAND);
	Control::bwana->mapAction("fire",::fIRE);
	Control::bwana->mapAction("iMAGEwork",::iMAGEwork);
	Control::bwana->mapAction("menu",::mENU);
	Control::bwana->mapAction("reBigify",::reBIGIFY);
	Control::bwana->mapAction("sORT",::sORT);
	Control::bwana->mapAction("tab",::sELECTtab);
	Control::bwana->mapAction("toggle",::tOGGLE);
}
/*	Warning: the following methods were referenced but not declared
	cOLLAPSErow(GroupItem*)
	expandTREE(GroupItem*)
*/
