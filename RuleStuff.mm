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

// parseR parse a term into a given label: into is an ARGUMENT to parse(), never a throwaway RuleStuff (stroke 1.1 site 2) -- driveStep's no-data arm
extern "C" GroupItem *parseR(GroupItem *term, GroupItem *into)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*got = 0;
	if ( !term )
		return 0;
	// traceGate identity-printing only, behind parseTrace -- a bare node prints an attribute count that reads like an answer
	if ( ruler->parseTrace )
		{
		::fprintf(stderr,"  parseR term= %s  into= %s\n",term->groupBody->tag,into->groupBody->tag);
		}
	got = term->parse(0,0,into);
	if ( ruler->parseTrace )
		{
		if ( got )
			::fprintf(stderr,"  parseR term= %s  -> attached as  %s  under  %s\n",term->groupBody->tag,got->groupBody->tag,into->groupBody->tag);
		else	::fprintf(stderr,"  parseR term= %s  -> NULL (no attachment)\n",term->groupBody->tag);
		}
	return got;
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
		if ( more && ruleStuff->max > 1 )
			return ::reportMaxLimit(field);
		if ( counter && counter >= ruleStuff->min )
			{
			if ( ruleStuff->noAdvance )
				ruler->atRuleMark = ruleStuff->hereAt;
			if ( ruleStuff->label )
				ruleStuff->label->setToken(ruleStuff->hereAt,counter);
			return 1;
			}
		}
	return 0;
}

// testAttributes parse each attribute in turn; true only when all succeed
extern "C" int testAttributes(RuleStuff *stuff, GroupItem *field)
{
GroupItem 	*grup = 0;
int 		result = 1;
	while ( grup = field->nextAttribute(grup) )
		if ( grup->groupBody->flags.noPrint )
			continue;
		else
		if ( grup->parse(stuff,0,0) )
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
		if ( more && ruleStuff->max > 1 )
			return ::reportMaxLimit(field);
		if ( counter && counter >= ruleStuff->min )
			{
			if ( ruleStuff->noAdvance )
				ruler->atRuleMark = ruleStuff->hereAt;
			if ( ruleStuff->label )
				ruleStuff->label->setToken(ruleStuff->hereAt,counter);
			return 1;
			}
		}
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
extern "C" int testOptions(RuleStuff *stuff, GroupItem *field)
{
GroupItem 	*grup = 0;
	while ( grup = field->nextMember(grup) )
		{
		if ( stuff->checkGuard(grup) )
			{
			if ( grup->parse(stuff,1,0) )
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
		if ( more && ruleStuff->max > 1 )
			return ::reportMaxLimit(field);
		if ( counter && counter >= ruleStuff->min )
			{
			if ( ruleStuff->noAdvance )
				ruler->atRuleMark = ruleStuff->hereAt;
			if ( ruleStuff->label )
				ruleStuff->label->setToken(ruleStuff->hereAt,counter);
			return 1;
			}
		}
	return 0;
}

// testString this rule's text at the current input
extern "C" int testString(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = field->getRStuff();
char 		*matchedString = field->matches(ruler->atRuleMark);
	// nodeInHand the match reads the field it was handed, never RuleStuff.owner (stroke 5.2)
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
	// oldRoadLabel the old road's label is on its stuff until 1.2f; a new-road leaf hands its own to upToMatch (SEQ 301)
	if ( field->getRStuff() )
		return ::upToMatch(field,field->getRStuff()->label);
	return ::upToMatch(field,0);
}

// upToMatch testUpTo's match, handed the label to fill -- it reads no label off the stuff (SEQ 301, 1.2c)
extern "C" int upToMatch(GroupItem *field, GroupItem *upLab)
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
				if ( upLab )
					{
					upLab->setText(buffer->toString());
					if ( grup )
						upLab->addAttribute(grup);
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
	label = 0;
	onGroup = 0;
	followed = 0;
	inProcess = 0;
	isTarget = 0;
	modPercent = 0;
	modPointer = 0;
	modUnGuarded = 0;
	noAdvance = 0;
	noLabel = 0;
	noSkip = 0;
	notifyFail = 0;
	overTo = 0;
	ruleTerm = 0;
	ruleName = grup->groupBody->tag;
	// min and max may be overwritten by the TraiT rule action
	max = 1;
	maxRepeat = 1;
	min = 1;
}

RuleStuff::RuleStuff(RuleStuff *r)
{
	testMatch = 0;
	parseMethod = 0;
	jitMethod = 0;
	actionMethod = 0;
	ruleName = 0;
	hereAt = 0;
	onGroup = 0;
	max = 0;
	maxRepeat = 0;
	min = 0;
	followed = 0;
	inProcess = 0;
	isTarget = 0;
	modPercent = 0;
	modPointer = 0;
	modUnGuarded = 0;
	noAdvance = 0;
	noLabel = 0;
	noSkip = 0;
	notifyFail = 0;
	overTo = 0;
	ruleTerm = 0;
	*this = *r;
	label = 0;
}

// checkGuard true when the rule is unguarded or the input character is in its guardSet
int RuleStuff::checkGuard(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	if ( field->isUnGuarded() )
		return 1;
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

// checkInput skip, set hereAt, pass the guard and mint the label -- true when input is valid; field is the node the caller runs, never RuleStuff.owner (stroke 5.4a). The old road and parseRule keep their values on this stuff until 1.2d-f; a new-road leaf calls inputAt, checkGuard and mintLabel itself and keeps them in locals (SEQ 301)
int RuleStuff::checkInput(GroupItem *field, int guardPassed)
{
char 	*inAt = inputAt();
int 	inOK = 0;
	if ( !inAt )
		return 0;
	// hereAtFirst set BEFORE the end-of-input exit -- a term failing at end of input is rewound to hereAt, and an unset one wrote a null mark (convLeakT)
	hereAt = inAt;
	if ( !*inAt )
		return 0;
	// verdictReturned the guard's verdict is RETURNED, never stored -- sukcess left RuleStuff in 1.2d (SEQ 302)
	if ( guardPassed )
		inOK = 1;
	else
	if ( checkGuard(field) )
		inOK = 1;
	// the label
	if ( inOK )
		label = mintLabel(field,label);
	return inOK;
}

// getWhatFollows sets the RuleStuff fields once, lazily, the first time a rule is needed
void RuleStuff::getWhatFollows(GroupItem *field)
{
	followed = 1;
	if ( isGROUP(field->groupBody->flags.data) )
		onGroup = field->getGroup();
	if ( isMember(field->options.affiliation) && !field->parent->groupBody->flags.binType )
		{
		isTarget = 1;
		}
	else
	if ( isEmbedded(field->options.affiliation) )
		{
		if ( (field->groupBody->flags.data && field->groupBody->flags.data < 4) || max == 1 )
			isTarget = 1;
		}
	// promotionRetired the parent-min promotion is RETIRED -- do not reintroduce it; an optional term must not make its whole rule optional
	if ( !testMatch )
		setTestMatch(field);
}

// inputAt skip to the input a term starts at and hand the mark back -- null only when there is no input at all (SEQ 301, 1.2c)
char *RuleStuff::inputAt()
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	if ( !ruler->atRuleMark )
		{
		::fprintf(stderr,"checkInput: no input source\n");
		return 0;
		}
	if ( *ruler->atRuleMark )
		if ( !noSkip && ruler->skipSet->contains(*ruler->atRuleMark) )
			ruler->atRuleMark = ruler->checkSkip(ruler->atRuleMark);
	// end of input
	if ( *ruler->atRuleMark )
		if ( !noSkip && ruler->skipSet->contains(*ruler->atRuleMark) )
			ruler->atRuleMark = ruler->checkSkip(ruler->atRuleMark);
	return ruler->atRuleMark;
}

// mintLabel the label of a term that passed its guard, or null for noLabel and a members rule; a recycled fLAG label is reused (SEQ 301, 1.2c)
GroupItem *RuleStuff::mintLabel(GroupItem *field, GroupItem *reuse)
{
GroupItem 	*lab = reuse;
	if ( noLabel || (field->groupBody->flags.hasMembers && !field->groupBody->flags.binType) )
		return 0;
	if ( !lab || !lab->groupBody->flags.fLAG )
		{
		lab = new GroupItem(field->groupBody->tag);
		lab->groupBody->flags.isLabel = 1;
		// labelOf the rule this label was minted for -- written here once, never rewritten (stroke 5.6a)
		lab->labelOf = field;
		}
	else	lab->groupBody->flags.fLAG = 0;
	if ( !lab->getRStuff() || ::compare(ruleName,field->groupBody->tag) != 0 )
		lab->setRStuff(this);
	// enclosingActivation
	if ( field->groupBody->flags.hasNewParse && isMember(field->options.affiliation) )
		{
		// driveRoot a generated DRIVE ROOT parks its label on the drive floor, where driveStep reads it
		if ( !::driveFloorLabel(this,lab) )
			{
			if ( field->parent && field->parent->getRStuff() )
				field->parent->getRStuff()->label = lab;
			else	::refuse(field,"checkInput: no enclosing activation to take the label");
			}
		}
	return lab;
}

// setTestMatch picks the old road's test for this rule's shape
void RuleStuff::setTestMatch(GroupItem *field)
{
	if ( upTo(overTo) || upToOver(overTo) )
		testMatch = ::testUpTo;
	else
	if ( isBIN(field->groupBody->flags.binType) || isREGISTRY(field->groupBody->flags.binType) )
		testMatch = ::testContainer;
	else
	if ( field->groupBody->flags.data )
		switch (field->groupBody->flags.data)
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
	if ( field->groupBody->flags.isCondition )
		testMatch = ::testCondition;
	else
	if ( parseACTION(field->groupBody->flags.methodType) )
		testMatch = ::testAction;
	else
	if ( !field->contents() )
		if ( !isMethod(field->groupBody->flags.instructType) )
			testMatch = ::testString;
}
