#include <Cocoa/Cocoa.h>
#include <string.h>
#include <stdio.h>
#include "OCroutines.h"
#include "GroupItem.h"
#include "Buffer.h"
#include "GroupRules.h"
#include "GroupControl.h"
#include "GroupBody.h"
#include "RuleStuff.h"
#include "PLGset.h"
#include "Stylish.h"
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
	item = new GroupItem("interpretMethod");
	commands->addMember(item);
	item->setMethod(::interpretMethod);
	item->groupBody->flags.methodType = 1;
	item->groupBody->flags.instructType = 1;
	item->groupBody->flags.noPrint = 1;
	item = new GroupItem("jitEmitter");
	commands->addMember(item);
	item->setMethod(::jitEmitter);
	item->groupBody->flags.methodType = 1;
	item->groupBody->flags.instructType = 1;
	item->groupBody->flags.noPrint = 1;
	/**************************************************************************
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
GroupItem 	*member = 0;
GroupItem 	*strap = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	bootCommands(ruler->commands);
	ruler->ruleSkipSet = new GroupItem("ruleSkipSet");
	ruler->skipSet = new PLGset(" \n\r\t/");
	ruler->ruleSkipSet->setCharacterSet(ruler->skipSet);
	ruler->properties->addMember(ruler->ruleSkipSet);
	ruler->currentRegistry = grok;
	member = new GroupItem("MEMBERs");
	member->setMethod(::processFlags);
	member->groupBody->flags.methodType = 2;
	member->groupBody->flags.instructType = 1;
	member->groupBody->flags.guarding = 2;
	/**************************************************************************
	initialize punctuation fields
	*************************************************************************/
	strap = grok->addMember(new GroupItem("leftBrace"));
	strap->setText("[");
	strap = grok->addMember(new GroupItem("leftCurly"));
	strap->setText("{");
	strap = grok->addMember(new GroupItem("leftParen"));
	strap->setText("(");
	strap = grok->addMember(new GroupItem("rightBrace"));
	strap->setText("]");
	strap = grok->addMember(new GroupItem("rightCurly"));
	strap->setText("}");
	strap = grok->addMember(new GroupItem("rightParen"));
	strap->setText(")");
	/**************************************************************************
	Define the setupFILE declared in GroupRules. It gets loaded at the
	end of this bootstrapper method.
	*************************************************************************/
	ruler->setupFILE = new GroupItem("setup");
	item = ruler->setupFILE->addString("File");
	item->setText("incant/setup");
	/*************************************************************************
	bootstrap character sets. Do these need to be in Grokking?
	*************************************************************************/
	strap = new GroupItem("counter");
	strap->setRuleStuff();
	strap->setCharacterSet(new PLGset("0-9"));
	item = grok->addMember(strap);
	strap = new GroupItem("nameSet");
	strap->setRuleStuff();
	strap->setCharacterSet(ruler->nameSet);
	grok->addMember(strap);
	strap = new GroupItem("numberSet");
	strap->setRuleStuff();
	strap->setCharacterSet(new PLGset("0-9"));
	grok->addMember(strap);
	strap = new GroupItem("delimiter");
	strap->setRuleStuff();
	strap->setText("#)");
	ruler->properties->addMember(strap);
	/*************************************************************************
	bootstrap rule definition rules.
	*************************************************************************/
	strap = new GroupItem("Modifier");
	strap->setRuleStuff();
	strap = grok->addMember(strap);
	strap->setCharacterSet(new PLGset("-~+?!%&|*@_<^{}$"));
	strap = new GroupItem("Limit");
	strap->setRuleStuff();
	strap = grok->addMember(strap);
	item = strap->addAttribute(grok->getMember("leftBrace"));
	::modify(item,"-");
	item = new GroupItem("min");
	item = strap->addAttribute(item);
	item->setRuleStuff();
	item->setGroup(grok->getMember("counter"));
	item = item->getGroup();
	::modify(item,"+");
	item = new GroupItem("max");
	item = strap->addAttribute(item);
	item->setRuleStuff();
	item->setGroup(grok->getMember("counter"));
	item = item->getGroup();
	::modify(item,"*");
	item = new GroupItem("]");
	::modify(item,"-");
	item = strap->addAttribute(item);
	strap = grok->addMember(new GroupItem("Any"));
	strap->groupBody->flags.data = 1;
	strap->setRuleStuff();
	strap = grok->addString("PoweR");
	strap->setRuleStuff();
	item = new GroupItem("exponent");
	item->setCharacterSet(new PLGset("eE"));
	item = strap->addAttribute(item);
	item->setRuleStuff();
	item = new GroupItem("sign");
	item->setCharacterSet(new PLGset("-+"));
	item = strap->addAttribute(item);
	::modify(item,"?");
	item = new GroupItem("power");
	item->setCharacterSet(new PLGset("0-9"));
	item = strap->addAttribute(item);
	::modify(item,"+");
	strap = grok->addString("FloaT");
	strap->setRuleStuff();
	item = new GroupItem("point");
	item->setCharacter('.');
	item = strap->addAttribute(item);
	item->setRuleStuff();
	::modify(item,"-");
	item = new GroupItem("decimals");
	item->setCharacterSet(new PLGset("0-9"));
	item = strap->addAttribute(item);
	::modify(item,"-+");
	item = grok->getMember("PoweR");
	item = strap->addAttribute(item);
	::modify(item,"-?");
	strap = grok->addString("QuotE");
	strap->setRuleStuff();
	strap->setMethod(::aCTionQuotE);
	item = new GroupItem("tik");
	item->setCharacterSet(new PLGset("'\""));
	item = strap->addAttribute(item);
	item->setRuleStuff();
	item = new GroupItem("quoteBody");
	item = strap->addAttribute(item);
	::modify(item,"}");
	strap = item;
	item = new GroupItem("tik");
	strap->setGroup(item);
	item = strap->groupBody->gGroup;
	::modify(item,"$");
	strap = grok->addString("NamE");
	strap->setRuleStuff();
	strap->setMethod(::aCTionNamE);
	/*  TOKENize's BOOTSTRAP ARM. NamE is built here in C++, not by
	aCTionDefinE, and its grammar-file line is inert -- measured, with a
	live line as the control. So its constitution is written at its
	construction site, which is here. The grammar arm sets the same bit
	through processFlags for rules the grammar actually defines.  */
	strap->groupBody->flags.tokened = 1;
	item = new GroupItem("first");
	item->setCharacterSet(new PLGset("a-zA-Z"));
	item = strap->addAttribute(item);
	::modify(item,"-");
	item = grok->get("nameSet");
	item = strap->addAttribute(item);
	::modify(item,"-^*");
	strap = grok->addString("NumbeR");
	strap->setRuleStuff();
	item = grok->get("numberSet");
	item = strap->addAttribute(item);
	/*  THE noLabel DASH, 2026-08-23. NumbeR reads its own token and nothing
	else -- aCTionNumbeR takes input.text and converts. A sub-term whose
	label no reader consumes should not mint one, and NamE has spelled it
	this way since the beginning, which is why NamE was immune to the
	persistence the glom used to sweep up. Labels are for readers.  */
	::modify(item,"-+");
	strap->setMethod(::aCTionNumbeR);
	strap->groupBody->flags.methodType = 1;
	strap->groupBody->flags.tokened = 1;
	item = grok->getMember("FloaT");
	item = strap->addAttribute(item);
	::modify(item,"-?");
	strap = grok->addString("GrouP");
	strap->setRuleStuff();
	dStuff = strap;
	item = strap->addMember(grok->getMember("NamE"));
	item = strap->addMember(grok->getMember("QuotE"));
	strap = grok->addString("SetBrackets");
	strap->setRuleStuff();
	strap->setMethod(::aCTionSetBrackets);
	item = strap->addAttribute(grok->getMember("leftBrace"));
	::modify(item,"-");
	item = strap->addAttribute(grok->getMember("rightBrace"));
	::modify(item,"}");
	strap = grok->addMember(new GroupItem("CodeBody"));
	strap->setRuleStuff();
	strap->setMethod(::aCTionCodE);
	strap->groupBody->guardSet = new PLGset("{");
	strap->groupBody->flags.guarding = 1;
	strap->groupBody->flags.methodType = 2;
	strap->groupBody->flags.isRule = 1;
	item = strap->addAttribute(grok->getMember("leftCurly"));
	item->setRuleStuff();
	item = strap->addAttribute(grok->getMember("rightCurly"));
	item->setRuleStuff();
	strap = grok->addString("DelimText");
	strap->setRuleStuff();
	item = strap->addAttribute(grok->getMember("leftParen"));
	item->setRuleStuff();
	strap->groupBody->guardSet = new PLGset("(");
	strap->groupBody->flags.guarding = 1;
	item = strap->addString("dtext");
	::modify(item,"^");
	item->setGroup(ruler->properties->getMember("delimiter"));
	item = item->getGroup();
	::modify(item,"}");
	strap = grok->addString("DatA");
	strap->setRuleStuff();
	item = strap->addMember(grok->getMember("GrouP"));
	item = strap->addMember(grok->getMember("NumbeR"));
	item = strap->addMember(grok->getMember("CodeBody"));
	item = strap->addMember(grok->getMember("SetBrackets"));
	item = strap->addMember(grok->getMember("DelimText"));
	item = new GroupItem("NotA");
	item->setCharacterSet(new PLGset("^ \t\r\n;"));
	item = strap->addMember(item);
	::modify(item,"+");
	strap = grok->addString("TraiTdata");
	strap->setRuleStuff();
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
	stuff->setRuleStuff();
	stuff->setMethod(::aCTionDefinE);
	strap = grok->addString("DEFINing");
	strap->setRuleStuff();
	strap->setMethod(::processFlags);
	strap->groupBody->flags.guarding = 2;
	strap = grok->addString("TraiT");
	strap->setRuleStuff();
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
	strap->setMethod(::aCTionNewGroup);
	strap->groupBody->flags.methodType = 1;
	strap->setRuleStuff();
	strap->setGroup(grok->getMember("TraiT"));
	strap = grok->addString("Attributes");
	strap->setRuleStuff();
	strap->setGroup(grok->getMember("TraiT"));
	item = strap->groupBody->gGroup;
	::modify(item,"+");
	strap = grok->addString("MemberS");
	strap->setRuleStuff();
	item = strap->addString(":");
	::modify(item,"-");
	item = strap->addAttribute(member);
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
	item = new GroupItem("endDefine");
	item->setCharacterSet(new PLGset(";>"));
	item = strap->addAttribute(item);
	::modify(item,"-");
	/*************************************************************************
	The define command (stuff is DefinE at this point).
	*************************************************************************/
	strap = grok->addString("define");
	strap->setRuleStuff();
	item = grok->getMember("DEFINing");
	item = strap->addAttribute(item);
	item->setRuleStuff();
	item = new GroupItem("definitions");
	item = strap->addAttribute(item);
	item->setRuleStuff();
	item->setGroup(stuff);
	item = item->groupBody->gGroup;
	::modify(item,"+");
	item = grok->getMember("DEFINing");
	item = strap->addAttribute(item);
	item->setRuleStuff();
	item = new GroupItem(";");
	item = strap->addAttribute(item);
	::modify(item,"-");
	strap = grok->addString("InvokE");
	strap->setRuleStuff();
	item = strap->addAttribute(grok->getMember("leftParen"));
	::modify(item,"-");
	item = grok->getMember("GrouP");
	item = strap->addAttribute(item);
	::modify(item,"?");
	item = strap->addAttribute(grok->getMember("rightParen"));
	::modify(item,"-");
	strap = grok->addString("RunRulE");
	strap->setRuleStuff();
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
	strap->setRuleStuff();
	strap->setGroup(grok->getMember("RunRulE"));
	item = strap->groupBody->gGroup;
	::modify(item,"+");
	item = grok->getMember("InitiatE");
	item = 0;
	/*************************************************************************
	The hand-built bootstrap rules above never go through aCTionDefinE, so
	they never get its define-time materialisation. Several of them add
	terms with no modify() call at all (Limit's "[" and "]"), which is why
	those terms had no rStuff and genParse refused them. One pass here, over
	the rules built above, before setup is parsed -- rules defined IN setup
	come through aCTionDefinE and are already covered.
	
	I commented out the following because all rules created in the bootstrap
	now have setRuleStuff() run on them so rStuff is set
	materialiseRegistry(grok);
	
	What replaces it is the `audit` COMMAND (Commands.rtn), and it is
	deliberately NOT called from here. Tony, 2026-07-29: this point is
	BEFORE setup is parsed, so an audit here sees only the hand-built
	bootstrap slice and is blind to every rule defined in incant source --
	which is most of the board the invariant is about. It runs from
	incant/oneTest instead, after the definitions are all in place.
	*************************************************************************/
	ruler->pushInput(::getFile(ruler->setupFILE));
	if ( ruler->sourceFILE )
		strap->parse(0);
	ruler->popInput();
	/*************************************************************************
	Set the buffer links
	*************************************************************************/
	item = ruler->properties->get("stringBUFFER");
	item->setBuffer(ruler->stringBUFFER);
	return strap;
}
