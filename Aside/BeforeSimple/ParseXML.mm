#include <Cocoa/Cocoa.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "GroupItem.h"
#include "OCroutines.h"
#include "StringRoutines.h"
#include "GroupRules.h"
#include "Buffer.h"
#include "GroupControl.h"
#include "PLGparse.h"
#include "KeyTable.h"
#include "Stak.h"
#include "GroupBody.h"
#include "Tape.h"
#include "PathIterator.h"
#include "PLGtester.h"
#include "DoubleLinkList.h"
#include "PLGrule.h"
#include "DoubleLink.h"
#include "PLGitem.h"
#include "PLGset.h"
#include "BaseHash.h"
#include "regex.h"
#include "PLGrgx.h"
#include "ParseXML.h"

int AttributeListParseXMLNow(PLGitem *iTEM)
{
PLGitem 	*name = iTEM->get("name");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
PLGitem 	*item = 0;
PLGitem 	*text = 0;
	p->blockStack->clear();
	for ( item = name; item; item = item->next )
		{
		text = item->get("text");
		p->blockStack->push(text->toString());
		}
	return 1;
}

/*******************************************************************************
                Rule actions
            *******************************************************************************/
void AttributeParseXMLAct(PLGitem *iTEM)
{
PLGitem 	*target = iTEM->get("target");
PLGitem 	*name = iTEM->get("name");
PLGitem 	*value = iTEM->get("value");
PLGitem 	*modify = iTEM->get("modify");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
PLGitem 	*field = name->get("field");
PLGitem 	*regex = field->find("regex");
char 		*fieldID = field->toString();
PLGitem 	*dollar = 0;
PLGitem 	*item = 0;
PLGitem 	*text = 0;
PLGitem 	*valueRegex = 0;
GroupItem 	*block = 0;
PLGrgx 		*rgx = 0;
	p->currentBlock = 0;
	if ( value )
		{
		dollar = value->get("dollar");
		text = value->get("text");
		valueRegex = value->get("regex");
		}
	if ( p->settingPath )
		p->currentBlock = GroupControl::groupController->itemFactory(fieldID);
	if ( !p->currentBlock )
		p->currentBlock = GroupControl::groupController->locate(fieldID);
	if ( !p->currentBlock )
		p->currentBlock = GroupControl::groupController->itemFactory(fieldID);
	if ( target )
		{
		char 	*atText = target->string();
		while ( *atText )
			{
			if ( *atText == '@' )
				p->currentBlock->isTarget = 1;
			else
			if ( *atText == '%' )
				p->currentBlock->noAnchor = 1;
			atText++;
			}
		target->unString();
		}
	if ( modify )
		modify->runDeferred();
	/*********************************************************************
	Check for tag regular expression. Note that the currentBlock
	text is not set. Check for isAny and isEOF.
	*********************************************************************/
	if ( regex )
		{
		fieldID++;
		rgx = new PLGrgx(fieldID);
		p->currentBlock->setRegex(rgx);
		}
	if ( field->find("any") )
		if ( *field->itemStart == '*' )
			p->currentBlock->groupBody->data = 1;
		else	p->currentBlock->groupBody->data = 3;
	//cout `"Attribute: " currentBlock.tag:;
	/*************************************************************************
	Process value if there is one and compile value regular expressions
	*************************************************************************/
	if ( value )
		{
		if ( isRegexGRP(p->currentBlock->groupBody->data) )
			::fprintf(stderr,"Error: %s is regex and cannot have a value: %s\n",fieldID,value->toString());
		item = value->find("number");
		if ( item )
			{
			if ( item->flag1 )
				p->currentBlock->setNumber(item->amount);
			else	p->currentBlock->setCount((int)item->amount);
			if ( value->find("percent") )
				p->currentBlock->groupBody->isPercent = 1;
			}
		else
		if ( valueRegex )
			{
			rgx = new PLGrgx(text->toString());
			p->currentBlock->setRegex(rgx);
			}
		else {
			if ( dollar )
				p->currentBlock->groupBody->isMacro = 1;
			else
			if ( text )
				if ( GroupControl::groupController->currentRegistry->groupBody->isRule && (block = p->locate(text)) )
					if ( block != p->currentBlock )
						{
						block = GroupControl::groupController->itemFactory(block);
						p->currentBlock->setGroup(block);
						block->parent = p->currentBlock;
						}
					else	::fprintf(stderr,"Attribute: tried to assign %s to itself\n",block->groupBody->tag);
				else
				if ( text->isSetPLG )
					p->currentBlock->setCharacterSet((PLGset*)text->value);
				else	p->currentBlock->setItem(text);
			}
		}
	if ( p->firstTag )
		p->firstTag = 0;
	else
	if ( !p->currentBlock->groupBody->registry )
		p->currentBlock->affiliation = 1;
doneAttribute:
	field->value = (void*)p->currentBlock;
}

int BodyPartsParseXMLNow(PLGitem *iTEM)
{
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
	if ( p->currentBlock )
		p->currentBlock->groupBody->cdata = 1;
	return 1;
}

void Closing2ParseXMLAct(PLGitem *iTEM)
{
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
GroupItem 	*block = p->currentBlock;
	while ( block )
		{
		block->groupBody->isClosed = 1;
		if ( !block->groupBody->hasMembers )
			block->groupBody->isSingleton = 1;
		p->ancestor = block = block->parent;
		if ( p->ancestor )
			p->currentBlock = p->ancestor;
		}
}

void ClosingParseXMLAct(PLGitem *iTEM)
{
PLGitem 	*closing = iTEM->get("closing");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
GroupItem 	*block = p->currentBlock;
	for ( ; closing; closing = closing->next )
		if ( block )
			{
			block->groupBody->isClosed = 1;
			p->ancestor = block = block->parent;
			if ( p->ancestor )
				p->currentBlock = p->ancestor;
			}
	//currentBlock should be now set to the last block closed
}

int CommandParseXMLNow(PLGitem *iTEM)
{
PLGitem 	*command = iTEM->get("command");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
	p->currentBlock = 0;
	if ( !command )
		{
		GroupControl::groupController->currentRegistry = 0;
		p->reset();
		}
	else	command->runDeferred();
	p->commanding = 0;
	return 1;
}

void CommandText2ParseXMLAct(PLGitem *iTEM)
{
PLGitem 	*type = iTEM->get("type");
PLGitem 	*flag = iTEM->get("flag");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
	/*****************************************************************************
	Create registry
	*****************************************************************************/
	type = type->get("text");
	p->pushState();
	GroupControl::groupController->currentRegistry = GroupControl::groupController->getRegistry(type->toString());
	/*************************************************************************
	The optional value argument sets registry characteristics that
	mostly relate to how the registry gets loaded
	*************************************************************************/
	for ( ; flag; flag = flag->next )
		{
		if ( ::compare(flag->string(),"asAttributes") == 0 )
			{
			GroupControl::groupController->currentRegistry->groupBody->loadAsAttributes = 1;
			GroupControl::groupController->currentRegistry->removeFromItsList("noAttributes");
			}
		else
		if ( ::compare(flag->string(),"base") == 0 )
						GroupControl::groupController->addBaseRegistry(GroupControl::groupController->currentRegistry);
		else
		if ( ::compare(flag->string(),"components") == 0 )
			{
			//  When registering a group, also register its components
			GroupControl::groupController->currentRegistry->groupBody->loadComponents = 1;
			}
		else
		if ( ::compare(flag->string(),"data") == 0 )
			{
			//  Register item text (as opposed to the tag)
			GroupControl::groupController->currentRegistry->groupBody->loadFromData = 1;
			}
		else
		if ( ::compare(flag->string(),"descending") == 0 )
						GroupControl::groupController->currentRegistry->groupBody->isSorted = 2;
		else
		if ( ::compare(flag->string(),"display") == 0 )
						GroupControl::groupController->currentRegistry->groupBody->isGUIregistry = 1;
		else
		if ( ::compare(flag->string(),"grouped") == 0 )
						GroupControl::groupController->currentRegistry->groupBody->grouped = 1;
		else
		if ( ::compare(flag->string(),"noPrint") == 0 )
						GroupControl::groupController->currentRegistry->groupBody->noPrint = !GroupControl::groupController->currentRegistry->groupBody->noPrint;
		else
		if ( ::compare(flag->string(),"rules") == 0 )
			{
			// if isRule is true for a registry then all registry entries are considered
			// rules (enforced in GroupItem addRule() when adding groups to the registry).
			GroupControl::groupController->currentRegistry->groupBody->isRule = 1;
			GroupControl::groupController->currentRegistry->groupBody->noMerge = 1;
			}
		else
		if ( ::compare(flag->string(),"search") == 0 )
			{
			//  Adds the current registry to the registry search list.
			if ( !GroupControl::groupController->searchList->groupBody->getFromList(GroupControl::groupController->currentRegistry->groupBody->tag) )
				GroupControl::groupController->searchList->addGroup(GroupControl::groupController->currentRegistry);
			}
		else
		if ( ::compare(flag->string(),"sort") == 0 )
						GroupControl::groupController->currentRegistry->groupBody->isSorted = 1;
		else
		if ( ::compare(flag->string(),"value") == 0 )
			{
			//  When adding an item to a registry, ignore the tag and load the value
			//  When referenced the tag is resolved to be the registry name
			GroupControl::groupController->currentRegistry->groupBody->loadByValue = 1;
			}
		flag->unString();
		}
	p->ancestor = 0;
}

void CommandText3ParseXMLAct(PLGitem *iTEM)
{
PLGitem 	*action = iTEM->get("action");
PLGitem 	*type = iTEM->get("type");
PLGitem 	*path = iTEM->get("path");
PLGitem 	*number = iTEM->get("number");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
	/*****************************************************************************
	Dump List or Print
	*****************************************************************************/
GroupItem 	*item = 0;
GroupItem 	*registri = 0;
char 		*text = 0;
	p->pushState();
	/*************************************************************************
	figure out the parameters
	*************************************************************************/
	if ( type )
		{
		type = type->get("text");
		text = type->string();
		if ( GroupControl::registries )
			registri = GroupControl::registries->groupBody->getFromList(text);
		}
	if ( path )
		{
		item = (GroupItem*)path->get("field")->value;
		if ( !item )
			::fprintf(stderr,"print: no path match for %s\n",path->toString());
		}
	/*************************************************************************
	If there is no block or registry argument the current outer block gets
	dumped provided it exists.
	*************************************************************************/
	if ( !type && !path )
		{
		if ( p->outerBlock )
			if ( *action->itemStart == 'd' )
				p->outerBlock->dumpDetail(0,1);
			else	::printf("%s",p->outerBlock->toString());
		return;
		}
	/*************************************************************************
	Process commands
	*************************************************************************/
	if ( ::compare(text,"registries") == 0 )
		if ( GroupControl::registries )
			{
			::printf("Registries: contains %d entries (maybe not all registries)\n",GroupControl::registries->groupBody->groupListLength);
			registri = 0;
			while ( registri = GroupControl::registries->next(registri) )
				if ( registri->groupBody->isRegistryGRP )
					::printf("\t%s entries:\t%d\n",registri->groupBody->tag,registri->groupBody->groupListLength);
			}
		else	::printf("\tNo registries found\n");
	if ( registri )
		item = registri;
	if ( number )
		p->recordNumber = (int)number->amount;
	if ( item )
		{
		if ( item->groupBody->isRegistryGRP )
			GroupControl::groupController->groupRules->ignoreNoPrint = 1;
		if ( action->compare("dump") == 0 )
			item->dumpDetail(0,99);
		else
		if ( action->compare("print") == 0 )
			::printf("%s\n",item->toString());
		else
		if ( action->compare("test") == 0 )
			{
			// use a directive to add a test matching on number
			number = 0;
			}
		else	item->list();
		GroupControl::groupController->groupRules->ignoreNoPrint = 0;
		}
	if ( type )
		type->unString();
	p->popState();
}

void CommandText4ParseXMLAct(PLGitem *iTEM)
{
PLGitem 	*flag = iTEM->get("flag");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
	/*****************************************************************************
	Process Flags
	*****************************************************************************/
	if ( *flag->itemStart == 'd' )
		p->currentRule->debug = !p->currentRule->debug;
	else
	if ( *flag->itemStart == 'e' )
		p->simpleSyntax = !p->simpleSyntax;
	else
	if ( *flag->itemStart == 'm' )
		GroupControl::groupController->groupRules->doNotExpandMacros = !GroupControl::groupController->groupRules->doNotExpandMacros;
	else
	if ( *flag->itemStart == 's' )
		{
		::printf("Exiting\n");
		p->stopParsing = 1;
		}
	else
	if ( flag->compare("noJIT") == 0 )
		{
		p->noLineByLine = !p->noLineByLine;
		}
	else
	if ( flag->compare("noPrint") == 0 )
		{
		GroupControl::groupController->groupRules->ignoreNoPrint = !GroupControl::groupController->groupRules->ignoreNoPrint;
		}
	else	::printf("pausing\n");
}

void CommandText5ParseXMLAct(PLGitem *iTEM)
{
PLGitem 	*names = iTEM->get("names");
PLGitem 	*name = 0;
GroupItem 	*registri = 0;
	/*****************************************************************************
	Search List
	Create, print out, overwrite or append to the registry search list
	*****************************************************************************/
	if ( !names )
		GroupControl::groupController->dumpSearchList();
	else {
		if ( GroupControl::registries )
			for ( ; names; names = names->next )
				{
				char 	*text = 0;
				name = names->get("text");
				text = name->string();
				registri = GroupControl::groupController->searchList->groupBody->getFromList(text);
				if ( !registri )
					if ( registri = GroupControl::registries->groupBody->getFromList(text) )
						GroupControl::groupController->searchList->addGroup(registri);
				name->unString();
				}
		else	::fprintf(stderr,"ERROR search command: no registries exist\n");
		}
}

void CommandText6ParseXMLAct(PLGitem *iTEM)
{
PLGitem 	*path = iTEM->get("path");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
	/*****************************************************************************
	Process load command.
	*****************************************************************************/
GroupItem 	*fieldItem = 0;
GroupItem 	*item = 0;
	p->recordNumber = 0;
	for ( ; path; path = path->next )
		if ( fieldItem = (GroupItem*)path->get("field")->value )
			if ( fieldItem->getAttribute("directory") )
				item = fieldItem->loadDirectory();
			else
			if ( fieldItem->getAttribute("json") )
				item = p->loadJSON(fieldItem);
			else
			if ( fieldItem->groupBody->isRule || fieldItem->getAttribute("rule") )
				if ( item = p->loadRule(fieldItem) )
					::dumpResults(item);
				else
				if ( item = p->loadDelimited(fieldItem) )
					if ( item->groupBody->groupListLength )
						::printf("Loaded %d entries\n",item->groupBody->groupListLength);
					else	::printf("Nothing loaded\n");
				else	::fprintf(stderr,"WARNING load: could not load %s\n",fieldItem->groupBody->tag);
			else	::fprintf(stderr,"ERROR load: Could not find %s\n",path->toString());
}

void CommandText7ParseXMLAct(PLGitem *iTEM)
{
PLGitem 	*group = iTEM->get("group");
PLGitem 	*argument = iTEM->get("argument");
GroupItem 	*item = 0;
GroupItem 	*parameter = 0;
GroupItem 	*block = 0;
	/*****************************************************************************
	Check the group passed in, if it has a method and an argument run it.
	*****************************************************************************/
	if ( block = (GroupItem*)group->get("field")->value )
		if ( !block->groupBody->gMethod )
			::fprintf(stderr,"\t\tNo method found for %s\n",block->groupBody->tag);
		else {
			if ( parameter = (GroupItem*)argument->get("field")->value )
				item = block->groupBody->gMethod(parameter);
			else	item = block->groupBody->gMethod(block);
			if ( item )
				::printf("\t\tSucceeded running %s\n",block->groupBody->tag);
			else	::printf("\t\t%s\tmethod failed\n",block->groupBody->tag);
			}
	// not sure what we do w/item ... just print it for now
}

void CommandTextParseXMLAct(PLGitem *iTEM)
{
PLGitem 	*file = iTEM->get("file");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
	p->includeFile(file->string());
	file->unString();
}

int DebuggingParseXMLNow(PLGitem *iTEM)
{
	PLGitem::plgItemDebug = 1;
	return 1;
}

int DelimitEmptyParseXMLNow(PLGitem *iTEM)
{
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
	p->yearRegistry->getItem()->flag1 = 1;
	return 1;
}

int DelimitFieldNameParseXMLNow(PLGitem *iTEM)
{
PLGitem 	*name = iTEM->get("name");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
PLGitem 	*delimit = name->get("delimit");
PLGitem 	*text = name->get("text");
	if ( !p->doneWithHeading )
		p->fieldRegistry->addGroup(GroupControl::groupController->itemFactory(text));
	else {
		p->block = 0;
		return 0;
		}
	if ( *delimit->itemStart == p->endRecord )
		p->doneWithHeading = 1;
	return 1;
}

void DelimitNumberParseXMLAct(PLGitem *iTEM)
{
PLGitem 	*number = iTEM->get("number");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
	//cout `"number: " number:;
	if ( p->getFieldBlock(number) && !p->block->groupBody->registry )
		if ( number->flag1 )
			p->block->setNumber(number->amount);
		else	p->block->setCount((int)number->amount);
}

void DelimitText2ParseXMLAct(PLGitem *iTEM)
{
PLGitem 	*text = iTEM->get("text");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
	if ( p->getFieldBlock(text) && !p->block->groupBody->registry )
		p->block->setItem(text);
}

void DelimitText3ParseXMLAct(PLGitem *iTEM)
{
PLGitem 	*text = iTEM->get("text");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
	if ( p->getFieldBlock(text) && !p->block->groupBody->registry )
		p->block->setItem(text);
}

void DelimitTextParseXMLAct(PLGitem *iTEM)
{
PLGitem 	*text = iTEM->get("text");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
	if ( p->getFieldBlock(text) && !p->block->groupBody->registry )
		p->block->setItem(text);
}

int EndBraceParseXMLNow(PLGitem *iTEM)
{
PLGitem 	*endBrace = iTEM->get("endBrace");
	if ( *(endBrace->itemStart - 1) == '\\' )
		return 0;
	return 1;
}

void EndTag2ParseXMLAct(PLGitem *iTEM)
{
PLGitem 	*action = iTEM->get("action");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
	if ( p->currentBlock = p->ancestor )
		{
		p->currentBlock->groupBody->isClosed = 1;
		p->currentBlock = p->ancestor = p->currentBlock->parent;
		if ( action )
			action->runDeferred();
		}
}

int EndTag2ParseXMLNow(PLGitem *iTEM)
{
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
	if ( !p->ancestor )
		return 0;
	return 1;
}

void EndTagParseXMLAct(PLGitem *iTEM)
{
PLGitem 	*action = iTEM->get("action");
PLGitem 	*field = iTEM->get("field");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
GroupItem 	*listTag = 0;
	p->currentBlock = p->ancestor;
	if ( field )
		while ( p->currentBlock )
			if ( field->compare(p->currentBlock->groupBody->tag) == 0 )
				break;
			else	p->currentBlock = p->currentBlock->parent;
	if ( !p->currentBlock )
		{
		if ( field )
			{
			listTag = GroupControl::groupController->itemFactory(field);
			field->isEndTag = 1;
			}
		else	listTag = GroupControl::groupController->itemFactory();
		listTag->groupBody->noTag = 1;
		listTag->groupBody->isSingleton = 1;
		if ( !p->ancestor )
			{
			if ( p->outerBlock && !p->outerBlock->groupBody->isClosed && !p->outerBlock->groupBody->isSingleton )
				p->currentBlock = p->outerBlock;
			else	p->currentBlock = listTag;
			}
		}
	if ( listTag )
		{
		if ( p->ancestor )
			{
			if ( p->ancestor->groupBody->hasMembers )
				p->ancestor->addGroup(listTag);
			else
			if ( field )
				{
				PLGitem 	*item = p->ancestor->getItem();
				field->isEndTag = 1;
				if ( item )
					item->append(field);
				else	p->ancestor->setItem(field);
				}
			p->currentBlock = p->ancestor;
			}
		else
		if ( listTag != p->currentBlock )
			p->currentBlock->addGroup(listTag);
		p->endTags->push(listTag);
		}
	else {
		while ( p->ancestor && p->ancestor != p->currentBlock )
			{
			p->ancestor->groupBody->isClosed = 1;
			p->ancestor = p->ancestor->parent;
			}
		p->currentBlock->groupBody->isClosed = 1;
		p->ancestor = p->currentBlock->parent;
		if ( !p->ancestor )
			p->outerBlock = p->currentBlock;
		p->openTags--;
		}
	if ( action )
		action->runDeferred();
}

int EndTagParseXMLNow(PLGitem *iTEM)
{
PLGitem 	*field = iTEM->get("field");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
GroupItem 	*group = p->ancestor;
	if ( field )
		while ( group && field->compare(group->groupBody->tag) != 0 )
			{
			group = group->parent;
			}
	return 1;
}

int FieldItemParseXMLNow(PLGitem *iTEM)
{
PLGitem 	*item = iTEM->get("item");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
	if ( !item->flag1 )
		p->processDelimitField(item);
	return 1;
}

int FieldName3ParseXMLNow(PLGitem *iTEM)
{
PLGitem 	*field = iTEM->get("field");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
	p->convertItem(field);
	return 1;
}

int FieldName4ParseXMLNow(PLGitem *iTEM)
{
PLGitem 	*field = iTEM->get("field");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
	p->convertItem(field);
	return 1;
}

void JSONblockParseXMLAct(PLGitem *iTEM)
{
PLGitem 	*pair = iTEM->get("pair");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
GroupItem 	*pater = p->ancestor;
GroupItem 	*blk = p->currentBlock;
	p->ancestor = p->currentBlock;
	for ( ; pair; pair = pair->next )
		pair->runDeferred();
	p->ancestor = pater;
	p->currentBlock = blk;
}

void JSONdata2ParseXMLAct(PLGitem *iTEM)
{
PLGitem 	*block = iTEM->get("block");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
	if ( block )
		block->runDeferred();
	if ( p->ancestor && p->ancestor != p->currentBlock )
		{
		p->ancestor->addGroup(p->currentBlock);
		//cout `"JSONdata2: adding block",currentBlock.tag,"to",ancestor.tag:;
		}
	p->jsonType = 1;
}

void JSONdata3ParseXMLAct(PLGitem *iTEM)
{
PLGitem 	*repeat = iTEM->get("repeat");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
	// to flag the current block as a repeat block
	p->currentBlock->groupBody->expanded = 1;
	p->ancestor = p->currentBlock;
	repeat->runDeferred();
	p->jsonType = 3;
}

void JSONdataParseXMLAct(PLGitem *iTEM)
{
PLGitem 	*name = iTEM->get("name");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
	// name may be an empty string
	if ( name )
		p->currentBlock->setItem(name);
	//cout `"JSONdata: added attribute",currentBlock,"to",ancestor:;
	if ( p->ancestor && p->ancestor->groupBody->expanded )
		{
		p->ancestor->addGroup(p->currentBlock);
		//cout `"JSONdata: adding block",currentBlock.tag,"to",ancestor.tag:;
		p->ancestor = p->currentBlock;
		}
	else	p->ancestor->addGroup(p->currentBlock);
	p->jsonType = 2;
}

int JSONlistEntryParseXMLNow(PLGitem *iTEM)
{
PLGitem 	*entry = iTEM->get("entry");
	entry->runDeferred();
	return 1;
}

void JSONpairParseXMLAct(PLGitem *iTEM)
{
PLGitem 	*name = iTEM->get("name");
PLGitem 	*data = iTEM->get("data");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
char 		*fieldName = name->toString();
	if ( p->fieldRegistry )
		{
		GroupItem 	*rename = p->fieldRegistry->groupBody->getFromList(fieldName);
		if ( rename )
			fieldName = rename->getText();
		}
	p->currentBlock = GroupControl::groupController->itemFactory(fieldName);
	if ( !p->ancestor )
		if ( p->list )
			p->list->addGroup(p->currentBlock);
		else
		if ( GroupControl::groupController->currentRegistry )
			GroupControl::groupController->currentRegistry->addGroup(p->currentBlock);
		else	::fprintf(stderr,"JSONpair rule: do not know what to load %s into\n",p->currentBlock->groupBody->tag);
	//cout "JSONpair: created a new block",fieldName:;
	data->runDeferred();
}

void JSONrepeatEntryParseXMLAct(PLGitem *iTEM)
{
PLGitem 	*data = iTEM->get("data");
	data->runDeferred();
}

void JSONrepeatParseXMLAct(PLGitem *iTEM)
{
PLGitem 	*entry = iTEM->get("entry");
	for ( ; entry; entry = entry->next )
		entry->runDeferred();
}

int LocateParseXMLNow(PLGitem *iTEM)
{
PLGitem 	*type = iTEM->get("type");
PLGitem 	*field = iTEM->get("field");
GroupItem 	*registri = 0;
GroupItem 	*group = 0;
PLGitem 	*item = field->get("text");
char 		*text = item->string();
	if ( type )
		registri = (GroupItem*)type->value;
	if ( registri )
		group = registri->getMember(text);
	else	group = GroupControl::groupController->locate(text);
	item->unString();
	if ( group )
		field->value = (void*)group;
	else	return 0;
	return 1;
}

int MacroParseXMLNow(PLGitem *iTEM)
{
PLGitem 	*macro = iTEM->get("macro");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
PLGitem 	*text = 0;
	p->scratch->setMark();
	for ( ; macro; macro = macro->next )
		{
		text = macro->get("text");
		p->scratch->appendItem(text,0,0);
		}
	p->block->setText(p->scratch->getMarkedString());
	return 1;
}

int MacroPartParseXMLNow(PLGitem *iTEM)
{
PLGitem 	*text = iTEM->get("text");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
GroupItem 	*group = 0;
char 		*name = 0;
	name = text->string();
	group = p->block->findUpward(name);
	if ( !group )
		group = GroupControl::groupController->locate(name);
	text->unString();
	if ( group )
		text->setString(group->getText());
	return 1;
}

void ModifierParseXMLAct(PLGitem *iTEM)
{
PLGitem 	*limit = iTEM->get("limit");
PLGitem 	*modifier = iTEM->get("modifier");
PLGitem 	*alternate = iTEM->get("alternate");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
GroupItem 	*attribute = 0;
PLGitem 	*item = 0;
int 		modifiers = 0;
	if ( modifier )
		while ( modifiers < modifier->itemLength )
			switch ( *(modifier->itemStart + modifiers++) )
				{
				case '!':
					p->currentBlock->groupBody->bangedGRP = 1;
					p->currentBlock->groupBody->noMerge = 1;
					break;
				case '?':
					p->currentBlock->groupBody->isOption = 2;
					break;
				case '+':
					p->currentBlock->groupBody->isOption = 4;
					break;
				case '*':
					p->currentBlock->groupBody->isOption = 5;
					break;
				case '}':
					p->currentBlock->groupBody->keepGoing = 2;
					break;
				case '{':
					p->currentBlock->groupBody->keepGoing = 1;
					break;
				case '%':
					p->currentBlock->groupBody->noAdvance = 1;
					break;
				case '<':
					p->currentBlock->groupBody->isContainerGRP = 1;
					break;
				case '&':
					p->currentBlock->groupBody->noSkip = 1;
				}
	if ( limit )
		{
		if ( item = limit->get("minimum") )
			if ( item->amount != 1 )
				{
				attribute = p->currentBlock->addAttrDouble("min",item->amount);
				attribute->groupBody->noPrint = 1;
				p->currentBlock->groupBody->isOption = 1;
				}
		if ( item = limit->get("maximum") )
			if ( item->amount != 1 )
				{
				attribute = p->currentBlock->addAttrDouble("max",item->amount);
				attribute->groupBody->noPrint = 1;
				p->currentBlock->groupBody->isOption = 3;
				}
		}
	if ( alternate )
		p->currentBlock->groupBody->isAlternate = 1;
}

int ModifierParseXMLNow(PLGitem *iTEM)
{
PLGitem 	*limit = iTEM->get("limit");
PLGitem 	*modifier = iTEM->get("modifier");
PLGitem 	*alternate = iTEM->get("alternate");
	if ( !modifier && !limit && !alternate )
		return 0;
	return 1;
}

int NumberParseXMLNow(PLGitem *iTEM)
{
PLGitem 	*number = iTEM->get("number");
PLGitem 	*part = iTEM->get("part");
	if ( part )
		{
		number->itemLength += part->itemLength;
		number->flag1 = 1;
		}
	number->amount = ::atof(number->string());
	number->unString();
	return 1;
}

int PartParseXMLNow(PLGitem *iTEM)
{
PLGitem 	*prefix = iTEM->get("prefix");
PLGitem 	*body = iTEM->get("body");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
GroupItem 	*group = 0;
char 		*suffixStart = 0;
PLGitem 	*suffix = 0;
PLGitem 	*head = 0;
	if ( p->stopParsing )
		return 0;
	/***************************************************************************
	If there are prefix parts (cdata), they get appended to body.
	If there is a suffix (any random text), it too gets appended to body.
	Code gets parsed and executed and does not exist as far as xml concerned.
	*** Code parsing and execution removed pending JIT rework
	***************************************************************************/
	head = body->valueItem;
	for ( ; prefix; prefix = prefix->next )
		{
		PLGitem 	*part = prefix->get("part");
		// Note: because comments are not labeled in BodyParts, they get ignored here
		if ( part )
			body->append(part);
		}
	if ( !p->ancestor && body->itemLength )
		{
		suffixStart = body->itemStart;
		}
	if ( suffixStart && suffixStart < p->plgStart )
		{
		suffix = p->plgItemFactory(suffixStart,(int)(p->plgStart - suffixStart));
		body->append(suffix);
		}
	if ( p->ancestor && body->itemLength )
		{
		if ( isBufferGRP(p->ancestor->groupBody->data) )
			p->ancestor->getBuffer()->appendItem(body,0,0);
		else {
			group = GroupControl::groupController->itemFactory("boDY");
			group->setItem(body);
			group->groupBody->noTag = 1;
			group->groupBody->isComment = 1;
			group->groupBody->isClosed = 1;
			p->ancestor->addGroup(group);
			p->ancestor->groupBody->hasBodyText = 1;
			}
		}
	if ( head )
		head->runDeferred();
	return 1;
}

void PathItemParseXMLAct(PLGitem *iTEM)
{
PLGitem 	*text = iTEM->get("text");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
char 		*name = text->string();
	if ( p->block )
		p->block = p->block->getMember(name);
	text->unString();
}

int PathParseXMLNow(PLGitem *iTEM)
{
PLGitem 	*up = iTEM->get("up");
PLGitem 	*path = iTEM->get("path");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
	if ( up )
		up->runDeferred();
	if ( up->get("slash") )
		for ( ; path; path = path->next )
			{
			path->runDeferred();
			if ( path->get("slash") )
				continue;
			else
			if ( path->next )
				{
				::fprintf(stderr,"Invalid path: expected a /\n");
				p->block = 0;
				break;
				}
			}
	else
	if ( path )
		{
		::fprintf(stderr,"Invalid path: expected a /\n");
		p->block = 0;
		}
	return 1;
}

int Quoted2ParseXMLNow(PLGitem *iTEM)
{
PLGitem 	*text = iTEM->get("text");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
	p->convertItem(text);
	text->flag2 = 1;
	return 1;
}

int QuotedParseXMLNow(PLGitem *iTEM)
{
PLGitem 	*text = iTEM->get("text");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
	p->convertItem(text);
	text->flag2 = 1;
	return 1;
}

int RegistryParseXMLNow(PLGitem *iTEM)
{
PLGitem 	*type = iTEM->get("type");
GroupItem 	*registri = 0;
	type = type->get("text");
	if ( GroupControl::registries && type->compare("registries") != 0 )
		{
		registri = GroupControl::registries->groupBody->getFromList(type->string());
		type->unString();
		if ( !registri )
			{
			//cout "Registry rule failed:",type:;
			return 0;
			}
		}
	type->value = (void*)registri;
	return 1;
}

void SetAttributesParseXMLAct(PLGitem *iTEM)
{
PLGitem 	*attributes = iTEM->get("attributes");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
GroupItem 	*item = 0;
GroupItem 	*block = 0;
	block = p->currentBlock = p->processTag(attributes);
	if ( !p->ancestor )
		p->outerBlock = block;
	if ( p->ancestor )
		block = p->ancestor->addGroup(block);
	else
	if ( GroupControl::groupController->currentRegistry && !block->groupBody->registry )
		{
		if ( !block->parent )
			GroupControl::groupController->currentRegistry->addGroup(block);
		else
		if ( (block->parent != GroupControl::groupController->currentRegistry && GroupControl::groupController->currentRegistry->getAttribute("loadComponents")) || (block->parent->groupBody->registry && block->parent->groupBody->registry != GroupControl::groupController->currentRegistry) )
			GroupControl::groupController->currentRegistry->addGroup(block);
		}
	p->currentBlock = block;
	if ( p->immediates->length )
		while ( item = (GroupItem*)p->immediates->pop() )
			{
			item->parent = block;
			// method needs to find block
			item->groupBody->gMethod(item);
			}
}

int SetSimpleEndParseXMLNow(PLGitem *iTEM)
{
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
	p->endString = iTEM->toString();
	return 1;
}

int SetTagFlagParseXMLNow(PLGitem *iTEM)
{
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
	p->firstTag = 1;
	return 1;
}

void SimpleEnd2ParseXMLAct(PLGitem *iTEM)
{
PLGitem 	*close = iTEM->get("close");
PLGitem 	*field = iTEM->get("field");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
int 		i = 0;
GroupItem 	*block = p->currentBlock;
	block->groupBody->isSingleton = 1;
	while ( block && i++ < close->itemLength )
		{
		block->groupBody->isClosed = 1;
		block = block->parent;
		}
	if ( field )
		while ( block )
			{
			block->groupBody->isClosed = 1;
			if ( field->compare(block->groupBody->tag) == 0 )
				break;
			block = block->parent;
			}
	if ( p->ancestor && p->ancestor->groupBody->isClosed )
		p->ancestor = p->ancestor->parent;
}

void SimpleEndParseXMLAct(PLGitem *iTEM)
{
PLGitem 	*textBody = iTEM->get("textBody");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
	if ( p->ancestor )
		p->currentBlock->parent = p->ancestor;
	p->ancestor = p->currentBlock;
	if ( textBody )
		textBody->runDeferred();
	p->currentBlock->groupBody->isSingleton = 0;
}

int SkipGuardParseXMLNow(PLGitem *iTEM)
{
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
	p->field = p->fieldRegistry->nextMember(0);
	if ( p->field->groupBody->fLAG )
		return 0;
	//cout `"Skipping: " field.tag:;
	return 1;
}

void StartTag2ParseXMLAct(PLGitem *iTEM)
{
PLGitem 	*traits = iTEM->get("traits");
PLGitem 	*end = iTEM->get("end");
	traits->runDeferred();
	end->runDeferred();
}

void StartTagParseXMLAct(PLGitem *iTEM)
{
PLGitem 	*traits = iTEM->get("traits");
PLGitem 	*singleton = iTEM->get("singleton");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
	traits->runDeferred();
GroupItem 	*block = p->currentBlock;
	/*************************************************************************
	Set block status wrt being open or closed
	*************************************************************************/
	if ( !singleton )
		{
		block->groupBody->isClosed = 0;
		block->groupBody->isSingleton = 0;
		p->ancestor = block;
		p->openTags++;
		}
	else {
		singleton->runDeferred();
		block->groupBody->isSingleton = 1;
		}
}

int StartXMLParseXMLNow(PLGitem *iTEM)
{
PLGitem 	*epilog = iTEM->get("epilog");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
GroupItem 	*epilogBlock = 0;
	if ( epilog && p->notSpace->foundIn(epilog) && p->trimEnd(epilog) )
		if ( p->ancestor && !p->ancestor->groupBody->hasMembers && !p->ancestor->groupBody->data )
			p->ancestor->setItem(epilog);
		else {
			epilogBlock = GroupControl::groupController->itemFactory("epilog");
			epilogBlock->setItem(epilog);
			epilogBlock->groupBody->noTag = 1;
			if ( !p->outerBlock )
				p->outerBlock = epilogBlock;
			else {
				if ( p->ancestor )
					p->ancestor->addGroup(epilogBlock);
				else	p->outerBlock->addGroup(epilogBlock);
				}
			}
	//cout "Total blocks: " groupController.length:;
	if ( p->endTags && p->endTags->length )
		{
		GroupItem 	*block = 0;
		::printf("End tags pending\n");
		while ( block = (GroupItem*)p->endTags->next() )
			::printf("\t%s\n",block->groupBody->tag);
		}
	p->resetItemTape();
	//groupTape.status();
	//itemTape.status();
	//globalLinkTape.status();
	return 1;
}

int StopHereParseXMLNow(PLGitem *iTEM)
{
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
	p->currentRule->debug = 0;
	return 1;
}

int StringSetParseXMLNow(PLGitem *iTEM)
{
PLGitem 	*text = iTEM->get("text");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
PLGset 		*set = p->getSet(p->convertSetInput(text));
	text->value = (void*)set;
	text->isSetPLG = 1;
	return 1;
}

void Tag2ParseXMLAct(PLGitem *iTEM)
{
PLGitem 	*tag = iTEM->get("tag");
	tag->runDeferred();
}

void Tag3ParseXMLAct(PLGitem *iTEM)
{
PLGitem 	*tag = iTEM->get("tag");
	tag->runDeferred();
}

void TextBodyParseXMLAct(PLGitem *iTEM)
{
PLGitem 	*body = iTEM->get("body");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
	p->endString = 0;
	if ( p->ancestor && body->itemLength )
		{
		if ( isBufferGRP(p->ancestor->groupBody->data) )
			p->ancestor->getBuffer()->appendItem(body,0,0);
		else {
			GroupItem 	*group = GroupControl::groupController->itemFactory("boDY");
			group->setItem(body);
			group->groupBody->noTag = 1;
			group->groupBody->isComment = 1;
			group->groupBody->isClosed = 1;
			p->ancestor->addGroup(group);
			p->ancestor->groupBody->hasBodyText = 1;
			}
		}
	p->ancestor = p->currentBlock->parent;
}

void UpParseXMLAct(PLGitem *iTEM)
{
PLGitem 	*more = iTEM->get("more");
ParseXML 	*p = (ParseXML*)iTEM->test->testParser;
	if ( p->block )
		p->block = p->block->parent;
	for ( ; more; more = more->next )
		if ( p->block )
			p->block = p->block->parent;
}

/*****************************************************************************
	Constructor
*****************************************************************************/
ParseXML::ParseXML()
{
	ancestor = 0;
	block = 0;
	currentBlock = 0;
	field = 0;
	fieldRegistry = 0;
	fileList = 0;
	foundItems = 0;
	jitInclude = 0;
	lastSelect = 0;
	list = 0;
	monthRegistry = 0;
	outerBlock = 0;
	record = 0;
	yearRegistry = 0;
	jitHeader = 0;
	testItem = 0;
	setName = 0;
	delimiter = 0;
	endRecord = 0;
	groupItems = 0;
	openTags = 0;
	recordNumber = 0;
	pathParser = 0;
	jsonType = 0;
	complexPath = 0;
	doneWithHeading = 0;
	droppedAnchor = 0;
	firstTag = 0;
	hasHeading = 0;
	ignoreSkip = 0;
	isThreaded = 0;
	commanding = 0;
	numberValues = 0;
	settingPath = 0;
	targetSet = 0;
	useStash = 0;
	alphaSet = 0;
	anchorSet = 0;
	bodySet = 0;
	commentSet = 0;
	dateSet = 0;
	delimitSet = 0;
	fieldSet = 0;
	nameSet = 0;
	singleQuote = 0;
	tagSet = 0;
	textSet = 0;
	Registering = 0;
	Flag = 0;
	CommandAction = 0;
	simpleEnd = 0;
	textFollow = 0;
	simpleSyntax = 0;
	stopParsing = 0;
	endString = 0;
	subString = 0;
	endTags = new Stak();
	immediates = new Stak();
	notSpace = new PLGset("^ \t\r\f\n");
	scratch = ::bufferFactory2("scratch buffer");
	spaces = new PLGset(" \t");
	if ( !GroupControl::mustQuoteSet )
		GroupControl::mustQuoteSet = new PLGset(" +?*:!#/@|$%<>~.,;=()\"[\r\t\n'{}");
	GroupControl::groupController->groupRules->doNotExpandMacros = 1;
	trimLeadingSpace = 1;
	outputDelimit = delimiter = ',';
	outputEnd = endRecord = '\n';
	blockStack = new Stak();
	skip = "skip";
	mainParser = (void*)this;
	noLineByLine = 1;
	noComments = 1;
}

ParseXML::ParseXML(ParseXML *p)
{
	*this = *p;
	mainParser = (void*)this;
	rules = new BaseHash();
	reset();
}

/*******************************************************************************
	Modifies the item passed in to handle backslash escape sequences
*******************************************************************************/
void ParseXML::convertItem(PLGitem *item)
{
char 	*atText = convertSetInput(item);
int 	atLength = (int)::strlen(atText);
	if ( item->itemLength != atLength )
		{
		item->itemStart = atText;
		item->itemLength = atLength;
		}
}

/*******************************************************************************
	Handles input specifying backslash escape sequences
*******************************************************************************/
char *ParseXML::convertSetInput(PLGitem *item)
{
char 	*atText = item->itemStart;
int 	i = 0;
	scratch->reset();
	while ( i < item->itemLength )
		if ( *atText == '\\' )
			{
			if ( *(atText + 1) == 'f' )
				scratch->appendString("\f",0,0);
			else
			if ( *(atText + 1) == 'n' )
				scratch->appendString("\n",0,0);
			else
			if ( *(atText + 1) == 'r' )
				scratch->appendString("\r",0,0);
			else
			if ( *(atText + 1) == 't' )
				scratch->appendString("\t",0,0);
			else	goto exitConvert;
			i += 2;
			atText += 2;
			}
		else {
exitConvert:
			scratch->appendChar(*atText++,0,0);
			i++;
			}
	return scratch->toString();
}

/******************************************************************************
	Utility routine to convert spaces in a string to underlines
******************************************************************************/
char *ParseXML::despace(char *s)
{
char 	*atText = s;
	while ( *atText )
		{
		if ( !nameSet->contains(*atText) )
			{
			*atText = '_';
			}
		atText++;
		}
	return s;
}

/*****************************************************************************
	Create a new group filtered so that its members only contain the attributes
    that are in the filter. The sources that get filtered are expected to be
    listed as attributes of the group passed in (along with a filterBy attribute
    that contains the attributes to be filtered in).
*****************************************************************************/
void ParseXML::filterBy(GroupItem *group, GroupItem *filter)
{
GroupItem 	*item = 0;
GroupItem 	*itemPart = 0;
GroupItem 	*mask = 0;
GroupItem 	*partCopy = 0;
	if ( filter && filter->groupBody->data )
		if ( mask = GroupControl::groupController->locate(filter->getText()) )
			{
			while ( item = group->nextAttribute(item) )
				if ( item != filter )
					{
					item = 0;
					while ( itemPart = item->nextMember(item) )
						if ( partCopy = itemPart->filter(mask) )
							group->addGroup(partCopy);
					}
			}
		else	::fprintf(stderr,"filterBy: could not find filter %s\n",filter->toString());
	else	::fprintf(stderr,"filterBy: no filter value specified\n");
}

/*******************************************************************************
	Build and return the next field block (used when processing delimited fields).
*******************************************************************************/
GroupItem *ParseXML::getFieldBlock(PLGitem *item)
{
char 	*text = field->groupBody->gText ? field->getText() : field->groupBody->tag;
	if ( item )
		{
		if ( field->groupBody->registry )
			{
			if ( !(block = field->groupBody->registry->get(item)) )
				{
				block = GroupControl::groupController->itemFactory(item);
				field->groupBody->registry->addGroup(block);
				}
			}
		else	block = GroupControl::groupController->itemFactory(text);
		}
	else	block = 0;
	return block;
}

/***************************************************************************
	Returns true if path has a target set
***************************************************************************/
int ParseXML::hasTarget(GroupItem *path)
{
GroupItem 	*group = 0;
	if ( path )
		{
		if ( path->isTarget )
			return 1;
		if ( path->groupBody->hasMembers )
			while ( group = path->nextMember(group) )
				if ( hasTarget(group) )
					return 1;
		if ( path->groupBody->hasAttributes )
			{
			group = 0;
			while ( group = path->nextAttribute(group) )
				if ( hasTarget(group) )
					return 1;
			}
		}
	return 0;
}

/***************************************************************************
	Include and parse the file named in its argument
***************************************************************************/
void ParseXML::includeFile(char *filename)
{
char 	*input = 0;
	if ( !fileList )
		fileList = GroupControl::groupController->getRegistry("FileList");
	else
	if ( fileList->groupBody->getFromList(filename) )
		return;
	fileList->addString(filename);
	input = ::getStringFromFile(filename);
	::printf("Including file: %s\n",filename);
	if ( input )
		{
		divertInput(input);
		parse("StartXML");
		revertInput();
		}
}

/*****************************************************************************
        Indent text
*****************************************************************************/
void ParseXML::indentText(char *source, Buffer *buffer)
{
int 	i = StringRoutines::debugIndent;
char 	*text = 0;
char 	*atText = 0;
char 	*begin = 0;
	if ( !source )
		return;
	text = (char*)::alloca(StringRoutines::debugIndent + 1);
	atText = text;
	for ( i = StringRoutines::debugIndent + 1; i > 0; i-- )
		*atText++ = '\t';
	*atText = 0;
	begin = atText = source;
	while ( *atText )
		{
		if ( *atText == '\n' )
			{
			if ( atText == begin )
				{
				buffer->appendString("\n",0,0);
				buffer->appendString(text,0,0);
				atText++;
				goto newLine;
				}
			*atText = 0;
			buffer->appendString(begin,0,0);
			buffer->appendString("\n",0,0);
			buffer->appendString(text,0,0);
			*atText++ = '\n';
			}
		else {
			atText++;
			continue;
			}
newLine:
		while ( *atText && *atText == '\n' )
			{
			buffer->appendChar('\n',0,0);
			atText++;
			}
		begin = atText;
		}
	if ( begin != atText )
		buffer->appendString(begin,0,0);
}

void ParseXML::initializeKeyWords()
{
	Registering = new KeyTable("Registering");
	Registering->add("asAttributes");
	Registering->add("base");
	Registering->add("components");
	Registering->add("data");
	Registering->add("descending");
	Registering->add("display");
	Registering->add("grouped");
	Registering->add("layout");
	Registering->add("noPrint");
	Registering->add("rules");
	Registering->add("search");
	Registering->add("sort");
	Registering->add("track");
	Registering->add("value");
	Flag = new KeyTable("Flag");
	Flag->add("debug");
	Flag->add("easy");
	Flag->add("macro");
	Flag->add("pause");
	Flag->add("noJIT");
	Flag->add("noPrint");
	Flag->add("stop");
	CommandAction = new KeyTable("CommandAction");
	CommandAction->add("dump");
	CommandAction->add("list");
	CommandAction->add("print");
	CommandAction->add("save");
	CommandAction->add("test");
}

void ParseXML::initializeSetTable()
{
	setTable->add("alphaSet",(void*)alphaSet);
	setTable->add("anchorSet",(void*)anchorSet);
	setTable->add("bodySet",(void*)bodySet);
	setTable->add("commentSet",(void*)commentSet);
	setTable->add("dateSet",(void*)dateSet);
	setTable->add("delimitSet",(void*)delimitSet);
	setTable->add("fieldSet",(void*)fieldSet);
	setTable->add("nameSet",(void*)nameSet);
	setTable->add("notSpace",(void*)notSpace);
	setTable->add("simpleEnd",(void*)simpleEnd);
	setTable->add("singleQuote",(void*)singleQuote);
	setTable->add("spaces",(void*)spaces);
	setTable->add("tagSet",(void*)tagSet);
	setTable->add("textFollow",(void*)textFollow);
}

/*******************************************************************************
	Returns a PLGitem if text is a URL
*******************************************************************************/
PLGitem *ParseXML::isURL(char *text)
{
PLGitem 	*result = 0;
	divertInput(text);
	result = run("URLhead");
	revertInput();
	return result;
}

/***************************************************************************
    Debugging routine to list out registries
***************************************************************************/
void ParseXML::listRegistries()
{
GroupItem 	*registri = 0;
	::printf("Registry List\n");
	if ( GroupControl::registries && GroupControl::registries->groupBody->groupListLength )
		while ( registri = GroupControl::registries->next(registri) )
			::printf("\t%s\n",registri->groupBody->tag);
	else	::printf("\tcontains no entries\n");
}

/******************************************************************************
	Load a delimited file and convert into a group item. The specs item
	passed in defines the delimit parameters.
******************************************************************************/
GroupItem *ParseXML::loadDelimited(GroupItem *specs)
{
char 		*inputFile = 0;
char 		*diverted = 0;
GroupItem 	*field = 0;
GroupItem 	*intoRegistry = 0;
GroupItem 	*item = 0;
	list = 0;
	setName = specs->groupBody->tag;
	if ( !specs->groupBody->hasAttributes && specs->groupBody->data )
		inputFile = specs->getText();
	if ( !fieldRegistry )
		{
		fieldRegistry = GroupControl::groupController->getRegistry("LoadFields");
		fieldRegistry->groupBody->isSorted = 0;
		}
	/**************************************************************************
	Read the attributes of the delimited file specification and set
	associated flags and fields
	**************************************************************************/
	if ( item = specs->groupBody->getFromList("file") )
		inputFile = item->getText();
	if ( item = specs->groupBody->getFromList("heading") )
		hasHeading = 1;
	if ( item = specs->groupBody->getFromList("noSkip") )
		ignoreSkip = 1;
	if ( item = specs->groupBody->getFromList("delimiter") )
		delimiter = item->getCharacter();
	if ( item = specs->groupBody->getFromList("endRecord") )
		endRecord = item->getCharacter();
	if ( item = specs->groupBody->getFromList("skip") )
		skip = item->getText();
	if ( item = specs->groupBody->getFromList("into") )
		{
		list = GroupControl::groupController->locate(item);
		if ( !list )
			if ( intoRegistry = GroupControl::registries->groupBody->getFromList(item->getText()) )
				list = intoRegistry;
		}
	if ( delimiter && endRecord )
		{
		delimitSet->clear();
		delimitSet->set(delimiter);
		delimitSet->set(endRecord);
		}
	else
	if ( delimiter || endRecord )
		::fprintf(stderr,"loadDelimited: warning must set both delimiter and endRecord or neither; assuming defaults\n");
	else	::printf("loadDelimited: assuming default delimiter , and endRecord: carriage return\n");
	if ( inputFile )
		{
		::printf("Loading %s\n",inputFile);
		if ( isURL(inputFile) )
			{
			scratch->reset();
			if ( ::getURLintoBuffer(inputFile,scratch) )
				if ( scratch->length() )
					{
					diverted = scratch->toString();
					divertInput(diverted);
					}
			if ( !diverted )
				{
				::fprintf(stderr,"URL load failed\n");
				// at this point field is null
				return field;
				}
			}
		else	divertInput(::getStringFromFile(inputFile));
		doneWithHeading = hasHeading ? (unsigned int)0 : (unsigned int)1;
		/**********************************************************************
		Read the heading line of the delimited file, if there is one
		to fill the field registry.
		**********************************************************************/
		if ( hasHeading )
			run("Heading");
		/**********************************************************************
		Flag the fields of interest and make sure the registries associated
		w/fields are not closed.
		**********************************************************************/
		if ( item = specs->groupBody->getFromList("fields") )
			loadFieldSpecs(item);
		else
		while ( field = fieldRegistry->nextMember(field) )
			{
			// Assume we want all the fields since no field list provided
			field->groupBody->fLAG = 1;
			}
		if ( specs->groupBody->getFromList("debug") )
			{
			fieldRegistry->dumpDetail(0,1);
			specs->dumpDetail(0,1);
			::printf("List of delimited fields\n");
			item = 0;
			while ( item = fieldRegistry->nextMember(item) )
				if ( item->groupBody->fLAG )
					::printf("\t%s flagged\n",item->groupBody->tag);
				else	::printf("\t\t%s\n",item->groupBody->tag);
			listRegistries();
			}
		/**********************************************************************
		Clear list of fields from specs.
		**********************************************************************/
		if ( !list )
			{
			list = specs;
			if ( list->groupBody->groupListStart )
				list->clear();
			}
		field = 0;
		run("List");
		resetItemTape();
		}
	else	::fprintf(stderr,"No input file specified\n");
	/**************************************************************************
	Close the registries for registered fields
	**************************************************************************/
	item = 0;
	while ( item = fieldRegistry->nextMember(item) )
		if ( item->groupBody->fLAG && item->groupBody->registry && item->groupBody->registry->getAttribute("loadFromData") )
			item->groupBody->registry->groupBody->isClosed = 1;
	if ( inputFile )
		revertInput();
	setName = 0;
	block = field = 0;
	return list;
}

/*******************************************************************************
    Reads field specifications and adds them to the field registry. Used in
    loadDelimited() and loadJSON().
        A field name of skip means ignore the field. If skip has a number
        value, that many fields are skipped.
 
        If there is a heading line, members of spec are merged with existing
        fields in the field registry.
*******************************************************************************/
void ParseXML::loadFieldSpecs(GroupItem *fieldSpecs)
{
char 		*skipName = 0;
GroupItem 	*field = GroupControl::groupController->locate(fieldSpecs);
GroupItem 	*item = 0;
int 		i = 0;
int 		skipper = 0;
	if ( !field )
		{
		::fprintf(stderr,"loadFieldSpecs: could not find%s\n",fieldSpecs->toString());
		return;
		}
	else	fieldSpecs = field;
	record = GroupControl::groupController->itemFactory();
	while ( item = fieldSpecs->nextMember(item) )
		{
		skipName = item->groupBody->data ? item->getText() : item->groupBody->tag;
		if ( field = fieldRegistry->groupBody->getFromList(item->groupBody->tag) )
			{
			GroupItem 	*registered = GroupControl::registries->groupBody->getFromList(skipName);
			field->groupBody->fLAG = 1;
			field->groupBody->registry = registered;
			field->setText(item->getText());
			}
		else
		if (::compare(item->groupBody->tag,skip) == 0)
			if ( !item->groupBody->data )
				{
				skipName = ::concat(2,skip,::toStringFromInt(skipper++));
				fieldRegistry->addGroup(GroupControl::groupController->itemFactory(skipName));
				}
			else
			for ( i = item->getCount(); i > 0; i-- )
				{
				skipName = ::concat(2,skip,::toStringFromInt(skipper++));
				fieldRegistry->addGroup(GroupControl::groupController->itemFactory(skipName));
				}
		else {
			fieldRegistry->addGroup(item);
			item->groupBody->fLAG = 1;
			field = item;
			}
		if ( field->groupBody->registry )
			field->groupBody->registry->groupBody->isClosed = 0;
		/**********************************************************************
		Check field attributes.
		**********************************************************************/
		if ( field && field->groupBody->hasAttributes )
			{
			/******************************************************************
			Date attributes are excised for now
			if field["mdy"]
			{
			//  field count set to 1 if date in MDY format
			field.count = 1;
			field.isDate = true;
			}
			or field["ymd"]
			field.isDate = true;
			if field.isDate && !monthRegistry
			{
			monthRegistry   = registries["month"];
			yearRegistry    = registries["year"];
			if !monthRegistry || !yearRegistry
			cerr "ERROR: month or year registry does not exist":;
			}
			******************************************************************/
			// If there is a tag attribute, use the field as the record tag
			if ( field->groupBody->getFromList("key") )
				{
				field->isTarget = 1;
				record->isTarget = 1;
				}
			if ( field->groupBody->getFromList("noMerge") )
				field->groupBody->noMerge = 1;
			}
		}
}

/******************************************************************************
    Load a json file and convert into a group item. The specs passed in defines
    the load parameters.
******************************************************************************/
GroupItem *ParseXML::loadJSON(GroupItem *specs)
{
GroupItem 	*registered = 0;
GroupItem 	*item = 0;
char 		*diverted = 0;
char 		*inputFile = 0;
char 		*outputName = 0;
	/**************************************************************************
	Read the parameters of the specification
	**************************************************************************/
	list = 0;
	if ( !fieldRegistry )
		fieldRegistry = GroupControl::groupController->getRegistry("LoadFields");
	if ( item = specs->groupBody->getFromList("file") )
		inputFile = item->getText();
	if ( item = specs->groupBody->getFromList("into") )
		{
		list = GroupControl::groupController->locate(item);
		outputName = item->getText();
		if ( !list && outputName )
			if ( registered = GroupControl::registries->groupBody->getFromList(outputName) )
				list = registered;
		if ( !list && !registered )
			::fprintf(stderr,"loadJSON: could not find %s\n",item->toString());
		}
	else	list = specs;
	if ( inputFile )
		{
		::printf("Loading JSON data from %s\n",inputFile);
		if ( isURL(inputFile) )
			{
			scratch->reset();
			if ( ::getURLintoBuffer(inputFile,scratch) )
				if ( scratch->length() )
					{
					diverted = scratch->toString();
					//cout diverted:;
					divertInput(diverted);
					}
			if ( !diverted )
				{
				::fprintf(stderr,"URL load failed\n");
				return 0;
				}
			}
		else	divertInput(::getStringFromFile(inputFile));
		if ( item = specs->groupBody->getFromList("fields") )
			loadFieldSpecs(item);
		//debug = true;
		run("JSONlist");
		//debug = false;
		revertInput();
		if ( !list )
			list = GroupControl::groupController->currentRegistry;
		}
	else {
		::fprintf(stderr,"loadJSON: No input file specified\n");
		list = 0;
		}
	return list;
}

/******************************************************************************
	Invoke gml rule parser applying the rule on the file given as attributes
    in the specs passed in. If you supply a file name in the specs, the file
    is used as input to the rule test, otherwise the current parser input is
    used. If no rule attribute is specified, the specs file is assumed to be
    a rule and is used for the test. The skip attribute is optional and only
    needed if the default skip set (which contains spaces, tabs, new lines,
    form feeds, and returns) does not suffice.
******************************************************************************/
GroupItem *ParseXML::loadRule(GroupItem *specs)
{
GroupItem 	*rule = specs->getAttribute("rule");
GroupItem 	*file = specs->getAttribute("file");
GroupItem 	*skip = specs->getAttribute("skip");
GroupItem 	*methodName = specs->getAttribute("methodName");
GroupItem 	*item = 0;
char 		*name = 0;
	/*********************************************************************
	item is set as the label of the rule to be parsed.
	*********************************************************************/
	if ( methodName )
		name = methodName->getText();
	else	name = specs->groupBody->tag;
	item = GroupControl::groupController->locate(name);
	if ( !item )
		{
		item = GroupControl::groupController->itemFactory(name);
		if ( GroupControl::groupController->currentRegistry )
			GroupControl::groupController->currentRegistry->addGroup(item);
		}
	/*********************************************************************
	Does this have to happen every fortnight? Looks like setup.
	*********************************************************************/
	if ( !GroupControl::groupController->groupRules->wordEnd )
		GroupControl::groupController->groupRules->wordEnd = GroupControl::groupController->locate("wordEnd");
	if ( skip && isSetGRP(skip->groupBody->data) )
		if ( GroupControl::groupController->groupRules->ruleSkipSet )
			GroupControl::groupController->groupRules->ruleSkipSet->setCharacterSet(skip->groupBody->gCharacterSet);
		else	GroupControl::groupController->groupRules->ruleSkipSet = skip;
	else
	if ( !GroupControl::groupController->groupRules->ruleSkipSet )
		{
		GroupControl::groupController->groupRules->ruleSkipSet = GroupControl::groupController->itemFactory("skip");
		GroupControl::groupController->groupRules->ruleSkipSet->setCharacterSet(defaultSkip);
		// defaultSkip is defined in PLGparse
		}
	/*********************************************************************
	Determine what input will be parsed.
	*********************************************************************/
	GroupControl::groupController->groupRules->atRuleMark = 0;
	if ( file )
		{
		char 	*inputFile = file->getText();
		if ( inputFile )
			GroupControl::groupController->groupRules->atRuleMark = ::getStringFromFile(inputFile);
		else	::fprintf(stderr,"loadRule: no file name given in attribute of %s\n",specs->getTagXML());
		}
	else
	if ( !(GroupControl::groupController->groupRules->atRuleMark = specs->getText()) )
		GroupControl::groupController->groupRules->atRuleMark = plgStart;
	GroupControl::groupController->groupRules->ruleInputStart = GroupControl::groupController->groupRules->atRuleMark;
	if ( !GroupControl::groupController->groupRules->atRuleMark )
		::fprintf(stderr,"loadRule: rule input not set %s\n",specs->getTagXML());
	/*********************************************************************
	Determine parse rule. Start is default rule if no rule specified.
	*********************************************************************/
	if ( rule )
		{
		char 	*ruleName = rule->getText();
		if ( ruleName )
			rule = GroupControl::groupController->locate(ruleName);
		else	rule = 0;
		}
	if ( !rule )
		rule = GroupControl::groupController->locate("Start");
	if ( !rule )
		::fprintf(stderr,"loadRule: could not find rule %s\n",specs->getTagXML());
	/*********************************************************************
	Fire in the hole. Run parser. Return result.
	*********************************************************************/
	if ( item && GroupControl::groupController->groupRules->atRuleMark && rule )
		if ( rule->groupBody->isRule )
			{
			GroupControl::groupController->groupRules->ruleInput = specs;
			if ( rule->runParseRule(item) )
				return item;
			}
		else	::fprintf(stderr,"loadRule: %s is not a rule\n",rule->groupBody->tag);
	return 0;
}

GroupItem *ParseXML::locate(PLGitem *item)
{
char 		*name = item->string();
GroupItem 	*group = GroupControl::groupController->locate(name);
	item->unString();
	return group;
}

/*****************************************************************************
	Parse the file (presumably contains an xml string) into a list of blocks
*****************************************************************************/
GroupItem *ParseXML::parseFile(char *filename)
{
char 	*text = ::getStringFromFile(filename);
	if ( text )
		return parseString(text,"StartXML");
	return 0;
}

/***************************************************************************
	Parses a macro. Diverts input to do it.
***************************************************************************/
void ParseXML::parseMacro(GroupItem *macro, char *text)
{
	block = macro;
	divertInput(text,getRule("Macro"));
	block = 0;
}

/*****************************************************************************
	Parse the xml string into a linked list of blocks
*****************************************************************************/
GroupItem *ParseXML::parseString(char *path, char *tag)
{
	if ( !path || !tag )
		return (GroupItem*)0;
	reset();
	setInput(path);
	run(tag);
	return outerBlock;
}

/*****************************************************************************
	pop the saved state of the parser off the state stack. If there is no
    saved state, nothing happens;
*****************************************************************************/
void ParseXML::popState()
{
	if ( !blockStack->length )
		::fprintf(stderr,"ERROR popState: nothing on block stack\n");
	else {
		outerBlock = (GroupItem*)blockStack->pop();
		currentBlock = (GroupItem*)blockStack->pop();
		ancestor = (GroupItem*)blockStack->pop();
		}
}

/*****************************************************************************
	Debugging routine to print to standard output the attributes from this
    item listed in the Stak passed in. If the parameter is null, all attributes
    are printed
*****************************************************************************/
void ParseXML::printAttributes(GroupItem *group, Stak *list)
{
char 		*name = 0;
GroupItem 	*item = 0;
	if ( group )
		{
		::printf("%s",item->groupBody->tag);
		if ( !list )
			while ( item = group->nextAttribute(item) )
				{
				if ( item->groupBody->data )
					::printf("\t%s=%s",item->groupBody->tag,item->getText());
				else
				if ( ::compare(name,item->groupBody->registry->groupBody->tag) == 0 )
					::printf("\t%s=%s",name,item->getText());
				else	::printf("\t%s",item->groupBody->tag);
				}
		else
		while ( name = (char*)list->next() )
			if ( item = group->getAttribute(name) )
				if ( item->groupBody->data )
					::printf("\t%s=%s",item->groupBody->tag,item->getText());
				else
				if ( ::compare(name,item->groupBody->registry->groupBody->tag) == 0 )
					::printf("\t%s=%s",name,item->getText());
				else	::printf("\t%s",item->groupBody->tag);
		::printf("\n");
		item = 0;
		while ( item = group->nextMember(item) )
			printAttributes(item,list);
		}
}

/***************************************************************************
	Process a parsed delimited field. This adds the item passed in to the
    current record. When end of record encountered, writes record to the
    list and starts a new record. record, field, block and list are GroupItems
    declared by this here parser.
***************************************************************************/
void ParseXML::processDelimitField(PLGitem *item)
{
PLGitem 	*delimit = 0;
	delimit = item->get("delimit");
	if ( field->groupBody->fLAG )
		{
		//cout "Processing field: " field.tag,item,recordNumber:;
		item->runDeferred();
		//cout `"processDelimitField:",block:;
		}
	if ( block )
		if ( field->isTarget )
			{
			block->groupBody->noMerge = field->groupBody->noMerge;
			record->setGroup(block);
			}
		else {
			if ( block->groupBody->registry = field->groupBody->registry )
				{
				block->setText(block->groupBody->tag);
				block->groupBody->tag = field->groupBody->tag;
				}
			block->affiliation = 1;
			block = record->addGroup(block);
			}
	if ( *delimit->itemStart == endRecord )
		{
		if ( record->isTarget )
			{
			block = record->getGroup();
			if ( block->groupBody->noMerge )
				block->copyList(record);
			else	block->merge(record);
			record->clear();
			if ( list->groupBody->isRegistryGRP )
				list->groupBody->registry->addGroup(block);
			else	list->addGroup(block);
			}
		else {
			record->groupBody->tag = ::concat(2,list->groupBody->tag,::toStringFromInt(recordNumber++));
			if ( list->groupBody->isRegistryGRP )
				list->groupBody->registry->addGroup(record);
			else	list->addGroup(record);
			record = GroupControl::groupController->itemFactory();
			}
		}
	block = 0;
}

/*****************************************************************************
    Process a path specification
*****************************************************************************/
void ParseXML::processPath(GroupItem *item)
{
GroupItem 	*group = 0;
GroupItem 	*part = 0;
GroupItem 	*path = 0;
	if ( item->getAttribute("LiSt") )
		::fprintf(stderr,"processPath: already processed %s\n",item->getTagXML());
	else
	if ( item->groupBody->hasMembers )
		{
		GroupItem 	*list = GroupControl::groupController->itemFactory("targets");
		/*********************************************************************
		We copy item members to list and remove them from item here so it
		does not mess up adding to item or looping thru list with nextMember.
		So list contains the members, which are the paths to be processed,
		and item only contains attributes, which are the sources.
		*********************************************************************/
		while ( group = item->nextMember(group) )
			{
			list->addGroup(group);
			item->removeFromItsList(group);
			}
		item->groupBody->hasMembers = 0;
		while ( part = list->nextMember(part) )
			if ( part->isPath )
				{
				// isPath IS NEVER SET
				if ( group = GroupControl::groupController->locate(part->groupBody->tag) )
					while ( path = group->nextMember(path) )
						{
						if ( !hasTarget(path) )
							path->isTarget = 1;
						processSourceByPath(path,item);
						}
				}
			else {
				path = part;
				if ( !hasTarget(path) )
					path->isTarget = 1;
				processSourceByPath(path,item);
				}
		item->isTarget = 0;
		list->clear();
		}
	else	::fprintf(stderr,"processPath: no paths specified as members of %s\n",item->toString());
}

/*****************************************************************************
    Process a path against one or more sources
*****************************************************************************/
void ParseXML::processSourceByPath(GroupItem *path, GroupItem *item)
{
GroupItem 		*group = 0;
GroupItem 		*source = 0;
PathIterator 	*iterator = 0;
	/*************************************************************************
	The attributes of item contain the sources to be matched against.
	If an attribute has no members, it is ignored, assumed to be a
	regular attribute. If debug specified it will apply to all sources
	specified after the debug attribute.
	*************************************************************************/
	if ( item->groupBody->hasAttributes )
		{
		GroupItem 	*debugFlag = item->groupBody->getFromList("debug");
		while ( source = item->nextAttribute(source) )
			{
			if ( !source->groupBody->hasMembers )
				continue;
			if ( !iterator )
				iterator = new PathIterator(path,source);
			else {
				iterator->setInitialPath(path);
				iterator->setInitialBlock(source);
				}
			if ( debugFlag )
				iterator->debugPath = 2;
			while ( group = iterator->next() )
				item->addGroup(group);
			}
		}
	else	::fprintf(stderr,"processSourceByPath: no source provided\n");
}

/*****************************************************************************
	Create a block from the parsed components
*****************************************************************************/
GroupItem *ParseXML::processTag(PLGitem *attributes)
{
GroupItem 	*block = 0;
GroupItem 	*trait = 0;
GroupItem 	*attribute = 0;
PLGitem 	*item = 0;
	attributes->runDeferred();
	block = currentBlock;
	while ( ancestor && ancestor->groupBody->isSingleton )
		ancestor = ancestor->parent;
	for ( item = attributes->next; item; item = item->next )
		{
		currentBlock = 0;
		item->runDeferred();
		if ( trait = currentBlock )
			{
			int 	saveAffiliation = 0;
			if ( immediateActionGRP(trait->groupBody->methodType) && !trait->groupBody->isRule && trait->groupBody->noPrint )
				{
				// noPrint immediate actions get fired but not added as attributes
				immediates->push(trait);
				continue;
				}
			/*****************************************************************
			Since we are adding an attribute, it should not be a member.
			*****************************************************************/
			if ( !isAttributeGRP(trait->affiliation) )
				{
				saveAffiliation = trait->affiliation;
				trait->affiliation = 1;
				}
			attribute = block->addGroup(trait);
			if ( saveAffiliation )
				trait->affiliation = saveAffiliation;
			if ( attribute->groupBody->isMacro )
				block->groupBody->hasMacro = 1;
			}
		}
	if ( commanding )
		commanding = 0;
	return block;
}

/*****************************************************************************
	push the current state of the parser onto the state stack
*****************************************************************************/
void ParseXML::pushState()
{
	blockStack->push((void*)ancestor);
	blockStack->push((void*)currentBlock);
	blockStack->push((void*)outerBlock);
}

/*****************************************************************************
	reset the parser to its original state (clear outerblock)
*****************************************************************************/
void ParseXML::reset()
{
	ancestor = currentBlock = outerBlock = 0;
	targetSet = 0;
}

/*****************************************************************************
	reset the itemTape to free all releasable PLGitems for reuse
*****************************************************************************/
void ParseXML::resetItemTape()
{
Tape 		*tape = PLGitem::itemTape;
PLGitem 	*item = 0;
int 		count = 0;
int 		freed = 0;
int 		inUse = 0;
int 		gone = 0;
void 		**spot = 0;
	tape->list->resetIterator();
	while ( spot = tape->atIndex(count++) )
		{
		item = (PLGitem*)spot;
		if ( item->released )
			gone++;
		else
		if ( item->noRelease )
			inUse++;
		else {
			item->free();
			freed++;
			}
		spot += tape->stripSize;
		}
	::printf("resetItemTape: count %d freed %d released %d in use %d\n",count,freed,gone,inUse);
	//tape.status();
}

PLGitem *ParseXML::run(char *name)
{
	initializeKeyWords();
	if ( !rules->hashList->length )
		{
		setRules();
		initialize();
		}
	return parse(name);
}

PLGitem *ParseXML::run(char *rule, char *text)
{
PLGitem 	*item = 0;
	divertInput(text);
	item = run(rule);
	revertInput();
	return item;
}

/*****************************************************************************
	Adds current block to ancestor and sets ancestor and outerBlock
*****************************************************************************/
void ParseXML::setAncestry()
{
	if ( !outerBlock )
		outerBlock = ancestor ? ancestor : currentBlock;
	if ( ancestor && ancestor != currentBlock )
		ancestor = ancestor->addGroup(currentBlock);
	else	ancestor = currentBlock;
}

void ParseXML::setRules()
{
	setSkip();
	alphaSet = getSet("alphaSet","A-Za-z_");
	anchorSet = getSet("anchorSet","/%");
	bodySet = getSet("bodySet","^<>'\"");
	commentSet = getSet("commentSet","!?-");
	dateSet = getSet("dateSet","0-9/:APM ");
	delimitSet = getSet("delimitSet",",\n");
	fieldSet = getSet("fieldSet","^ `,:+?*:!#/@|$%&<>~.;=()[\r\t\n'{}\"");
	nameSet = getSet("nameSet","A-Za-z0-9_");
	notSpace = getSet("notSpace","^ \t\n\r\f");
	simpleEnd = getSet("simpleEnd","!@#$%&*()_");
	singleQuote = getSet("singleQuote","'");
	spaces = getSet("spaces"," \t\n\r\f");
	tagSet = getSet("tagSet"," =~");
	textFollow = getSet("textFollow","A-Za-z0-9_");
	//
	currentRule = getRule("Attribute");
	currentRule->defer = ::AttributeParseXMLAct;
	currentSet = getSet("@%");
	addTest(6,(void*)currentSet,"target",0,268435455,"defaultSKIP");
	addTest(5,(void*)getRule("Field"),"name",1,1,(char*)0);
	addTest(5,(void*)getRule("Value"),"value",0,1,"defaultSKIP");
	addTest(5,(void*)getRule("Modifier"),"modify",0,1,"defaultSKIP");
	//
	currentRule = getRule("CommandText");
	currentRule->defer = ::CommandTextParseXMLAct;
	addTest(7,(void*)"include",(char*)0,1,1,"defaultSKIP");
	currentSet = textFollow;
	addTest(6,(void*)currentSet,(char*)0,-1,1,"defaultSKIP");
	addTest(7,(void*)";","file",0,1,(char*)0);
	currentTest->processUpTo = 1;
	currentRule->next = getRule("CommandText2");
	//
	currentRule = getRule("EndTag");
	currentRule->immediate = ::EndTagParseXMLNow;
	currentRule->defer = ::EndTagParseXMLAct;
	addTest(7,(void*)"<",(char*)0,1,1,"defaultSKIP");
	addTest(5,(void*)getRule("Closing"),"action",1,1,"defaultSKIP");
	addTest(5,(void*)getRule("Field"),"field",0,1,"defaultSKIP");
	addTest(7,(void*)">",(char*)0,1,1,"defaultSKIP");
	currentRule->next = getRule("EndTag2");
	//
	currentRule = getRule("Epilog");
	currentRule->doNotGuard = 1;
	addTest(3,(void*)0,"epilog",0,1,(char*)0);
	currentTest->skipOverMatch = 1;
	currentTest->processUpTo = 1;
	//
	currentRule = getRule("JSONrepeatEntry");
	currentRule->defer = ::JSONrepeatEntryParseXMLAct;
	addTest(5,(void*)getRule("JSONdata"),"data",1,1,"defaultSKIP");
	addTest(7,(void*)",",(char*)0,0,1,"defaultSKIP");
	//
	currentRule = getRule("Field");
	addTest(5,(void*)getRule("FieldName"),"field",1,1,"defaultSKIP");
	//
	currentRule = getRule("Comment4");
	addTest(5,(void*)getRule("Comment4BalancE"),"comment",1,1,(char*)0);
	//
	currentRule = getRule("JSONpair");
	currentRule->defer = ::JSONpairParseXMLAct;
	addTest(5,(void*)getRule("JSONtext"),"name",1,1,"defaultSKIP");
	addTest(7,(void*)":",(char*)0,1,1,"defaultSKIP");
	addTest(5,(void*)getRule("JSONdata"),"data",1,1,"defaultSKIP");
	addTest(7,(void*)",",(char*)0,0,1,"defaultSKIP");
	//
	currentRule = getRule("Integer");
	addTest(5,(void*)getRule("IntegerBlock10"),"count",1,1,"defaultSKIP");
	//
	currentRule = getRule("LocateRegistry");
	//
	currentRule = getRule("Registry");
	currentRule->immediate = ::RegistryParseXMLNow;
	addTest(5,(void*)getRule("Text"),"type",1,1,"defaultSKIP");
	//
	currentRule = getRule("Locate");
	currentRule->immediate = ::LocateParseXMLNow;
	addTest(5,(void*)getRule("Registry"),"type",0,1,"defaultSKIP");
	addTest(5,(void*)getRule("Text"),"field",1,1,"defaultSKIP");
	//
	currentRule = getRule("Max");
	addTest(7,(void*)",",(char*)0,1,1,"defaultSKIP");
	addTest(5,(void*)getRule("Integer"),"maximum",1,1,"defaultSKIP");
	//
	currentRule = getRule("Modifier");
	currentRule->immediate = ::ModifierParseXMLNow;
	currentRule->defer = ::ModifierParseXMLAct;
	addTest(5,(void*)getRule("Limit"),"limit",0,1,"defaultSKIP");
	currentSet = getSet("+?!*{}%&<");
	addTest(6,(void*)currentSet,"modifier",0,268435455,"defaultSKIP");
	addTest(7,(void*)"|","alternate",0,1,"defaultSKIP");
	//
	currentRule = getRule("Number");
	currentRule->immediate = ::NumberParseXMLNow;
	addTest(5,(void*)getRule("NumberBlock1"),"number",1,1,(char*)0);
	addTest(5,(void*)getRule("NumberBlock2"),"part",0,1,(char*)0);
	currentSet = alphaSet;
	addTest(6,(void*)currentSet,(char*)0,-1,1,(char*)0);
	//
	currentRule = getRule("Lines");
	addTest(5,(void*)getRule("Line"),"lines",1,268435455,(char*)0);
	//
	currentRule = getRule("DelimitNumber");
	currentRule->defer = ::DelimitNumberParseXMLAct;
	currentSet = getSet("'\"");
	addTest(6,(void*)currentSet,(char*)0,0,1,(char*)0);
	addTest(5,(void*)getRule("Number"),"number",1,1,(char*)0);
	currentSet = getSet("'\"");
	addTest(6,(void*)currentSet,(char*)0,0,1,(char*)0);
	currentSet = delimitSet;
	addTest(6,(void*)currentSet,"delimit",1,1,(char*)0);
	//
	currentRule = getRule("StopHere");
	currentRule->immediate = ::StopHereParseXMLNow;
	//
	currentRule = getRule("Parameter");
	//
	currentRule = getRule("Part");
	currentRule->immediate = ::PartParseXMLNow;
	addTest(5,(void*)getRule("BodyParts"),"prefix",0,268435455,"defaultSKIP");
	addTest(5,(void*)getRule("Tag"),"body",0,1,(char*)0);
	currentTest->skipOverMatch = 1;
	currentTest->processUpTo = 1;
	//
	currentRule = getRule("Reference");
	//
	currentRule = getRule("NumberBlock2");
	currentSet = getSet(".0-9");
	addTest(6,(void*)currentSet,(char*)0,1,268435455,(char*)0);
	//
	currentRule = getRule("Quoted2");
	currentRule->immediate = ::Quoted2ParseXMLNow;
	currentSet = getSet("'");
	addTest(6,(void*)currentSet,(char*)0,1,1,(char*)0);
	addTest(5,(void*)getRule("Quoted2Block4"),"text",1,1,(char*)0);
	currentSet = getSet("'");
	addTest(6,(void*)currentSet,(char*)0,1,1,(char*)0);
	//
	currentRule = getRule("SetTagFlag");
	currentRule->immediate = ::SetTagFlagParseXMLNow;
	//
	currentRule = getRule("Tag");
	addTest(5,(void*)getRule("Command"),(char*)0,1,1,"defaultSKIP");
	currentRule->next = getRule("Tag2");
	//
	currentRule = getRule("CommandText4");
	currentRule->defer = ::CommandText4ParseXMLAct;
	addTest(4,(void*)Flag,"flag",1,1,"defaultSKIP");
	currentSet = textFollow;
	addTest(6,(void*)currentSet,(char*)0,-1,1,(char*)0);
	currentRule->next = getRule("CommandText5");
	//
	currentRule = getRule("Text");
	addTest(5,(void*)getRule("Quoted"),"text",1,1,(char*)0);
	currentRule->next = getRule("Text2");
	//
	currentRule = getRule("TextBody");
	currentRule->defer = ::TextBodyParseXMLAct;
	addTest(5,(void*)getRule("SetSimpleEnd"),(char*)0,1,1,"defaultSKIP");
	addTest(7,(void*)&endString,"body",0,1,(char*)0);
	currentTest->aVariable = 1;
	currentTest->skipOverMatch = 1;
	currentTest->processUpTo = 1;
	addTest(7,(void*)";",(char*)0,1,1,"defaultSKIP");
	//
	currentRule = getRule("Comment3BoDY");
	currentRule->immediate = ::balancEbody;
	addTest(7,(void*)"<?","begin",0,1,(char*)0);
	addTest(7,(void*)"?>","end",0,1,(char*)0);
	currentRule->next = getRule("Comment3Any");
	//
	currentRule = getRule("Value");
	addTest(7,(void*)"=~","regex",1,1,"defaultSKIP");
	addTest(5,(void*)getRule("RegexText"),"text",1,1,"defaultSKIP");
	currentRule->next = getRule("Value2");
	//
	currentRule = getRule("AttributeList");
	currentRule->immediate = ::AttributeListParseXMLNow;
	addTest(7,(void*)"[",(char*)0,1,1,"defaultSKIP");
	addTest(5,(void*)getRule("Text"),"name",1,268435455,"defaultSKIP");
	//
	currentRule = getRule("Command");
	currentRule->immediate = ::CommandParseXMLNow;
	addTest(7,(void*)"#",(char*)0,1,1,"defaultSKIP");
	addTest(5,(void*)getRule("CommandText"),"command",0,1,"defaultSKIP");
	addTest(7,(void*)";",(char*)0,1,1,"defaultSKIP");
	//
	currentRule = getRule("CommandText3");
	currentRule->defer = ::CommandText3ParseXMLAct;
	addTest(4,(void*)CommandAction,"action",1,1,"defaultSKIP");
	currentSet = textFollow;
	addTest(6,(void*)currentSet,(char*)0,-1,1,(char*)0);
	addTest(5,(void*)getRule("Registry"),"type",0,1,"defaultSKIP");
	addTest(5,(void*)getRule("Locate"),"path",0,1,"defaultSKIP");
	addTest(5,(void*)getRule("AttributeList"),"list",0,1,"defaultSKIP");
	addTest(5,(void*)getRule("Number"),"number",0,1,"defaultSKIP");
	currentRule->next = getRule("CommandText4");
	//
	currentRule = getRule("CommandText2");
	currentRule->defer = ::CommandText2ParseXMLAct;
	addTest(7,(void*)"registry",(char*)0,1,1,"defaultSKIP");
	currentSet = textFollow;
	addTest(6,(void*)currentSet,(char*)0,-1,1,(char*)0);
	addTest(5,(void*)getRule("Text"),"type",1,1,"defaultSKIP");
	addTest(4,(void*)Registering,"flag",0,268435455,"defaultSKIP");
	currentRule->next = getRule("CommandText3");
	//
	currentRule = getRule("CommandText5");
	currentRule->defer = ::CommandText5ParseXMLAct;
	addTest(7,(void*)"search",(char*)0,1,1,"defaultSKIP");
	currentSet = textFollow;
	addTest(6,(void*)currentSet,(char*)0,-1,1,(char*)0);
	addTest(7,(void*)"+","plus",0,1,"defaultSKIP");
	addTest(5,(void*)getRule("Text"),"names",0,268435455,"defaultSKIP");
	currentRule->next = getRule("CommandText6");
	//
	currentRule = getRule("CommandText6");
	currentRule->defer = ::CommandText6ParseXMLAct;
	addTest(7,(void*)"load",(char*)0,1,1,"defaultSKIP");
	currentSet = textFollow;
	addTest(6,(void*)currentSet,(char*)0,-1,1,(char*)0);
	addTest(5,(void*)getRule("Locate"),"path",1,1,"defaultSKIP");
	currentRule->next = getRule("CommandText7");
	//
	currentRule = getRule("CommandText7");
	currentRule->defer = ::CommandText7ParseXMLAct;
	addTest(5,(void*)getRule("Locate"),"group",1,1,"defaultSKIP");
	addTest(5,(void*)getRule("CommandArgument"),"argument",0,1,"defaultSKIP");
	//
	currentRule = getRule("BodyParts");
	currentRule->immediate = ::BodyPartsParseXMLNow;
	addTest(5,(void*)getRule("BodyPartsBalancE"),"part",1,1,"defaultSKIP");
	currentRule->next = getRule("BodyParts2");
	//
	currentRule = getRule("Closing");
	currentRule->defer = ::ClosingParseXMLAct;
	addTest(7,(void*)"/","closing",1,268435455,"defaultSKIP");
	currentRule->next = getRule("Closing2");
	//
	currentRule = getRule("CommentBoDY");
	currentRule->immediate = ::balancEbody;
	addTest(7,(void*)"/*","begin",0,1,(char*)0);
	addTest(7,(void*)"*/","end",0,1,(char*)0);
	currentRule->next = getRule("CommentAny");
	//
	currentRule = getRule("Closing2");
	currentRule->defer = ::Closing2ParseXMLAct;
	addTest(7,(void*)";","closing",1,1,"defaultSKIP");
	//
	currentRule = getRule("Debugging");
	currentRule->immediate = ::DebuggingParseXMLNow;
	//
	currentRule = getRule("EndBrace");
	currentRule->immediate = ::EndBraceParseXMLNow;
	addTest(7,(void*)"]","endBrace",1,1,(char*)0);
	//
	currentRule = getRule("DelimitEmpty");
	currentRule->immediate = ::DelimitEmptyParseXMLNow;
	currentRule->doNotGuard = 1;
	currentSet = getSet("'\"");
	addTest(6,(void*)currentSet,(char*)0,0,268435455,(char*)0);
	currentSet = delimitSet;
	addTest(6,(void*)currentSet,"delimit",1,1,(char*)0);
	//
	currentRule = getRule("EndTag2");
	currentRule->immediate = ::EndTag2ParseXMLNow;
	currentRule->defer = ::EndTag2ParseXMLAct;
	addTest(8,(void*)&simpleSyntax,(char*)0,1,1,"defaultSKIP");
	currentTest->type = 8;
	addTest(5,(void*)getRule("Closing"),"action",1,1,"defaultSKIP");
	//
	currentRule = getRule("QuotedBlock3");
	currentSet = getSet("^\"");
	addTest(6,(void*)currentSet,(char*)0,1,268435455,(char*)0);
	//
	currentRule = getRule("FieldName3");
	currentRule->immediate = ::FieldName3ParseXMLNow;
	addTest(7,(void*)"\"",(char*)0,1,1,"defaultSKIP");
	addTest(5,(void*)getRule("FieldName3Block7"),"field",1,1,"defaultSKIP");
	addTest(7,(void*)"\"",(char*)0,1,1,"defaultSKIP");
	currentRule->next = getRule("FieldName4");
	//
	currentRule = getRule("FieldName4");
	currentRule->immediate = ::FieldName4ParseXMLNow;
	currentSet = getSet("'");
	addTest(6,(void*)currentSet,(char*)0,1,1,"defaultSKIP");
	addTest(5,(void*)getRule("FieldName4Block8"),"field",1,1,"defaultSKIP");
	currentSet = getSet("'");
	addTest(6,(void*)currentSet,(char*)0,1,1,"defaultSKIP");
	currentRule->next = getRule("FieldName5");
	//
	currentRule = getRule("FieldName3Block7");
	currentSet = getSet("^\"");
	addTest(6,(void*)currentSet,(char*)0,1,268435455,(char*)0);
	//
	currentRule = getRule("DelimitDate");
	currentSet = getSet("'\"");
	addTest(6,(void*)currentSet,(char*)0,0,1,(char*)0);
	addTest(5,(void*)getRule("DelimitDateBlock0"),"date",1,1,(char*)0);
	currentSet = getSet("'\"");
	addTest(6,(void*)currentSet,(char*)0,0,1,(char*)0);
	currentSet = delimitSet;
	addTest(6,(void*)currentSet,"delimit",1,1,(char*)0);
	//
	currentRule = getRule("MacroPart");
	currentRule->immediate = ::MacroPartParseXMLNow;
	addTest(7,(void*)"$",(char*)0,1,1,(char*)0);
	addTest(5,(void*)getRule("Text"),"text",1,1,(char*)0);
	currentRule->next = getRule("MacroPart2");
	//
	currentRule = getRule("Macro");
	currentRule->immediate = ::MacroParseXMLNow;
	addTest(5,(void*)getRule("MacroPart"),"macro",1,268435455,(char*)0);
	//
	currentRule = getRule("Limit");
	addTest(7,(void*)"{",(char*)0,1,1,"defaultSKIP");
	addTest(5,(void*)getRule("Number"),"minimum",1,1,"defaultSKIP");
	addTest(7,(void*)",",(char*)0,0,1,"defaultSKIP");
	addTest(5,(void*)getRule("Number"),"maximum",0,1,"defaultSKIP");
	addTest(7,(void*)"}",(char*)0,1,1,"defaultSKIP");
	//
	currentRule = getRule("Path");
	currentRule->immediate = ::PathParseXMLNow;
	addTest(5,(void*)getRule("Up"),"up",0,1,(char*)0);
	addTest(5,(void*)getRule("PathItem"),"path",0,268435455,(char*)0);
	//
	currentRule = getRule("ValueText2");
	addTest(5,(void*)getRule("Text"),"text",1,1,"defaultSKIP");
	//
	currentRule = getRule("PathItem");
	currentRule->defer = ::PathItemParseXMLAct;
	addTest(5,(void*)getRule("Text"),"text",1,1,(char*)0);
	addTest(7,(void*)"/","slash",0,1,(char*)0);
	//
	currentRule = getRule("Quoted");
	currentRule->immediate = ::QuotedParseXMLNow;
	addTest(7,(void*)"\"",(char*)0,1,1,(char*)0);
	addTest(5,(void*)getRule("QuotedBlock3"),"text",1,1,(char*)0);
	addTest(7,(void*)"\"",(char*)0,1,1,(char*)0);
	currentRule->next = getRule("Quoted2");
	//
	currentRule = getRule("SetAttributes");
	currentRule->defer = ::SetAttributesParseXMLAct;
	addTest(5,(void*)getRule("SetTagFlag"),(char*)0,0,1,"defaultSKIP");
	addTest(5,(void*)getRule("Attribute"),"attributes",1,268435455,"defaultSKIP");
	//
	currentRule = getRule("BodyPartsBalancE");
	currentRule->immediate = ::balancE;
	addTest(7,(void*)"<![CDATA[","start",1,1,"defaultSKIP");
	currentTest->leftBalance = 1;
	addTest(5,(void*)getRule("BodyPartsBoDY"),"body",0,268435455,"defaultSKIP");
	addTest(7,(void*)"]]>","finish",1,1,(char*)0);
	currentTest->rightBalance = 1;
	//
	currentRule = getRule("Comment4BalancE");
	currentRule->immediate = ::balancE;
	addTest(7,(void*)"<-","start",1,1,(char*)0);
	currentTest->leftBalance = 1;
	addTest(5,(void*)getRule("Comment4BoDY"),"body",0,268435455,(char*)0);
	addTest(7,(void*)"->","finish",1,1,(char*)0);
	currentTest->rightBalance = 1;
	//
	currentRule = getRule("Comment3BalancE");
	currentRule->immediate = ::balancE;
	addTest(7,(void*)"<?","start",1,1,(char*)0);
	currentTest->leftBalance = 1;
	addTest(5,(void*)getRule("Comment3BoDY"),"body",0,268435455,(char*)0);
	addTest(7,(void*)"?>","finish",1,1,(char*)0);
	currentTest->rightBalance = 1;
	//
	currentRule = getRule("Comment2BalancE");
	currentRule->immediate = ::balancE;
	addTest(7,(void*)"<!","start",1,1,(char*)0);
	currentTest->leftBalance = 1;
	addTest(5,(void*)getRule("Comment2BoDY"),"body",0,268435455,(char*)0);
	addTest(7,(void*)"!>","finish",1,1,(char*)0);
	currentTest->rightBalance = 1;
	//
	currentRule = getRule("CommentBalancE");
	currentRule->immediate = ::balancE;
	addTest(7,(void*)"/*","start",1,1,(char*)0);
	currentTest->leftBalance = 1;
	addTest(5,(void*)getRule("CommentBoDY"),"body",0,268435455,(char*)0);
	addTest(7,(void*)"*/","finish",1,1,(char*)0);
	currentTest->rightBalance = 1;
	//
	currentRule = getRule("SetSimpleEnd");
	currentRule->immediate = ::SetSimpleEndParseXMLNow;
	currentSet = simpleEnd;
	addTest(6,(void*)currentSet,(char*)0,1,268435455,"defaultSKIP");
	//
	currentRule = getRule("SimpleEnd");
	currentRule->defer = ::SimpleEndParseXMLAct;
	addTest(7,(void*)":",(char*)0,1,1,"defaultSKIP");
	addTest(5,(void*)getRule("TextBody"),"textBody",0,1,"defaultSKIP");
	currentRule->next = getRule("SimpleEnd2");
	//
	currentRule = getRule("SimpleEnd2");
	currentRule->defer = ::SimpleEnd2ParseXMLAct;
	currentSet = getSet(",;");
	addTest(6,(void*)currentSet,"close",1,268435455,"defaultSKIP");
	addTest(5,(void*)getRule("Field"),"field",0,1,(char*)0);
	//
	currentRule = getRule("StartTag");
	currentRule->defer = ::StartTagParseXMLAct;
	addTest(7,(void*)"<",(char*)0,1,1,"defaultSKIP");
	currentSet = commentSet;
	addTest(6,(void*)currentSet,(char*)0,-1,1,"defaultSKIP");
	addTest(5,(void*)getRule("SetAttributes"),"traits",1,1,"defaultSKIP");
	addTest(5,(void*)getRule("Closing"),"singleton",0,1,"defaultSKIP");
	addTest(7,(void*)">",(char*)0,1,1,"defaultSKIP");
	currentRule->next = getRule("StartTag2");
	//
	currentRule = getRule("StartTag2");
	currentRule->defer = ::StartTag2ParseXMLAct;
	addTest(8,(void*)&simpleSyntax,(char*)0,1,1,"defaultSKIP");
	currentTest->type = 8;
	addTest(5,(void*)getRule("SetAttributes"),"traits",1,1,"defaultSKIP");
	addTest(5,(void*)getRule("SimpleEnd"),"end",1,1,"defaultSKIP");
	//
	currentRule = getRule("StartXML");
	currentRule->immediate = ::StartXMLParseXMLNow;
	addTest(5,(void*)getRule("Part"),(char*)0,1,268435455,"defaultSKIP");
	currentSet = spaces;
	addTest(6,(void*)currentSet,(char*)0,0,268435455,"defaultSKIP");
	addTest(5,(void*)getRule("Epilog"),"epilog",0,1,"defaultSKIP");
	//
	currentRule = getRule("StringSet");
	currentRule->immediate = ::StringSetParseXMLNow;
	addTest(7,(void*)"[",(char*)0,1,1,(char*)0);
	addTest(5,(void*)getRule("EndBrace"),"text",0,1,(char*)0);
	currentTest->skipOverMatch = 1;
	currentTest->processUpTo = 1;
	//
	currentRule = getRule("Tag2");
	currentRule->defer = ::Tag2ParseXMLAct;
	addTest(5,(void*)getRule("StartTag"),"tag",1,1,"defaultSKIP");
	currentRule->next = getRule("Tag3");
	//
	currentRule = getRule("Tag3");
	currentRule->defer = ::Tag3ParseXMLAct;
	addTest(5,(void*)getRule("EndTag"),"tag",1,1,"defaultSKIP");
	//
	currentRule = getRule("Up");
	currentRule->defer = ::UpParseXMLAct;
	addTest(7,(void*)"..",(char*)0,1,1,(char*)0);
	addTest(7,(void*)"/..","more",0,268435455,(char*)0);
	addTest(7,(void*)"/","slash",0,1,(char*)0);
	//
	currentRule = getRule("CommandArgument");
	addTest(7,(void*)"(",(char*)0,1,1,"defaultSKIP");
	addTest(5,(void*)getRule("Locate"),"argument",0,1,"defaultSKIP");
	addTest(7,(void*)")",(char*)0,1,1,"defaultSKIP");
	//
	currentRule = getRule("RegexTextBlock6");
	currentSet = getSet("^'");
	addTest(6,(void*)currentSet,(char*)0,1,268435455,(char*)0);
	//
	currentRule = getRule("URLhead");
	addTest(7,(void*)"ftp:",(char*)0,1,1,"defaultSKIP");
	currentRule->next = getRule("URLhead2");
	//
	currentRule = getRule("Comment");
	addTest(5,(void*)getRule("CommentBalancE"),"comment",1,1,(char*)0);
	currentRule->next = getRule("Comment2");
	//
	currentRule = getRule("URLhead2");
	addTest(7,(void*)"file:",(char*)0,1,1,"defaultSKIP");
	currentRule->next = getRule("URLhead3");
	//
	currentRule = getRule("URLhead3");
	addTest(7,(void*)"http",(char*)0,1,1,"defaultSKIP");
	addTest(7,(void*)"s",(char*)0,0,1,"defaultSKIP");
	addTest(7,(void*)":",(char*)0,1,1,"defaultSKIP");
	currentRule->next = getRule("URLhead4");
	//
	currentRule = getRule("JSONtext");
	addTest(7,(void*)"\"","quote",1,1,"defaultSKIP");
	addTest(7,(void*)"\"","name",0,1,(char*)0);
	currentTest->skipOverMatch = 1;
	currentTest->processUpTo = 1;
	currentRule->next = getRule("JSONtext2");
	//
	currentRule = getRule("URLhead4");
	addTest(7,(void*)"data:",(char*)0,1,1,"defaultSKIP");
	//
	currentRule = getRule("DelimitText");
	currentRule->defer = ::DelimitTextParseXMLAct;
	addTest(7,(void*)"\"",(char*)0,1,1,(char*)0);
	addTest(7,(void*)"\"","text",0,1,(char*)0);
	currentTest->skipOverMatch = 1;
	currentTest->processUpTo = 1;
	currentSet = delimitSet;
	addTest(6,(void*)currentSet,"delimit",1,1,(char*)0);
	currentRule->next = getRule("DelimitText2");
	//
	currentRule = getRule("DelimitText2");
	currentRule->defer = ::DelimitText2ParseXMLAct;
	currentSet = singleQuote;
	addTest(6,(void*)currentSet,(char*)0,1,1,(char*)0);
	currentSet = singleQuote;
	addTest(6,(void*)currentSet,"text",0,1,(char*)0);
	currentTest->skipOverMatch = 1;
	currentTest->processUpTo = 1;
	currentSet = delimitSet;
	addTest(6,(void*)currentSet,"delimit",1,1,(char*)0);
	currentRule->next = getRule("DelimitText3");
	//
	currentRule = getRule("DelimitText3");
	currentRule->defer = ::DelimitText3ParseXMLAct;
	currentRule->doNotGuard = 1;
	currentSet = delimitSet;
	addTest(6,(void*)currentSet,"text",0,1,(char*)0);
	currentTest->processUpTo = 1;
	currentSet = delimitSet;
	addTest(6,(void*)currentSet,"delimit",1,1,(char*)0);
	//
	currentRule = getRule("DelimitFieldName");
	currentRule->immediate = ::DelimitFieldNameParseXMLNow;
	addTest(5,(void*)getRule("DelimitText"),"name",1,1,(char*)0);
	//
	currentRule = getRule("FieldName");
	addTest(7,(void*)"~","regex",1,1,"defaultSKIP");
	addTest(5,(void*)getRule("RegexText"),(char*)0,1,1,"defaultSKIP");
	currentRule->next = getRule("FieldName2");
	//
	currentRule = getRule("TagBody");
	currentSet = bodySet;
	addTest(6,(void*)currentSet,(char*)0,1,268435455,"defaultSKIP");
	currentRule->next = getRule("TagBody2");
	//
	currentRule = getRule("FieldItem");
	currentRule->immediate = ::FieldItemParseXMLNow;
	addTest(5,(void*)getRule("Skipping"),"skips",0,268435455,(char*)0);
	addTest(5,(void*)getRule("DelimitField"),"item",1,1,(char*)0);
	//
	currentRule = getRule("SkipGuard");
	currentRule->immediate = ::SkipGuardParseXMLNow;
	//
	currentRule = getRule("JSONblock");
	currentRule->defer = ::JSONblockParseXMLAct;
	addTest(7,(void*)"{",(char*)0,1,1,"defaultSKIP");
	addTest(5,(void*)getRule("JSONpair"),"pair",1,268435455,"defaultSKIP");
	addTest(7,(void*)"}",(char*)0,1,1,"defaultSKIP");
	//
	currentRule = getRule("JSONdata");
	currentRule->defer = ::JSONdataParseXMLAct;
	addTest(5,(void*)getRule("JSONtext"),"name",1,1,"defaultSKIP");
	currentRule->next = getRule("JSONdata2");
	//
	currentRule = getRule("JSONdata2");
	currentRule->defer = ::JSONdata2ParseXMLAct;
	addTest(5,(void*)getRule("JSONblock"),"block",1,1,"defaultSKIP");
	currentRule->next = getRule("JSONdata3");
	//
	currentRule = getRule("JSONdata3");
	currentRule->defer = ::JSONdata3ParseXMLAct;
	addTest(5,(void*)getRule("JSONrepeat"),"repeat",1,1,"defaultSKIP");
	//
	currentRule = getRule("ValueText");
	addTest(5,(void*)getRule("Number"),"amount",1,1,"defaultSKIP");
	addTest(7,(void*)"%","percent",0,1,(char*)0);
	currentRule->next = getRule("ValueText2");
	//
	currentRule = getRule("JSONlistEntry");
	currentRule->immediate = ::JSONlistEntryParseXMLNow;
	addTest(5,(void*)getRule("JSONblock"),"entry",1,1,"defaultSKIP");
	//
	currentRule = getRule("JSONrepeat");
	currentRule->defer = ::JSONrepeatParseXMLAct;
	addTest(7,(void*)"[",(char*)0,1,1,"defaultSKIP");
	addTest(5,(void*)getRule("JSONrepeatEntry"),"entry",1,268435455,"defaultSKIP");
	addTest(7,(void*)"]",(char*)0,0,1,"defaultSKIP");
	//
	currentRule = getRule("DelimitDateBlock0");
	currentSet = dateSet;
	addTest(6,(void*)currentSet,(char*)0,1,268435455,(char*)0);
	//
	currentRule = getRule("DelimitField");
	addTest(5,(void*)getRule("DelimitDate"),"item",1,1,(char*)0);
	currentRule->next = getRule("DelimitField2");
	//
	currentRule = getRule("Comment2Any");
	currentRule->immediate = ::balancEbail;
	addTest(1,(void*)0,(char*)0,1,1,(char*)0);
	//
	currentRule = getRule("DelimitField2");
	addTest(5,(void*)getRule("DelimitNumber"),"item",1,1,(char*)0);
	currentRule->next = getRule("DelimitField3");
	//
	currentRule = getRule("DelimitField3");
	addTest(5,(void*)getRule("DelimitText"),"item",1,1,(char*)0);
	currentRule->next = getRule("DelimitField4");
	//
	currentRule = getRule("DelimitField4");
	addTest(5,(void*)getRule("DelimitEmpty"),"item",1,1,(char*)0);
	//
	currentRule = getRule("Heading");
	addTest(5,(void*)getRule("DelimitFieldName"),(char*)0,1,268435455,(char*)0);
	//
	currentRule = getRule("Skipping");
	addTest(5,(void*)getRule("SkipGuard"),"skip",1,1,(char*)0);
	currentSet = delimitSet;
	addTest(6,(void*)currentSet,"data",0,1,(char*)0);
	currentTest->skipOverMatch = 1;
	currentTest->processUpTo = 1;
	//
	currentRule = getRule("List");
	addTest(5,(void*)getRule("FieldItem"),(char*)0,1,268435455,(char*)0);
	//
	currentRule = getRule("NumberBlock1");
	addTest(7,(void*)"-",(char*)0,0,1,(char*)0);
	currentSet = getSet("0-9");
	addTest(6,(void*)currentSet,(char*)0,1,268435455,(char*)0);
	//
	currentRule = getRule("Value3");
	addTest(7,(void*)"=",(char*)0,1,1,"defaultSKIP");
	addTest(7,(void*)"$","dollar",0,1,"defaultSKIP");
	addTest(5,(void*)getRule("ValueText"),"text",1,1,"defaultSKIP");
	//
	currentRule = getRule("JSONtext2");
	currentSet = getSet("^,:{}[ \\]\t\n\r");
	addTest(6,(void*)currentSet,"name",1,268435455,"defaultSKIP");
	//
	currentRule = getRule("JSONlist");
	addTest(5,(void*)getRule("JSONlistEntry"),"blocks",1,268435455,"defaultSKIP");
	//
	currentRule = getRule("CommentAny");
	currentRule->immediate = ::balancEbail;
	addTest(1,(void*)0,(char*)0,1,1,(char*)0);
	//
	currentRule = getRule("FieldName5Block9");
	currentSet = fieldSet;
	addTest(6,(void*)currentSet,(char*)0,1,268435455,(char*)0);
	//
	currentRule = getRule("Comment2");
	addTest(5,(void*)getRule("Comment2BalancE"),"comment",1,1,(char*)0);
	currentRule->next = getRule("Comment3");
	//
	currentRule = getRule("MacroPart2");
	addTest(5,(void*)getRule("MacroPart2Block11"),"text",1,1,(char*)0);
	//
	currentRule = getRule("Comment2BoDY");
	currentRule->immediate = ::balancEbody;
	addTest(7,(void*)"<!","begin",0,1,(char*)0);
	addTest(7,(void*)"!>","end",0,1,(char*)0);
	currentRule->next = getRule("Comment2Any");
	//
	currentRule = getRule("Comment3");
	addTest(5,(void*)getRule("Comment3BalancE"),"comment",1,1,(char*)0);
	currentRule->next = getRule("Comment4");
	//
	currentRule = getRule("Comment3Any");
	currentRule->immediate = ::balancEbail;
	addTest(1,(void*)0,(char*)0,1,1,(char*)0);
	//
	currentRule = getRule("Comment4BoDY");
	currentRule->immediate = ::balancEbody;
	addTest(7,(void*)"<-","begin",0,1,(char*)0);
	addTest(7,(void*)"->","end",0,1,(char*)0);
	currentRule->next = getRule("Comment4Any");
	//
	currentRule = getRule("Comment4Any");
	currentRule->immediate = ::balancEbail;
	addTest(1,(void*)0,(char*)0,1,1,(char*)0);
	//
	currentRule = getRule("Quoted2Block4");
	currentSet = getSet("^'");
	addTest(6,(void*)currentSet,(char*)0,1,268435455,(char*)0);
	//
	currentRule = getRule("Text2");
	addTest(5,(void*)getRule("Text2Block5"),"text",1,1,(char*)0);
	//
	currentRule = getRule("Text2Block5");
	currentSet = fieldSet;
	addTest(6,(void*)currentSet,(char*)0,1,268435455,(char*)0);
	//
	currentRule = getRule("RegexText");
	currentSet = getSet("'");
	addTest(6,(void*)currentSet,(char*)0,1,1,(char*)0);
	addTest(5,(void*)getRule("RegexTextBlock6"),"text",1,1,(char*)0);
	currentSet = getSet("'");
	addTest(6,(void*)currentSet,(char*)0,1,1,(char*)0);
	currentRule->next = getRule("RegexText2");
	//
	currentRule = getRule("RegexText2");
	currentSet = notSpace;
	addTest(6,(void*)currentSet,(char*)0,1,268435455,(char*)0);
	//
	currentRule = getRule("SubString");
	currentRule->doNotGuard = 1;
	addTest(7,(void*)&subString,(char*)0,0,1,(char*)0);
	currentTest->aVariable = 1;
	currentTest->skipOverMatch = 1;
	currentTest->processUpTo = 1;
	//
	currentRule = getRule("FieldName2");
	currentSet = getSet("*$");
	addTest(6,(void*)currentSet,"any",1,1,"defaultSKIP");
	currentRule->next = getRule("FieldName3");
	//
	currentRule = getRule("FieldName4Block8");
	currentSet = getSet("^'");
	addTest(6,(void*)currentSet,(char*)0,1,268435455,(char*)0);
	//
	currentRule = getRule("FieldName5");
	addTest(5,(void*)getRule("FieldName5Block9"),(char*)0,1,1,"defaultSKIP");
	//
	currentRule = getRule("Line");
	currentRule->doNotGuard = 1;
	addTest(7,(void*)"\n","line",0,1,(char*)0);
	currentTest->skipOverMatch = 1;
	currentTest->processUpTo = 1;
	//
	currentRule = getRule("Value2");
	addTest(7,(void*)"=",(char*)0,1,1,"defaultSKIP");
	addTest(5,(void*)getRule("StringSet"),"text",1,1,"defaultSKIP");
	currentRule->next = getRule("Value3");
	//
	currentRule = getRule("IntegerBlock10");
	currentSet = getSet("0-9");
	addTest(6,(void*)currentSet,(char*)0,1,268435455,(char*)0);
	//
	currentRule = getRule("TagBody2");
	addTest(7,(void*)"\"",(char*)0,1,1,"defaultSKIP");
	currentSet = getSet("^\"");
	addTest(6,(void*)currentSet,(char*)0,1,268435455,"defaultSKIP");
	addTest(7,(void*)"\"",(char*)0,1,1,"defaultSKIP");
	currentRule->next = getRule("TagBody3");
	//
	currentRule = getRule("TagBody3");
	currentSet = getSet("'");
	addTest(6,(void*)currentSet,(char*)0,1,1,"defaultSKIP");
	currentSet = getSet("^'");
	addTest(6,(void*)currentSet,(char*)0,1,268435455,"defaultSKIP");
	currentSet = getSet("'");
	addTest(6,(void*)currentSet,(char*)0,1,1,"defaultSKIP");
	//
	currentRule = getRule("BodyPartsBoDY");
	currentRule->immediate = ::balancEbody;
	addTest(7,(void*)"<![CDATA[","begin",0,1,(char*)0);
	addTest(7,(void*)"]]>","end",0,1,(char*)0);
	currentRule->next = getRule("BodyPartsAny");
	//
	currentRule = getRule("BodyPartsAny");
	currentRule->immediate = ::balancEbail;
	addTest(1,(void*)0,(char*)0,1,1,(char*)0);
	//
	currentRule = getRule("BodyParts2");
	addTest(5,(void*)getRule("Comment"),(char*)0,1,1,"defaultSKIP");
	//
	currentRule = getRule("MacroPart2Block11");
	currentSet = getSet("^$");
	addTest(6,(void*)currentSet,(char*)0,1,268435455,(char*)0);
}

/*****************************************************************************
	Navigate a simple path, setting item.group to its end point
*****************************************************************************/
GroupItem *ParseXML::simplePath(GroupItem *item)
{
	if ( !pathParser )
		pathParser = new ParseXML(this);
	if ( block = item->parent )
		{
		pathParser->reset();
		setInput(item->getText());
		run("Path");
		if ( !block )
			::fprintf(stderr,"simplePath failed to navigate path: %s\n",item->getText());
		//else cout "simplePath: found",block.tag,block.index:;
		}
	else	::fprintf(stderr,"simplePath: no path provided\n");
	return block;
}

/*****************************************************************************
	trim end space off the PLGitem passed in
*****************************************************************************/
PLGitem *ParseXML::trimEnd(PLGitem *item)
{
unsigned char 	*endBody = 0;
	if ( item )
		{
		if ( skipSet )
			{
			if ( trimLeadingSpace )
				while ( item->itemLength && skipSet->contains(*item->itemStart) )
					{
					item->itemStart++;
					item->itemLength--;
					}
			endBody = (unsigned char*)item->itemStart + item->itemLength - 1;
			while ( item->itemLength > 0 && skipSet->contains(*endBody) )
				{
				endBody--;
				item->itemLength--;
				}
			}
		if ( item->itemLength )
			return item;
		}
	return 0;
}
// Ignoring declaration of unused variable part in method: BodyPartsParseXMLNow(PLGitem*)
// Ignoring declaration of unused variable closing in method: Closing2ParseXMLAct(PLGitem*)
// Ignoring declaration of unused variable block in method: CommandText2ParseXMLAct(PLGitem*)
// Ignoring declaration of unused variable list in method: CommandText3ParseXMLAct(PLGitem*)
// Ignoring declaration of unused variable plus in method: CommandText5ParseXMLAct(PLGitem*)
// Ignoring declaration of unused variable p in method: CommandText5ParseXMLAct(PLGitem*)
// Ignoring declaration of unused variable p in method: CommandText7ParseXMLAct(PLGitem*)
// Ignoring declaration of unused variable p in method: DebuggingParseXMLNow(PLGitem*)
// Ignoring declaration of unused variable delimit in method: DelimitEmptyParseXMLNow(PLGitem*)
// Ignoring declaration of unused variable delimit in method: DelimitNumberParseXMLAct(PLGitem*)
// Ignoring declaration of unused variable delimit in method: DelimitText2ParseXMLAct(PLGitem*)
// Ignoring declaration of unused variable delimit in method: DelimitText3ParseXMLAct(PLGitem*)
// Ignoring declaration of unused variable delimit in method: DelimitTextParseXMLAct(PLGitem*)
// Ignoring declaration of unused variable p in method: EndBraceParseXMLNow(PLGitem*)
// Ignoring declaration of unused variable action in method: EndTag2ParseXMLNow(PLGitem*)
// Ignoring declaration of unused variable action in method: EndTagParseXMLNow(PLGitem*)
// Ignoring declaration of unused variable skips in method: FieldItemParseXMLNow(PLGitem*)
// Ignoring declaration of unused variable p in method: JSONlistEntryParseXMLNow(PLGitem*)
// Ignoring declaration of unused variable p in method: JSONrepeatEntryParseXMLAct(PLGitem*)
// Ignoring declaration of unused variable p in method: JSONrepeatParseXMLAct(PLGitem*)
// Ignoring declaration of unused variable p in method: LocateParseXMLNow(PLGitem*)
// Ignoring declaration of unused variable p in method: ModifierParseXMLNow(PLGitem*)
// Ignoring declaration of unused variable p in method: NumberParseXMLNow(PLGitem*)
// Ignoring declaration of unused variable slash in method: PathItemParseXMLAct(PLGitem*)
// Ignoring declaration of unused variable p in method: RegistryParseXMLNow(PLGitem*)
// Ignoring declaration of unused variable p in method: StartTag2ParseXMLAct(PLGitem*)
// Ignoring declaration of unused variable p in method: Tag2ParseXMLAct(PLGitem*)
// Ignoring declaration of unused variable p in method: Tag3ParseXMLAct(PLGitem*)
// Ignoring declaration of unused variable slash in method: UpParseXMLAct(PLGitem*)
