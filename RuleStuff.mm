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
#include "GroupList.h"
#include "GroupBody.h"
#include "RuleStuff.h"
#include "GroupDraw.h"

/*******************************************************************************
	This sets the data of rule to the value of a previously processed label
    with the same name as rule
*******************************************************************************/
extern "C" int setMacroValue(GroupItem *field)
{
RuleStuff 	*ruleStuff = field->rStuff;
GroupItem 	*grup = 0;
GroupItem 	*macro = field->getGroup();
GroupItem 	*ancestor = 0;
	if ( ruleStuff->parentStuff )
		ancestor = ruleStuff->parentStuff->label;
	if ( ancestor )
		while ( grup = ancestor->next(grup) )
			if ( ::compare(macro->groupBody->tag,grup->groupBody->tag) == 0 )
				{
				macro->copyData(grup);
				return 1;
				}
	::fprintf(stderr,"setMacroValue: could not find macro for %s\n",field->groupBody->tag);
	return 0;
}

/*******************************************************************************
	Process a parseAction
*******************************************************************************/
extern "C" int testAction(GroupItem *field)
{
	if ( field->rStuff->label && field->groupBody->gMethod(field->rStuff->label) )
		return 1;
	else
	if ( field->groupBody->gMethod(field) )
		return 1;
	return 0;
}

/*******************************************************************************
	Run a wild card test on this group against current input
*******************************************************************************/
extern "C" int testAny(GroupItem *field)
{
int 		counter = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = field->rStuff;
	ruleStuff->isOK = 0;
	if ( *ruler->atRuleMark )
		{
		while ( counter < ruleStuff->max )
			{
			counter++;
			ruler->atRuleMark++;
			if ( !*ruler->atRuleMark || counter >= ruleStuff->max )
				break;
			}
		if ( counter && counter >= ruleStuff->min )
			{
			if ( ruleStuff->noAdvance )
				ruler->atRuleMark = ruleStuff->hereAt;
			if ( ruleStuff->label )
				ruleStuff->label->setToken(ruleStuff->hereAt,counter);
			ruleStuff->isOK = 1;
			}
		}
	if ( ruleStuff->isOK )
		return 1;
	return 0;
}

/*******************************************************************************
	Parse field attributes and return true if they all succeed
*******************************************************************************/
extern "C" int testAttributes(RuleStuff *stuff)
{
GroupItem 	*grup = 0;
	while ( grup = stuff->rule->nextAttribute(grup) )
		if ( grup->groupBody->flags.noPrint )
			continue;
		else
		if ( !grup->parse(stuff) )
			return 0;
	return 1;
}

/*******************************************************************************
	Run a character test on this group against current input
*******************************************************************************/
extern "C" int testCharacter(GroupItem *field)
{
int 		counter = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = field->rStuff;
	ruleStuff->isOK = 0;
	if ( *ruler->atRuleMark )
		{
		while ( *ruler->atRuleMark == field->getCharacter() && counter < ruleStuff->max )
			{
			counter++;
			ruler->atRuleMark++;
			if ( !*ruler->atRuleMark || counter >= ruleStuff->max )
				break;
			}
		if ( counter && counter >= ruleStuff->min )
			{
			if ( ruleStuff->noAdvance )
				ruler->atRuleMark = ruleStuff->hereAt;
			if ( ruleStuff->label )
				ruleStuff->label->setToken(ruleStuff->hereAt,counter);
			ruleStuff->isOK = 1;
			}
		}
	if ( ruleStuff->isOK )
		return 1;
	return 0;
}

/*******************************************************************************
	Process a condition
*******************************************************************************/
extern "C" int testCondition(GroupItem *field)
{
RuleStuff 	*ruleStuff = field->rStuff;
	if ( ruleStuff->min )
		return 1;
	return 0;
}

/*******************************************************************************
    Registry and Container test looks for an entry that matches the input stream.
*******************************************************************************/
extern "C" int testContainer(GroupItem *field)
{
GroupItem 	*grup = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = field->rStuff;
PLGset 		*inSet = field->getCharacterSet();
char 		*atInput = ruler->atRuleMark;
int 		advance = 0;
Buffer 		*buffer = ruler->stringBUFFER;
	buffer->reset();
	while ( *atInput )
		if ( inSet->contains(*atInput) )
			buffer->appendChar(*atInput++);
		else	break;
	if ( advance = buffer->length() )
		if ( grup = field->get(buffer->string()) )
			{
			if ( !ruleStuff->noAdvance )
				ruler->atRuleMark += advance;
			if ( ruleStuff->label )
				ruleStuff->label->setGroup(grup);
			return 1;
			}
	return 0;
}

/*******************************************************************************
	Process the first field member that passes its guard
*******************************************************************************/
extern "C" int testOptions(RuleStuff *stuff)
{
GroupItem 	*grup = 0;
	while ( grup = stuff->rule->nextMember(grup) )
		{
		if ( stuff->checkGuard(grup) )
			{
			grup->rStuff->guardOK = 1;
			if ( grup->parse(stuff) )
				return 1;
			}
		}
	return 0;
}

/*******************************************************************************
	Run a character set test on this group against current input
*******************************************************************************/
extern "C" int testSet(GroupItem *field)
{
PLGset 	*set = field->getCharacterSet();
int 		counter = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = field->rStuff;
	ruleStuff->isOK = 0;
	if ( *ruler->atRuleMark )
		{
		while ( set->contains(*ruler->atRuleMark) )
			{
			counter++;
			ruler->atRuleMark++;
			if ( !*ruler->atRuleMark || counter >= ruleStuff->max )
				break;
			}
		if ( counter && counter >= ruleStuff->min )
			{
			if ( ruleStuff->noAdvance )
				ruler->atRuleMark = ruleStuff->hereAt;
			if ( ruleStuff->label )
				ruleStuff->label->setToken(ruleStuff->hereAt,counter);
			ruleStuff->isOK = 1;
			}
		}
	if ( ruleStuff->isOK )
		return 1;
	return 0;
}

/*******************************************************************************
	Run a string test on this group against current input
*******************************************************************************/
extern "C" int testString(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = field->rStuff;
char 		*matchedString = ruleStuff->rule->matches(ruler->atRuleMark);
	if ( matchedString )
		{
		if ( ruleStuff->noAdvance )
			ruler->atRuleMark = ruleStuff->hereAt;
		if ( ruleStuff->label )
			ruleStuff->label->setText(matchedString);
		return 1;
		}
	return 0;
}

/***************************************************************************
	Capture input until it gets a match. It returns a token and the input
    stream is left pointing at the match if upTo or after the match if upToOver.
    If the current rule is a set, the set is matched against.
    If the current rule isSTRING its text is matched against. Otherwise
    the default match is against a comma.
***************************************************************************/
extern "C" int testUpTo(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = field->rStuff;
char 		*atText = ruler->atRuleMark;
char 		*endString = 0;
int 		counter = 1;
int 		lngth = 0;
int 		matched = 0;
int 		matchLength = 1;
int 		skipping = 0;
Buffer 		*buffer = ruler->stringBUFFER;
GroupItem 	*grup = isGROUP(field->groupBody->flags.data) ? field->getGroup() : field;
	buffer->reset();
	endString = grup->getText();
	matchLength = (int)::strlen(endString);
	if ( ruleStuff->noLabel && isCOUNT(grup->groupBody->flags.data) )
		{
		counter = field->getCount();
		skipping = 1;
		}
	grup = 0;
	while ( counter-- )
		{
		/*******************************************************************
		Advance atText until the rule matches
		*******************************************************************/
		for ( ; *atText; atText++, lngth++ )
			{
			if ( isSET(field->groupBody->flags.data) && field->getCharacterSet()->contains(*atText) )
				matched++;
			else
			if ( field->groupBody->groupList )
				{
				while ( grup = field->next(grup) )
					if ( !::compareToStream(grup->groupBody->tag,atText) )
						{
						matchLength = (int)::strlen(grup->groupBody->tag);
						matched++;
						goto gotMatch;
						}
				}
			else
			if ( matchLength == 1 )
				{
				if ( *atText == '\\' )
					{
					atText++;
					switch (*atText)
						{
						case 'r':
							*atText = '\r';
							break;
						case 't':
							*atText = '\t';
							break;
						case 'n':
							*atText = '\n';
						}
					}
				else
				if ( *atText == *endString )
					matched++;
				}
			else
			if ( !::compareToStream(endString,atText) )
				matched++;
			if ( matched )
				break;
			else
			if ( *atText )
				buffer->appendChar(*atText);
			}
		/*******************************************************************
		Fields w/o label are skips. The number of fields skipped is
		determined by the counter set above from the field count
		*******************************************************************/
gotMatch:
		if ( skipping )
			{
			atText += matchLength;
			lngth += matchLength;
			if ( counter > 0 )
				continue;
			else	ruler->atRuleMark += lngth;
			}
		/*******************************************************************
		If succeeds, update rule label and advance atRuleMark
		*******************************************************************/
		if ( matched )
			{
			if ( lngth )
				{
				if ( ruleStuff->label )
					{
					ruleStuff->label->setText(buffer->toString());
					if ( grup )
						ruleStuff->label->addAttribute(grup);
					}
				ruler->atRuleMark = atText;
				}
			if ( upToOver(ruleStuff->overTo) )
				ruler->atRuleMark += matchLength;
			return 1;
			}
		}
	return 0;
}

/*******************************************************************************
	RuleStuff constructors.
*******************************************************************************/
RuleStuff::RuleStuff(GroupItem *grup)
{
	testMatch = 0;
	hereAt = 0;
	label = 0;
	onFail = 0;
	onGroup = 0;
	kount = 0;
	parentStuff = 0;
	banged = 0;
	doNothing = 0;
	followed = 0;
	guardOK = 0;
	guardFAIL = 0;
	hasMacro = 0;
	inProcess = 0;
	isOK = 0;
	isOption = 0;
	isTarget = 0;
	limitsSet = 0;
	noAdvance = 0;
	noLabel = 0;
	noSkip = 0;
	overTo = 0;
	sukcess = 0;
	rule = grup;
	ruleName = grup->groupBody->tag;
	// min and max may be overwritten by the TraiT rule action
	max = 1;
	min = 1;
}

RuleStuff::RuleStuff(RuleStuff *r)
{
	testMatch = 0;
	ruleName = 0;
	hereAt = 0;
	onFail = 0;
	onGroup = 0;
	rule = 0;
	max = 0;
	min = 0;
	banged = 0;
	doNothing = 0;
	followed = 0;
	guardOK = 0;
	guardFAIL = 0;
	hasMacro = 0;
	inProcess = 0;
	isOK = 0;
	isOption = 0;
	isTarget = 0;
	limitsSet = 0;
	noAdvance = 0;
	noLabel = 0;
	noSkip = 0;
	overTo = 0;
	*this = *r;
	label = 0;
	sukcess = 0;
	kount = 0;
	parentStuff = 0;
}

/*******************************************************************************
	checkGuard returns true if rule is unGuarded or input pointer is in guardSet
*******************************************************************************/
int RuleStuff::checkGuard(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	sukcess = 0;
	if ( guardInProcess(field->groupBody->flags.guarding) )
		field->groupBody->flags.guarding = 0;
	if ( !field->groupBody->flags.guarding )
		field->getGuard();
	if ( unGuarded(field->groupBody->flags.guarding) )
		return 1;
	else
	if ( guarded(field->groupBody->flags.guarding) && field->groupBody->guardSet->contains(*ruler->atRuleMark) )
		return 1;
	return 0;
}

/*******************************************************************************
	checkInput sets hereAt and atRuleMark, handles input diversion, and returns
    true if current input is valid. Called by GroupItem match()
*******************************************************************************/
int RuleStuff::checkInput()
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*field = rule;
	sukcess = 0;
	guardFAIL = 0;
	if ( !ruler->atRuleMark )
		{
		::fprintf(stderr,"checkInput: no input source\n");
		goto checkFailed;
		}
	if ( *ruler->atRuleMark )
		if ( !noSkip )
			ruler->atRuleMark = ruler->checkSkip(ruler->atRuleMark);
	/***************************************************************************
	Check for end of input and deal w/diversion if diverted
	***************************************************************************/
	if ( !*ruler->atRuleMark && ruler->inputDiverted )
		{
		while ( ruler->inputDiverted && !*ruler->atRuleMark )
			ruler->popInput();
		if ( *ruler->atRuleMark )
			if ( !noSkip )
				ruler->atRuleMark = ruler->checkSkip(ruler->atRuleMark);
		}
	if ( !*ruler->atRuleMark )
		goto checkFailed;
	/***************************************************************************
	Check the rule guard if there is one
	***************************************************************************/
	hereAt = ruler->atRuleMark;
	if ( guardOK )
		{
		guardOK = 0;
		sukcess = 1;
		}
	else {
		if ( guardInProcess(field->groupBody->flags.guarding) )
			field->groupBody->flags.guarding = 0;
		if ( !field->groupBody->flags.guarding )
			field->getGuard();
		if ( unGuarded(field->groupBody->flags.guarding) )
			sukcess = 1;
		else
		if ( guarded(field->groupBody->flags.guarding) && field->groupBody->guardSet->contains(*ruler->atRuleMark) )
			sukcess = 1;
		else	guardFAIL = 1;
		}
	/***************************************************************************
	Set the label
	***************************************************************************/
	if ( sukcess )
		if ( noLabel )
			label = 0;
		else {
			if ( isTarget )
				if ( parentStuff )
					label = parentStuff->label;
				else	::fprintf(stderr,"getStuff: %s is target but no parent label provided\n",field->groupBody->tag);
			else
			if ( !label || !label->groupBody->flags.fLAG )
				{
				label = new GroupItem(field->groupBody->tag);
				label->groupBody->flags.isLabel = 1;
				}
			else	label->groupBody->flags.fLAG = 0;
			if ( !label->rStuff )
				label->rStuff = this;
			}
checkFailed:
	return sukcess;
}

/*****************************************************************************
    Return the member following this group in the parent list
    Called by getWhatFollows() in RuleStuff
*****************************************************************************/
GroupItem *RuleStuff::followingMember()
{
	if ( rule->parent )
		{
		GroupItem 	*grup = rule;
		while ( grup = grup->nextInParent )
			if ( isMember(grup->options.affiliation) )
				break;
		return grup;
		}
	return 0;
}

/*******************************************************************************
	Sets the fields of RuleStuff.
*******************************************************************************/
void RuleStuff::getWhatFollows()
{
GroupItem 	*grup = 0;
	followed = 1;
	if ( isGROUP(rule->groupBody->flags.data) )
		{
		grup = rule->getGroup();
		if ( grup->groupBody->flags.isMacro )
			hasMacro = 1;
		else	onGroup = grup;
		}
	if ( isMember(rule->options.affiliation) && !rule->parent->groupBody->flags.binType )
		{
		isTarget = 1;
		if ( grup = followingMember() )
			onFail = grup;
		}
	else
	if ( isEmbedded(rule->options.affiliation) )
		{
		if ( (rule->groupBody->flags.data && rule->groupBody->flags.data < 4) || max == 1 )
			isTarget = 1;
		if ( !min && rule->parent->rStuff->min )
			rule->parent->rStuff->min = 0;
		}
	if ( !testMatch )
		setTestMatch();
}

/*******************************************************************************
	Set testMatch
*******************************************************************************/
void RuleStuff::setTestMatch()
{
	if ( upTo(overTo) || upToOver(overTo) )
		testMatch = ::testUpTo;
	else
	if ( isBIN(rule->groupBody->flags.binType) || isREGISTRY(rule->groupBody->flags.binType) )
		testMatch = ::testContainer;
	else
	if ( rule->groupBody->flags.data )
		switch (rule->groupBody->flags.data)
			{
			case 1:
				testMatch = ::testAny;
				break;
			case 2:
				testMatch = ::testCharacter;
				break;
			case 3:
				testMatch = ::testSet;
				break;
			case 6:
				testMatch = 0;
				break;
			default:
				testMatch = ::testString;
			}
	else
	if ( rule->groupBody->flags.isMacro )
		testMatch = ::setMacroValue;
	else
	if ( rule->groupBody->flags.isCondition )
		testMatch = ::testCondition;
	else
	if ( parseACTION(rule->groupBody->flags.methodType) )
		testMatch = ::testAction;
	else
	if ( !rule->contents() )
		if ( isMethod(rule->groupBody->flags.instructType) )
			{
			testMatch = ::testAction;
			rule->groupBody->flags.methodType = 2;
			}
		else	testMatch = ::testString;
}
