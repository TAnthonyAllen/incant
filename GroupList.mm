#include <Cocoa/Cocoa.h>
#include <string.h>
#include <stdio.h>
#include "OCroutines.h"
#include "StringRoutines.h"
#include "GroupItem.h"
#include "PLGset.h"
#include "GroupBody.h"
#include "GroupStak.h"
#include "GroupDraw.h"
#include "GroupList.h"

/*****************************************************************************
	Constructor
*****************************************************************************/
GroupList::GroupList(GroupItem *item)
{
	firstInList = 0;
	lastInList = 0;
	listLength = 0;
	stakked = 0;
	if ( item->groupBody->flags.binType )
		{
		PLGset 	*set = new PLGset();
		set->name = ::concat(3,item->groupBody->tag,"InSet","\n");
		if ( !item->groupBody->guardSet )
			item->groupBody->guardSet = new PLGset();
		item->setCharacterSet(set);
		item->groupBody->flags.guarding = 1;
		}
}

/***************************************************************************
	Clear the list.
***************************************************************************/
void GroupList::clear()
{
	firstInList = lastInList = 0;
	listLength = 0;
	if ( stakked )
		stakked->clearStak();
}
