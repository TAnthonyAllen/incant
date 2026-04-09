#include <Cocoa/Cocoa.h>
#include <stdlib.h>
#include <WebKit/WebKit.h>
#include <string.h>
#include <stdio.h>
#include "GroupItem.h"
#include "OCroutines.h"
#include "GroupList.h"
#include "Details.h"
#include "DoubleLinkList.h"
#include "DoubleLink.h"
#include "Bwana.h"
#include "Source.h"

/*******************************************************************************
	Constructors
*******************************************************************************/
Source::Source()
{
	list = 0;
	sourceItem = 0;
	listeners = 0;
	current = 0;
	priorStart = 0;
	exhausted = 0;
	noNext = 0;
	resetOnResize = 0;
	sourceSelected = 0;
	sorted = 0;
	sourceAttributes = 0;
	length = 0;
	// empty constructor
}

Source::Source(GroupItem *item)
{
	list = 0;
	sourceItem = 0;
	listeners = 0;
	current = 0;
	priorStart = 0;
	exhausted = 0;
	noNext = 0;
	resetOnResize = 0;
	sourceSelected = 0;
	sorted = 0;
	sourceAttributes = 0;
	length = 0;
	setSourceItem(item);
}

/*****************************************************************************
	Add a listener to this source.
*****************************************************************************/
void Source::addListener(GroupItem *item)
{
	if ( !listeners )
		listeners = new DoubleLinkList();
	// Adding a listener done as follows to not bugger item parent
	//cout "addListener",item.tag:;
	listeners->add(item);
}

/******************************************************************************
	Debugging dump of list
******************************************************************************/
void Source::dump()
{
GroupItem 	**atList = 0;
GroupItem 	*item = 0;
	::printf("Source listeners\n");
	if ( !listeners )
		::printf("\tnone\n");
	else
	while ( item = (GroupItem*)listeners->next() )
		::printf("\t%s\n",item->getTagXML());
	if ( sourceItem )
		{
		::printf("Source: %s\n\tContent\n",sourceItem->getTagXML());
		if ( list )
			for ( atList = list; atList && *atList; atList++ )
				{
				item = *atList;
				::printf("\t\t%s\n",item->getTagXML());
				}
		else
		if ( sourceAttributes && item->hasAttributes )
			while ( item = sourceItem->nextAttribute(item) )
				::printf("\t\t%s\n",item->getTagXML());
		else
		if ( item->hasMembers )
			while ( item = sourceItem->nextMember(item) )
				::printf("\t\t%s\n",item->getTagXML());
		else	::printf("\tContent empty\n");
		}
}

/*****************************************************************************
	Returns the indexed element of this list, assuming it is in range,
	otherwise null. Index starts at one and is decremented because the
    list index starts at zero.
*****************************************************************************/
GroupItem *Source::get(int index)
{
	if ( !list )
		setList();
	/*************************************************************************
	current gets modified when the source is scrolled so it is added
	to index so get returns the current element relative to scrolling
	*************************************************************************/
	index += current;
	if ( --index >= 0 && index < sourceItem->parts->length )
		return list[index];
	return 0;
}

/*****************************************************************************
	Returns the next element of this source and increments the current index
    that points to the next item. Sets exhausted if at the end of the list.
*****************************************************************************/
GroupItem *Source::next()
{
GroupItem 	*item = 0;
	if ( !noNext )
		{
		if ( sourceItem )
			{
			if ( !list )
				setList();
			if ( !exhausted && current >= 0 && current + 1 < sourceItem->parts->length )
				item = list[current++];
			}
		if ( !item )
			exhausted = 1;
		}
	return item;
}

/*****************************************************************************
	Reduce current by the amount passed in making sure that it does not exceed
	the bounds of the underlying list.
*****************************************************************************/
int Source::pageShift(int length)
{
int 	start = current;
	noNext = 0;
	if ( (exhausted && length < 0) || (start == 0 && length > 0) )
		return 0;
	start -= length;
	if ( start >= sourceItem->parts->length )
		{
		start = sourceItem->parts->length - 1;
		exhausted = 1;
		}
	else
	if ( start <= 0 )
		{
		start = 0;
		exhausted = 0;
		}
	current = start;
	return 1;
}

/*******************************************************************************
    Reset current pointer - not sure if should be setting current to priorStart
*******************************************************************************/
void Source::reset()
{
	noNext = 0;
	current = priorStart;
	exhausted = current < length;
}

/******************************************************************************
	Set the list to a double indirection array of sourceItem contents.
    If the sourceItem has no contents, creates an empty list.
******************************************************************************/
void Source::setList()
{
	//cout "Setting list for " sourceItem.getTagXML():;
	if ( sourceItem )
		{
		GroupItem 	*group = 0;
		if ( list )
			::free(list);
		if ( !sourceItem->parts )
			list = (GroupItem**)::calloc(2,sizeof(GroupItem*));
		else {
			list = (GroupItem**)::calloc(sourceItem->parts->length + 1,sizeof(GroupItem*));
			GroupItem **atList = list;
			reset();
			length = 0;
			if ( !sourceAttributes && sourceItem->hasMembers )
				while ( group = sourceItem->nextMember() )
					{
					*atList++ = group;
					length++;
					}
			else
			if ( sourceAttributes && sourceItem->hasAttributes )
				while ( group = sourceItem->nextAttribute() )
					{
					*atList++ = group;
					length++;
					}
			}
		}
}

/******************************************************************************
	sourceItem setter
******************************************************************************/
void Source::setSourceItem(GroupItem *item)
{
	if ( item )
		{
		sourceItem = item;
		exhausted = 0;
		sorted = 0;
		current = 0;
		if ( list )
			{
			::free(list);
			list = 0;
			}
		updateListeners();
		}
	else	sourceItem = 0;
}

/*****************************************************************************
	Sort the source. sortAscending or sortDescending must be set first.
*****************************************************************************/
void Source::sort(char *name)
{
	noNext = 0;
	if ( !name )
		{
		::fprintf(stderr,"Source sort: name passed in is null\n");
		return;
		}
	sourceItem->sort(name);
	setList();
	sorted = 1;
	current = 0;
	exhausted = 0;
	updateListeners();
}

/*****************************************************************************
	Updates listeners that depend on this source (set in the sOURCE method).
*****************************************************************************/
void Source::updateListeners()
{
GroupItem 	*item = 0;
Details 	*detail = 0;
	if ( !listeners )
		return;
	//cout `"updateListeners for source: " sourceItem.tag:;
	while ( item = (GroupItem*)listeners->next() )
		{
		if ( !(detail = ::getDetail(item)) )
			{
			::fprintf(stderr,"ERROR: Source updateListeners could not find detail for %s\n",item->tag);
			return;
			}
		//cout ``"updateListeners for " item.tag,item.index:;
		if ( detail->hasReactions )
			detail->processReaction();
		}
	//cout `"updateListeners done":;
}
