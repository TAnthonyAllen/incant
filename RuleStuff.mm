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

/********************************************************************************
    Bridge to the GENERIC driver for rules genParse hasn't converted yet
    (GrouP, NumbeR -- pre-existing bootstrap rules, out of scope for this
    prototype). Builds a throwaway RuleStuff whose .label IS `into`, so
    parse()'s own attach logic (`pStuff.label +% label;`) appends directly
    where a converted callee's leaveRule/leaveAlt would have. Generated
    methods and the generic driver coexist rule by rule (S0) -- this is the
    seam.
********************************************************************************/
extern "C" GroupItem *parseGeneric(GroupItem *into, char *ruleName)
{
GroupItem 	*rule = GroupControl::groupController->locate(ruleName);
RuleStuff 	*bridge = new RuleStuff(rule);
	bridge->label = into;
	return rule->parse(bridge);
}

/********************************************************************************
    parseR (genParseShape S1.6) -- the set-then-call primitive for a term that
    references another rule. Two jobs the emitted `&&` chain cannot do itself:

    1. The `into` handover is an ASSIGNMENT, and an assignment is not a term
       (S2.5's expression-vs-statement problem in a new place). Keeping it in
       one primitive leaves emitted text a pure boolean expression.
    2. It routes THROUGH parse(), not directly at a generated method, so the
       fork decides. Generation is per-rule, so a generated rule can call an
       interpretive one and vice versa: mixed mode is free, conversion is
       order-independent, and the interpretive walk stays the oracle for
       everything not yet converted. The cost is an indirect call opaque to
       LLVM's inliner -- not a correctness cost, and reversible later inside
       this one function, with no emitted file regenerated.

    No name lookup (S1.3): the term IS the thing to parse. That is a
    CORRECTION to S1.6's stated mechanism, made against the tree rather than
    against the design -- see the measurement in genParse.rtn's dumpRuleTerms
    header. S1.6 writes `t2.onGroup.parentLabel = label`, but NO rule-reference
    term is isGROUP and none has onGroup set, before or after a parse
    (getWhatFollows gates on isGROUP). There is no onGroup there to write to.
    What a reference term actually is: a distinct node carrying isRule and
    SHARING the referenced rule's child list. So it parses directly, which is
    exactly what the interpretive walk does -- testAttributes calls
    `grup.parse(stuff)` on the term itself, never on a dereferenced target.
    Parity with the oracle, not a parallel mechanism that can drift from it.

    The handover travels as the bridge stuff's label, exactly as parseGeneric
    already does it: parse() derives parentLabel from it on the generated path
    and attaches through `pStuff.label +% label` on the interpretive one. ONE
    mechanism serves both halves of mixed mode, and it is why a null pStuff is
    never handed down (which would silently orphan the callee's result).

    OPEN, and it is Tony's/Clay's call, not a coding decision -- see the seal.
    parseMethod lives on rStuff, and rStuff is PER NODE: the term has its own,
    separate from the registry rule's. So binding a rule's parseMethod does NOT
    reach the term nodes that reference it, and a converted rule would be used
    when invoked BY NAME but not when referenced from another rule. Mixed mode
    (S1.6's whole justification) needs an answer to that before rung 4, which
    is the first cross-method call. It does not bite rungs 1-2: Scaf/Scaf2 have
    no rule-reference terms.
********************************************************************************/
extern "C" GroupItem *parseR(GroupItem *term, GroupItem *into)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*bridge = 0;
GroupItem 	*got = 0;
	if ( !term )
		return 0;
	/*  FU-2', 2026-08-05 -- THE LOCALIZER, BUILT ONCE IN THE SUPPORT LAYER.
	Instrumenting parseR rather than the emitted methods means every
	generated method self-narrates FOR FREE and rules 13-78 inherit it
	unwritten. A full-monty verify is a DETECTOR (corpus GM-14); this is
	the localizer that names the fork point.
	
	⚠ GATED ON THE EXISTING parseTrace, not on a new flag: leaveRule above
	already uses it, so this joins the standing debug idiom instead of
	minting a second switch. Default OFF, and the fleet is asserted
	byte-identical with the gate closed -- a gate that leaks is not a gate.
	
	⚠ IDENTITY-PRINTING ONLY -- taG and shape facts, NEVER a bare node.
	Printing a group prints its ATTRIBUTE COUNT, which is a legal-looking
	number in the same range as an answer and does not announce itself as
	the wrong quantity. That near-miss is kant8T's K6c, and it nearly
	inverted a diagnosis; this is that lesson written into an instrument.  */
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

/********************************************************************************
	This sets the data of rule to the value of a previously processed label
    with the same name as rule
********************************************************************************/
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

/********************************************************************************
	Process a parseAction
********************************************************************************/
extern "C" int testAction(GroupItem *field)
{
	/*  installedIsTheParse  AN INSTALLED rStuff IS CALLED THROUGH ITS LEAF. Tony's ruling,
	2026-09-15. A parseAction REPLACES the parse, so it is a leaf and lives in parseMethod
	undisguised, written at definition by setParseAction -- the ONE writer on both roads.
	actionMethod holds the rule's real action or null, and null at exit is a no-op.
	⚠ THE FALLBACK THAT STOOD HERE IS GONE AND F-61 CLOSES BY REMOVAL. It wrote by COPYING
	gMethod, which setParseWalk overwrites with the ENTRY, so it filed the entry as the
	action and parseAction called itself. A writer now exists at DEFINITION, which is what
	the row asked for.
	⚠ hasNewParse is a groupBody flag and IS copied; rStuff is not -- the guard asks both.
	RuleStuff.testAction.installedIsTheParse  */
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

/********************************************************************************
	Run a wild card test on this group against current input
********************************************************************************/
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

/********************************************************************************
	Parse field attributes and return true if they all succeed
********************************************************************************/
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

/********************************************************************************
	Run a character test on this group against current input
********************************************************************************/
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

/********************************************************************************
	Process a condition
********************************************************************************/
extern "C" int testCondition(GroupItem *field)
{
RuleStuff 	*ruleStuff = field->getRStuff();
	if ( ruleStuff->min )
		return 1;
	return 0;
}

/********************************************************************************
    Registry and Container test looks for an entry that matches the input stream.

    LONGEST-ENTRY MATCH (Tony's finding and ruling, 2026-08-02). The greedy
    character scan is an UPPER BOUND, not the answer. Character-set membership
    can only say "this character could belong to SOME entry"; it can never say
    "this prefix IS an entry", because a set has no notion of where an entry
    ends. So the scan runs to the end of the run, and then the buffer is backed
    off one character at a time until it either IS an entry or is empty. The
    longest prefix that is an actual entry wins.

    THE PRESENTING BUG: `--grup;` against Operators. `negate` and `modedOP` are
    word-spelled entries, so their letters are in the container's character set
    -- `g` among them. The scan therefore built `--g`, which is an entry of
    nothing, and the whole match failed. It is a design flaw and not an edge
    case: any container holding both a symbol and a word can produce it.
    Backing off finds `--` and advances 2, which is the answer.

    Same disease class as the ShortcuT `+`-merge that sank `,` as the string
    opener (2026-07-31): set-based character grouping making token decisions.
********************************************************************************/
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

/********************************************************************************
	Process the first field member that passes its guard
********************************************************************************/
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

/********************************************************************************
	Run a character set test on this group against current input
********************************************************************************/
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

/********************************************************************************
	Run a string test on this group against current input
********************************************************************************/
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

/****************************************************************************
	Capture input until it gets a match. It returns a token and the input
    stream is left pointing at the match if upTo or after the match if upToOver.
    If the current rule is a set, the set is matched against.
    If the current rule isSTRING its text is matched against. Otherwise
    the default match is against a comma.
****************************************************************************/
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

/********************************************************************************
	RuleStuff constructors.
********************************************************************************/
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

/********************************************************************************
	checkGuard returns true if rule is unGuarded or input pointer is in guardSet
********************************************************************************/
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

/********************************************************************************
	checkInput sets hereAt and atRuleMark, handles input diversion, and returns
    true if current input is valid. Called by GroupItem match()
********************************************************************************/
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
	/****************************************************************************
	Check for end of input
	****************************************************************************/
	if ( *ruler->atRuleMark )
		if ( !noSkip && ruler->skipSet->contains(*ruler->atRuleMark) )
			ruler->atRuleMark = ruler->checkSkip(ruler->atRuleMark);
	// hereAtFirst set BEFORE the end-of-input exit -- a term failing at end of input is rewound to hereAt, and an unset one wrote a null mark (convLeakT)
	hereAt = ruler->atRuleMark;
	if ( !*ruler->atRuleMark )
		goto checkFailed;
	/****************************************************************************
	Check the rule guard if there is one
	****************************************************************************/
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
	/****************************************************************************
	Set the label
	****************************************************************************/
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

/******************************************************************************
    Return the member following this group in the parent list
    Called by getWhatFollows() in RuleStuff
******************************************************************************/
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

/********************************************************************************
	Sets the fields of RuleStuff.
********************************************************************************/
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
	/*  ⚠ THE PARENT-min PROMOTION IS RETIRED HERE (Tony, SEQ 152, 2026-09-03).
	Do not reintroduce it: it fired ZERO times and its absence is the reason
	an optional term can no longer silently make its whole rule optional.
	RuleStuff.getWhatFollows.promotionRetired  */
	if ( !testMatch )
		setTestMatch();
}

/********************************************************************************
	Set testMatch
********************************************************************************/
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
