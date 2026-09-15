#include <Cocoa/Cocoa.h>
#include <dispatch/dispatch.h>
#include <dlfcn.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "OCroutines.h"
#include "StringRoutines.h"
#include "GroupItem.h"
#include "DoubleLinkList.h"
#include "jitContext.h"
#include "Stak.h"
#include "Buffer.h"
#include "DispatchQ.h"
#include "BitMAP.h"
#include "GroupRules.h"
#include "GroupControl.h"
#include "GroupList.h"
#include "GroupBody.h"
#include "regex.h"
#include "RuleStuff.h"
#include "GroupStak.h"
#include "Bytecode.h"
#include "PLGset.h"
#include "PLGrgx.h"
#include "PLGitem.h"
#include "Stylish.h"
#include "measure.h"
#include "GroupDraw.h"

/*****************************************************************************
                                compareAttribute
    Compare attribute value of group1 to attribute value of group2. The results
    get a little arbitrary if the values differ in type. Attributes are less than members.
    The way this works is text in the group being sorted is set to the name
    of the tag in the attributes whose values are used in the compare for the sort
*****************************************************************************/
int compareAttribute(GroupItem *group1, GroupItem *group2)
{
char 		*traitName = group1->parent->getText();
GroupItem 	*trait1 = group1->get(traitName);
GroupItem 	*trait2 = group2->get(traitName);
int 		result = 0;
	if ( isAttribute(group1->options.affiliation) && !isAttribute(group2->options.affiliation) )
		result = -1;
	else
	if ( isMember(group1->options.affiliation) && !isMember(group2->options.affiliation) )
		result = 1;
	else
	if ( !result && isMember(group1->options.affiliation) )
		{
		if ( trait1->groupBody->flags.data == trait2->groupBody->flags.data )
			switch (trait1->groupBody->flags.data)
				{
				case 5:
				case 9:
					result = (int)(trait1->getNumber() - trait2->getNumber());
					break;
				case 7:
					result = trait1->getItem()->compare(trait2->getItem());
					break;
				case 13:
					result = ::compare(trait1->getText(),trait2->getText());
				}
		else
		if ( !trait1->groupBody->flags.data )
			result = -1;
		else	result = 1;
		}
	return result;
}

/*****************************************************************************
                                compareTags
    Compare tag of group1 to tag of group2. Attributes are less than members.
*****************************************************************************/
int compareTags(GroupItem *group1, GroupItem *group2)
{
int 	result = 0;
	if ( isAttribute(group1->options.affiliation) && !isAttribute(group2->options.affiliation) )
		result = -1;
	else
	if ( isMember(group1->options.affiliation) && !isMember(group2->options.affiliation) )
		result = 1;
	else
	if ( !result && isMember(group1->options.affiliation) )
		{
		result = ::compare(group1->groupBody->tag,group2->groupBody->tag);
		if ( !result && group2->groupBody->registry && group2->groupBody->registry == group1->groupBody->registry && group2->groupBody->registry->getAttribute("loadByValue") )
			result = ::compare(group1->getText(),group2->getText());
		}
	return result;
}

/*****************************************************************************
                                compareValues
    Compare value of group1 to value of group2.
*****************************************************************************/
int compareValues(GroupItem *group1, GroupItem *group2)
{
int 	result = -1;
	if ( group1 && !group2 )
		result = 1;
	else
	if ( group2 && !group1 )
		result = -1;
	else
	if ( group1->groupBody == group2->groupBody )
		result = 0;
	else
	if ( group1->groupBody->flags.data )
		switch (group1->groupBody->flags.data)
			{
			case 7:
				result = group1->getItem()->compare(group2->getItem());
				break;
			case 9:
				if ( isCOUNT(group2->groupBody->flags.data) || isNUMBER(group2->groupBody->flags.data) || isSTRING(group2->groupBody->flags.data) )
					result = (int)(group1->groupBody->gNumber - group2->getNumber());
				break;
			case 4:
			case 13:
			case 14:
				if ( isCOUNT(group2->groupBody->flags.data) || isNUMBER(group2->groupBody->flags.data) )
					result = group1->getCount() - group2->getCount();
				else	result = ::compare(group1->getText(),group2->getText());
				break;
			case 5:
				if ( isCOUNT(group2->groupBody->flags.data) || isNUMBER(group2->groupBody->flags.data) || isSTRING(group2->groupBody->flags.data) )
					result = group1->getCount() - group2->getCount();
				break;
			default:
				result = ::compare(group1->getText(),group2->getText());
			}
	else
	if ( group2->groupBody->flags.data )
		result = -1;
	else	result = ::compare(group1->getText(),group2->getText());
	return result;
}

/*******************************************************************************
                                GroupItem
    GroupItem constructors
*******************************************************************************/
GroupItem::GroupItem()
{
	parent = 0;
	nextInParent = 0;
	priorInParent = 0;
	rStuff = 0;
	jitData = 0;
	groupBody = new GroupBody();
	groupBody->flags.isSingleton = 1;
}

/******************************************************************************
                                GroupItem
    Copy constructor. Changes to this group will change the group passed in and
    vice versa. This group will have no parent (that will change as soon as it
    is added to another). The affiliation remains the same pending any change
    in parent.
******************************************************************************/
GroupItem::GroupItem(GroupItem *grup)
{
	parent = 0;
	nextInParent = 0;
	priorInParent = 0;
	rStuff = 0;
	jitData = 0;
	groupBody = grup->groupBody;
	options.isCopy = 1;
	if ( grup->rStuff )
		{
		rStuff = new RuleStuff(this);
		*rStuff = *grup->getRStuff();
		rStuff->rule = this;
		rStuff->followed = rStuff->isOK = rStuff->sukcess = 0;
		}
}

GroupItem::GroupItem(char *c)
{
	parent = 0;
	nextInParent = 0;
	priorInParent = 0;
	rStuff = 0;
	jitData = 0;
	groupBody = new GroupBody(c);
	groupBody->flags.isSingleton = 1;
}

/***************************************************************************
                                addAttribute
	Add an attribute.
***************************************************************************/
GroupItem *GroupItem::addAttribute(GroupItem *grup)
{
	if ( !grup )
		return 0;
	if ( grup->groupBody->flags.mergeOn && groupBody->flags.mergeOn )
		{
		merge(grup);
		return this;
		}
	grup = addGroup(grup);
	grup->options.affiliation = 1;
	groupBody->flags.hasAttributes = 1;
	/***************************************************************
	hasTraits is set if the field passed in is not noPrint-class.
	***************************************************************/
	if ( !grup->groupBody->flags.noPrint )
		groupBody->flags.hasTraits = 1;
	return grup;
}

/***************************************************************************
                                addGroup
	Add a group to this group. Should only be called from addAttribute()
    or addMember().
***************************************************************************/
GroupItem *GroupItem::addGroup(GroupItem *group)
{
	if ( group )
		{
		if ( !groupBody->groupList )
			groupBody->groupList = new GroupList(this);
		if ( group == this )
			{
			::fprintf(stderr,"GroupItem add: Tried to add %s to itself\n",group->groupBody->tag);
			return 0;
			}
		if ( isREGISTRY(groupBody->flags.binType) || isCLASS(groupBody->flags.binType) )
			if ( !group->groupBody->registry )
				group->groupBody->registry = this;
		/***************************************************************
		The following handles adding an attribute or member.
		Note: if group has a parent it gets copied (using new) before
		it is added.
		***************************************************************/
		if ( group->parent )
			group = new GroupItem(group);
		group->parent = this;
		if ( groupBody->flags.isSorted || groupBody->flags.actionType )
			put(group);
		else	push(group);
		groupBody->flags.isInitialized = 1;
		if ( !isREGISTRY(groupBody->flags.binType) && group->groupBody->registry && group->groupBody->registry->get("grouped") )
			group->addMember(this);
		if ( groupBody->flags.binType )
			{
			PLGset 	*binGuard = groupBody->guardSet;
			groupBody->flags.altered = 1;
			binGuard->set((int)*group->groupBody->tag);
			binGuard = getCharacterSet();
			binGuard->setSimple(group->groupBody->tag);
			if ( groupBody->flags.isIndexed )
				group->setCount(groupBody->groupList->listLength);
			}
		}
	return group;
}

/***************************************************************************
                                addMember
	Add a member.
***************************************************************************/
GroupItem *GroupItem::addMember(GroupItem *grup)
{
	if ( !grup )
		return 0;
	grup = addGroup(grup);
	grup->options.affiliation = 2;
	groupBody->flags.hasMembers = 1;
	groupBody->flags.isSingleton = 0;
	return grup;
}

/***************************************************************************
                                addString
	Adds an attribute, or if this is a container (binType), adds a member.
    If the entry already exists, returns it,
***************************************************************************/
GroupItem *GroupItem::addString(char *n)
{
GroupItem 	*group = 0;
	if ( n )
		{
		group = getFromList(n);
		if ( !group )
			{
			group = new GroupItem(n);
			if ( groupBody->flags.binType )
				group = addMember(group);
			else	group = addAttribute(group);
			}
		}
	return group;
}

/***************************************************************************
                                allAttributesOptional
    // allAttributesOptional an attribute with no rStuff counts as MANDATORY -- not yet known is not the same as optional
***************************************************************************/
int GroupItem::allAttributesOptional()
{
GroupItem 	*attr = 0;
	while ( attr = nextAttribute(attr) )
		if ( !attr->getRStuff() || attr->getRStuff()->min )
			return 0;
	return 1;
}

/*****************************************************************************
                                append
	Append the group passed in to this one. Does not care if there is no
    parent (does not increment parent or listLength).
*****************************************************************************/
void GroupItem::append(GroupItem *grup)
{
	grup->priorInParent = this;
	grup->nextInParent = nextInParent;
	if ( nextInParent )
		nextInParent->priorInParent = grup;
	else
	if ( parent )
		parent->groupBody->groupList->lastInList = grup;
	nextInParent = grup;
}

/***************************************************************************
                                attachLabel
    // attachLabel the yield protocol IS the skip -- NULL failed, labelNO yields nothing, anything else
    // attachLabel attaches. Do not reach for a flag here, it was falsified fleet-wide
***************************************************************************/
void GroupItem::attachLabel(RuleStuff *stuff, RuleStuff *pStuff, int promote)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*lab = stuff->label;
	if ( !lab || lab == ruler->labelNO )
		return;
	if ( !pStuff )
		return;
	// caseLocalizer parseTrace-gated -- the interesting failure is a SILENT return at the no-label guard, and
	// caseLocalizer an absent attach announces nothing on its own
	if ( ruler->parseTrace )
		::fprintf(stderr,"    attachLabel lab=%s promote=%d isTarget=%u pLabel=%lu pRule=%s\n",lab->groupBody->tag,promote,stuff->isTarget,(pStuff->label != 0),pStuff->ruleName);
	// promoteUnguarded promotion is an assign and is NOT guarded on the destination -- a parent with no label
	// promoteUnguarded yet is the normal case here, and this is what gives it one
	// pc1Restated the disjunct is PC-1 RESTATED, not loosened -- the forbidden consult is the one where a
	// pc1Restated parent label exists, because that is the one with a subtree to destroy
	if ( (promote || !pStuff->label) && stuff->isTarget )
		{
		pStuff->label = lab;
		lab->groupBody->tag = pStuff->ruleName;
		return;
		}
	// attachGuardHere the guard belongs HERE and not above the promote case -- both placements were measured
	// attachGuardHere and each crashes the fleet the other way, three lines apart
	// ia2Narrow the landed spelling is the NARROW one -- the broad one was also green and was rejected
	// ia2Narrow because ZERO of 216 calls fell in the cell where the two differ
	if ( !pStuff->label )
		{
		// dropSiteProbe parseTrace-gated -- at the instant an option's label is dropped, is there a reachable
		// dropSiteProbe destination in the frame, or is the label simply homeless
		
		if ( GroupControl::groupController->groupRules->parseTrace )
		{
		const char *pName  = pStuff->ruleName ? pStuff->ruleName : "(none)";
		const char *pPar   = pStuff->parentLabel ? pStuff->parentLabel->groupBody->tag : "(null)";
		const char *ppName = (pStuff->parentStuff && pStuff->parentStuff->ruleName)
		? pStuff->parentStuff->ruleName : "(none)";
		const char *ppLab  = (pStuff->parentStuff && pStuff->parentStuff->label)
		? pStuff->parentStuff->label->groupBody->tag : "(null)";
		const char *sPar   = stuff->parentLabel ? stuff->parentLabel->groupBody->tag : "(null)";
		::fprintf(stderr,"    IA2 DROP  lab=%s  pRule=%s  pStuff.parentLabel=%s  pStuff.parentStuff=%s pp.label=%s  stuff.parentLabel=%s\n",
		lab->groupBody->tag,pName,pPar,ppName,ppLab,sPar);
		}
		
		// rung2bRed reachable is not correct -- an alternation must YIELD its winning option's label upward,
		// rung2bRed never park it in the grandparent's subtree
		return;
		}
	if ( promote && isGROUP(lab->groupBody->flags.data) && stuff->max > 1 )
		{
		pStuff->label->addAttribute(lab->getGroup());
		lab->clear();
		lab->groupBody->flags.fLAG = 1;
		return;
		}
	pStuff->label->addAttribute(lab);
}

/***************************************************************************
                                captureSpan
    // captureSpan the formula is THIS chair's -- from the action's chair the same rule reads the other way
    // captureSpan round, so the action-chair spelling must never be copied here
***************************************************************************/
void GroupItem::captureSpan(RuleStuff *stuff)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*label = stuff->label;
char 		*spanFrom = stuff->hereAt;
char 		*spanTo = ruler->atRuleMark;
int 		spanLen = 0;
	if ( !label )
		return;
	if ( !spanFrom )
		return;
	if ( !spanTo )
		return;
	spanLen = (int)(spanTo - spanFrom);
	if ( spanLen < 0 )
		return;
	
	// oracleBeforeWrite the comparator samples the product BEFORE the write below, or it compares this function
	// oracleBeforeWrite to itself and reads MATCH forever
	if ( GroupControl::groupController->groupRules->parseTrace )
	{
	int   shipLen  = isTOKEN(label->groupBody->flags.data) ? label->groupBody->gCount : -1;
	char *shipFrom = isTOKEN(label->groupBody->flags.data) ? label->groupBody->gText : 0;
	const char *verdict;
	if ( !shipFrom )                                   verdict = "ORACLE-ABSENT";
	else if ( shipLen <= 0 && spanLen <= 0 )           verdict = "VOID-bothEmpty";
	else if ( shipLen != spanLen )                     verdict = "DIVERGE-len";
	else if ( ::strncmp(shipFrom,spanFrom,spanLen) )   verdict = "DIVERGE-bytes";
	else                                               verdict = "MATCH";
	::fprintf(stderr,"CAPTURE %s rule=%s shipLen=%d spanLen=%d ship=[%.*s] span=[%.*s]\n",
	verdict, groupBody->tag ? groupBody->tag : "?", shipLen, spanLen,
	shipLen > 0 ? shipLen : 0, shipFrom ? shipFrom : "",
	spanLen > 0 ? spanLen : 0, spanFrom);
	}
	
	label->setToken(spanFrom,spanLen);
}

/******************************************************************************
                                clear
    Clear list and data. Flags are not cleared, neither is rStuff.
******************************************************************************/
void GroupItem::clear()
{
	clearData();
	clearList();
}

/******************************************************************************
                                clearData
    Clears data. Does not clear pointer.
******************************************************************************/
void GroupItem::clearData()
{
	if ( !groupBody->flags.isPointer )
		groupBody->gText = 0;
	groupBody->flags.data = 0;
	groupBody->gNumber = 0;
}

/***************************************************************************
                                clearList
	Clear the list.
***************************************************************************/
void GroupItem::clearList()
{
	if ( !groupBody->groupList )
		return;
	groupBody->groupList = 0;
	groupBody->flags.hasAttributes = groupBody->flags.hasMembers = 0;
}

/*****************************************************************************
                                contents
	Returns true if this is a registry or data or has anything on its list
    If fLAG is set return true even without contents
*****************************************************************************/
int GroupItem::contents()
{
	if ( isREGISTRY(groupBody->flags.binType) || groupBody->flags.data )
		return 1;
	if ( groupBody->groupList && groupBody->groupList->listLength )
		return 1;
	return 0;
}

/*****************************************************************************
                                copyData
	copyData copies data but not lists. Data type is changed to match input.
    It is called by setContent() which then copies list;
*****************************************************************************/
void GroupItem::copyData(GroupItem *item)
{
	if ( item )
		if ( !item->groupBody->flags.data )
			setText(item->groupBody->tag);
		else {
			groupBody->flags.data = item->groupBody->flags.data;
			groupBody->gText = item->groupBody->gText;
			groupBody->gNumber = item->groupBody->gNumber;
			}
	if ( groupBody->flags.data )
		groupBody->flags.isInitialized = 1;
	else	groupBody->flags.isInitialized = 0;
	if ( groupBody->flags.hasListeners )
		updateListeners();
}

/*****************************************************************************
                                copyListFrom
    Copy the list of this from the list of the group passed in. The new entries
    have the same data content as the source entries (but they are copies
    so they have a new parent);
*****************************************************************************/
void GroupItem::copyListFrom(GroupItem *grup)
{
GroupItem 	*fild = 0;
GroupItem 	*entry = 0;
	clearList();
	if ( grup->groupBody->groupList )
		while ( entry = grup->next(entry) )
			{
			if ( entry->groupBody->groupList )
				fild = new GroupItem(entry);
			else	fild = entry;
			if ( isAttribute(entry->options.affiliation) )
				addAttribute(fild);
			else	addMember(fild);
			}
}

/*****************************************************************************
                                copyListTo
    Copy this list into the grup passed in.
*****************************************************************************/
void GroupItem::copyListTo(GroupItem *grup)
{
GroupItem 	*entry = 0;
	if ( groupBody->groupList )
		while ( entry = next(entry) )
			if ( isAttribute(entry->options.affiliation) )
				grup->addAttribute(entry);
			else	grup->addMember(entry);
}

/***************************************************************************
                                dQ
	Like pop treats the list as stack but pops off first item, not last.
***************************************************************************/
GroupItem *GroupItem::dQ()
{
GroupItem 	*stuff = 0;
	if ( groupBody->groupList->firstInList )
		{
		GroupItem 	*follows = groupBody->groupList->firstInList->nextInParent;
		stuff = groupBody->groupList->firstInList->remove();
		if ( follows )
			follows->priorInParent = 0;
		groupBody->groupList->firstInList = follows;
		if ( !groupBody->groupList->listLength )
			groupBody->groupList = 0;
		}
	return stuff;
}

/***************************************************************************
                                definingRule
    // definingRule the definer is the first child's PARENT, by pointer, with no name lookup -- and the test
    // definingRule discriminates, which is why it is unguarded on purpose
***************************************************************************/
GroupItem *GroupItem::definingRule()
{
GroupItem 	*first = get(1);
GroupItem 	*owner = 0;
	if ( first )
		owner = first->parent;
	if ( owner && owner != this )
		return owner;
	return this;
}

/*****************************************************************************
                                dispatch
	Run a group method in the dispatch Q
*****************************************************************************/
void GroupItem::dispatch()
{
DispatchQ 	*dq = GroupControl::groupController->dispatchQ;
	dq->data = (void*)this;
	if ( dq->dispatchGroup )
		::dispatch_group_async_f(dq->dispatchGroup,dq->qu,dq->data,::dispatcher);
	else	::dispatch_async_f(dq->qu,dq->data,::dispatcher);
}

/*****************************************************************************
                                dumpField
	dumpField — debugging dump of one field: tag, data value, and (if it has
	a list) the member tags only. tok cousin of the incant dumpField action.
	Uses cerr (not print) so it never disturbs the sticky print default.
	Read-only; never mutates. Call as item.dumpField().
*****************************************************************************/
void GroupItem::dumpField()
{
GroupItem 	*grup = 0;
	if ( groupBody->groupList )
		{
		::fprintf(stderr,"   %s  | data= %s  | listLen= %d\n",groupBody->tag,getText(),groupBody->groupList->listLength);
		while ( grup = next(grup) )
			::fprintf(stderr,"      -  %s\n",grup->groupBody->tag);
		}
	else	::fprintf(stderr,"   %s  | data= %s  | (no list)\n",groupBody->tag,getText());
}

/***************************************************************************
                                embedRule
    embedRule -- THE ONE LEGITIMATE COPY OF AN EMBEDDED RULE, AND THE SOLE WRITER
    OF isEmbedded.   GroupItem.embedRule
***************************************************************************/
void GroupItem::embedRule(GroupItem *g)
{
GroupItem 	*copy = 0;
	if ( !g || !g->groupBody->flags.isRule )
		setGroup(g);
	else {
		copy = new GroupItem(g);
		copy->parent = this;
		copy->options.affiliation = 3;
		setGroup(copy);
		}
}

/***************************************************************************
                                ensureGuard
    // ensureGuard builds and memoises the guard set -- LINE 1 raises isRule on the SHARED body
***************************************************************************/
PLGset *GroupItem::ensureGuard()
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*item = 0;
PLGset 		*itemGuard = 0;
char 		*junk = 0;
int 		noMoreAttributes = 0;
	setRuleStuff();
	if ( groupBody->flags.guarding )
		goto returnGuard;
	if ( !isAttribute(options.affiliation) && !contents() )
		goto returnGuard;
	if ( groupBody->flags.isCondition )
		{
		groupBody->flags.guarding = 2;
		goto endSetGuard;
		}
	groupBody->flags.guarding = 3;
	if ( isSET(groupBody->flags.data) )
		{
		groupBody->guardSet = getCharacterSet();
		groupBody->flags.guarding = 1;
		goto endSetGuard;
		}
	groupBody->guardSet = new PLGset();
	/***************************************************************************
	Handle data
	***************************************************************************/
	if ( groupBody->registry == ruler->opFields || (!groupBody->flags.data && !groupBody->groupList) )
		{
		groupBody->guardSet->set((int)*groupBody->tag);
		goto endSetGuard;
		}
	if ( !groupBody->flags.binType )
		if ( groupBody->flags.data )
			{
			switch (groupBody->flags.data)
				{
				case 6:
					item = getGroup();
					itemGuard = item->ensureGuard();
					if ( guardInProcess(item->groupBody->flags.guarding) )
						goto returnGuard;
					if ( unGuarded(item->groupBody->flags.guarding) )
						groupBody->flags.guarding = 2;
					else	groupBody->guardSet->set(itemGuard);
					if ( item->getRStuff() && item->getRStuff()->min )
						goto endSetGuard;
					break;
				case 1:
				case 4:
				case 7:
				case 8:
				case 10:
				case 11:
				case 12:
					groupBody->flags.guarding = 2;
					break;
				default:
					if ( junk = getText() )
						groupBody->guardSet->set((int)*junk);
					else	groupBody->flags.guarding = 2;
				}
			if ( getRStuff()->min )
				goto endSetGuard;
			}
		else
		if ( !groupBody->groupList )
			groupBody->guardSet->set((int)*groupBody->tag);
	/***************************************************************************
	Handle hashes, attributes and members
	***************************************************************************/
	if ( groupBody->flags.binType )
		while ( item = next(item) )
			groupBody->guardSet->set(*item->groupBody->tag);
	else {
		if ( groupBody->flags.hasAttributes )
			while ( item = nextAttribute(item) )
				{
				if ( noMoreAttributes )
					break;
				if ( item->groupBody->flags.noPrint )
					continue;
				itemGuard = item->ensureGuard();
				if ( isAttribute(item->options.affiliation) )
					if ( noMoreAttributes )
						continue;
					else
					if ( guardInProcess(item->groupBody->flags.guarding) )
						goto returnGuard;
					else
					if ( guarded(item->groupBody->flags.guarding) && item->getRStuff()->min )
						noMoreAttributes = 1;
				if ( unGuarded(item->groupBody->flags.guarding) )
					groupBody->flags.guarding = 2;
				if ( itemGuard )
					groupBody->guardSet->set(itemGuard);
				if ( unGuarded(groupBody->flags.guarding) )
					break;
				}
		item = 0;
		if ( groupBody->flags.hasMembers )
			while ( item = nextMember(item) )
				if ( item->contents() )
					if ( itemGuard = item->ensureGuard() )
						groupBody->guardSet->set(itemGuard);
		}
	/***************************************************************************
	Rule guard set built. Assess result and see if we need to keep it.
	***************************************************************************/
endSetGuard:
	if ( groupBody->guardSet )
		{
		if ( groupBody->guardSet->isEmpty() )
			groupBody->guardSet = 0;
		if ( groupBody->guardSet )
			{
			groupBody->guardSet->name = ::concat(2,groupBody->tag," Guardset");
			groupBody->flags.guarding = 1;
			if ( isMember(options.affiliation) && parent->groupBody->guardSet )
				parent->groupBody->guardSet->set(groupBody->guardSet);
			}
		}
	else	groupBody->flags.guarding = 2;
returnGuard:
	return groupBody->guardSet;
}

/*******************************************************************************
                                ensureRStuff
    // ensureRStuff the constructing half -- it is NOT setRuleStuff, whose second arm
    // re-clones an rStuff belonging to another node
*******************************************************************************/
RuleStuff *GroupItem::ensureRStuff()
{
	if ( !getRStuff() )
		{
		RuleStuff 	*fresh = new RuleStuff(this);
		setRStuff(fresh);
		}
	return getRStuff();
}

/***************************************************************************
                                establishFrame
    // establishFrame the SINGLE WRITER of parentLabel, and there is deliberately no save/restore -- the callee
    // establishFrame lifts it at entry, so a parseMethod that reads it LATE is unsafe under recursion
***************************************************************************/
void GroupItem::establishFrame(GroupItem *parentLabel)
{
	if ( getRStuff() )
		getRStuff()->parentLabel = parentLabel;
}

/*****************************************************************************
                                findAttribute
	Searches ancestors bottom up for the first attribute matching name.
    Keep in mind the parent hierarchy has to be reset first for this to work.
*****************************************************************************/
GroupItem *GroupItem::findAttribute(char *name)
{
GroupItem 	*result = 0;
GroupItem 	*group = this;
	while ( group )
		{
		if ( result = group->getAttribute(name) )
			break;
		if ( group = group->parent )
			if ( result = group->findAttribute(name) )
				break;
		}
	return result;
}

/*****************************************************************************
                                findParent
	Returns the named parent.
*****************************************************************************/
GroupItem *GroupItem::findParent(char *name)
{
GroupItem 	*group = this;
	while ( group )
		{
		if ( ::compare(group->groupBody->tag,name) == 0 )
			break;
		group = group->parent;
		}
	return group;
}

/***************************************************************************
                                fireLabelMethod
    // fireLabelMethod returns NOTHING deliberately -- a null label already means
    // noLabel-on-success, so handing it back would be one channel with two meanings
***************************************************************************/
void GroupItem::fireLabelMethod(RuleStuff *stuff)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	if ( !stuff->actionMethod )
		{
		GroupItem 	*builtinActoR = getAttribute("builtinActoR");
		if ( builtinActoR )
			stuff->actionMethod = builtinActoR->groupBody->gMethod;
		}
	ruler->ruleSTUFF = stuff;
	// collisionProbe this seat stays ABOVE captureSpan, so the capture's own comparator
	// line prints inside the bracket
	::measureFireLabelEntry(this);
	if ( groupBody->flags.tokened )
		captureSpan(stuff);
	::measureFireLabelFork(this,stuff->label);
	if ( stuff->actionMethod && stuff->label )
		{
		if ( groupBody->flags.deferred )
			{
			stuff->label->setMethod(stuff->actionMethod);
			stuff->label->groupBody->flags.deferred = 1;
			if ( !stuff->label->groupBody->flags.data )
				stuff->label->setText(::concat(2,"g",groupBody->tag));
			}
		else
		if ( !parseACTION(groupBody->flags.methodType) )
			{
			// replacementReturn IN and OUT are two seats -- one read after the fire
			// cannot tell a replacement from a pass-through
			::measureFireLabelActionIn(this,stuff->label);
			stuff->label = stuff->actionMethod(stuff->label);
			::measureFireLabelActionOut(this,stuff->label);
			if ( !stuff->label )
				stuff->sukcess = 0;
			}
		}
}

/***************************************************************************
                                firstComponent
	Returns first component with matching tag. Unlike get() it recurses and descends.
    This should check to make sure it does not search the same field more
    than once or it ends up in an infinite loop. TBD need a searchable Stak
***************************************************************************/
GroupItem *GroupItem::firstComponent(char *name)
{
GroupItem 	*grup = 0;
GroupItem 	*entry = get(name);
	if ( !entry )
		if ( groupBody->groupList )
			while ( entry = next(entry) )
				if ( grup = entry->firstComponent(name) )
					{
					entry = grup;
					break;
					}
	return entry;
}

/***************************************************************************
                                frameParent
    // frameParent it reads runRule's OWN argument, never the ruleSTUFF singleton -- a singleton answers what
    // frameParent happened last, never who is asking
***************************************************************************/
GroupItem *GroupItem::frameParent(GroupItem *holder)
{
RuleStuff 	*holderStuff = 0;
	if ( !holder )
		return holder;
	holderStuff = holder->getRStuff();
	if ( holderStuff && holderStuff->label )
		return holderStuff->label;
	return holder;
}

/***************************************************************************
                                get
	Returns first component with tag == name. The search does not descend.
***************************************************************************/
GroupItem *GroupItem::get(char *name)
{
GroupItem 	*entry = 0;
	if ( name )
		if ( groupBody->groupList )
			{
			if ( groupBody->flags.binType )
				{
				if ( groupBody->groupList->stakked )
					return groupBody->groupList->stakked->getFromStak(name);
				else
				if ( guarded(groupBody->flags.guarding) && !groupBody->guardSet->contains(*name) )
					return 0;
				}
			if ( groupBody->groupList->listLength )
				while ( entry = next(entry) )
					if ( ::compare(entry->groupBody->tag,name) == 0 )
						return entry;
			}
	return 0;
}

/*****************************************************************************
                                get
    Return nth component if it exists. Not efficient unless this is stakked.
*****************************************************************************/
GroupItem *GroupItem::get(int offset)
{
GroupItem 	*entry = 0;
int 		i = 0;
	if ( offset && groupBody->groupList )
		{
		if ( groupBody->groupList->stakked )
			return groupBody->groupList->stakked->getFromStak(offset);
		else
		if ( --offset <= groupBody->groupList->listLength )
			{
			entry = groupBody->groupList->firstInList;
			while ( offset > i++ )
				entry = entry->nextInParent;
			}
		return entry;
		}
	return 0;
}

/*****************************************************************************
                                getAttribute
	Get the named attribute. This will return an attribute even if the
	attribute noPrint flag is set.
*****************************************************************************/
GroupItem *GroupItem::getAttribute(char *name)
{
GroupItem 	*block = 0;
	if ( name )
		if ( block = get(name) )
			if ( isAttribute(block->options.affiliation) )
				return block;
	return 0;
}

/*****************************************************************************
                                getBuffer
	Value getters
*****************************************************************************/
Buffer *GroupItem::getBuffer()
{
	if ( isBUFFER(groupBody->flags.data) )
		return groupBody->gBuffer;
	return 0;
}

char GroupItem::getCharacter()
{
char 	*atStart = 0;
char 	*atNext = 0;
	if ( groupBody->flags.data )
		if ( isCHAR(groupBody->flags.data) )
			return groupBody->gCharacter;
		else
		if ( isSTRING(groupBody->flags.data) && groupBody->gCount == 1 )
			atStart = groupBody->gText;
	if ( atStart )
		{
		if ( *atStart != '\\' )
			return *atStart;
		else {
			atNext = atStart + 1;
			switch (*atNext)
				{
				case 'n':
					return '\n';
				case 'r':
					return '\r';
				case 'f':
					return '\f';
				case 't':
					return '\t';
				case '\\':
					return '\\';
				default:
					return *atNext;
				}
			}
		}
	return 0;
}

PLGset *GroupItem::getCharacterSet()
{
	if ( isSET(groupBody->flags.data) )
		return groupBody->gCharacterSet;
	return 0;
}

int GroupItem::getCount()
{
	if ( groupBody->flags.data )
		{
		if ( isCOUNT(groupBody->flags.data) || isTOKEN(groupBody->flags.data) || isCHAR(groupBody->flags.data) || isSTRING(groupBody->flags.data) )
			return groupBody->gCount;
		// roundHalfUp THE site -- every .count read of a double lands here, and it is floor(x+0.5) and NOT
		// roundHalfUp lround, which rounds half AWAY from zero and would send -2.5 to -3
		if ( isNUMBER(groupBody->flags.data) )
			return (int)floor(groupBody->gNumber + 0.5);
		if ( isBUFFER(groupBody->flags.data) )
			return groupBody->gBuffer->length();
		if ( isGROUP(groupBody->flags.data) )
			{
			::fprintf(stderr,"ERROR getCount on %s -- holds a group; say *\n",groupBody->tag);
			return 0;
			}
		}
	return 0;
}

int GroupItem::getDataType()
{
	if ( isGROUP(groupBody->flags.data) )
		if ( getGroup() == this )
			return 0;
		else {
			::fprintf(stderr,"ERROR getDataType on %s -- holds a group; say *\n",groupBody->tag);
			return 0;
			}
	return groupBody->flags.data;
}

/***************************************************************************
                                getFromList
	Returns first component with tag == name. The search does not descend.
    Called from put() because unlike get() it does not search stakked.
***************************************************************************/
GroupItem *GroupItem::getFromList(char *name)
{
GroupItem 	*entry = 0;
	if ( name )
		if ( groupBody->groupList )
			if ( guarded(groupBody->flags.guarding) && !groupBody->guardSet->contains(*name) )
				return 0;
			else
			if ( groupBody->groupList->listLength )
				while ( entry = next(entry) )
					if ( ::compare(entry->groupBody->tag,name) == 0 )
						return entry;
	return 0;
}

/*****************************************************************************
                                getGroup
	Need to test how getMacro works in this case
*****************************************************************************/
GroupItem *GroupItem::getGroup()
{
	if ( isGROUP(groupBody->flags.data) )
		return groupBody->gGroup;
	return 0;
}

/***************************************************************************
                                getGuard
    // getGuard a PURE read -- it builds NOTHING; ensureGuard is what constructs
***************************************************************************/
PLGset *GroupItem::getGuard()
{
	return groupBody->guardSet;
}

PLGitem *GroupItem::getItem()
{
	if ( isITEM(groupBody->flags.data) || "isDate" )
		return groupBody->gItem;
	if ( isGROUP(groupBody->flags.data) )
		{
		::fprintf(stderr,"ERROR getItem on %s -- holds a group; say *\n",groupBody->tag);
		return 0;
		}
	return 0;
}

/***************************************************************************
                                getLabelGroup
	Initializer method for accessing rule results (used in rule actions);
***************************************************************************/
GroupItem *GroupItem::getLabelGroup(char *name)
{
GroupItem 	*block = get(name);
	while ( block && isGROUP(block->groupBody->flags.data) && !isMethod(block->groupBody->flags.instructType) && !block->groupBody->flags.isRule )
		block = block->getGroup();
	return block;
}

/*****************************************************************************
                                getMember
	Return the member matching the tag passed in.
*****************************************************************************/
GroupItem *GroupItem::getMember(char *name)
{
	if ( name && groupBody->flags.hasMembers )
		{
		GroupItem 	*block = get(name);
		if ( block && isMember(block->options.affiliation) )
			return block;
		}
	return 0;
}

double GroupItem::getNumber()
{
	if ( groupBody->flags.data )
		{
		if ( isNUMBER(groupBody->flags.data) )
			return groupBody->gNumber;
		if ( isCOUNT(groupBody->flags.data) )
			return (double)groupBody->gCount;
		if ( isGROUP(groupBody->flags.data) )
			{
			::fprintf(stderr,"ERROR getNumber on %s -- holds a group; say *\n",groupBody->tag);
			return 0;
			}
		}
	return 0;
}

NSObject *GroupItem::getObject()
{
	if ( isOBJECT(groupBody->flags.data) )
		return groupBody->gObject;
	if ( isGROUP(groupBody->flags.data) )
		{
		::fprintf(stderr,"ERROR getObject on %s -- holds a group; say *\n",groupBody->tag);
		return 0;
		}
	return 0;
}

void *GroupItem::getPointer()
{
	if ( groupBody->flags.isPointer )
		return groupBody->gPointer;
	return 0;
}

/*******************************************************************************
                                getRStuff
    // getRStuff a PURE getter -- it does not construct, and no miss-complaint belongs
    // in this seat: every caller is asking whether there is one
*******************************************************************************/
RuleStuff *GroupItem::getRStuff()
{
	return rStuff;
}

PLGrgx *GroupItem::getRegex()
{
	if ( isREGEX(groupBody->flags.data) )
		return groupBody->gRegex;
	return 0;
}

Stak *GroupItem::getStak()
{
	if ( isSTAK(groupBody->flags.data) )
		return groupBody->gStak;
	return 0;
}

/*******************************************************************************
                                getStuff
	Returns rStuff unless it is inProcess, IWC returns a fresh copy of rStuff
*******************************************************************************/
RuleStuff *GroupItem::getStuff(RuleStuff *pStuff)
{
	// lazyMaterialisation it asks ensureRStuff BY NAME -- a node arriving with no rStuff is the parser's design,
	// lazyMaterialisation not a mis-use to be repaired
RuleStuff *stuff = ensureRStuff();
	if ( stuff->rule != this || stuff->inProcess )
		{
		stuff = new RuleStuff(getRStuff());
		stuff->rule = this;
		}
	if ( stuff->parentStuff = pStuff )
		stuff->parentLabel = stuff->parentStuff->label;
	if ( !stuff->followed )
		stuff->getWhatFollows();
	return stuff;
}

/*****************************************************************************
                                getText
	getText does what it can to return the contents of this group as text.
    Note: if has text but is not a string, text is ignored.
*****************************************************************************/
char *GroupItem::getText()
{
char 	*junkText = 0;
	if ( isTOKEN(groupBody->flags.data) )
		{
		junkText = (char*)::malloc(groupBody->gCount + 1);
		::strncpy(junkText,groupBody->gText,groupBody->gCount);
		*(junkText + groupBody->gCount) = 0;
		}
	else
	if ( groupBody->flags.data && !groupBody->flags.binType )
		switch (groupBody->flags.data)
			{
			case 13:
				if ( groupBody->gText )
					junkText = groupBody->gText;
				else	groupBody->flags.data = 0;
				break;
			case 5:
			case 9:
				junkText = (char*)::malloc(20);
				if ( isCOUNT(groupBody->flags.data) )
					::sprintf(junkText,"%d",groupBody->gCount);
				else
				if ( isNUMBER(groupBody->flags.data) )
					::sprintf(junkText,"%g",groupBody->gNumber);
				if ( groupBody->flags.isPercent )
					::strcat(junkText,"%");
				// printDoesNotFollow print reads the TAG of a held field and never follows
				// gGroup -- cyclic chains are legal data, so no overflow guard belongs here
				break;
			case 6:
				if ( groupBody->gGroup )
					junkText = groupBody->gGroup->groupBody->tag;
				break;
			case 3:
				junkText = groupBody->gCharacterSet->name;
				break;
			case 4:
				junkText = groupBody->gBuffer->toString();
				break;
			case 7:
				junkText = groupBody->gItem->toString();
				break;
			case 2:
				junkText = (char*)::malloc(2);
				*junkText = groupBody->gCharacter;
				*(junkText + 1) = 0;
				break;
			default:
				junkText = ::concat(2,groupBody->tag,"data type has no toString() method");
			}
	else
	if ( groupBody->tag )
		junkText = groupBody->tag;
	return junkText;
}

/*****************************************************************************
                                insertAfter
    Insert grup into this's parent list immediately after this. Bookkeeping
    parallel: append() only adjusts sibling pointers, so this wraps it with
    parent/listLength/lastInList updates so the parent list stays consistent.
*****************************************************************************/
void GroupItem::insertAfter(GroupItem *grup)
{
	append(grup);
	grup->parent = parent;
	if ( parent )
		{
		parent->groupBody->groupList->listLength++;
		if ( !grup->nextInParent )
			parent->groupBody->groupList->lastInList = grup;
		}
}

/*****************************************************************************
                                insertGroup
	Insert an item at the beginning of this list. If list has entries and is
    sorted will throw an error and return null;
*****************************************************************************/
GroupItem *GroupItem::insertGroup(GroupItem *grup)
{
	if ( !groupBody->groupList || !groupBody->groupList->listLength )
		return addGroup(grup);
	if ( groupBody->flags.isSorted )
		{
		::fprintf(stderr,"insertGroup: cannot insert into a sorted list\n");
		return 0;
		}
	if ( groupBody->groupList->firstInList )
		groupBody->groupList->firstInList->prepend(grup);
	else	groupBody->groupList->firstInList = groupBody->groupList->lastInList = push(grup);
	grup->parent = this;
	groupBody->groupList->listLength++;
	return groupBody->groupList->firstInList;
}

/***************************************************************************
                                makeRegistry
    Makes the group passed in a registry
***************************************************************************/
void GroupItem::makeRegistry()
{
	if ( groupBody->groupList && groupBody->groupList->listLength && !sortAscending(groupBody->flags.isSorted) )
		::fprintf(stderr,"ERROR makeRegistry: %s has unsorted list\n",groupBody->tag);
	else
	if ( !GroupControl::groupController->groupRules->registries->get(groupBody->tag) )
		{
		/*******************************************************************
		Set the registry. Note: stakked is not set here, it is set
		after the registry is filled using the define command (if there
		are more than 10 members defined).
		*******************************************************************/
		groupBody->flags.binType = 4;
		groupBody->flags.isSorted = 1;
		if ( groupBody->groupList && groupBody->groupList->listLength )
			{
			GroupItem 	*grup = 0;
			groupBody->guardSet = new PLGset();
			while ( grup = next(grup) )
				groupBody->guardSet->set(*grup->groupBody->tag);
			groupBody->flags.guarding = 1;
			}
		GroupControl::groupController->groupRules->registries->addMember(this);
		groupBody->registry = this;
		}
	else	::fprintf(stderr,"%s is already a registry\n",groupBody->tag);
}

/*****************************************************************************
                                matches
    Returns true if this data matches data of the group passed in.
*****************************************************************************/
int GroupItem::matches(GroupItem *arg)
{
char 	*thisString = groupBody->flags.data ? getText() : groupBody->tag;
char 	*argString = arg->groupBody->flags.data ? arg->getText() : arg->groupBody->tag;
	if ( groupBody->flags.data && groupBody->flags.data == arg->groupBody->flags.data )
		switch (groupBody->flags.data)
			{
			case 5:
				return groupBody->gCount == arg->groupBody->gCount;
			case 9:
				return groupBody->gNumber == arg->groupBody->gNumber;
			case 7:
				return getItem()->compare(arg->getItem()) == 0;
			default:
				return ::compare(thisString,argString) == 0;
			}
	return ::compare(thisString,argString) == 0;
}

/*****************************************************************************
                                matches
	Check to see if this matches the string passed in. If this has text
    it matches with the text, otherwise it matches the tag (registry matches
    are always against the tag). If this matches, returns the matching text
    and advances the stream pointer passed in.
*****************************************************************************/
char *GroupItem::matches(char *&atString)
{
char 	*atText = getText();
char 	*matchText = atString;
char 	*atStart = atText;
	while ( *atText )
		if ( *atText == *atString )
			{
			atText++;
			atString++;
			}
		else	break;
	if ( !*atText )
		return atStart;
	atString = matchText;
	return 0;
}

/***************************************************************************
                                merge
	Merge group into this item. Does not add matching attributes.
***************************************************************************/
void GroupItem::merge(GroupItem *group)
{
	if ( group && group->groupBody->groupList->listLength )
		{
		if ( group->groupBody->flags.hasAttributes )
			mergeAttributes(group,0);
		if ( group->groupBody->flags.hasMembers )
			{
			GroupItem 	*item = 0;
			groupBody->flags.isSingleton = 0;
			groupBody->flags.hasMembers = 1;
			while ( item = group->nextMember(item) )
				addMember(item);
			}
		}
}

/***************************************************************************
                                mergeAttributes
	Merge attributes from the group passed in into this item. Does not add
    matching attributes.
***************************************************************************/
void GroupItem::mergeAttributes(GroupItem *group, int mergeFlag)
{
GroupItem 	*existing = 0;
GroupItem 	*replacement = 0;
GroupItem 	*item = 0;
	while ( item = group->nextAttribute(item) )
		{
		existing = getAttribute(item->groupBody->tag);
		if ( !existing || (mergeFlag && existing != item) )
			{
			/***************************************************************
			The following only happens if item is supposed to override
			an existing copy (based on the mergeFlag passed in)
			***************************************************************/
			if ( existing )
				existing->remove();
			/***************************************************************
			Note: if the attribute to be merged has its own attributes
			or members, the attributes and members are merged but not
			the attribute itself
			***************************************************************/
			if ( item->groupBody->flags.mergeOn && item->groupBody->groupList->listLength )
				{
				merge(item);
				continue;
				}
			if ( !item->groupBody->flags.data )
				{
				if ( replacement = GroupControl::groupController->locate(item->groupBody->tag) )
					{
					if ( replacement->groupBody->flags.mergeOn && replacement->groupBody->groupList->listLength )
						{
						merge(replacement);
						continue;
						}
					}
				addAttribute(item);
				continue;
				}
			else	addAttribute(item);
			}
		}
}

/***************************************************************************
                                moveTo
    Moves this group to the item passed in. No copy involved because remove
    clears the item parent.
***************************************************************************/
void GroupItem::moveTo(GroupItem *item)
{
	remove();
	if ( isAttribute(options.affiliation) )
		item->addAttribute(this);
	else	item->addMember(this);
	updateContentFlags();
}

/***************************************************************************
                                next
	Iterates thru attributes and members. The group passed in is taken as
    the last item iterated. If it is null, the first entry found is returned.
***************************************************************************/
GroupItem *GroupItem::next(GroupItem *current)
{
	while ( current = nextGroup(current) )
		if ( GroupControl::groupController->groupRules->ignoreNoPrint && current->groupBody->flags.noPrint )
			continue;
		else	break;
	return current;
}

/***************************************************************************
                                nextAttribute
	Iterates thru attributes. The group passed in is taken as the last item
	iterated. If it is null, the first attribute found is returned.
***************************************************************************/
GroupItem *GroupItem::nextAttribute(GroupItem *current)
{
	while ( current = nextGroup(current) )
		if ( isAttribute(current->options.affiliation) )
			break;
	return current;
}

/***************************************************************************
                                nextGroup
    Return the group following the group passed in. If a null group is
    passed in, returns the first group;
***************************************************************************/
GroupItem *GroupItem::nextGroup(GroupItem *grup)
{
	if ( groupBody->groupList )
		if ( grup )
			return grup->nextInParent;
		else	return groupBody->groupList->firstInList;
	else	::fprintf(stderr,"nextGroup: ERROR %s does not contain a list\n",groupBody->tag);
	return 0;
}

/***************************************************************************
                                nextMember
	Iterates thru members. The group passed in is taken as the last member
	iterated thru. If it is null, the first member found is returned.
***************************************************************************/
GroupItem *GroupItem::nextMember(GroupItem *current)
{
	while ( current = nextGroup(current) )
		if ( isMember(current->options.affiliation) )
			break;
	return current;
}

/***************************************************************************
                                parse
    Treat this field as a rule and match it against the input stream.
***************************************************************************/
GroupItem *GroupItem::parse(RuleStuff *pStuff)
{
GroupItem 	*parentLabel = 0;
GroupItem 	*definer = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*defStuff = 0;
RuleStuff 	*ruleStuff = getStuff(pStuff);
	if ( pStuff )
		parentLabel = pStuff->label;
	ruleStuff->kount = 0;
	ruleStuff->isOK = 0;
	ruleStuff->inProcess = 1;
	//  genParseRuleAccess
	definer = definingRule();
	defStuff = definer->getRStuff();
	// bindReadSeamProbe
	while ( !ruleStuff->isOK && ruleStuff->kount < ruleStuff->maxRepeat )
		{
continueHere:
		ruleStuff->sukcess = 0;
		if ( !ruleStuff->checkInput() )
			goto matchFailed;
		if ( ruleStuff->hasMacro )
			::setMacroValue(this);
		/*******************************************************************
		Run the matches that determine if this rule succeeds
		//runParseMatches
		*******************************************************************/
		if ( groupBody->flags.isRule && groupBody->flags.hasMembers && !groupBody->flags.data )
			ruleStuff->sukcess = ::testOptions(ruleStuff);
		else
		if ( ruleStuff->testMatch || ruleStuff->onGroup || groupBody->flags.hasAttributes )
			{
			if ( ruleStuff->testMatch )
				ruleStuff->sukcess = ruleStuff->testMatch(this);
			if ( !parseACTION(groupBody->flags.methodType) )
				{
				if ( ruleStuff->sukcess && ruleStuff->onGroup && !ruleStuff->onGroup->parse(ruleStuff) )
					ruleStuff->sukcess = 0;
				if ( ruleStuff->sukcess && groupBody->flags.hasAttributes )
					ruleStuff->sukcess = ::testAttributes(ruleStuff);
				}
			}
		if ( !ruleStuff->sukcess )
			goto matchFailed;
		/*******************************************************************
		Success. Fire label method if there is one.
		*******************************************************************/
		fireLabelMethod(ruleStuff);
		if ( ruleStuff->sukcess )
			{
			ruleStuff->kount++;
			attachLabel(ruleStuff,pStuff,1);
			}
		else	break;
		}
	if ( ruleStuff->kount >= ruleStuff->maxRepeat && ruleStuff->maxRepeat > 1 && !ruleStuff->limitsSet )
		::reportRepeatLimit(ruleStuff->rule,ruleStuff->kount,ruleStuff->maxRepeat);
matchFailed:
	if ( !ruleStuff->sukcess )
		{
		if ( !ruleStuff->sukcess && ruleStuff->kount >= ruleStuff->min )
			ruleStuff->sukcess = 1;
debugHere:
		if ( !*ruler->atRuleMark && ruler->inputDiverted )
			{
			while ( ruler->inputDiverted && !*ruler->atRuleMark )
				{
				ruler->lastIndent = 0;
				ruler->popInput();
				}
			if ( ruleStuff->sukcess && *ruler->atRuleMark )
				goto continueHere;
			}
		if ( !ruleStuff->sukcess )
			{
			ruleStuff->failedAt = ruler->atRuleMark;
			ruler->atRuleMark = ruleStuff->hereAt;
			if ( ruleStuff->label )
				ruleStuff->label = 0;
			}
		}
generatedExit:
	if ( !ruleStuff->sukcess && ruleStuff->notifyFail )
		::aCTionFailed(ruleStuff->rule);
	if ( ruleStuff->sukcess && !ruleStuff->label )
		ruleStuff->label = ruler->labelNO;
	ruleStuff->inProcess = 0;
	return ruleStuff->label;
}

/***************************************************************************
                                pop
    Pop treats the list as a stack and pops off the last item.
***************************************************************************/
GroupItem *GroupItem::pop()
{
GroupItem 	*stuff = 0;
	if ( groupBody->groupList && groupBody->groupList->listLength )
		{
		stuff = groupBody->groupList->lastInList;
		if ( groupBody->groupList->lastInList = stuff->priorInParent )
			groupBody->groupList->lastInList->nextInParent = 0;
		stuff->parent = 0;
		stuff->priorInParent = 0;
		groupBody->groupList->listLength--;
		if ( !groupBody->groupList->listLength )
			groupBody->groupList = 0;
		}
	return stuff;
}

/*****************************************************************************
                                prepend
	Insert the group passed in before this one. Does not update listLength
    or parent (in case called from addHash).
*****************************************************************************/
void GroupItem::prepend(GroupItem *grup)
{
	grup->priorInParent = priorInParent;
	grup->nextInParent = this;
	if ( priorInParent )
		priorInParent->nextInParent = grup;
	else
	if ( parent )
		parent->groupBody->groupList->firstInList = grup;
	priorInParent = grup;
}

/***************************************************************************
                                prior
    Return the group preceeding the group passed in. If a null group is
    passed in, returns the last group;
***************************************************************************/
GroupItem *GroupItem::prior(GroupItem *grup)
{
	if ( groupBody->groupList )
		if ( grup )
			return grup->priorInParent;
		else	return groupBody->groupList->lastInList;
	else	::fprintf(stderr,"nextGroup: ERROR %s does not contain a list\n",groupBody->tag);
	return 0;
}

/*****************************************************************************
                                push
	Add to list. Does not care about duplicates. If sorted sorts in ascending
    order. next and prior methods flip if sort is descending.
*****************************************************************************/
GroupItem *GroupItem::push(GroupItem *grup)
{
int 		comparison = 0;
GroupItem 	*entry = 0;
	if ( !groupBody->groupList )
		groupBody->groupList = new GroupList(this);
	entry = groupBody->groupList->firstInList;
	if ( !grup )
		{
		::fprintf(stderr,"GroupBody add: tried to add a null entry\n");
		return grup;
		}
	if ( groupBody->flags.isSorted )
		{
		while ( entry )
			{
			comparison = ::compare(grup->groupBody->tag,entry->groupBody->tag);
			if ( comparison > 0 )
				if ( entry = entry->nextInParent )
					continue;
				else	goto appendLink;
			else
			if ( comparison == 0 )
				goto appendLink;
			else	goto insertLink;
			}
		}
	else {
		if ( groupBody->groupList->lastInList )
			groupBody->groupList->lastInList->append(grup);
		else	groupBody->groupList->firstInList = grup;
		groupBody->groupList->lastInList = grup;
		goto finishAdd;
		}
appendLink:
	if ( entry )
		entry->append(grup);
	else
	if ( groupBody->groupList->lastInList )
		{
		groupBody->groupList->lastInList->append(grup);
		groupBody->groupList->lastInList = grup;
		}
	else {
		groupBody->groupList->firstInList = groupBody->groupList->lastInList = grup;
		grup->nextInParent = 0;
		grup->priorInParent = 0;
		}
	goto finishAdd;
insertLink:
	if ( entry )
		entry->prepend(grup);
	else
	if ( groupBody->groupList->firstInList )
		groupBody->groupList->firstInList->prepend(grup);
	else {
		groupBody->groupList->firstInList = groupBody->groupList->lastInList = grup;
		grup->nextInParent = 0;
		grup->priorInParent = 0;
		}
finishAdd:
	groupBody->groupList->listLength++;
	return grup;
}

/*****************************************************************************
                                put
	Adds an entry unless it already exists. No duplicates
*****************************************************************************/
void GroupItem::put(GroupItem *grup)
{
	if ( !getFromList(grup->groupBody->tag) )
		push(grup);
}

/*****************************************************************************
                                remove
	Remove this group from its parent list and return it.
*****************************************************************************/
GroupItem *GroupItem::remove()
{
	if ( parent && parent->groupBody->groupList )
		{
		GroupItem 	*grup = 0;
		if ( parent->groupBody->groupList->listLength )
			parent->groupBody->groupList->listLength--;
		if ( !parent->groupBody->groupList->listLength )
			parent->clearList();
		else {
			if ( priorInParent )
				priorInParent->nextInParent = nextInParent;
			else	parent->groupBody->groupList->firstInList = nextInParent;
			if ( nextInParent )
				nextInParent->priorInParent = priorInParent;
			else	parent->groupBody->groupList->lastInList = priorInParent;
			nextInParent = priorInParent = 0;
			if ( isAttribute(options.affiliation) )
				{
				grup = parent->nextAttribute(grup);
				if ( !grup )
					parent->groupBody->flags.hasAttributes = 0;
				}
			else
			if ( isMember(options.affiliation) )
				{
				grup = parent->nextMember(grup);
				if ( !grup )
					parent->groupBody->flags.hasMembers = 0;
				}
			if ( parent->groupBody->groupList->stakked )
				parent->groupBody->flags.altered = 1;
			parent = 0;
			}
		}
	return this;
}

/*****************************************************************************
                                remove
	Remove named group from this list, if there is a matching group on the list.
    Returns the removed group.
*****************************************************************************/
GroupItem *GroupItem::remove(char *name)
{
GroupItem 	*group = getFromList(name);
	if ( group )
		group->remove();
	return group;
}

/*****************************************************************************
                                replace
	If this contains an entry matching the tag of the argument passed in, replace
    the entry with the argument. If no matching entry, insert the argument.
*****************************************************************************/
GroupItem *GroupItem::replace(GroupItem *argument)
{
GroupItem 	*grup = getFromList(argument->groupBody->tag);
	if ( grup )
		grup->remove();
	if ( isAttribute(argument->options.affiliation) )
		argument = addAttribute(argument);
	else	argument = addMember(argument);
	return argument;
}

/***************************************************************************
                                resolvedTag
    Returns the right tag in case of loadByValue groups
***************************************************************************/
char *GroupItem::resolvedTag()
{
	if ( isAttribute(options.affiliation) && groupBody->registry && groupBody->registry->getAttribute("loadByValue") )
		return groupBody->registry->groupBody->tag;
	return groupBody->tag;
}

/***************************************************************************
                                runNotified
    runNotified is called by updateListeners() to handle listener notifications.
***************************************************************************/
GroupItem *GroupItem::runNotified(GroupItem *notifier)
{
GroupItem 	*onNotify = get("onNotify");
GroupItem 	*action = 0;
	if ( onNotify )
		action = GroupControl::groupController->locate(onNotify->getText());
	if ( action )
		return action->groupBody->gMethod(notifier);
	else	setContent(notifier);
	return this;
}

/*******************************************************************************
                                setActionMethod
    setActionMethod adds builtinActoR to contain rule action method. It is not
    a setter. The actionMethod field in rStuff gets set from it in
    fireLabelMethod
*******************************************************************************/
void GroupItem::setActionMethod()
{
RuleStuff 	*ruleStuff = getRStuff();
	if ( getAttribute("builtinActoR") )
		return;
	if ( isCoded(groupBody->flags.actionType) )
		setMethod(::processAction);
	else
	if ( !isMethod(groupBody->flags.instructType) )
		{
		char 	*methodName = ::concat(2,"aCTion",groupBody->tag);
		void 	*methodAddress = 0;
		if ( methodAddress = ::dlsym(RTLD_SELF,methodName) )
			{
			// markThenAdd noPrint is set BEFORE the node is attached, because addAttribute reads it at the instant of adding to decide hasTraits -- marking after is always too late (fixIts F-58)   GroupItem.setActionMethod.markThenAdd
			GroupItem *builtinActoR = new GroupItem("builtinActoR");
			builtinActoR->groupBody->flags.noPrint = 1;
			builtinActoR->setRStuff(ruleStuff);
			builtinActoR->setMethod((GroupItem*(*)(GroupItem*))methodAddress);
			addAttribute(builtinActoR);
			}
		::free(methodName);
		if ( groupBody->gMethod )
			groupBody->flags.methodType = 1;
		}
	else
	if ( groupBody->gMethod )
		{
		// registeredActor a ruleMethod= registration has ALREADY set gMethod, so the dlsym arm is skipped and NOTHING publishes the actor   GroupItem.setActionMethod.registeredActor
		void *actorAddress = (void*)groupBody->gMethod;
		// markThenAdd as the dlsym arm above -- noPrint before the attach, never after (fixIts F-58)
		GroupItem *builtinActoR = new GroupItem("builtinActoR");
		builtinActoR->groupBody->flags.noPrint = 1;
		builtinActoR->setRStuff(ruleStuff);
		builtinActoR->setMethod((GroupItem*(*)(GroupItem*))actorAddress);
		addAttribute(builtinActoR);
		}
}

/*****************************************************************************
                                setBuffer
	Value setters
*****************************************************************************/
void GroupItem::setBuffer(Buffer *b)
{
	groupBody->gBuffer = b;
	if ( b )
		groupBody->flags.data = 4;
	else	groupBody->flags.data = 0;
	groupBody->flags.isInitialized = 1;
	if ( groupBody->flags.hasListeners )
		updateListeners();
}

void GroupItem::setCharacter(char c)
{
	groupBody->gCharacter = c;
	if ( c )
		groupBody->flags.data = 2;
	else	groupBody->flags.data = 0;
	groupBody->flags.isInitialized = 1;
	if ( groupBody->flags.hasListeners )
		updateListeners();
}

void GroupItem::setCharacterSet(PLGset *set)
{
	groupBody->gCharacterSet = set;
	if ( set )
		groupBody->flags.data = 3;
	else	groupBody->flags.data = 0;
	groupBody->flags.isInitialized = 1;
	if ( groupBody->flags.hasListeners )
		updateListeners();
}

/*****************************************************************************
                                setContent
	setContent is not a setter. It updates data.
*****************************************************************************/
void GroupItem::setContent(GroupItem *item)
{
	if ( item )
		{
		if ( groupBody != item->groupBody )
			if ( !item->contents() )
				setText(item->groupBody->tag);
			else {
				if ( item->groupBody->groupList )
					copyListFrom(item);
				if ( isGROUP(item->groupBody->flags.data) )
					setGroup(item->groupBody->gGroup);
				else
				if ( isBUFFER(item->groupBody->flags.data) )
					setText(item->getText());
				else
				if ( item->groupBody->flags.data )
					copyData(item);
				}
		else	::fprintf(stderr,"setContent: tried to set group to itself %s\n",groupBody->tag);
		}
	else	clearData();
}

void GroupItem::setCount(int i)
{
	groupBody->flags.data = 5;
	groupBody->gCount = i;
	if ( groupBody->flags.hasListeners )
		updateListeners();
	groupBody->flags.isInitialized = 1;
}

void GroupItem::setGroup(GroupItem *g)
{
	if ( !g )
		{
		groupBody->gGroup = 0;
		groupBody->flags.data = 0;
		}
	else {
		// selfAdd the self-add guard is RETIRED -- a one-element cycle is legal data and nothing follows
		// selfAdd gGroup transitively
		// setGroup NEVER copies; embedRule() owns the one legitimate copy   GroupItem.setGroup
		groupBody->gGroup = g;
		groupBody->flags.isInitialized = 1;
		groupBody->flags.data = 6;
		if ( groupBody->flags.hasListeners )
			updateListeners();
		}
}

void GroupItem::setItem(PLGitem *i)
{
	groupBody->gItem = i;
	if ( i )
		groupBody->flags.data = 7;
	else	groupBody->flags.data = 0;
	groupBody->flags.isInitialized = 1;
	if ( groupBody->flags.hasListeners )
		updateListeners();
}

void GroupItem::setJitEmitter(void *m)
{
	// noFlagSet it sets NO flag deliberately -- presence of the slot IS the gate, and the emitter rides
	// noFlagSet alongside the interpreter binding rather than replacing it
	 groupBody->gJitEmitter = (GroupItem*(*)(GroupItem*,GroupItem*))m; 
}

void GroupItem::setMap(BitMAP *i)
{
	groupBody->gMap = i;
	if ( i )
		groupBody->flags.data = 8;
	else	groupBody->flags.data = 0;
	groupBody->flags.isInitialized = 1;
	if ( groupBody->flags.hasListeners )
		updateListeners();
}

/***************************************************************************
                                setMethod
    // setMethod SYMMETRIC, and the sole maintainer of isMethod -- a raw gMethod write anywhere else
    // setMethod desynchronises the shape fact by construction
***************************************************************************/
void GroupItem::setMethod(GroupItem *(*m)(GroupItem *))
{
	groupBody->gMethod = m;
	if ( m )
		groupBody->flags.instructType = 1;
	else	groupBody->flags.instructType = 0;
}

void GroupItem::setNumber(double d)
{
	groupBody->flags.data = 9;
	groupBody->gNumber = d;
	if ( groupBody->flags.hasListeners )
		updateListeners();
	groupBody->flags.isInitialized = 1;
}

void GroupItem::setObject(NSObject *v)
{
	groupBody->gObject = v;
	if ( v )
		groupBody->flags.data = 10;
	else	groupBody->flags.data = 0;
	groupBody->flags.isInitialized = 1;
	if ( groupBody->flags.hasListeners )
		updateListeners();
}

void GroupItem::setOperat(void *m)
{
	groupBody->flags.instructType = 2;
	// gOp by-ref: tok can't render a fnptr cast with a reference param (FormatC.twk bug).
	// Until that's fixed, take the dlsym result as void* and hand-cast it here in raw C++.
	// Revise to typed `void setOperat(GroupItem &m(GroupItem,GroupItem&)){ operat = m; }` post-fix.
	 groupBody->gOp = (GroupItem*(*)(GroupItem*,GroupItem*))m; 
}

void GroupItem::setPointer(void *v)
{
	groupBody->gPointer = v;
	groupBody->flags.isPointer = 1;
	groupBody->flags.isInitialized = 1;
	if ( groupBody->flags.hasListeners )
		updateListeners();
}

/*******************************************************************************
                                setRStuff
    setRStuff is the single writer of the rStuff field. Route every rStuff
    assignment through here so the field has one observable chokepoint (set a
    breakpoint/log here to trace where rStuff took a wrong turn). For now plain.
*******************************************************************************/
void GroupItem::setRStuff(RuleStuff *stuff)
{
	rStuff = stuff;
}

void GroupItem::setRegex(PLGrgx *v)
{
	groupBody->gRegex = v;
	if ( v )
		groupBody->flags.data = 11;
	else	groupBody->flags.data = 0;
	groupBody->flags.isInitialized = 1;
	if ( groupBody->flags.hasListeners )
		updateListeners();
}

/*******************************************************************************
                                setRuleStuff
    Set rStuff and isRule. This takes no argument so not a setter
*******************************************************************************/
void GroupItem::setRuleStuff()
{
	if ( !groupBody->flags.isRule )
		if ( groupBody->registry && groupBody->registry->groupBody->flags.isRule )
			groupBody->flags.isRule = 1;
		else
		if ( parent && parent->groupBody->flags.isRule )
			if ( !groupBody->registry || groupBody->registry == GroupControl::groupController->groupRules->keyWords )
				groupBody->flags.isRule = 1;
	if ( !getRStuff() )
		setRStuff(new RuleStuff(this));
	else
	if ( getRStuff()->rule != this )
		{
		setRStuff(new RuleStuff(getRStuff()));
		getRStuff()->rule = this;
		}
}

void GroupItem::setStak(Stak *s)
{
	if ( s )
		{
		groupBody->flags.data = 12;
		groupBody->gStak = s;
		}
	else	groupBody->flags.data = 0;
	groupBody->flags.isInitialized = 1;
	if ( groupBody->flags.hasListeners )
		updateListeners();
}

void GroupItem::setText(char *s)
{
	groupBody->gText = s;
	if ( s )
		{
		groupBody->gCount = (int)::strlen(s);
		groupBody->flags.data = 13;
		}
	else	groupBody->flags.data = 0;
	groupBody->flags.isInitialized = 1;
	if ( groupBody->flags.hasListeners )
		updateListeners();
}

/*****************************************************************************
                                setToken
	setToken is not a setter (there is no token field)
*****************************************************************************/
void GroupItem::setToken(char *s, int length)
{
	groupBody->flags.data = 14;
	groupBody->gText = s;
	groupBody->gCount = length;
	groupBody->flags.isInitialized = 1;
}

/***************************************************************************
                                sort
    Sorts list using the compare method. The basic idea is to walk the list
    forward, and keep the already traversed part of the list in order.
    At the end of the list we done. If order is not null, sort is descending
    NEED TO MAKE SURE THIS WORKS
***************************************************************************/
void GroupItem::sort(int (*comparisor)(GroupItem *, GroupItem *))
{
GroupItem 	*follow = 0;
GroupItem 	*current = 0;
	if ( groupBody->flags.isSorted )
		{
		int 	order = sortDescending(groupBody->flags.isSorted) ? -1 : 1;
		while ( current = next(current) )
			{
moveForward:
			follow = nextInParent;
			if ( order * comparisor(current,follow) <= 0 )
				continue;
			else {
				while ( current = priorInParent )
					{
					if ( order * comparisor(follow,current) < 0 )
						continue;
					else {
						current->append(follow);
						goto moveForward;
						}
					}
				if ( !current && groupBody->groupList->firstInList )
					{
					groupBody->groupList->firstInList->prepend(follow);
					goto moveForward;
					}
				}
			}
		return;
		}
	::fprintf(stderr,"GroupBody sort: must set isSorted first\n");
}

/*****************************************************************************
                                sortByAttribute
    Sort members by the value of the attribute named in the parameter
    passed in.
*****************************************************************************/
void GroupItem::sortByAttribute(char *attributeName)
{
char 	*saveText = getText();
	setText(attributeName);
	sort(::compareAttribute);
	setText(saveText);
}

/*******************************************************************************
                                updateContentFlags
	Make sure affiliation and content flags (hasMembers, hasAttributes) match
*******************************************************************************/
void GroupItem::updateContentFlags()
{
	if ( parent )
		if ( isAttribute(options.affiliation) )
			{
			parent->groupBody->flags.hasAttributes = 1;
			if ( !groupBody->flags.noPrint )
				parent->groupBody->flags.hasTraits = 1;
			}
		else
		if ( isMember(options.affiliation) )
			parent->groupBody->flags.hasMembers = 1;
	// groupListGuard a LEAF has no list, so a bare listLength read goes through a null groupList and dies at
	// groupListGuard EXC_BAD_ACCESS
	if ( groupBody->groupList && groupBody->groupList->listLength )
		{
		GroupItem 	*item = 0;
		// onePassNoEarlyOut three flags, ONE pass -- the old early-outs could break out before a
		// onePassNoEarlyOut trait-bearing attribute was reached, leaving the third flag answering about a partial scan
		groupBody->flags.hasAttributes = 0;
		groupBody->flags.hasMembers = 0;
		groupBody->flags.hasTraits = 0;
		while ( item = next(item) )
			if ( isAttribute(item->options.affiliation) )
				{
				groupBody->flags.hasAttributes = 1;
				if ( !item->groupBody->flags.noPrint )
					groupBody->flags.hasTraits = 1;
				}
			else
			if ( isMember(item->options.affiliation) )
				groupBody->flags.hasMembers = 1;
		}
}

/*****************************************************************************
                                updateDispatch
	Not used, was updateListeners, saved here just in case
*****************************************************************************/
void GroupItem::updateDispatch()
{
GroupItem 	*item = 0;
GroupItem 	*listener = 0;
	if ( !GroupControl::groupController->dispatchQ )
		{
		GroupControl::groupController->dispatchQ = new DispatchQ();
		GroupControl::groupController->dispatchQ->dispatchGroup = ::dispatch_group_create();
		}
	if ( listener = getAttribute("notifyLIST") )
		while ( item = listener->next(item) )
			item->dispatch();
	::printf("\t%s finished dispatching listeners\n",groupBody->tag);
	GroupControl::groupController->dispatchQ->wait(DISPATCH_TIME_FOREVER);
	::printf("\t%s finished updating listeners\n",groupBody->tag);
}

/*****************************************************************************
                                updateListeners
	Notify groups listening to this one.
*****************************************************************************/
void GroupItem::updateListeners()
{
GroupItem 	*grup = 0;
GroupItem 	*listener = 0;
	if ( listener = getAttribute("notifyLIST") )
		while ( grup = listener->next(grup) )
			runNotified(grup);
}

/***************************************************************************
                                walk
	Iterates thru the member hierarchy in a depth first walk. The group pointer
    passed in is taken as the last item iterated. If it is null, this group
    is returned. If the item passed in is this group, the first member of
    this group is returned. This way the walk starts with the calling block
    that is, the first block returned is the calling block, unless you pass
    the calling block as the item parameter.
***************************************************************************/
GroupItem *GroupItem::walk(GroupItem *item)
{
GroupItem 	*result = 0;
GroupItem 	*group = 0;
	if ( !item )
		result = this;
	else
	if ( item == this )
		result = next(result);
	else
	if ( item->groupBody->groupList->listLength )
		result = item->next(result);
	else {
		group = item->parent;
		if ( group->groupBody == groupBody || !group )
			{
			if ( item->groupBody->groupList->listLength )
				result = item->next(result);
			if ( !result )
				{
				result = item;
				result = next(result);
				}
			}
		else {
			result = item->nextInParent;
			if ( !result )
				while ( item = item->parent )
					{
					if ( item->groupBody == groupBody )
						break;
					if ( group = item->parent )
						{
						result = item;
						if ( result = group->next(result) )
							break;
						}
					}
			}
		}
	return result;
}
/*	Warning: the following methods were referenced but not declared
	floor(double)
*/
