#include <Cocoa/Cocoa.h>
#include <string.h>
#include <stdio.h>
#include "OCroutines.h"
#include "StringRoutines.h"
#include "GroupItem.h"
#include "PLGset.h"
#include "Buffer.h"
#include "GroupControl.h"
#include "GroupRules.h"
#include "GroupBody.h"
#include "RuleStuff.h"
#include "GroupDraw.h"
#include "GroupMain.h"

/*******************************************************************************
	Constructor
*******************************************************************************/
GroupMain::GroupMain()
{
	GroupControl::groupController = new GroupControl(10000);
GroupRules *ruler = GroupControl::groupController->groupRules;
	GroupControl::groupController->setBaseRegistries();
	ruler->searchList = GroupControl::groupController->getRegistry("SearchList");
	ruler->grokking = GroupControl::groupController->getRegistry("Grokking");
	ruler->grokking->groupBody->flags.isRule = 1;
	grok = ruler->grokking;
	ruler->searchList->addMember(ruler->grokking);
	ruler->searchList->groupBody->flags.isSorted = 0;
}

/*****************************************************************************
	bootCommands loads commands needed for bootstrapping
*****************************************************************************/
void GroupMain::bootCommands(GroupItem *commands)
{
GroupItem 	*item = 0;
	/*************************************************************************
	We will need the parseAction command
	*************************************************************************/
	item = new GroupItem("parseAction");
	commands->addMember(item);
	item->setMethod(::setRuleAction);
	item->groupBody->flags.methodType = 1;
	item->groupBody->flags.instructType = 1;
	item->groupBody->flags.noPrint = 1;
	/*************************************************************************
	and the ruleMethod and operateMethod commands
	*************************************************************************/
	item = new GroupItem("ruleMethod");
	commands->addMember(item);
	item->setMethod(::ruleMethod);
	item->groupBody->flags.methodType = 1;
	item->groupBody->flags.instructType = 1;
	item->groupBody->flags.noPrint = 1;
	item = new GroupItem("operateMethod");
	commands->addMember(item);
	item->setMethod(::ruleMethod);
	item->groupBody->flags.methodType = 1;
	item->groupBody->flags.instructType = 1;
	item->groupBody->flags.noPrint = 1;
	/*************************************************************************
	and the registry command
	*************************************************************************/
	item = new GroupItem("registry");
	commands->addMember(item);
	item->setMethod(::rEGISTER);
	item->groupBody->flags.methodType = 1;
	item->groupBody->flags.instructType = 1;
	item->groupBody->flags.noPrint = 1;
}

/*****************************************************************************
	bootstrapper creates rules and groups incant needs to define and run a rule.
	The bootstrap rule definitions are shown in the grammar listing.
*****************************************************************************/
GroupItem *GroupMain::bootstrapper()
{
GroupItem 	*dStuff = 0;
GroupItem 	*item = 0;
GroupItem 	*stuff = 0;
GroupItem 	*strap = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	bootCommands(ruler->commands);
	ruler->ruleSkipSet = new GroupItem("ruleSkipSet");
	ruler->ruleSkipSet->setCharacterSet(new PLGset(" \n\r\t/"));
	ruler->properties->addMember(ruler->ruleSkipSet);
	ruler->currentRegistry = grok;
	/*************************************************************************
	bootstrap character sets. Do these need to be in Grokking?
	*************************************************************************/
	strap = new GroupItem("counter");
	strap->setCharacterSet(new PLGset("0-9"));
	item = grok->addMember(strap);
	strap = new GroupItem("nameSet");
	strap->setCharacterSet(ruler->nameSet);
	grok->addMember(strap);
	strap = new GroupItem("numberSet");
	strap->setCharacterSet(new PLGset("0-9"));
	grok->addMember(strap);
	/*************************************************************************
	bootstrap rule definition rules.
	*************************************************************************/
	strap = new GroupItem("Modifier");
	strap = grok->addMember(strap);
	strap->setCharacterSet(new PLGset("-~+?!%&|*@_<^{}$"));
	strap = new GroupItem("Limit");
	strap = grok->addMember(strap);
	strap->addAttribute(new GroupItem("["));
	item = new GroupItem("min");
	item = strap->addAttribute(item);
	item->setGroup(grok->getMember("counter"));
	item = item->getGroup();
	::modify(item,"+");
	item = new GroupItem("max");
	item = strap->addAttribute(item);
	item->setGroup(grok->getMember("counter"));
	item = item->getGroup();
	::modify(item,"*");
	item = new GroupItem("]");
	item = strap->addAttribute(item);
	strap = new GroupItem("tokenize");
	strap->setMethod(::tokenize);
	strap->groupBody->flags.guarding = 2;
	strap = grok->addMember(strap);
	::modify(strap,"^@");
	strap = grok->addString("Any");
	strap->groupBody->flags.data = 1;
	strap = grok->addString("PoweR");
	strap->setCharacterSet(new PLGset("eE"));
	item = new GroupItem("sign");
	item->setCharacterSet(new PLGset("-+"));
	item = strap->addAttribute(item);
	::modify(item,"?");
	item = new GroupItem("power");
	item->setCharacterSet(new PLGset("0-9"));
	item = strap->addAttribute(item);
	::modify(item,"+");
	strap = grok->addString("FloaT");
	strap->setCharacter('.');
	item = new GroupItem("decimals");
	item->setCharacterSet(new PLGset("0-9"));
	item = strap->addAttribute(item);
	::modify(item,"+");
	item = grok->getMember("PoweR");
	item = strap->addAttribute(item);
	::modify(item,"?");
	strap = grok->addString("QuotE");
	strap->setMethod(::aCTionQuotE);
	item = new GroupItem("tik");
	item->setCharacterSet(new PLGset("'\""));
	item = strap->addAttribute(item);
	item = new GroupItem("quoteBody");
	item = strap->addAttribute(item);
	::modify(item,"}");
	strap = item;
	item = new GroupItem("tik");
	strap->setGroup(item);
	item = strap->groupBody->gGroup;
	::modify(item,"$");
	strap = grok->addString("NamE");
	strap->setMethod(::aCTionNamE);
	item = new GroupItem("first");
	item->setCharacterSet(new PLGset("a-zA-Z"));
	item = strap->addAttribute(item);
	::modify(item,"-");
	item = grok->get("nameSet");
	item = strap->addAttribute(item);
	::modify(item,"-*");
	item = grok->get("tokenize");
	strap->addAttribute(item);
	strap = grok->addString("NumbeR");
	item = grok->get("numberSet");
	strap->setGroup(item);
	item = strap->groupBody->gGroup;
	::modify(item,"+");
	strap->setMethod(::aCTionNumbeR);
	strap->groupBody->flags.methodType = 1;
	item = grok->getMember("FloaT");
	item = strap->addAttribute(item);
	::modify(item,"?");
	item = grok->get("tokenize");
	strap->addAttribute(item);
	strap = grok->addString("GrouP");
	dStuff = strap;
	item = strap->addMember(grok->getMember("NamE"));
	item = strap->addMember(grok->getMember("QuotE"));
	strap = grok->addString("SetBrackets");
	strap->setMethod(::aCTionSetBrackets);
	item = strap->addString("[");
	::modify(item,"-");
	item = strap->addString("]");
	::modify(item,"}");
	strap = grok->addString("DatA");
	item = strap->addMember(grok->getMember("GrouP"));
	item = strap->addMember(grok->getMember("NumbeR"));
	item = strap->addMember(grok->getMember("SetBrackets"));
	item = new GroupItem("NotA");
	item->setCharacterSet(new PLGset("^ \t\r\n;"));
	item = strap->addMember(item);
	::modify(item,"+");
	strap = grok->addString("CodE");
	item = strap->addString("{");
	item = strap->addString("}");
	::modify(item,"}");
	item = grok->get("tokenize");
	strap->addAttribute(item);
	strap = grok->addString("TraiTdata");
	strap->setMethod(::aCTionTraiTdata);
	strap->groupBody->flags.methodType = 1;
	item = strap->addString("=");
	::modify(item,"-");
	item = grok->getMember("DatA");
	item = strap->addAttribute(item);
	item = grok->getMember("Modifier");
	item = strap->addAttribute(item);
	::modify(item,"*");
	item = grok->getMember("Limit");
	item = strap->addAttribute(item);
	::modify(item,"?");
	/*************************************************************************
	DefinE stub to be added to a little further down
	*************************************************************************/
	stuff = grok->addString("DefinE");
	stuff->setMethod(::aCTionDefinE);
	strap = grok->addString("TraiT");
	strap->setMethod(::aCTionTraiT);
	strap->groupBody->flags.methodType = 1;
	item = grok->getMember("GrouP");
	item = strap->addAttribute(item);
	item = grok->getMember("Modifier");
	item = strap->addAttribute(item);
	::modify(item,"*");
	item = grok->getMember("Limit");
	item = strap->addAttribute(item);
	::modify(item,"?");
	item = grok->getMember("TraiTdata");
	item = strap->addAttribute(item);
	::modify(item,"?");
	strap = grok->addString("NewGroup");
	strap->setGroup(grok->getMember("TraiT"));
	strap = grok->addString("Attributes");
	strap->setGroup(grok->getMember("TraiT"));
	item = strap->groupBody->gGroup;
	::modify(item,"+");
	strap = grok->addString("MemberS");
	item = strap->addString(":");
	::modify(item,"-");
	item = strap->addAttribute(stuff);
	::modify(item,"+");
	/*************************************************************************
	DefinE gets filled in below. A bit of musical chairs happening
	*************************************************************************/
	strap = stuff;
	item = grok->getMember("NewGroup");
	item = strap->addAttribute(item);
	strap->setMethod(::aCTionDefinE);
	strap->groupBody->flags.methodType = 1;
	item = grok->getMember("Attributes");
	item = strap->addAttribute(item);
	::modify(item,"?");
	item = grok->getMember("MemberS");
	item = strap->addAttribute(item);
	::modify(item,"?");
	item = new GroupItem(";");
	item = strap->addAttribute(item);
	::modify(item,"-");
	item = grok->getMember("CodE");
	item = strap->addAttribute(item);
	::modify(item,"?");
	/*************************************************************************
	The define command (stuff is DefinE at this point).
	*************************************************************************/
	strap = grok->addString("define");
	strap->groupBody->flags.isRule = 1;
	item = new GroupItem("definitions");
	item = strap->addAttribute(item);
	item->setGroup(stuff);
	item = item->groupBody->gGroup;
	::modify(item,"+");
	item = new GroupItem(";");
	item = strap->addAttribute(item);
	::modify(item,"-");
	strap = grok->addString("InvokE");
	item = new GroupItem("(");
	item = strap->addAttribute(item);
	::modify(item,"-");
	item = grok->getMember("GrouP");
	item = strap->addAttribute(item);
	::modify(item,"?");
	item = new GroupItem(")");
	item = strap->addAttribute(item);
	::modify(item,"-");
	strap = grok->addString("RunRulE");
	strap->setMethod(::aCTionRunRulE);
	strap->groupBody->flags.methodType = 1;
	item = grok->getMember("NamE");
	item = strap->addAttribute(item);
	item = grok->getMember("InvokE");
	item = strap->addAttribute(item);
	::modify(item,"?");
	item = new GroupItem(";");
	item = strap->addAttribute(item);
	::modify(item,"-?");
	strap = grok->addString("InitiatE");
	strap->groupBody->flags.isRule = 1;
	strap->setGroup(grok->getMember("RunRulE"));
	item = strap->groupBody->gGroup;
	::modify(item,"+");
	item = grok->getMember("InitiatE");
	item = 0;
	ruler->pushInput(::getStringFromFile("/Users/anthony/Dropbox/data/InProcess/Groups/XML/WorkingOn/setup"));
	//getTokens();
	strap->parse(0);
	/*************************************************************************
	Set the buffer links
	*************************************************************************/
	item = ruler->properties->get("stringBUFFER");
	item->setBuffer(ruler->stringBUFFER);
	return strap;
}
