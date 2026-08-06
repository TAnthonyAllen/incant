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
	groupRules->properties->addMember(groupRules->inDENT);
	groupRules->properties->addMember(groupRules->printSPACE);
}
