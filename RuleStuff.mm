#include <Cocoa/Cocoa.h>
#include <string.h>
#include <stdio.h>
#include "OCroutines.h"
#include "StringRoutines.h"
#include "GroupItem.h"
#include "Buffer.h"
#include "GroupRules.h"
#include "GroupControl.h"
#include "GroupBody.h"
#include "RuleStuff.h"
#include "PLGset.h"
#include "Stylish.h"
#include "measure.h"
#include "GroupDraw.h"

// parseR parse a term into a given label: a throwaway RuleStuff whose label is into, so parse() attaches there -- driveStep's no-data arm
extern "C" GroupItem *parseR(GroupItem *term, GroupItem *into)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*bridge = 0;
GroupItem 	*got = 0;
	if ( !term )
		return 0;
	// traceGate identity-printing only, behind parseTrace -- a bare node prints an attribute count that reads like an answer
	if ( ruler->parseTrace )
		{
		::fprintf(stderr,"  parseR term= %s  into= %s\n",term->groupBody->tag,into->groupBody->tag);
		}
	bridge = new RuleStuff(term);
	bridge->label = into;
	got = term->parse(bridge);
	if ( ruler->parseTrace )
		{
		if ( got )
			::fprintf(stderr,"  parseR term= %s  -> attached as  %s  under  %s\n",term->groupBody->tag,got->groupBody->tag,into->groupBody->tag);
		else	::fprintf(stderr,"  parseR term= %s  -> NULL (no attachment)\n",term->groupBody->tag);
		}
	return got;
}

// setMacroValue copy into the macro the data of the nearest ancestor label with the same tag
extern "C" int setMacroValue(GroupItem *field)
{
RuleStuff 	*ruleStuff = field->getRStuff();
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

// testAction the old road's test for a parseAction rule -- an installed rule runs its leaf
extern "C" int testAction(GroupItem *field)
{
	// installedIsTheParse an installed rule runs its LEAF; hasNewParse is copied and rStuff is not, so the guard asks both
	if ( field->groupBody->flags.hasNewParse && field->getRStuff() && field->getRStuff()->parseMethod )
		if ( field->getRStuff()->parseMethod(field) )
			return 1;
		else	return 0;
	if ( field->getRStuff()->actionMethod )
		if ( parseACTION(field->groupBody->flags.methodType) || !field->getRStuff()->label )
			if ( field->getRStuff()->actionMethod(field) )
				return 1;
			else
			if ( field->getRStuff()->label && field->getRStuff()->actionMethod(field->getRStuff()->label) )
				return 1;
			else	::fprintf(stderr,"testAction: %shas no actionMethod\n",field->groupBody->tag);
	return 0;
}

// testAny a wild-card run against the current input
extern "C" int testAny(GroupItem *field)
{
int 		counter = 0;
int 		more = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = field->getRStuff();
	ruleStuff->isOK = 0;
	if ( *ruler->atRuleMark )
		{
		while ( *ruler->atRuleMark )
			{
			if ( counter >= ruleStuff->max )
				{
				more = 1;
				break;
				}
			counter++;
			ruler->atRuleMark++;
			if ( !*ruler->atRuleMark )
				break;
			}
		if ( more && ruleStuff->max > 1 && !ruleStuff->limitsSet )
			return ::reportMaxLimit(field);
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

// testAttributes parse each attribute in turn; true only when all succeed
extern "C" int testAttributes(RuleStuff *stuff)
{
GroupItem 	*grup = 0;
int 		result = 1;
	while ( grup = stuff->rule->nextAttribute(grup) )
		if ( grup->groupBody->flags.noPrint )
			continue;
		else
		if ( grup->parse(stuff) )
			result = 1;
		else {
			result = 0;
			break;
			}
	return result;
}

// testCharacter a run of one character against the current input
extern "C" int testCharacter(GroupItem *field)
{
int 		counter = 0;
int 		more = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = field->getRStuff();
	ruleStuff->isOK = 0;
	if ( *ruler->atRuleMark )
		{
		while ( *ruler->atRuleMark == field->getCharacter() )
			{
			if ( counter >= ruleStuff->max )
				{
				more = 1;
				break;
				}
			counter++;
			ruler->atRuleMark++;
			if ( !*ruler->atRuleMark )
				break;
			}
		if ( more && ruleStuff->max > 1 && !ruleStuff->limitsSet )
			return ::reportMaxLimit(field);
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

// testCondition a condition succeeds exactly when min is set
extern "C" int testCondition(GroupItem *field)
{
RuleStuff 	*ruleStuff = field->getRStuff();
	if ( ruleStuff->min )
		return 1;
	return 0;
}

// longestEntry the longest input prefix that IS an entry of this bin or registry -- the greedy scan is only an upper bound
extern "C" int testContainer(GroupItem *field)
{
GroupItem 	*grup = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = field->getRStuff();
PLGset 		*inSet = field->getCharacterSet();
char 		*atInput = ruler->atRuleMark;
int 		advance = 0;
Buffer 		*buffer = ruler->stringBUFFER;
	buffer->reset();
	while ( *atInput )
		if ( inSet->contains(*atInput) )
			{
			buffer->appendChar(*atInput,0,0);
			atInput++;
			}
		else	break;
	while ( advance = buffer->length() )
		{
		if ( grup = field->get(buffer->string()) )
			{
			if ( !ruleStuff->noAdvance )
				ruler->atRuleMark += advance;
			if ( ruleStuff->label )
				ruleStuff->label->setGroup(grup);
			return 1;
			}
		buffer->shorten(1);
		}
	return 0;
}

// testOptions parse the first member that passes its guard
extern "C" int testOptions(RuleStuff *stuff)
{
GroupItem 	*grup = 0;
	while ( grup = stuff->rule->nextMember(grup) )
		{
		if ( stuff->checkGuard(grup) )
			{
			grup->getRStuff()->guardOK = 1;
			if ( grup->parse(stuff) )
				return 1;
			}
		}
	return 0;
}

// testSet a run of characters from this rule's set
extern "C" int testSet(GroupItem *field)
{
PLGset 	*set = field->getCharacterSet();
int 		counter = 0;
int 		more = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = field->getRStuff();
	ruleStuff->isOK = 0;
	if ( *ruler->atRuleMark )
		{
		while ( set->contains(*ruler->atRuleMark) )
			{
			if ( counter >= ruleStuff->max )
				{
				more = 1;
				break;
				}
			counter++;
			ruler->atRuleMark++;
			if ( !*ruler->atRuleMark )
				break;
			}
		if ( more && ruleStuff->max > 1 && !ruleStuff->limitsSet )
			return ::reportMaxLimit(field);
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

// testString this rule's text at the current input
extern "C" int testString(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = field->getRStuff();
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

// testUpTo capture input up to (or over) the terminator: the rule's set, its string, or a comma
extern "C" int testUpTo(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = field->getRStuff();
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
		/********************************************************************
		Advance atText until the rule matches
		********************************************************************/
		for ( ; *atText; atText++, lngth++ )
			{
			if ( isSET(field->groupBody->flags.data) && field->getCharacterSet()->contains(*atText) )
				matched++;
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
				buffer->appendChar(*atText,0,0);
			}
		if ( skipping )
			{
			atText += matchLength;
			lngth += matchLength;
			if ( counter > 0 )
				continue;
			else	ruler->atRuleMark += lngth;
			}
		/********************************************************************
		If succeeds, update rule label and advance atRuleMark
		********************************************************************/
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

// RuleStuff constructors -- min and max start at 1; the TraiT action may overwrite them
RuleStuff::RuleStuff(GroupItem *grup)
{
	testMatch = 0;
	parseMethod = 0;
	jitMethod = 0;
	actionMethod = 0;
	hereAt = 0;
	failedAt = 0;
	label = 0;
	onFail = 0;
	onGroup = 0;
	parentLabel = 0;
	sourceLine = 0;
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
	notifyFail = 0;
	overTo = 0;
	sukcess = 0;
	rule = grup;
	ruleName = grup->groupBody->tag;
	// min and max may be overwritten by the TraiT rule action
	max = 1;
	maxRepeat = 1;
	min = 1;
	if ( grup = grup->parent )
		if ( parentStuff = grup->rStuff )
			parentLabel = parentStuff->label;
}

RuleStuff::RuleStuff(RuleStuff *r)
{
	testMatch = 0;
	parseMethod = 0;
	jitMethod = 0;
	actionMethod = 0;
	ruleName = 0;
	hereAt = 0;
	failedAt = 0;
	onFail = 0;
	onGroup = 0;
	parentLabel = 0;
	sourceLine = 0;
	rule = 0;
	max = 0;
	maxRepeat = 0;
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
	notifyFail = 0;
	overTo = 0;
	*this = *r;
	label = 0;
	sukcess = 0;
	kount = 0;
	parentStuff = 0;
}

// checkGuard true when the rule is unguarded or the input character is in its guardSet
int RuleStuff::checkGuard(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	if ( guardInProcess(field->groupBody->flags.guarding) )
		field->groupBody->flags.guarding = 0;
	if ( !field->groupBody->flags.guarding )
		field->ensureGuard();
	if ( unGuarded(field->groupBody->flags.guarding) )
		return 1;
	else
	if ( guarded(field->groupBody->flags.guarding) && field->groupBody->guardSet->contains(*ruler->atRuleMark) )
		return 1;
	return 0;
}

// checkInput skip, set hereAt, pass the guard and mint the label -- true when input is valid
int RuleStuff::checkInput()
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*field = rule;
	guardFAIL = 0;
	if ( !ruler->atRuleMark )
		{
		::fprintf(stderr,"checkInput: no input source\n");
		goto checkFailed;
		}
	if ( *ruler->atRuleMark )
		if ( !noSkip && ruler->skipSet->contains(*ruler->atRuleMark) )
			ruler->atRuleMark = ruler->checkSkip(ruler->atRuleMark);
	// end of input
	if ( *ruler->atRuleMark )
		if ( !noSkip && ruler->skipSet->contains(*ruler->atRuleMark) )
			ruler->atRuleMark = ruler->checkSkip(ruler->atRuleMark);
	// hereAtFirst set BEFORE the end-of-input exit -- a term failing at end of input is rewound to hereAt, and an unset one wrote a null mark (convLeakT)
	hereAt = ruler->atRuleMark;
	if ( !*ruler->atRuleMark )
		goto checkFailed;
	// the rule guard, if there is one
	if ( guardOK )
		{
		guardOK = 0;
		sukcess = 1;
		}
	else {
		if ( guardInProcess(field->groupBody->flags.guarding) )
			field->groupBody->flags.guarding = 0;
		if ( !field->groupBody->flags.guarding )
			field->ensureGuard();
		if ( unGuarded(field->groupBody->flags.guarding) )
			sukcess = 1;
		else
		if ( guarded(field->groupBody->flags.guarding) && field->groupBody->guardSet->contains(*ruler->atRuleMark) )
			sukcess = 1;
		else	guardFAIL = 1;
		}
	// the label
	if ( sukcess )
		if ( noLabel || (field->groupBody->flags.hasMembers && !field->groupBody->flags.binType) )
			label = 0;
		else {
			if ( !label || !label->groupBody->flags.fLAG )
				{
				label = new GroupItem(field->groupBody->tag);
				label->groupBody->flags.isLabel = 1;
				}
			else	label->groupBody->flags.fLAG = 0;
			if ( !label->getRStuff() || ::compare(ruleName,field->groupBody->tag) != 0 )
				label->setRStuff(this);
			// enclosingActivation
			if ( field->groupBody->flags.hasNewParse && isMember(field->options.affiliation) )
				{
				// driveRoot a generated DRIVE ROOT parks its label on the drive floor, where driveStep reads it
				if ( !::driveFloorLabel(this,label) )
					{
					if ( field->parent && field->parent->getRStuff() )
						field->parent->getRStuff()->label = label;
					else	::refuse(field,"checkInput: no enclosing activation to take the label");
					}
				}
			}
checkFailed:
	return sukcess;
}

// followingMember the next member after this rule in its parent list -- getWhatFollows' onFail
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

// getWhatFollows sets the RuleStuff fields once, lazily, the first time a rule is needed
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
		}
	// promotionRetired the parent-min promotion is RETIRED -- do not reintroduce it; an optional term must not make its whole rule optional
	if ( !testMatch )
		setTestMatch();
}

// setTestMatch picks the old road's test for this rule's shape
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
		if ( !isMethod(rule->groupBody->flags.instructType) )
			testMatch = ::testString;
}
