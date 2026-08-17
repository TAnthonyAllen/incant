#include <Cocoa/Cocoa.h>
#include <dispatch/dispatch.h>
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
#include "GroupDraw.h"

/*****************************************************************************
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
		*rStuff = *grup->rStuff;
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
	return grup;
}

/***************************************************************************
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
    True if every attribute of this group has min 0. getWhatFollows() only
    zeroes a parent rule's min when ALL of its attributes are individually
    optional -- one optional attribute among mandatory siblings must not
    drag the parent's own min down to 0 (genParseSpec.md S7.1). An attribute
    with no rStuff yet has not had a chance to relax its implicit default
    min of 1 (RuleStuff(GroupItem) sets min=1), so treat "not yet known" as
    mandatory, not as optional -- the safe default, same as an untouched min.
***************************************************************************/
int GroupItem::allAttributesOptional()
{
GroupItem 	*attr = 0;
	while ( attr = nextAttribute(attr) )
		if ( !attr->rStuff || attr->rStuff->min )
			return 0;
	return 1;
}

/*****************************************************************************
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
    attachLabel — THE LABEL ATTACH, and the ONLY site that performs one.

    PC-4, 2026-08-07. Extracted from parse()'s match loop so both arms run the
    same code. Second half of the pair GX started: GX made both arms fire the
    same rule ACTION, this makes both perform the same ATTACH. It supersedes
    leaveRule's `if into  into +% label`, which was ONE case, run BEFORE the
    action instead of after -- GM-17's divergence. Removed there, not duplicated.

    THE YIELD PROTOCOL IS THE SKIP, and it is not a forensic test:
        NULL      the rule FAILED               -- nothing to attach
        labelNO   succeeded, yields NOTHING     -- nothing to attach
        anything  succeeded, yields THAT node   -- attach it
    An earlier attempt guarded on `isLabel` instead and was falsified fleet-wide
    (GM-19/GM-21): trueResult is minted as `new("true")` and never stamped, so
    the guard silently dropped DEFINing's attach and killed every definition in
    the file. Do not reach for a flag here; the channel says what it means.

    ⚠ THE `promote` PARAMETER IS A DATED DIVERGENCE, NOT A DESIGN. PC-1 rules
    the generated arm ATTACH-UNDER ALWAYS -- it never consults isTarget --
    while interpretive promotion runs untouched as legacy. So the fork is real
    today and is passed explicitly rather than inferred, because a divergence
    the signature states is one the next reader cannot miss.

    ⚠ AND IT HAS A NAMED EXPIRY (IT-3, director 2026-08-07). isTarget promotion
    is retired as a PARSE-LAYER mechanism -- the parse builds one shape, and
    opinions about shape belong to actions. Promotion becomes opt-in in one
    line: an action returns the child's label as its own yield, and attach-under
    plants it. When the last carrier converts, `promote` and the isTarget case
    DELETE, three cases become one, and this function is `pStuff.label +% lab`
    with the two skips. Attrition list per GM-23: aCTionNewGroup (done),
    aCTionShortcuT, plus the four text-readers at their own rungs.

    ⚠ DEMOLITION ITEM ADDED 2026-08-13 (SEQ 61, with the PC-1 restatement):
    BEFORE the promote/isTarget case deletes, THE IA-2 CELL NEEDS AN
    ACTION-LAYER CARRIER -- the winning option's label yielded UPWARD as the
    alternation's own yield. Not attached into the grandparent's subtree: that
    was built and measured RED (SEQ 59 rung 2b, recorded at the drop site
    below). The narrow guard is NOT a new carrier; it extends the condemned
    case and deletes with it, so IT-3's end state is unmoved. THE TRIPWIRE IS
    incant/bindSeamB PINNED AT 251 in genLadder/pop.sh -- delete the case
    without supplying the carrier and that pin goes red.

    ⚠ NESTED REFERENCES ARE COVERED, MEASURED BEFORE THIS LANDED. parseR
    (RuleStuff.twk:689) does `bridge.label = into; term.parse(bridge)`, so a
    reference term reaches parse() with `into` as pStuff's label -- both arms of
    the nested call come through here too. parseR's header always claimed "ONE
    mechanism serves both halves of mixed mode"; now it is true.

    litOption keeps its own attach: a literal option builds its own fresh label
    and never enters parse().
***************************************************************************/
void GroupItem::attachLabel(RuleStuff *stuff, RuleStuff *pStuff, int promote)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*lab = stuff->label;
	if ( !lab || lab == ruler->labelNO )
		return;
	if ( !pStuff )
		return;
	/*  IA-2 LOCALIZER, gated on the standing parseTrace and therefore silent by
	default. Reports the four quantities that decide which case below runs,
	because the interesting failure is a SILENT return at the no-label guard
	and an absent attach announces nothing on its own.  */
	if ( ruler->parseTrace )
		::fprintf(stderr,"    attachLabel lab=%s promote=%d isTarget=%u pLabel=%lu pRule=%s\n",lab->groupBody->tag,promote,stuff->isTarget,(pStuff->label != 0),pStuff->ruleName);
	/*  PROMOTION IS AN ASSIGN AND IS NOT GUARDED ON THE DESTINATION -- a parent
	with no label yet is the NORMAL case here, and this is what gives it
	one.  */
	/*  ⚠ THE `!pStuff.label` DISJUNCT IS PC-1 AS RESTATED BY THE DIRECTOR ON
	2026-08-13 (SEQ 61), NOT A LOOSENING OF IT. The generated arm never
	consults isTarget WHERE A PARENT LABEL EXISTS -- promotion there would
	replace the parent's subtree, which is GM-22's third wall, measured as
	ScafOUT coming back childless. Where no parent label exists there is no
	subtree at risk, so the consult is permitted, and that cell is IA-2's.
	PC-1's rationale stands; its letter is trimmed to the rationale's reach.
	See the IA-2 block below and docs/parseCodeMeasurements.md addendum (j)
	for the ruling verbatim and the trial it rests on.  */
	if ( (promote || !pStuff->label) && stuff->isTarget )
		{
		pStuff->label = lab;
		lab->groupBody->tag = pStuff->ruleName;
		return;
		}
	/*  ⚠ THE ATTACH CASES ARE GUARDED, AND leaveRule ALREADY KNEW THIS. Its
	line was `if into  into +% label` -- and `into` IS pStuff.label.
	Extracting the body without the guard cost a fleet-wide SIGSEGV the
	moment a rule was installed under a parent with no label
	(RuleStuff.twk:181 sets label = 0 for a noLabel rule, ON SUCCESS):
	addGroup with a null `this`, no diagnostic. A parent with nowhere to
	put a child is not an error; there is simply nothing to attach to.
	⚠ AND THE GUARD BELONGS HERE, NOT ABOVE THE PROMOTE CASE. Placing it at
	the top -- which was the first attempt -- ALSO crashes the fleet, by
	skipping the promotion that was supposed to create the missing label.
	Same symptom, opposite cause, and only three lines apart.  */
	/*  ⚠ IA-2, 2026-08-07 — THIS SILENT RETURN IS WHERE A GENERATED OPTION OF AN
	ALTERNATION DIES, and it is measured, not suspected. An alternation is
	label-transparent (S2.4): it mints no label, so `pStuff.label` is null
	and there is nothing to attach under. Interpretively that is fine
	because promotion at the isTarget case ABOVE runs first and is what
	gives the alternation its label — but the generated arm passes
	promote=0 by PC-1's ruling, so it reaches here and drops the option on
	the floor. Probe line, Parens installed:
	attachLabel lab=Parens promote=0 isTarget=1 pLabel=0 pRule=InvokeArg
	A one-line experiment promoting in this case turned parensMin green with
	the whole fleet at its standing footprint — so the missing promotion
	ACCOUNTS for the red completely. It was NOT landed: it makes the
	generated arm consult isTarget, which PC-1 forbids, and it moves against
	IT-3's end state where promotion deletes entirely. Director's call.
	
	⚠ RULED 2026-08-13, SEQ 61 -- AND THE CELL IS NOW CLOSED. Both
	objections were answered rather than waived. PC-1 was RESTATED, not
	overridden: the forbidden consult is the one where a parent label
	exists, because that is the one with a subtree to destroy; this cell has
	no parent label and therefore nothing at risk. IT-3 is unmoved because
	the narrow guard adds no carrier -- it rides the condemned case and dies
	with it, and IT-3's list gained the demolition item this cell needs
	(see the header above). The landed spelling is the NARROW one,
	`(promote || !pStuff.label) && stuff.isTarget`. The broad spelling was
	also measured green and was REJECTED ON PRINCIPLE: over 216 attachLabel
	calls in one full run, ZERO fell in the cell where the two spellings
	differ, so its green was a pass on a case that never occurs.
	Ruling verbatim: docs/parseCodeMeasurements.md addendum (j).  */
	if ( !pStuff->label )
		{
		/*  SEQ 59 RUNG 2 -- THE FRAME PROBE AT THE DROP SITE. Gated on the
		standing parse-trace flag, so no baseline can move. It asks one
		thing: at the instant an option's label is dropped, is there a
		reachable destination anywhere in the frame, or is the label simply
		homeless. Reports the label itself (present, by construction -- the
		guard above already returned if it were not), the parent rule, and
		three candidate destinations one step out.  */
		
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
		
		/*  ⚠ RUNG 2b WAS BUILT HERE AND IS RED. SEQ 59, 2026-08-13. Recorded
		because the destination it used is the one the frame offers, so the
		next reader will reach for it too.
		
		The probe above measures a reachable destination one step out --
		pStuff.parentStuff.label, which is TokenXP when Braced dies. That is
		the interpreted spelling of the `into` a GENERATED alternation hands
		its options through parseR's bridge, so it looked like option 2
		exactly: no target flag consulted, nothing promoted, PC-1 untouched.
		
		if pStuff.parentStuff && pStuff.parentStuff.label {
		pStuff.parentStuff.label +% lab;
		return; }
		
		Built, run, and it moved NOTHING: bindSeamB stayed at 1, and its
		whole trace and stdout came back byte-identical but for ASLR. The
		attach demonstrably ran -- the guard is true by the probe's own
		printed values and the generated line was read at the site -- so the
		node was really planted and NOTHING READS IT THERE.
		
		The lesson, which is the part worth keeping: an alternation must
		YIELD its winning option's label upward, not park it in the
		grandparent's subtree. Reachable is not the same as correct, and the
		frame having somewhere to put a node is not evidence that it is the
		right somewhere.  */
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

/******************************************************************************
    Clear list and data. Flags are not cleared, neither is rStuff.
******************************************************************************/
void GroupItem::clear()
{
	clearData();
	clearList();
}

/******************************************************************************
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
    definingRule -- the node a rule-reference term refers to, reached WITHOUT
    a name lookup. Clay SEQ 26 S1; measured, not reasoned (incant/termScratch).

    A reference term is a distinct node that SHARES the defining rule's child
    list. The children are parented to the definer, so the first child's parent
    IS the definer, by pointer. Verified on JSONblock->JSONfield,
    JSONfield->JSONtoken and JSONfield->JSONvalue: pointer-identical to what
    locate() returns for the same name.

    The test discriminates, which is why it can be trusted unguarded: a node
    that OWNS its children (a defining rule, and also CodE/BlocK) routes back
    to ITSELF, and a leaf term has no children at all. Both fall through to
    `return this`, so the only nodes that resolve elsewhere are the ones that
    genuinely reference something else.

    This is what makes rung 4 possible. parseMethod is SHAPE -- one answer,
    always the same -- so resolving it here means binding a rule once reaches
    every reference to it, including references created LATER. No registry
    sweep (which would miss late references) and no locate (S1.3 forbids it).
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

/*****************************************************************************
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
    Treat this field as a rule and match it against the input stream.
***************************************************************************/
/***************************************************************************
    fireLabelMethod — THE RULE ACTION, and the ONLY site that fires one.

    GX-1, 2026-08-06. Extracted verbatim from parse()'s match loop so that the
    interpretive arm and the generated arm RUN THE SAME CODE rather than
    carrying two carefully-matched copies. That is the same principle parse()'s
    own S1.3 comment already states about the shared exit — "the generated path
    matches the interpretive path because it RUNS the same exit, not because the
    exit was copied carefully" — applied one region further up. The defect this
    closes was precisely that the shared region STARTED TOO LATE: it began at
    generatedExit, so the action layer sat outside it and the generated arm's
    `goto` jumped clean over the rule action.

    ⚠ MEASURED CONSEQUENCE OF THE GAP, TWO SPECIMENS, BOTH SHAPE-IDENTICAL:
    `Braced` (2026-08-05) and `Parens` (2026-08-06) each parsed correctly,
    attached their term under the right label, HIT and WIN — and their actions
    never ran. corpus GM-16 / GM-17. Parens was catastrophic rather than subtle
    only because of where it sits in the grammar: every parenthesised
    invocation goes through it, so `include(x)` invoked `include` with no
    argument and every fixture died on its first statement.

    ⚠ NO RETURN VALUE, AND THAT IS DELIBERATE. Both things this can change --
    the label and the success flag -- live on the RuleStuff, so it mutates them
    in place and reports nothing. The tempting shape, "return the label, null
    means failure", is WRONG here and quietly so: RuleStuff.twk:181 sets
    `label = 0` for a `noLabel` rule ON SUCCESS, so a null label means "this
    rule has no label" AND "the method failed" — one channel, two meanings, the
    failure family this project has paid for repeatedly. Nothing is returned,
    so there is nothing to conflate.

    Not in groups.ext: called only from parse(), in this file.
***************************************************************************/
void GroupItem::fireLabelMethod(RuleStuff *stuff)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	ruler->ruleSTUFF = stuff;
	if ( ruler->parseTrace )
		::fprintf(stderr,"  fireLabelMethod %s isMethod=%s label=%s deferred=%s parseACTION=%s\n",groupBody->tag,::toStringFromInt(isMethod(groupBody->flags.instructType) != 0),::toStringFromInt(stuff->label != 0),::toStringFromInt(groupBody->flags.deferred != 0),::toStringFromInt(parseACTION(groupBody->flags.methodType) != 0));
	if ( isMethod(groupBody->flags.instructType) && stuff->label )
		if ( groupBody->flags.deferred )
			{
			stuff->label->setMethod(groupBody->gMethod);
			stuff->label->groupBody->flags.deferred = 1;
			if ( !stuff->label->groupBody->flags.data )
				stuff->label->setText(::concat(2,"g",groupBody->tag));
			}
		else
		if ( !parseACTION(groupBody->flags.methodType) )
			{
			/*  LA''-5 RIDER, 2026-08-06: the flag dump at a REPLACEMENT-RETURN
			site. 14 of 33 rule actions return a node they were not handed,
			so the question is whether the node coming BACK still carries
			isLabel. clear() does not strip flags (director, 2026-08-07), so
			a replacement is the only remaining way an unstamped node can
			reach the label channel. Gated on the standing parseTrace.  */
			if ( ruler->parseTrace )
				::fprintf(stderr,"    fireLabel IN  %s isLabel=%s\n",groupBody->tag,::toStringFromInt(stuff->label->groupBody->flags.isLabel != 0));
			stuff->label = groupBody->gMethod(stuff->label);
			if ( ruler->parseTrace )
				if ( stuff->label )
					::fprintf(stderr,"    fireLabel OUT %s isLabel=%s tag=%s\n",groupBody->tag,::toStringFromInt(stuff->label->groupBody->flags.isLabel != 0),stuff->label->groupBody->tag);
				else	::fprintf(stderr,"    fireLabel OUT %s NULL\n",groupBody->tag);
			if ( !stuff->label )
				stuff->sukcess = 0;
			}
}

/***************************************************************************
	Returns first component with matching tag. Unlike get() it recurses and descends.
    This should check to make sure it does not search the same field more
    than once or it ends up in an infinite loop. TBD need a searchable Stak
***************************************************************************/
GroupItem *GroupItem::firstComponent(char *name)
{
GroupItem 	*grup = 0;
GroupItem 	*entry = get(name);
	if ( !entry )
		if ( groupBody->groupList->listLength )
			while ( entry = next(entry) )
				if ( grup = entry->firstComponent(name) )
					{
					entry = grup;
					break;
					}
	return entry;
}

/***************************************************************************
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
		/*  IMPLICIT NARROWING ROUNDS HALF-UP, UNIFORMLY (Tony's ruling,
		2026-08-01, clause 3). This is THE site: every `.count` read of a
		double reaches here, so one line makes the rule uniform rather than
		per-operator. It used to be `(int)number`, a C truncating cast, which
		is neither of the two behaviours a user could reasonably expect.
		floor(x + 0.5) is round-half-UP as ruled -- >= .5 goes up, < .5 goes
		down -- and it is deliberately NOT lround(), which rounds half AWAY
		FROM ZERO and so sends -2.5 to -3 where this ruling sends it to -2.
		No error arm, no context-dependent behaviour, no guard rails: one
		rule, and a user who divides then indexes owns the result. */
		if ( isNUMBER(groupBody->flags.data) )
			return (int)floor(groupBody->gNumber + 0.5);
		if ( isBUFFER(groupBody->flags.data) )
			return groupBody->gBuffer->length();
		if ( isGROUP(groupBody->flags.data) )
			return groupBody->gGroup->getCount();
		}
	return 0;
}

int GroupItem::getDataType()
{
	if ( isGROUP(groupBody->flags.data) )
		if ( getGroup() == this )
			return 0;
		else	return getGroup()->getDataType();
	return groupBody->flags.data;
}

/***************************************************************************
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
	Need to test how getMacro works in this case
*****************************************************************************/
GroupItem *GroupItem::getGroup()
{
	if ( isGROUP(groupBody->flags.data) )
		return groupBody->gGroup;
	return 0;
}

/*******************************************************************************
	Return the guard set. Create it if we have to
*******************************************************************************/
PLGset *GroupItem::getGuard()
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
					itemGuard = item->getGuard();
					if ( guardInProcess(item->groupBody->flags.guarding) )
						goto returnGuard;
					if ( unGuarded(item->groupBody->flags.guarding) )
						groupBody->flags.guarding = 2;
					else	groupBody->guardSet->set(itemGuard);
					if ( item->rStuff && item->rStuff->min )
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
			if ( rStuff->min )
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
				itemGuard = item->getGuard();
				if ( isAttribute(item->options.affiliation) )
					if ( noMoreAttributes )
						continue;
					else
					if ( guardInProcess(item->groupBody->flags.guarding) )
						goto returnGuard;
					else
					if ( guarded(item->groupBody->flags.guarding) && item->rStuff->min )
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
					if ( itemGuard = item->getGuard() )
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

PLGitem *GroupItem::getItem()
{
	if ( isITEM(groupBody->flags.data) || "isDate" )
		return groupBody->gItem;
	if ( isGROUP(groupBody->flags.data) )
		return groupBody->gGroup->getItem();
	return 0;
}

/***************************************************************************
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
			return groupBody->gGroup->getNumber();
		}
	return 0;
}

NSObject *GroupItem::getObject()
{
	if ( isOBJECT(groupBody->flags.data) )
		return groupBody->gObject;
	if ( isGROUP(groupBody->flags.data) )
		return groupBody->gGroup->getObject();
	return 0;
}

void *GroupItem::getPointer()
{
	if ( groupBody->flags.isPointer )
		return groupBody->gPointer;
	return 0;
}

/*******************************************************************************
    getRStuff is the ensure-and-fetch reader. Warns if it had to create one so
    we can ID a node that reached this path with no rStuff. Existence-check
    reads (if !rStuff) stay raw elsewhere to avoid warn-spam.
*******************************************************************************/
RuleStuff *GroupItem::getRStuff()
{
	if ( !rStuff )
		{
		RuleStuff 	*fresh = new RuleStuff(this);
		setRStuff(fresh);
		}
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
	Returns rStuff unless it is inProcess, IWC returns a fresh copy of rStuff
*******************************************************************************/
RuleStuff *GroupItem::getStuff(RuleStuff *pStuff)
{
RuleStuff 	*stuff = getRStuff();
	if ( stuff->rule != this || stuff->inProcess )
		{
		stuff = new RuleStuff(rStuff);
		stuff->rule = this;
		}
	stuff->parentStuff = pStuff;
	if ( !stuff->followed )
		stuff->getWhatFollows();
	return stuff;
}

/*****************************************************************************
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
				break;
			case 6:
				if ( groupBody->gGroup )
					junkText = groupBody->gGroup->getText();
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
	/***********************************************************************
	genParseRuleAccess S1.3 -- a generated parse supersedes the
	interpretive walk.
	
	INSIDE the inProcess bracket, DELIBERATELY, and it does NOT return
	early. Two reasons, both load-bearing:
	1. inProcess must be SET, so getStuff() hands a nested call a fresh
	clone. The JSON family is mutually recursive (JSONvalue ->
	JSONblock -> JSONfield -> JSONvalue); without it a nested call
	shares one frame with its parent. Placing the fork BEFORE this
	line is safe against leaks and wrong about reentrancy.
	2. inProcess must be CLEARED, and aCTionFailed/trueResult must still
	run. So the fork sets sukcess and falls through to the ONE shared
	exit rather than reimplementing it. The generated path then
	matches the interpretive path because it RUNS the same exit, not
	because the exit was copied carefully -- model-not-oracle applied
	to the exit itself. In particular notifyFail survives onto the
	generated path: a generated rule that could not report failure
	would rebuild exactly the blindness that made jsonTest useless.
	
	leaveRule/leaveAlt own only the REWIND (Invariant R) and the
	label-or-0 return. parse()'s tail keeps the trueResult substitution
	and the aCTionFailed decision. One implementer each.
	
	NO-OP until something is generated: no current path assigns
	parseMethod, so every rule takes the old road and the baseline must
	be byte-identical.
	Deliberately NOT lazily initialized (contrast testMatch's
	`if !testMatch setTestMatch()` at RuleStuff.twk:159). Generation is
	explicit and idempotent; an `if !parseMethod genParse(rule)` here
	would turn first-parse into a generation event -- this phase, that
	means emitting text and running a build, from inside a parse.
	
	RUNG-6 TRIPWIRE: the interpretive path does kount++ on success, which
	feeds `kount >= min` and the iteration bound. The generated path does
	not. Invisible at max 1 (rungs 1-2); rung 6 must address it.
	
	genParseShape S1.1/S1.2 (2026-07-28): the fnptr takes ONE argument and
	it is the rule -- kant methods take one argument, so the old
	(rule, parentLabel) pair could never survive the kant handover. The
	`into` travels through the named parentLabel field instead, and THIS
	LINE IS ITS SINGLE WRITER. It is written on the rule's OWN rStuff, not
	on ruleStuff, because ruleStuff may be a reentrancy clone the callee
	cannot reach -- the callee only receives the rule. The callee lifts it
	into a stack local at entry, before descending, so a nested invocation
	overwriting it here cannot disturb an outer frame already under way.
	
	RUNG 4, and the split is the whole point (Clay SEQ 26 S1/S2). The two
	fields go to DIFFERENT nodes, deliberately:
	
	parseMethod is SHAPE. One answer, always the same for a given rule,
	so it is read from the DEFINING rule (definingRule(), a pointer walk,
	no name lookup). That is what lets a generated rule be reached
	through another rule's reference term and not only by name -- bind
	once, and every reference sees it, including references created after
	the binding.
	
	parentLabel is FRAME. It varies per invocation and is what carries
	the variation. It stays on `this` -- the node actually being parsed.
	Routing it to the defining rule instead would make every reference to
	a recursive rule write the SAME slot, which is correct-looking right
	up until the recursion is live. A field that looks like it belongs
	with the rule because it is usually the same is exactly the dangerous
	case.
	
	`this` is what gets passed, not the definer: the two share a child
	list, so rule[n] reads the same terms from either, while
	rule.rStuff.parentLabel has to be this invocation's.
	***********************************************************************/
	definer = definingRule();
	defStuff = definer->rStuff;
	/*  THE READ HALF OF THE BIND-READ SEAM PROBE, SEQ 58, 2026-08-13. Its
	write half sits in the binding door in genParse. Together they
	answered, in one bit, why a cross-file parse-method bind was written
	and never read: the door bound onto a satellite node while this fork
	resolved the real one.
	
	Gated on the parse-trace flag, so an ordinary run cannot see it and no
	baseline can move. A bind runs live in swept fixtures, and an
	unconditional print here would move them.
	
	NARROWED TO ONE RULE NAME ON PURPOSE, and cheap to widen. Braced is
	the campaign's specimen; printing for every rule would add a line per
	parse to a trace that is already verbose. If the next seam question is
	about a different rule, change the string -- do not delete the probe,
	because it is the only instrument that makes this seam visible.
	
	Written as passthrough because it reads the flag off the rules
	singleton from inside a method on this class, and the generated file
	already carries the headers that spelling needs.  */
	
	if ( GroupControl::groupController->groupRules->parseTrace
	&& groupBody->tag && !::strcmp(groupBody->tag,"Braced") )
	::fprintf(stderr,"SEAM fork  Braced  this=%p thisRStuff=%p definer=%p defStuff=%p defParseMethod=%p\n",
	(void*)this,(void*)rStuff,(void*)definer,(void*)defStuff,
	defStuff ? (void*)defStuff->parseMethod : (void*)0);
	
	if ( defStuff && defStuff->parseMethod )
		{
		rStuff->parentLabel = parentLabel;
		ruleStuff->label = defStuff->parseMethod(this);
		ruleStuff->sukcess = ruleStuff->label != 0;
		/*  GX-1: fire the rule action, through the SAME method the
		interpretive arm calls. Guarded on sukcess so it sits at exactly
		the point in the sequence its interpretive twin does -- there, the
		action block is reached only after `if !sukcess goto matchFailed`.
		The kount++/pStuff-label plumbing below it is NOT wanted here and
		is not shared: leaveRule already attached this label through
		`into`, and the kount question is the rung-6 tripwire noted above,
		which is a separate and still-owed decision.  */
		/*  PC-1: ATTACH-UNDER, ALWAYS. The generated arm passes promote=0 and
		so never consults isTarget -- the emitted method bakes `into` and
		assumes attachment, and promotion would replace the parent's subtree
		instead of growing it (GM-22's third wall, measured as ScafOUT
		coming back childless).  */
		if ( ruleStuff->sukcess )
			{
			fireLabelMethod(ruleStuff);
			attachLabel(ruleStuff,pStuff,0);
			}
		goto generatedExit;
		}
	while ( !ruleStuff->isOK && ruleStuff->kount < ruleStuff->max )
		{
continueHere:
		ruleStuff->sukcess = 0;
		if ( !ruleStuff->checkInput() )
			goto matchFailed;
		if ( ruleStuff->hasMacro )
			::setMacroValue(this);
		/*******************************************************************
		Run the matches that determine if this rule succeeds
		*******************************************************************/
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
		else
		if ( groupBody->flags.isRule && groupBody->flags.hasMembers )
			ruleStuff->sukcess = ::testOptions(ruleStuff);
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
	/*  PC-3: a label-less SUCCESS yields labelNO, not trueResult. The old
	substitution manufactured a value to mean "succeeded with nothing to
	hand back". labelNO is non-null, so every pointer-null consumer (parseR,
	each emitted method's && chain) still reads success exactly as before,
	and isCOUNT 0 keeps its numeric reading identical.  */
	if ( ruleStuff->sukcess && !ruleStuff->label )
		ruleStuff->label = ruler->labelNO;
	ruleStuff->inProcess = 0;
	return ruleStuff->label;
}

/***************************************************************************
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
	Adds an entry unless it already exists. No duplicates
*****************************************************************************/
void GroupItem::put(GroupItem *grup)
{
	if ( !getFromList(grup->groupBody->tag) )
		push(grup);
}

/*****************************************************************************
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
    Returns the right tag in case of loadByValue groups
***************************************************************************/
char *GroupItem::resolvedTag()
{
	if ( isAttribute(options.affiliation) && groupBody->registry && groupBody->registry->getAttribute("loadByValue") )
		return groupBody->registry->groupBody->tag;
	return groupBody->tag;
}

/***************************************************************************
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

/*****************************************************************************
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
		if ( groupBody == g->groupBody )
			{
			::fprintf(stderr,"setGroup: cannot add a group %s to itself\n",groupBody->tag);
			return;
			}
		if ( groupBody->flags.isLocal || groupBody->flags.isLabel || g->groupBody->flags.byRef )
			groupBody->gGroup = g;
		else {
			if ( !g->parent )
				groupBody->gGroup = g;
			else	groupBody->gGroup = new GroupItem(g);
			groupBody->gGroup->parent = this;
			groupBody->gGroup->options.affiliation = 3;
			}
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
	/*  Deliberately sets NO flag. isOperator and isMethod describe how the
	INTERPRETER dispatches this op, and installing an emitter must not
	disturb that -- the emitter rides alongside the binding, it does not
	replace it. Presence of the slot IS the gate, which is what makes the
	migration fork in runOP a null test and nothing more.
	void* and a hand-cast for the same reason setOperat does it.  */
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

void GroupItem::setMethod(GroupItem *(*m)(GroupItem *))
{
	groupBody->flags.instructType = 1;
	groupBody->gMethod = m;
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
	if ( !rStuff )
		setRStuff(new RuleStuff(this));
	else
	if ( rStuff->rule != this )
		{
		setRStuff(new RuleStuff(rStuff));
		rStuff->rule = this;
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
	Make sure affiliation and content flags (hasMembers, hasAttributes) match
*******************************************************************************/
void GroupItem::updateContentFlags()
{
	if ( parent )
		if ( isAttribute(options.affiliation) )
			parent->groupBody->flags.hasAttributes = 1;
		else
		if ( isMember(options.affiliation) )
			parent->groupBody->flags.hasMembers = 1;
	if ( groupBody->groupList->listLength )
		{
		GroupItem 	*item = 0;
		groupBody->flags.hasAttributes = 0;
		groupBody->flags.hasMembers = 0;
		while ( item = next(item) )
			if ( !groupBody->flags.hasAttributes && isAttribute(item->options.affiliation) )
				{
				groupBody->flags.hasAttributes = 1;
				if ( groupBody->flags.hasMembers )
					break;
				}
			else
			if ( !groupBody->flags.hasMembers && isMember(item->options.affiliation) )
				{
				groupBody->flags.hasMembers = 1;
				if ( groupBody->flags.hasAttributes )
					break;
				}
		}
}

/*****************************************************************************
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
