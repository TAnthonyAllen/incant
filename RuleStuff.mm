#include <Cocoa/Cocoa.h>
#include <string.h>
#include <stdio.h>
#include "OCroutines.h"
#include "StringRoutines.h"
#include "GroupItem.h"
#include "Buffer.h"
#include "GroupRules.h"
#include "GroupControl.h"
#include "GroupList.h"
#include "GroupBody.h"
#include "RuleStuff.h"
#include "PLGset.h"
#include "Stylish.h"
#include "GroupDraw.h"

/*******************************************************************************
    True if ch is one of the characters in chars -- a guard test for baked
    guard sets. PLGset stays the default for larger sets (banked, S5.2); this
    covers the single/small-explicit-set cases in the JSONblock family.
*******************************************************************************/
extern "C" int inGuard(char *chars, char ch)
{
	while ( *chars )
		if ( *chars == ch )
			return 1;
		else	chars++;
	return 0;
}

/*******************************************************************************
    Alternation exit. No label of its own (S2.4) -- the winning option has
    already attached (rule-reference options attach via their own leaveRule
    against the same `into`; literal options attach via litOption). Only
    handles the rewind-on-failure half of Invariant R.
*******************************************************************************/
extern "C" int leaveAlt(char *from, int ok)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	if ( ok )
		return 1;
	ruler->atRuleMark = from;
	return 0;
}

/*******************************************************************************
    Sequence exit -- Invariant R lives here and in leaveAlt, nowhere else.
    On success: attach label into `into`'s list, return true. On failure:
    rewind atRuleMark to `from`, return false (label is simply not attached;
    GC reclaims it, same as parse()'s own comment on label leaks).
*******************************************************************************/
extern "C" int leaveRule(GroupItem *into, GroupItem *label, char *from, int ok)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	if ( ok )
		{
		into->addAttribute(label);
		return 1;
		}
	ruler->atRuleMark = from;
	return 0;
}

/*******************************************************************************
    genParse Step 1/2 prototype (docs/genParseSpec.md S3/S5): hand-written
    support library + the seven JSONblock methods + entry wrapper. No tok
    macros -- every primitive below is a real function, so &&/|| composition
    works natively. (tok's #name(args)-...- macro facility segfaults or
    silently drops statements once a macro call is anything but the sole
    content of its function -- see CLAUDE.md bear traps.)
*******************************************************************************/
/*******************************************************************************
    Match a literal string at atRuleMark (skip-set pass first). No label --
    for "-"/noLabel attribute terms (JSONblock's "{"-/"}"-,  JSONfield's ":"-,
    JSONitem's ","?-).
*******************************************************************************/
extern "C" int lit(char *str)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
char 		*atText = 0;
char 		*matchStr = 0;
	if ( ruler->skipSet->contains(*ruler->atRuleMark) )
		ruler->atRuleMark = ruler->checkSkip(ruler->atRuleMark);
	atText = ruler->atRuleMark;
	matchStr = str;
	while ( *matchStr )
		if ( *atText == *matchStr )
			{
			atText++;
			matchStr++;
			}
		else	return 0;
	ruler->atRuleMark = atText;
	return 1;
}

/*******************************************************************************
    Match a literal string as an alternation MEMBER (JSONtoken's "false"/
    "true"). A plain literal member is not noLabel, so on success this
    creates a label tagged with the literal text and attaches it into `into`
    directly -- leaveAlt is label-transparent by design, so literal options
    must attach themselves (rule-reference options attach via their own
    leaveRule against the same `into`).
*******************************************************************************/
extern "C" int litOption(GroupItem *into, char *str)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*fresh = 0;
char 		*atText = 0;
char 		*matchStr = 0;
	if ( ruler->skipSet->contains(*ruler->atRuleMark) )
		ruler->atRuleMark = ruler->checkSkip(ruler->atRuleMark);
	atText = ruler->atRuleMark;
	matchStr = str;
	while ( *matchStr )
		if ( *atText == *matchStr )
			{
			atText++;
			matchStr++;
			}
		else	return 0;
	ruler->atRuleMark = atText;
	fresh = new GroupItem(str);
	into->addAttribute(fresh);
	return 1;
}

/*******************************************************************************
    Generated per-term iteration helper for JSONblock's `JSONfield*` (min 0).
    Same treatment S5.2 already gives character-level accumulators, extended
    to group-reference iteration -- one small function per loop site rather
    than a reusable macro (S2.5).
*******************************************************************************/
extern "C" int manyJSONblockFields(GroupItem *label)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
char 		*from = ruler->atRuleMark;
int 		kount = 0;
	while ( parseJSONfield(label) )
		kount++;
	if ( kount >= 0 )
		return 1;
	ruler->atRuleMark = from;
	return 0;
}

/*******************************************************************************
    Generated per-term iteration helper for JSONlist's `JSONitem+` (min 1).
*******************************************************************************/
extern "C" int manyJSONlistItems(GroupItem *label)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
char 		*from = ruler->atRuleMark;
int 		kount = 0;
	while ( parseJSONitem(label) )
		kount++;
	if ( kount >= 1 )
		return 1;
	ruler->atRuleMark = from;
	return 0;
}

/*******************************************************************************
    Bridge to the GENERIC driver for rules genParse hasn't converted yet
    (GrouP, NumbeR -- pre-existing bootstrap rules, out of scope for this
    prototype). Builds a throwaway RuleStuff whose .label IS `into`, so
    parse()'s own attach logic (`pStuff.label +% label;`) appends directly
    where a converted callee's leaveRule/leaveAlt would have. Generated
    methods and the generic driver coexist rule by rule (S0) -- this is the
    seam.
*******************************************************************************/
extern "C" int parseGeneric(GroupItem *into, char *ruleName)
{
GroupItem 	*rule = GroupControl::groupController->locate(ruleName);
RuleStuff 	*bridge = new RuleStuff(rule);
	bridge->label = into;
	return rule->parse(bridge) != 0;
}

/*******************************************************************************
    JSONarray isRule "["- JSONlist? "]"- code={
        if JSONlist; for grup in JSONlist; grup <: grup; };
*******************************************************************************/
extern "C" int parseJSONarray(GroupItem *into)
{
GroupItem 	*label = new GroupItem("JSONarray");
GroupItem 	*rule = GroupControl::groupController->locate("JSONarray");
GroupRules 	*ruler = GroupControl::groupController->groupRules;
char 		*from = ruler->atRuleMark;
int 		ok = 0;
	ok = ::lit("[") && (::parseJSONlist(label) || 1) && ::lit("]");
	if ( ok )
		label = rule->groupBody->gMethod(label);
	return ::leaveRule(into,label,from,ok && label);
}

/*******************************************************************************
    JSONblock isRule fail "{"- JSONfield* "}"-;
*******************************************************************************/
extern "C" int parseJSONblock(GroupItem *into)
{
GroupItem 	*label = new GroupItem("JSONblock");
GroupRules 	*ruler = GroupControl::groupController->groupRules;
char 		*from = ruler->atRuleMark;
	return ::leaveRule(into,label,from,::lit("{") && ::manyJSONblockFields(label) && ::lit("}"));
}

/*******************************************************************************
    JSONfield isRule JSONtoken ":"- JSONvalue ","?- code={
        token <: JSONtoken; token = JSONvalue; return token; };
*******************************************************************************/
extern "C" int parseJSONfield(GroupItem *into)
{
GroupItem 	*label = new GroupItem("JSONfield");
GroupItem 	*rule = GroupControl::groupController->locate("JSONfield");
GroupRules 	*ruler = GroupControl::groupController->groupRules;
char 		*from = ruler->atRuleMark;
int 		ok = 0;
	ok = parseJSONtoken(label) && ::lit(":") && parseJSONvalue(label) && (::lit(",") || 1);
	if ( ok )
		label = rule->groupBody->gMethod(label);
	return ::leaveRule(into,label,from,ok && label);
}

/*******************************************************************************
    JSONitem isRule JSONtoken@ ","?-;
    @ (isTarget/promote): the child's label becomes JSONitem's own result,
    retagged. No fresh label of its own and no leaveRule call -- JSONtoken's
    own leaveAlt/leaveRule already rewinds on failure (Invariant R), so
    promotion needs nothing extra on the failure path.
*******************************************************************************/
extern "C" int parseJSONitem(GroupItem *into)
{
	if ( !::parseJSONtoken(into) )
		return 0;
	into->groupBody->tag = "JSONitem";
	::lit(",");
	return 1;
}

/*******************************************************************************
    JSONlist isRule JSONitem+;
*******************************************************************************/
extern "C" int parseJSONlist(GroupItem *into)
{
GroupItem 	*label = new GroupItem("JSONlist");
GroupRules 	*ruler = GroupControl::groupController->groupRules;
char 		*from = ruler->atRuleMark;
	return ::leaveRule(into,label,from,::manyJSONlistItems(label));
}

/*******************************************************************************
    JSONtoken isRule JSONblock; "false"; "true"; GrouP; NumbeR;
*******************************************************************************/
extern "C" int parseJSONtoken(GroupItem *into)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
char 		*from = ruler->atRuleMark;
	return ::leaveAlt(from,(::inGuard("{",*ruler->atRuleMark) && ::parseJSONblock(into)) || ::litOption(into,"false") || ::litOption(into,"true") || parseGeneric(into,"GrouP") || parseGeneric(into,"NumbeR"));
}

/*******************************************************************************
    JSONvalue isRule JSONblock; JSONarray; JSONtoken;
*******************************************************************************/
extern "C" int parseJSONvalue(GroupItem *into)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
char 		*from = ruler->atRuleMark;
	return ::leaveAlt(from,(::inGuard("{",*ruler->atRuleMark) && ::parseJSONblock(into)) || (::inGuard("[",*ruler->atRuleMark) && parseJSONarray(into)) || parseJSONtoken(into));
}

/*******************************************************************************
    Entry wrapper -- outside callers do field = runJSONblock(argument) and
    expect a GroupItem (genParseSpec S5.3).

    NOTE (Clod, 2026-07-25): S5.3's own worked example checks
    `!result.hasMembers` here, but leaveRule attaches via `+%` == addAttribute
    (confirmed from the generated code -- see bear-trap), which sets
    hasAttributes, not hasMembers. `hasMembers` is never true for JSONblock's
    own content, so that check always fired and silently discarded every
    successful parse's real content in favour of the empty `trueResult`
    sentinel -- found empirically via the tree-diff POP, not by inspection.
    Checking hasAttributes instead is the fix; flagging in the spec too.
*******************************************************************************/
extern "C" GroupItem *runJSONblock(GroupItem *argument)
{
GroupItem 	*result = new GroupItem("JSONblock");
	GroupControl::groupController->groupRules->pushInput(argument);
	if ( !::parseJSONblock(result) )
		result = 0;
	else
	if ( !result->groupBody->flags.hasAttributes )
		result = GroupControl::groupController->groupRules->trueResult;
	return result;
}

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
	if ( parseACTION(field->groupBody->flags.methodType) || !field->rStuff->label )
		{
		if ( field->groupBody->gMethod(field) )
			return 1;
		}
	else
	if ( field->rStuff->label && field->groupBody->gMethod(field->rStuff->label) )
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
int 		result = 0;
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
			{
			buffer->appendChar(*atInput,0,0);
			atInput++;
			}
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
				buffer->appendChar(*atText,0,0);
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
	failedAt = 0;
	label = 0;
	onFail = 0;
	onGroup = 0;
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
	min = 1;
}

RuleStuff::RuleStuff(RuleStuff *r)
{
	testMatch = 0;
	ruleName = 0;
	hereAt = 0;
	failedAt = 0;
	onFail = 0;
	onGroup = 0;
	sourceLine = 0;
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
	notifyFail = 0;
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
	guardFAIL = 0;
	if ( !ruler->atRuleMark )
		{
		::fprintf(stderr,"checkInput: no input source\n");
		goto checkFailed;
		}
	if ( *ruler->atRuleMark )
		if ( !noSkip && ruler->skipSet->contains(*ruler->atRuleMark) )
			ruler->atRuleMark = ruler->checkSkip(ruler->atRuleMark);
	/***************************************************************************
	Check for end of input
	***************************************************************************/
	if ( *ruler->atRuleMark )
		if ( !noSkip && ruler->skipSet->contains(*ruler->atRuleMark) )
			ruler->atRuleMark = ruler->checkSkip(ruler->atRuleMark);
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
		if ( noLabel || (field->groupBody->flags.isRule && field->groupBody->flags.hasMembers && !field->groupBody->flags.binType) )
			label = 0;
		else {
			if ( !label || !label->groupBody->flags.fLAG )
				{
				label = new GroupItem(field->groupBody->tag);
				label->groupBody->flags.isLabel = 1;
				}
			else	label->groupBody->flags.fLAG = 0;
			if ( !label->rStuff )
				label->setRStuff(this);
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
		if ( !min && rule->parent->rStuff->min && rule->parent->allAttributesOptional() )
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
		if ( !isMethod(rule->groupBody->flags.instructType) )
			testMatch = ::testString;
}
/*	Warning: the following methods were referenced but not declared
	allAttributesOptional()
*/
