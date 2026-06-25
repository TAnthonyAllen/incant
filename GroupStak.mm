#include <Cocoa/Cocoa.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "OCroutines.h"
#include "GroupItem.h"
#include "GroupList.h"
#include "GroupBody.h"
#include "GroupDraw.h"
#include "GroupStak.h"

/*****************************************************************************
	Constructor initializes and fills the stak from the field passed in
    leaving space to expand
*****************************************************************************/
GroupStak::GroupStak(GroupItem *g)
{
	length = 0;
	size = 0;
	entry = 0;
	stakSource = g;
	if ( !g->groupBody->groupList || !g->groupBody->groupList->listLength )
		size = 100;
	else	size = g->groupBody->groupList->listLength + 10;
	start = (GroupItem**)::calloc(size,sizeof(GroupItem*));
	end = start;
	if ( g->groupBody->groupList )
		resetStak();
}

/*****************************************************************************
	Clear the stack. Does not clear the guardSet (if any entry is removed
    the guardSet might end up overly guarded).
*****************************************************************************/
void GroupStak::clearStak()
{
	length = 0;
	entry = end = start;
	*end = 0;
}

/***************************************************************************
	Search stak for name using a binary search
***************************************************************************/
GroupItem *GroupStak::getFromStak(char *name)
{
	if ( stakSource->groupBody->flags.altered )
		resetStak();
int low = 0;
int high = length - 1;
int mid = 0;
int offset = 0;
GroupItem *grup = *start;
	offset = ::strcmp(name,grup->groupBody->tag);
	if ( offset < 0 )
		return 0;
	else
	if ( offset == 0 )
		return grup;
	grup = *(start + high);
	offset = ::strcmp(name,grup->groupBody->tag);
	if ( offset > 0 )
		return 0;
	else
	if ( offset == 0 )
		return grup;
	while ( high - low > 1 )
		{
		mid = (low + high) / 2;
		grup = *(start + mid);
		offset = ::strcmp(name,grup->groupBody->tag);
		if ( !offset )
			return grup;
		else
		if ( offset < 0 )
			{
			high = --mid;
			grup = *(start + high);
			offset = ::strcmp(name,grup->groupBody->tag);
			if ( offset > 0 )
				return 0;
			else
			if ( offset == 0 )
				return grup;
			}
		else {
			low = ++mid;
			grup = *(start + low);
			offset = ::strcmp(name,grup->groupBody->tag);
			if ( offset < 0 )
				return 0;
			else
			if ( offset == 0 )
				return grup;
			}
		}
	return 0;
}

/***************************************************************************
	return the entry on the stak at the index position passed in (index starts
    at 0) with no complaint if index is out of range.
***************************************************************************/
GroupItem *GroupStak::getFromStak(int indx)
{
	if ( stakSource->groupBody->flags.altered )
		resetStak();
	if ( length > 0 && length < indx )
		return *(start + indx);
	return 0;
}

/*****************************************************************************
	List out entries on the stak.
*****************************************************************************/
void GroupStak::listStakked()
{
GroupItem 	*grup = 0;
	::printf("List of entries in %s\n",stakSource->groupBody->tag);
	entry = 0;
	while ( grup = next() )
		::printf("\t%s\n",grup->groupBody->tag);
}

/*****************************************************************************
	Iterates thru the stack returning the next entry.
*****************************************************************************/
GroupItem *GroupStak::next()
{
	if ( stakSource->groupBody->flags.altered )
		resetStak();
	if ( length )
		{
		if ( !entry || entry < start )
			entry = start;
		else	entry++;
		if ( entry >= end )
			entry = 0;
		}
	else	entry = 0;
	if ( entry )
		return *entry;
	return 0;
}

GroupItem *GroupStak::pop()
{
GroupItem 	*top = 0;
	if ( stakSource->groupBody->flags.altered )
		resetStak();
	if ( length )
		{
		length--;
		end--;
		top = *end;
		*end = 0;
		if ( !length )
			entry = 0;
		}
	return top;
}

/*****************************************************************************
	Iterates thru the stack in lifo order returning the next entry.
*****************************************************************************/
GroupItem *GroupStak::prior()
{
	if ( stakSource->groupBody->flags.altered )
		resetStak();
	if ( length )
		{
		if ( !entry || entry >= end )
			entry = end - 1;
		else	entry--;
		if ( entry < start )
			entry = 0;
		}
	else	entry = 0;
	if ( entry )
		return *entry;
	return 0;
}

/*****************************************************************************
	Push and pop methods just move the top pointer and set length, resizing
	when length reaches size
*****************************************************************************/
void GroupStak::push(GroupItem *grup)
{
	if ( stakSource->groupBody->flags.altered )
		resetStak();
	if ( length == size )
		resize();
	*end++ = grup;
	length++;
}

/******************************************************************************
	Build or rebuild the GroupStak from the stackSource. Members and attributes
    get added to the stack.
******************************************************************************/
void GroupStak::resetStak()
{
GroupItem 	*part = 0;
	stakSource->groupBody->flags.altered = 0;
	if ( length )
		clearStak();
	if ( stakSource->groupBody->groupList->listLength )
		while ( part = stakSource->next(part) )
			push(part);
}

/*****************************************************************************
	Adds reallocs the stak to be big enough to contain the stakSource plus 10
*****************************************************************************/
void GroupStak::resize()
{
	size = stakSource->groupBody->groupList->listLength + 10;
	start = (GroupItem**)::reallocf((void*)start,size * sizeof(void*));
	end = start + length;
	*end = 0;
	entry = 0;
}
