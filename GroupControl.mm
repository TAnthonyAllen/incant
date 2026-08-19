#include <Cocoa/Cocoa.h>
#include <dispatch/dispatch.h>
#include <string.h>
#include <stdio.h>
#include "OCroutines.h"
#include "StringRoutines.h"
#include "GroupItem.h"
#include "Buffer.h"
#include "DispatchQ.h"
#include "GroupRules.h"
#include "GroupList.h"
#include "GroupBody.h"
#include "PLGset.h"
#include "Stylish.h"
#include "GroupDraw.h"
#include "GroupControl.h"
GroupControl *GroupControl::groupController;

/******************************************************************************
	GroupControl constructor
******************************************************************************/
GroupControl::GroupControl(int i)
{
	dispatchQ = 0;
	cdataSet = new PLGset("'<>&\"");
	endNameSet = new PLGset("-~+?!%&|*@_<^ \n\r\t/;.,:='$#\\\"'()[]{}");
	mustQuoteSet = new PLGset(" +?*:!#/@|$%<>~.,;=()\"[\r\t\n'{}");
	groupRules = new GroupRules();
}

/*******************************************************************************
	Add the registry passed in to the list of base registries
*******************************************************************************/
void GroupControl::addBaseRegistry(GroupItem *r)
{
	if ( !groupRules->baseRegistryList )
		groupRules->baseRegistryList = getRegistry("BaseRegistries");
	groupRules->baseRegistryList->addMember(r);
}

/***************************************************************************
	Debugging routine to list out the registry search list
***************************************************************************/
void GroupControl::dumpSearchList()
{
GroupItem 	*registri = 0;
	::printf("Search list: \n");
	while ( registri = groupRules->searchList->next(registri) )
		if ( isREGISTRY(registri->groupBody->flags.binType) )
			::printf("\t%s\n",registri->groupBody->tag);
	if ( groupRules->baseRegistryList )
		{
		::printf("Base Search list: \n");
		registri = 0;
		while ( registri = groupRules->baseRegistryList->next(registri) )
			if ( isREGISTRY(registri->groupBody->flags.binType) )
				::printf("\t%s\n",registri->groupBody->tag);
		}
}

/***************************************************************************
    Registry factory
***************************************************************************/
GroupItem *GroupControl::getRegistry(char *c)
{
GroupItem 	*registri = 0;
	if ( groupRules->registries )
		registri = groupRules->registries->getFromList(c);
	if ( !registri )
		{
		/*******************************************************************
		Set the registry
		*******************************************************************/
		registri = new GroupItem(c);
		registri->groupBody->flags.binType = 4;
		registri->groupBody->flags.isSorted = 1;
		registri->groupBody->registry = registri;
		if ( groupRules->registries )
			registri = groupRules->registries->addMember(registri);
		}
	return registri;
}

/******************************************************************************
	Locate a group looking for it in the usual suspects.
******************************************************************************/
GroupItem *GroupControl::locate(char *name)
{
GroupItem 	*registri = 0;
GroupItem 	*group = groupRules->registries->get(name);
GroupRules 	*ruler = groupRules;
	if ( !group && ruler->currentRegistry )
		group = ruler->currentRegistry->get(name);
	if ( group )
		return group;
	while ( registri = ruler->searchList->next(registri) )
		if ( group = registri->get(name) )
			return group;
	while ( registri = ruler->baseRegistryList->next(registri) )
		if ( group = registri->get(name) )
			return group;
	if ( ::compare(name,ruler->registries->groupBody->tag) == 0 )
		group = ruler->registries;
	return group;
}

/******************************************************************************
	This version of locate searches for a group matching text of item passed in.
******************************************************************************/
GroupItem *GroupControl::locate(GroupItem *item)
{
char 	*name = item->getText();
	return locate(name);
}

/******************************************************************************
	locateInMethod when processing code, looks for a group matching name in
    local fields before calling locate()
******************************************************************************/
GroupItem *GroupControl::locateInMethod(char *name)
{
GroupItem 	*action = groupRules->currentMETHOD;
GroupItem 	*result = 0;
	if ( groupRules->processingCode )
		result = action->getAttribute(name);
	if ( !result )
		result = locate(name);
	return result;
}

/***************************************************************************
    Create a block and initialize content
***************************************************************************/
void GroupControl::setBaseRegistries()
{
GroupItem 	*action = 0;
	groupRules->fieldBUFFER = new Buffer();
	groupRules->stringBUFFER = new Buffer("string buffer");
	groupRules->formatBUFFER = new Buffer("format buffer");
	groupRules->registries = getRegistry("registries");
	groupRules->registries->groupBody->registry = groupRules->registries;
	groupRules->registries->groupBody->groupList = new GroupList(groupRules->registries);
	groupRules->inDENT = new GroupItem("indenter");
	groupRules->inDENT->groupBody->flags.data = 5;
	/***********************************************************************
	Create properties registry and add groups to it
	***********************************************************************/
	groupRules->properties = getRegistry("pROPERTIEs");
	groupRules->trueResult = groupRules->properties->addMember(new GroupItem("fieldBUFFER"));
	groupRules->trueResult->setBuffer(groupRules->fieldBUFFER);
	groupRules->trueResult = groupRules->properties->addMember(new GroupItem("true"));
	groupRules->trueResult->setCount(1);
	groupRules->trueResult->groupBody->flags.noPrint = 1;
	groupRules->falseResult = groupRules->properties->addMember(new GroupItem("false"));
	groupRules->falseResult->groupBody->flags.data = 5;
	groupRules->falseResult->groupBody->flags.noPrint = 1;
	/*  labelNO -- the return channel's third value (LA''-0, PC-3, 2026-08-07).
	NULL = failed · labelNO = succeeded and yields NOTHING · any other node
	= succeeded and yields that node.
	
	⚠ isCOUNT, VALUE 0, AND THAT IS THE WHOLE OF PC-3's ANSWER. The
	"yields nothing" meaning lives in labelNO's IDENTITY -- `lab == labelNO`
	-- and NOT in its numeric reading. That distinction is what lets the row
	land without an engine divergence.
	
	The alternative was to leave it non-numeric, and it does not work: the
	JIT's value channel is an i32 alloca (jitEmitters.rtn:1984), so a jitted
	empty construct yields the integer 0 and CANNOT yield a GroupItem at
	all. Making labelNO non-numeric would have put the interpreter and the
	JIT into permanent disagreement about what an empty construct is worth
	-- measured as ladder rung JV going red -- and closing that would mean
	widening the JIT's entire value representation, which is the frame arc
	and not this row.
	
	With isCOUNT it reads 0 exactly as falseResult did, so BOTH ENGINES
	STILL AGREE and JV needs no re-pin; what is new is only that the attach
	can now TELL "nothing" from "the number zero", which is the one thing
	it could never do before.  */
	groupRules->labelNO = groupRules->properties->addMember(new GroupItem("labelNO"));
	groupRules->labelNO->groupBody->flags.data = 5;
	groupRules->labelNO->groupBody->flags.noPrint = 1;
	groupRules->lastREF = groupRules->properties->addMember(new GroupItem("lastREF"));
	/***********************************************************************
	Create other base registries
	***********************************************************************/
	groupRules->keyWords = getRegistry("Keywords");
	groupRules->opFields = getRegistry("Operators");
	groupRules->opFields->groupBody->flags.isSorted = 0;
	groupRules->opFields->groupBody->flags.instructType = 2;
	groupRules->groupFields = getRegistry("GroupFields");
	groupRules->commands = getRegistry("cOMMANDs");
	groupRules->files = getRegistry("fILEs");
	groupRules->bcOPs = getRegistry("bcOPs");
	groupRules->bcOPs->groupBody->flags.instructType = 2;
	addBaseRegistry(groupRules->properties);
	addBaseRegistry(groupRules->opFields);
	addBaseRegistry(groupRules->commands);
	addBaseRegistry(groupRules->files);
	addBaseRegistry(groupRules->keyWords);
	addBaseRegistry(groupRules->groupFields);
	/***********************************************************************
	Initialize commands needed by the rule parser (associating those
	commands w/their methods). A bit of bootstrapping. Once done the
	parser can take over command initialization.
	***********************************************************************/
	action = groupRules->commands->addString("immediateAction");
	action->setMethod(::setRuleAction);
	action->groupBody->flags.methodType = 1;
	action->groupBody->flags.noPrint = 1;
	action->groupBody->registry = groupRules->commands;
	action = groupRules->commands->addString("noPrint");
	action->setMethod(::processFlags);
	action->groupBody->flags.methodType = 1;
	action->groupBody->flags.noPrint = 1;
	action->groupBody->registry = groupRules->commands;
	groupRules->printSPACE = new GroupItem("printSPACE");
	groupRules->printSPACE->setText(" ");
	/***********************************************************************
	maxLimit -- the ceiling modify() stamps into rStuff.max for the `+`
	and `*` modifiers, replacing the inline -0xefffffff it used to
	write. Ordinary user-visible data in pROPERTIEs, so a grammar sets
	it the way it sets any other property.
	
	⚠ modify() STAMPS max AT RULE-DEFINITION TIME, so a change to
	maxLimit affects only rules defined AFTER it. Set it before the
	grammar loads, never mid-session. The stamp is deliberate rather
	than a defect: the comparison it feeds sits on the hottest loop in
	the parser, and a live field read there would be paid for on every
	character of every match.
	
	⚠⚠ TWO KNOBS, BECAUSE ONE FIELD WAS BOUNDING TWO DIFFERENT KINDS OF
	QUANTITY (Tony's ruling, 2026-08-19, closing F-28). Both defaults are
	measured -- a 181-fixture sweep instrumented each population:
	
	maxLimit     TOKEN limit, characters in one match   ceiling  79
	(NotA, grammarOnTheFly)                default 100
	repeatLimit  REPETITION limit, times a rule repeats ceiling 171
	(StatemenT, phaseA)                    default 100000
	
	They are not the same kind of number and that is why they split. 79 is
	a real bound on a token: no name or number gets much longer, so 100 is
	a limit with meaning and a hit is worth refusing. 171 is not a bound on
	anything -- it is the length of one fixture, and the next file may have
	a thousand statements -- so its ceiling is chosen to be unreachable
	rather than chosen from the data. Sharing one field forced the token
	limit up to the repetition limit's number, which is what made 100
	unusable until now.
	
	⚠ AND THE ASYMMETRY IN WHAT A HIT MEANS SURVIVES THE SPLIT. A token cut
	short is WRONG CONTENT, so the character loops refuse through
	reportMaxLimit and fail the match. A rule that repeated to its ceiling
	matched everything it matched correctly; what is wrong is that there may
	be more. So the repetition loop REPORTS through reportRepeatLimit and
	leaves the match alone -- it no longer stops in silence, which is what
	made the old shared ceiling dangerous.
	
	⚠ THE CEILING IS ALSO LOAD-BEARING AS A RUNAWAY STOP, found by the sweep
	rather than looked for: incant/sinkProbe drives StatemenT to the ceiling
	EXACTLY, so it was doing 268435457 iterations and burning 17 seconds of
	CPU per run. At 100000 the identical run terminates the same way in
	milliseconds with byte-identical output. A runaway sets no floor, so it
	pins nothing. See docs/fixIts.md F-29.
	***********************************************************************/
	groupRules->maxLimit = new GroupItem("maxLimit");
	groupRules->maxLimit->setCount(100);
	groupRules->repeatLimit = new GroupItem("repeatLimit");
	groupRules->repeatLimit->setCount(100000);
	groupRules->properties->addMember(groupRules->inDENT);
	groupRules->properties->addMember(groupRules->printSPACE);
	groupRules->properties->addMember(groupRules->maxLimit);
	groupRules->properties->addMember(groupRules->repeatLimit);
}
