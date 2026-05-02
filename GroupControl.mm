#include <Cocoa/Cocoa.h>
#include <dispatch/dispatch.h>
#include <string.h>
#include <stdio.h>
#include "OCroutines.h"
#include "StringRoutines.h"
#include "GroupItem.h"
#include "PLGset.h"
#include "Buffer.h"
#include "DispatchQ.h"
#include "GroupRules.h"
#include "GroupList.h"
#include "GroupBody.h"
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

/******************************************************************************
    copyOf() makes a copy of the field passed in. The copy groupBody is a copy
    as is its groupList.
******************************************************************************/
GroupItem *GroupControl::copyOf(GroupItem *grup)
{
GroupItem 	*block = new GroupItem();
	*block->groupBody = *grup->groupBody;
	block->groupBody->groupList = 0;
	if ( grup->groupBody->groupList )
		block->copyListFrom(grup);
	return block;
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
	groupRules->fieldBUFFER = ::bufferFactory1();
	groupRules->stringBUFFER = ::bufferFactory2("string buffer");
	groupRules->formatBUFFER = ::bufferFactory2("format buffer");
	groupRules->registries = getRegistry("registries");
	groupRules->registries->groupBody->registry = groupRules->registries;
	groupRules->registries->groupBody->groupList = new GroupList(groupRules->registries);
	GroupDraw::drawer = new GroupDraw();
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
	addBaseRegistry(groupRules->properties);
	addBaseRegistry(groupRules->opFields);
	addBaseRegistry(groupRules->commands);
	addBaseRegistry(groupRules->files);
	addBaseRegistry(groupRules->keyWords);
	addBaseRegistry(groupRules->groupFields);
	GroupDraw::drawer->drawRegistry = getRegistry("Drawing");
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
