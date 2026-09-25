#include <Cocoa/Cocoa.h>
#include <string.h>
#include <stdio.h>
#include "OCroutines.h"
#include "StringRoutines.h"
#include "GroupItem.h"
#include "GroupRules.h"
#include "GroupControl.h"
#include "GroupList.h"
#include "GroupBody.h"
#include "RuleStuff.h"
#include "Stylish.h"
#include "GroupDraw.h"
#include "measure.h"

/*  identity as a SMALL STABLE INTEGER, because a raw %p moves every run and a
    fixture cannot pin it (rule H3). ⚠ H13: name the QUESTION before the column.
    measure.addrOf  */
extern "C" GroupItem *addrOf(GroupItem *field)
{
	if ( !field )
		{
		::fprintf(stderr,"addrOf: no field\n");
		return 0;
		}
	/*  ⚠ NO WIDTH SPECIFIER IN ANY FORMAT STRING BELOW -- `%` followed by `-`
	is the passthrough CLOSE marker and ends the block inside the string
	literal, wiping the extern block to zero. Bear-trap #40, measured
	2026-09-01 in this very file.  */
	
	{
	static void *seenTable[512];
	static int   seenCount = 0;
	void *nodeKey = (void*)field;
	void *bodyKey = (void*)field->groupBody;
	int nodeNum = 0, bodyNum = 0, i;
	for ( i = 0; i < seenCount; i++ )
	{
	if ( seenTable[i] == nodeKey ) nodeNum = i + 1;
	if ( seenTable[i] == bodyKey ) bodyNum = i + 1;
	}
	if ( !nodeNum && seenCount < 512 ) { seenTable[seenCount++] = nodeKey; nodeNum = seenCount; }
	if ( !bodyNum && seenCount < 512 ) { seenTable[seenCount++] = bodyKey; bodyNum = seenCount; }
	::fprintf(stderr,"ADDROF %s field=#%d body=#%d  isCopy=%d  raw %p %p\n",
	field->groupBody->tag ? field->groupBody->tag : "(untagged)",
	nodeNum, bodyNum, (int)field->options.isCopy,
	nodeKey, bodyKey);
	::fflush(stderr);
	}
	
	return field;
}

/*  the invariant is a BICONDITIONAL -- isRule IFF has rStuff -- and the summary
    prints even when clean, because an absence check passes by being deleted.
    measure.auditMissingRules  */
extern "C" int auditMissingRules(GroupItem *registry)
{
GroupItem 	*entry = 0;
int 		missing = 0;
	while ( entry = registry->next(entry) )
		if ( entry->groupBody->flags.isRule && !entry->getRStuff() )
			{
			::fprintf(stderr,"AUDIT MISSRULE %s/%s -- isRule, no rStuff\n",registry->groupBody->tag,entry->groupBody->tag);
			missing++;
			}
	return missing;
}

/*  a TERM of a rule carrying no rStuff. Split from MISSRULE deliberately; the two
    are not one population.   measure.auditMissingRules  */
extern "C" int auditMissingTerms(GroupItem *registry)
{
GroupItem 	*entry = 0;
GroupItem 	*term = 0;
int 		i = 0;
int 		missing = 0;
	while ( entry = registry->next(entry) )
		if ( entry->groupBody->flags.isRule )
			{
			i = 1;
			while ( term = entry->get(i) )
				{
				if ( term->groupBody->flags.isRule && !term->getRStuff() )
					{
					::fprintf(stderr,"AUDIT MISSTERM %s [%s] %s -- isRule term, no rStuff\n",entry->groupBody->tag,::toStringFromInt(i),term->groupBody->tag);
					missing++;
					}
				i++;
				}
			}
	return missing;
}

/*  A NO-ARGUMENT CALL HANDS BACK THE COMMAND NODE ITSELF -- that is the test for
    "no argument given", and it is asked of the REGISTRY, not the tag. Run it AFTER
    the definitions are in place.   measure.auditRStuff  */
extern "C" GroupItem *auditRStuff(GroupItem *argument)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*registry = 0;
GroupItem 	*target = 0;
int 		missRules = 0;
int 		missTerms = 0;
int 		loose = 0;
int 		unconsumed = 0;
	target = argument;
	if ( isGROUP(target->groupBody->flags.data) )
		target = target->getGroup();
	if ( target->groupBody->registry == ruler->commands )
		target = 0;
	if ( target )
		{
		missRules = ::auditMissingRules(target);
		missTerms = ::auditMissingTerms(target);
		loose = ::auditSpurious(target);
		unconsumed += ::auditUnconsumed(target);
		::fprintf(stderr,"AUDIT %s: %s missing rules, %s missing terms, %s loose, %s unconsumed\n",target->groupBody->tag,::toStringFromInt(missRules),::toStringFromInt(missTerms),::toStringFromInt(loose),::toStringFromInt(unconsumed));
		}
	else {
		while ( registry = ruler->registries->next(registry) )
			{
			missRules += ::auditMissingRules(registry);
			missTerms += ::auditMissingTerms(registry);
			loose += ::auditSpurious(registry);
			unconsumed += ::auditUnconsumed(registry);
			}
		/*  ⚠ REPORTED UNCONDITIONALLY AND WITH ITS VALUE (rule H4). An absence
		check on the UNCONSUMED lines would go green the day the emitter is
		deleted; a count that is always printed and asserted at zero cannot.  */
		::fprintf(stderr,"AUDIT all registries: %s missing rules, %s missing terms, %s loose, %s unconsumed\n",::toStringFromInt(missRules),::toStringFromInt(missTerms),::toStringFromInt(loose),::toStringFromInt(unconsumed));
		}
	return argument;
}

/*  TERM and LOOSE are TWO populations and must not be totalled together -- only
    LOOSE is a defect.   measure.auditMissingRules  */
extern "C" int auditSpurious(GroupItem *registry)
{
GroupItem 	*entry = 0;
GroupItem 	*term = 0;
int 		i = 0;
int 		spurious = 0;
	while ( entry = registry->next(entry) )
		{
		if ( !entry->groupBody->flags.isRule && entry->getRStuff() )
			{
			::fprintf(stderr,"AUDIT LOOSE    %s/%s -- not a rule, not a rule term, has rStuff\n",registry->groupBody->tag,entry->groupBody->tag);
			spurious++;
			}
		i = 1;
		while ( term = entry->get(i) )
			{
			if ( !term->groupBody->flags.isRule && term->getRStuff() )
				if ( entry->groupBody->flags.isRule )
					::fprintf(stderr,"AUDIT TERM     %s [%s] %s -- rule TERM, not isRule, has rStuff\n",entry->groupBody->tag,::toStringFromInt(i),term->groupBody->tag);
				else {
					::fprintf(stderr,"AUDIT LOOSE    %s [%s] %s -- not a rule, not a rule term, has rStuff\n",entry->groupBody->tag,::toStringFromInt(i),term->groupBody->tag);
					spurious++;
					}
			i++;
			}
		}
	return spurious;
}

/*  an install attribute found in a rule's TERM LIST proves it was never a command
    in that context. Its own check, not MISSTERM's.   measure.auditUnconsumed  */
extern "C" int auditUnconsumed(GroupItem *registry)
{
GroupItem 	*entry = 0;
GroupItem 	*term = 0;
int 		i = 0;
int 		found = 0;
	while ( entry = registry->next(entry) )
		if ( entry->groupBody->flags.isRule )
			{
			i = 1;
			while ( term = entry->get(i) )
				{
				if ( ::compare(term->groupBody->tag,"parseMethod") == 0 || ::compare(term->groupBody->tag,"parseTerms") == 0 )
					{
					::fprintf(stderr,"AUDIT UNCONSUMED %s [%s] %s -- install attribute survived as a TERM; it was not a command where this grammar was read\n",entry->groupBody->tag,::toStringFromInt(i),term->groupBody->tag);
					found++;
					}
				i++;
				}
			}
	return found;
}

/*  prints its counts UNCONDITIONALLY (rule H4): zero pending is a reportable
    answer here, not a silence.   measure.bodyCensus  */
extern "C" GroupItem *bodyCensus(GroupItem *ignored)
{
GroupItem 	*reg = 0;
GroupItem 	*entry = 0;
int 		pending = 0;
int 		compiled = 0;
int 		active = 0;
int 		stray = 0;
int 		total = 0;
	reg = GroupControl::groupController->getRegistry("GenBodies");
	if ( reg->groupBody->groupList )
		while ( entry = reg->next(entry) )
			{
			total = total + 1;
			if ( entry->getCount() == 1 )
				pending = pending + 1;
			else
			if ( entry->getCount() == 3 )
				compiled = compiled + 1;
			else
			if ( entry->getCount() == 2 )
				active = active + 1;
			else	stray = stray + 1;
			}
	::fprintf(stderr,"CORPUS pending %s compiled %s commissioned %s stray %s total %s\n",::toStringFromInt(pending),::toStringFromInt(compiled),::toStringFromInt(active),::toStringFromInt(stray),::toStringFromInt(total));
	return GroupControl::groupController->groupRules->trueResult;
}

/*  ⚠ definingRule() IS ASSIGNED TO A LOCAL, NEVER TESTED INLINE -- the inline
    form does not parse.   measure.canonOf  */
extern "C" GroupItem *canonOf(GroupItem *argument)
{
GroupItem 	*canon = 0;
	if ( !argument )
		{
		::fprintf(stderr,"canonOf: no field passed in\n");
		return 0;
		}
	canon = argument->definingRule();
	if ( !canon )
		{
		::fprintf(stderr,"canonOf: %s resolved to nothing\n",argument->groupBody->tag);
		return 0;
		}
	/*  ⚠ POINTERS, NOT TAGS, AND THE TRIAL IS WHY. On 2026-08-22 this
	function reported `canonOf: Braced -> Braced` and that sentence was
	USELESS: the whole question was whether the catalog face and canon are
	the SAME NODE, and two nodes of one rule share a tag by construction.
	A resolver that reports names cannot answer a question about identity.
	Passthrough because %p on a GroupItem* is not sayable in tok.  */
	
	::fprintf(stderr,"canonOf: %s face=%p canon=%p  %s  faceStuff=%p canonStuff=%p canonParseMethod=%p\n",
	argument->groupBody->tag,(void*)argument,(void*)canon,
	argument == canon ? "SAME NODE" : "DIFFERENT NODES",
	(void*)argument->rStuff,(void*)canon->rStuff,
	canon->rStuff ? (void*)canon->rStuff->parseMethod : (void*)0);
	
	return canon;
}

/*  SAME MUST EQUAL BINDS, and the row asserts a NON-ZERO total too, because 0 of 0
    is agreement between two absences. ⚠ It reads the counters through
    GroupControl::groupController->groupRules -- a class member, NOT a file static,
    which is what lets this live outside the GroupRules TU at all.
    measure.chanReport  */
extern "C" GroupItem *chanReport(GroupItem *input)
{
	
	::fprintf(stderr,"=== ARGCHANNEL binds = %d same = %d ===\n",GroupControl::groupController->groupRules->chanBinds,GroupControl::groupController->groupRules->chanSame);
	::fflush(stderr);
	
	return GroupControl::groupController->groupRules->trueResult;
}

/*  RELOCATE-THEN-NULL IS STRUCTURAL: the null must be unreachable until the
    relocation is verified. It REFUSES rather than substitutes.   measure.evictAction  */
extern "C" GroupItem *evictAction(GroupItem *field)
{
RuleStuff 	*ruleStuff = field->getRStuff();
char 		*outcome = "no-rstuff";
int 		doEvict = 0;
	if ( ruleStuff )
		{
		
		GroupItem *(*am)(GroupItem *) = ruleStuff->actionMethod;
		GroupItem *(*gm)(GroupItem *) = field->groupBody->gMethod;
		if      ( !gm )        outcome = (char *)"already-vacant";
		else if ( !am )        outcome = (char *)"REFUSED-unparked";
		else if ( am != gm )   outcome = (char *)"REFUSED-mismatch";
		else                 { outcome = (char *)"evicted"; doEvict = 1; }
		
		}
	::fprintf(stderr,"EVICT %s %s\n",field->groupBody->tag,outcome);
	if ( doEvict )
		field->setMethod((GroupItem*(*)(GroupItem*))0);
	return field;
}

/*  labelMinters -- HOW MANY OF THIS RULE'S SUB-TERMS WILL MINT A LABEL. The
    condition is copied from checkInput, not from the spelling.   measure.labelMinters  */
extern "C" int labelMinters(GroupItem *rule)
{
GroupItem 	*grup = 0;
RuleStuff 	*termStuff = 0;
int 		minters = 0;
	if ( !rule )
		return 0;
	while ( grup = rule->next(grup) )
		{
		if ( grup->groupBody->flags.noPrint )
			continue;
		termStuff = grup->getRStuff();
		if ( termStuff && termStuff->noLabel )
			continue;
		if ( grup->groupBody->flags.isRule && grup->groupBody->flags.hasMembers && !grup->groupBody->flags.binType )
			continue;
		minters++;
		}
	return minters;
}

/*  WHAT A BLOCK HANDS BACK, and whether the thing it hands back is a VALUE or a
    SIGNAL. parseTrace gated. ⚠ It READS the state at the foot of the walk; it does not
    re-derive which arm ended it. ⚠ No percent-dash in the format string (bear-trap
    #40).   measure.measureBlockResult  */
extern "C" GroupItem *measureBlockResult(GroupItem *input, GroupItem *result, int stopped)
{
	
	if ( GroupControl::groupController->groupRules->parseTrace )
	::fprintf(stderr,"BLOCKRESULT items=%d stopped=%d result=%s isBranch=%d refused=%d\n",
	(input && input->groupBody->groupList) ? (int)input->groupBody->groupList->listLength : 0,
	stopped,
	result ? result->groupBody->tag : "(null)",
	result ? (int)result->groupBody->flags.isBranch : -1,
	GroupControl::groupController->groupRules->refused);
	
	return result;
}

/*  WHAT opDot RECEIVES ON THE RIGHT. parseTrace gated. The accessor family turns on
    one test -- `argument.registry == groupFields` -- and everything else is a
    subscript by text, so this prints the RIGHT operand's registry membership, its
    gCount and its tag, plus the target it will read from. ⚠ No percent-dash in the
    format string (bear-trap #40).   measure.measureDotOperands  */
extern "C" GroupItem *measureDotOperands(GroupItem *argument, GroupItem *target)
{
	
	if ( GroupControl::groupController->groupRules->parseTrace )
	::fprintf(stderr,"DOTOPERANDS right=%s rightAt=%p isGroupField=%d gCount=%d rightData=%d left=%s leftAt=%p\n",
	argument ? argument->groupBody->tag : "(null)",
	(void*)argument,
	(argument && argument->groupBody->registry == GroupControl::groupController->groupRules->groupFields) ? 1 : 0,
	argument ? (int)argument->groupBody->gCount : -1,
	argument ? (int)argument->groupBody->flags.data : -1,
	target ? target->groupBody->tag : "(null)",
	(void*)target);
	
	return argument;
}

/*  THE ACTION SEAT, BEFORE THE FIRE -- the label's isLabel bit on the way IN, then the
    fire marker itself, so the pair brackets whatever the action prints. parseTrace-gated,
    inert otherwise. ⚠ No percent-dash in the format string (bear-trap #40).
    measure.measureFireLabelActionIn  */
extern "C" GroupItem *measureFireLabelActionIn(GroupItem *field, GroupItem *myLabel)
{
	
	if ( GroupControl::groupController->groupRules->parseTrace && field )
	{
	::fprintf(stderr,"    fireLabel IN  %s isLabel=%d\n",
	field->groupBody->tag,
	(myLabel && myLabel->groupBody->flags.isLabel) ? 1 : 0);
	::fprintf(stderr,"  ACTFIRE fireLabelMethod %s\n",field->groupBody->tag);
	// labelKids how many children the label carries AT THE FIRE -- the direct witness that a nested call of the same rule left the outer label intact (F-114)
	::fprintf(stderr,"    LABELKIDS %s n=%d\n",field->groupBody->tag,
	(myLabel && myLabel->groupBody->groupList) ? myLabel->groupBody->groupList->listLength : 0);
	}
	
	return field;
}

/*  THE ACTION SEAT, AFTER THE FIRE -- whether the node coming BACK is the node that went
    in, and whether it still carries isLabel. A NULL is printed as NULL and never as
    isLabel=0: the two say different things and one channel may not carry both.
    parseTrace-gated, inert otherwise. ⚠ No percent-dash in the format string
    (bear-trap #40).   measure.measureFireLabelActionOut  */
extern "C" GroupItem *measureFireLabelActionOut(GroupItem *field, GroupItem *myLabel)
{
	
	if ( GroupControl::groupController->groupRules->parseTrace && field )
	{
	if ( myLabel )
	::fprintf(stderr,"    fireLabel OUT %s isLabel=%d tag=%s\n",
	field->groupBody->tag,
	myLabel->groupBody->flags.isLabel != 0,
	myLabel->groupBody->tag);
	else
	::fprintf(stderr,"    fireLabel OUT %s NULL\n",field->groupBody->tag);
	}
	
	return field;
}

/*  THE CAPTURE SEAT in GroupItem's fireLabelMethod -- printed BEFORE captureSpan, so
    the capture's own comparator line sits between this line and measureFireLabelFork's.
    parseTrace-gated, inert otherwise. ⚠ It reads the node it is handed and re-derives
    nothing. ⚠ No percent-dash in the format string (bear-trap #40).
    measure.measureFireLabelEntry  */
extern "C" GroupItem *measureFireLabelEntry(GroupItem *field)
{
	
	if ( GroupControl::groupController->groupRules->parseTrace && field )
	::fprintf(stderr,"  CAPFIRE fireLabelMethod %s tokened=%d\n",
	field->groupBody->tag,
	field->groupBody->flags.tokened != 0);
	
	return field;
}

/*  THE FORK SEAT in GroupItem's fireLabelMethod -- the four flags the action fork below
    it reads, printed before it forks. parseTrace-gated, inert otherwise. ⚠ The label is
    PASSED IN rather than re-read off the stuff, because the question is what the fork
    saw. ⚠ No percent-dash in the format string (bear-trap #40).
    measure.measureFireLabelFork  */
extern "C" GroupItem *measureFireLabelFork(GroupItem *field, GroupItem *myLabel)
{
	
	if ( GroupControl::groupController->groupRules->parseTrace && field )
	::fprintf(stderr,"  fireLabelMethod %s isMethod=%d label=%d deferred=%d parseACTION=%d\n",
	field->groupBody->tag,
	isMethod(field->groupBody->flags.instructType) != 0,
	myLabel != 0,
	field->groupBody->flags.deferred != 0,
	parseACTION(field->groupBody->flags.methodType) != 0);
	
	return field;
}

/*  THE FRAME SEAT in runRule -- the rule, the field, and the stuff/label chain the
    fork below is about to read. parseTrace-gated, inert otherwise. ⚠ No percent-dash in the format string -- that
    token closes passthrough (bear-trap #40).   measure.measureFrameProbe  */
extern "C" GroupItem *measureFrameProbe(GroupItem *field, GroupItem *rule)
{
	
	if ( GroupControl::groupController->groupRules->parseTrace )
	::fprintf(stderr,"FRAMEPROBE rule=%s field=%p fieldTag=%s fieldParent=%p fieldStuff=%p fieldStuffLabel=%p fieldStuffLabelTag=%s ruleSTUFF=%p\n",
	rule ? rule->groupBody->tag : "(none)",
	(void*)field,
	field ? field->groupBody->tag : "(none)",
	field ? (void*)field->parent : (void*)0,
	field ? (void*)field->rStuff : (void*)0,
	(field && field->rStuff) ? (void*)field->rStuff->label : (void*)0,
	(field && field->rStuff && field->rStuff->label) ? field->rStuff->label->groupBody->tag : "(none)",
	(void*)GroupControl::groupController->groupRules->ruleSTUFF);
	
	return field;
}

/*  THE PER-KIND ARM WITNESS. Names the kind-specific operator method that ran and the
    target it ran on, so a fixture can count the fork -- which is value-transparent by
    construction, so nothing but a count can see it. Armed by INCANT_KIND_PROBE, inert
    otherwise. Reads what it is handed; re-derives nothing.
    measure.measureKindArm  */
extern "C" GroupItem *measureKindArm(char *arm, GroupItem *field)
{
	
	if ( ::getenv("INCANT_KIND_PROBE") && field )
	::fprintf(stderr,"KINDARM %s tag=%s data=%s\n",
	arm, field->groupBody->tag ? field->groupBody->tag : "(untagged)",
	::dataName(field->groupBody->flags.data));
	
	return field;
}

/*  TEMPORARY, parseTrace-gated. Prints at the MINT so an outer activation's line
    brackets its inner one's: distinctness is an address comparison, survival is the
    same address appearing again at measureLabelProbe. ⚠ No percent-dash in the format
    string -- that token closes passthrough (bear-trap #40).   measure.measureLabelMint  */
extern "C" GroupItem *measureLabelMint(GroupItem *field, GroupItem *myLabel, GroupItem *into)
{
	
	if ( GroupControl::groupController->groupRules->parseTrace )
	::fprintf(stderr,"LABELMINT %s at=%p into=%s intoAt=%p intoLen=%d\n",
	field->groupBody->tag,(void*)myLabel,
	into ? into->groupBody->tag : "(none)",(void*)into,
	(into && into->groupBody->groupList) ? (int)into->groupBody->groupList->listLength : 0);
	
	return field;
}

/*  ⚠ NOT TEMPORARY -- genLadder/pop.sh PINS THIS LINE BY EXACT STRING (trigDO arms
    1 and 2), so its format is a fleet target and changing it is a re-pin owed a
    sentence (rule H6). parseTrace-gated. ⚠ No percent-dash in the format string
    (bear-trap #40).   measure.measureLabelProbe  */
extern "C" GroupItem *measureLabelProbe(GroupItem *field, GroupItem *myLabel, GroupItem *into, GroupItem *result, int yielded)
{
	
	if ( GroupControl::groupController->groupRules->parseTrace )
	::fprintf(stderr,"LABELPROBE %s minted=%s mintedLen=%d into=%s chainTrue=%d yielded=%d at=%p\n",
	field->groupBody->tag,
	myLabel ? myLabel->groupBody->tag : "(none)",
	(myLabel && myLabel->groupBody->groupList) ? (int)myLabel->groupBody->groupList->listLength : 0,
	into ? into->groupBody->tag : "(none)",
	::truthOf(result),
	yielded,
	(void*)myLabel);
	
	return field;
}

/*  THE DRIVE STRING'S EXTENT, RECORDED ONCE SO EVERY LATER POINT CAN ASK "IS THE MARK
    STILL IN HERE". It writes ONLY to the instrument's own static and nothing the program
    reads, so it witnesses without deciding. SEQ 166. parseTrace-gated.
    measure.measureMarkArm  */
extern "C" GroupItem *measureMarkArm(GroupItem *driveNode)
{
	
	if ( GroupControl::groupController->groupRules->parseTrace && driveNode )
	{
	gMarkDriveBase = driveNode->getText();
	gMarkDriveLen  = gMarkDriveBase ? (long)::strlen(gMarkDriveBase) : 0;
	::fprintf(stderr,"  MARKARM drive base=%p len=%ld text=[%s]\n",
	(void*)gMarkDriveBase, gMarkDriveLen,
	::getDebugText(gMarkDriveBase,20));
	}
	
	return driveNode;
}

/*  atRuleMark AT A NAMED POINT: the pointer, WHICH BUFFER it is in, and the next 20
    characters. The buffer answer is the whole point -- text that merely looks plausible
    is not proof the mark is in the right buffer, and on this road it has been seen to
    walk out of the diverted string entirely. SEQ 166. parseTrace-gated.
    measure.measureMarkPoint  */
extern "C" GroupItem *measureMarkPoint(char *where)
{
	
	GroupRules *r = GroupControl::groupController->groupRules;
	if ( r->parseTrace )
	{
	char *m = r->atRuleMark;
	const char *inside = "?";
	if ( gMarkDriveBase && m >= gMarkDriveBase && m <= gMarkDriveBase + gMarkDriveLen )
	inside = "DRIVE-STRING";
	else if ( m ) inside = "not-in-drive";
	else          inside = "NULL";
	::fprintf(stderr,"  MARKPT %s mark=%p in=%s diverted=%d level=%s text=[%s]\n",
	where, (void*)m, inside,
	r->inputDiverted ? 1 : 0,
	(r->sourceFILE ? r->sourceFILE->groupBody->tag : "(none)"),
	::getDebugText(m,20));
	}
	
	return 0;
}

/*  TEMPORARY, parseTrace-gated. Which parent can a parseMethod see from the field
    handed in -- the structural one, or the per-invocation parse-time one. Prints
    both with POINTERS, because the discriminator is recursion: one structural node
    in flight at two depths prints the same address twice. ⚠ No percent-dash in the
    format string (bear-trap #40).   measure.measureParentProbe  */
extern "C" GroupItem *measureParentProbe(GroupItem *field)
{
	
	if ( GroupControl::groupController->groupRules->parseTrace )
	::fprintf(stderr,"PARENTPROBE %s self=%p parent=%p parentTag=%s stuff=%p parentLabel=%p parentLabelTag=%s\n",
	field->groupBody->tag,
	(void*)field,
	(void*)field->parent,
	field->parent ? field->parent->groupBody->tag : "(none)",
	(void*)field->rStuff,
	field->rStuff ? (void*)field->rStuff->parentLabel : (void*)0,
	(field->rStuff && field->rStuff->parentLabel) ? field->rStuff->parentLabel->groupBody->tag : "(none)");
	
	return field;
}

/*  WHAT parseRule's SUCCESS TEST IS ACTUALLY READING: the rule, the node the body
    returned, and what truthOf makes of it. This settles row 1 independently of any
    crash. parseTrace-gated. ⚠ No percent-dash in the format string (bear-trap #40).
    measure.measureParseResult  */
extern "C" GroupItem *measureParseResult(GroupItem *field, GroupItem *result)
{
	
	if ( GroupControl::groupController->groupRules->parseTrace )
	::fprintf(stderr,"  PARSERESULT rule=%s result=%p tag=%s truthOf=%d\n",
	(field ? field->groupBody->tag : "(none)"),
	(void*)result,
	(result ? result->groupBody->tag : "(null)"),
	(result ? ::truthOf(result) : -1));
	
	return result;
}

/*  WHICH BRANCH OF opPlusEQ A FIRE TOOK, with the target's kind and shape and the
    argument's. The census instrument for the per-kind += split: it is the before-
    picture of every pre-switch branch, and it goes silent as members take them.
    Armed by INCANT_PEQ_PROBE, inert otherwise. Reads what it is handed.
    measure.measurePlusEQBranch  */
extern "C" GroupItem *measurePlusEQBranch(char *branch, GroupItem *target, GroupItem *argument)
{
	
	if ( ::getenv("INCANT_PEQ_PROBE") && target )
	::fprintf(stderr,"PEQBRANCH %s tkind=%s tstruct=%d tRule=%d tag=%s akind=%s aList=%d\n",
	branch, ::dataName(target->groupBody->flags.data),
	(target->groupBody->flags.binType || target->groupBody->groupList) ? 1 : 0,
	(target->groupBody->flags.isRule || target->groupBody->flags.actionType) ? 1 : 0,
	target->groupBody->tag ? target->groupBody->tag : "(untagged)",
	argument ? ::dataName(argument->groupBody->flags.data) : "(null)",
	(argument && isLIST(argument->groupBody->flags.binType)) ? 1 : 0);
	
	return target;
}

/*  measure.measurePlusEQWrite  */
extern "C" GroupItem *measurePlusEQWrite(GroupItem *field)
{
	
	if ( GroupControl::groupController->groupRules->parseTrace && field )
	::fprintf(stderr,"PEQWRITE tag=%s field=%p body=%p data=%d count=%d jitting=%d isCopy=%d isVirtual=%d\n",
	field->groupBody->tag ? field->groupBody->tag : "(untagged)",
	(void*)field, (void*)field->groupBody,
	(int)field->groupBody->flags.data,
	(int)field->groupBody->gCount,
	(int)GroupControl::groupController->groupRules->jitting,
	(int)field->options.isCopy,
	(int)field->groupBody->flags.isVirtual);
	
	return field;
}

/*  THE TWO STORE SEATS, printed as RAW POINTERS so they are comparable with addrOf's
    `raw` columns across instruments -- the small-integer tables are per-instrument and
    two of them cannot be compared. parseTrace-gated, inert otherwise.
    ⚠ Each reads the field it is HANDED and re-derives nothing.
    ⚠ No percent-dash in any format string (bear-trap #40).
    measure.measurePlusPlusWrite  */
extern "C" GroupItem *measurePlusPlusWrite(GroupItem *field)
{
	
	if ( GroupControl::groupController->groupRules->parseTrace && field )
	::fprintf(stderr,"PPWRITE tag=%s field=%p body=%p data=%d count=%d jitting=%d isCopy=%d isVirtual=%d\n",
	field->groupBody->tag ? field->groupBody->tag : "(untagged)",
	(void*)field, (void*)field->groupBody,
	(int)field->groupBody->flags.data,
	(int)field->groupBody->gCount,
	(int)GroupControl::groupController->groupRules->jitting,
	(int)field->options.isCopy,
	(int)field->groupBody->flags.isVirtual);
	if ( GroupControl::groupController->groupRules->parseTrace && field )
	::fprintf(stderr,"PPWRITE   isIterator=%d fLAG=%d isGROUP=%d hasAttributes=%d hasMembers=%d\n",
	(int)field->groupBody->flags.isIterator,
	(int)field->groupBody->flags.fLAG,
	isGROUP(field->groupBody->flags.data) ? 1 : 0,
	(int)field->groupBody->flags.hasAttributes,
	(int)field->groupBody->flags.hasMembers);
	
	return field;
}

/*  THE FORK ABOVE runRule, and it prints the node the NAME actually reached --
    not the node a subscript reaches. parseTrace-gated.
    ⚠ THE `arm=` STRING RE-DERIVES runOP's LADDER AND MUST BE EDITED WITH IT. It went
    stale within the hour on 2026-09-10: the door widened to hasNewParse and this still
    said arm=NONE for the node that had just gone through. A witness that recomputes its
    subject's decision drifts from it silently.   measure.measureRuleDispatch ⚠ No percent-dash in the
    format string (bear-trap #40).   measure.measureRuleDispatch  */
extern "C" GroupItem *measureRuleDispatch(GroupItem *op, GroupItem *target, GroupItem *arg)
{
	
	if ( GroupControl::groupController->groupRules->parseTrace && target )
	::fprintf(stderr,"RULEDISPATCH %s at=%p body=%p isRule=%d binType=%d hasNewParse=%d actionType=%d isMethod=%d isOperator=%d arm=%s\n",
	target->groupBody->tag,
	(void*)target,
	(void*)target->groupBody,
	target->groupBody->flags.isRule,
	target->groupBody->flags.binType,
	target->groupBody->flags.hasNewParse,
	target->groupBody->flags.actionType,
	isMethod(target->groupBody->flags.instructType) ? 1 : 0,
	isOperator(target->groupBody->flags.instructType) ? 1 : 0,
	(op && isOperator(op->groupBody->flags.instructType)) ? "operator"
	: (op && isMethod(op->groupBody->flags.instructType)) ? "opMethod"
	: target->groupBody->flags.hasNewParse ? "runRule"
	: target->groupBody->flags.isRule ? "runRule"
	: target->groupBody->flags.actionType ? "runAction"
	: isMethod(target->groupBody->flags.instructType) ? "method"
	: "NONE");
	
	return target;
}

/*  THE DOOR SEAT in runRule -- WHICH DOOR a rule arrived through, which is the one
    question the dispatch fork above cannot answer. parseTrace-gated, inert otherwise.
    ⚠ IT READS THE STATE IT IS HANDED AND NAMES NO ARM. measureRuleDispatch already
    carries the re-derived `arm=` string and the warning about what that cost; this seat
    prints the two flags the fork will read and lets the reader do the forking.
    ⚠ Null-safe on BOTH operands, which the kant line it replaced was not: that line
    read field.data behind a parseTrace gate, so a null field was a crash waiting for
    somebody to turn tracing on. ⚠ No percent-dash in the format string (bear-trap #40).
    measure.measureRuleDoor  */
extern "C" GroupItem *measureRuleDoor(GroupItem *field, GroupItem *rule)
{
	
	if ( GroupControl::groupController->groupRules->parseTrace )
	::fprintf(stderr,"  runRule DOOR on %s field=%d fieldData=%d hasNewParse=%d gMethod=%d\n",
	rule ? rule->groupBody->tag : "(none)",
	field != 0,
	(field && field->groupBody->flags.data) != 0,
	(rule && rule->groupBody->flags.hasNewParse) != 0,
	(rule && rule->groupBody->gMethod) != 0);
	
	return field;
}

/*  WHO ASKED THE PARSE TO STOP, and by which verb. parseTrace gated. stopParsingInput
    serves both `stop` and `bail`, and the two are told apart by the node handed in --
    so this prints that node's TAG, which is the discriminator itself, and NOT a
    re-derived verdict.   measure.measureStopCaller  */
extern "C" GroupItem *measureStopCaller(GroupItem *caller)
{
	
	if ( GroupControl::groupController->groupRules->parseTrace )
	::fprintf(stderr,"STOPCALLER tag=%s node=%p diverted=%d\n",
	caller ? (caller->groupBody->tag ? caller->groupBody->tag : "(untagged)") : "(null)",
	(void*)caller,
	GroupControl::groupController->groupRules->inputDiverted ? 1 : 0);
	
	return caller;
}

/*  WHICH ARM OF aCTionTokenXP's DISPATCH A TERM TOOK, and whether the dot it carries is
    the LEADING form. parseTrace gated. ⚠ It READS the arm it is handed rather than
    re-deriving the ladder -- the callout convention's fourth sentence, paid for by
    measureRuleDispatch going stale. ⚠ No percent-dash in the format string (bear-trap
    #40).   measure.measureTokenArm  */
extern "C" GroupItem *measureTokenArm(char *arm, GroupItem *ANYtoken, GroupItem *InvokeArg, GroupItem *unary)
{
	
	if ( GroupControl::groupController->groupRules->parseTrace )
	::fprintf(stderr,"TOKENARM %s primary=%s invokeArg=%s invokeList=%d unary=%s\n",
	arm ? arm : "(none)",
	ANYtoken ? ANYtoken->groupBody->tag : "(null)",
	InvokeArg ? InvokeArg->groupBody->tag : "(none)",
	(InvokeArg && InvokeArg->groupBody->groupList) ? 1 : 0,
	unary ? unary->groupBody->tag : "(none)");
	
	return ANYtoken;
}

/*  IT READS THE BOUND POINTER, it does not re-derive the arm. ⚠ `fires` is a table
    over that pointer and goes stale if a builtin ever gains a fire.
    measure.parseClassify  */
extern "C" GroupItem *parseClassify(GroupItem *field)
{
char 	*pcName = "other";
	
	if (!field)                 pcName = (char *)"null-field";
	else if (isREGISTRY(field->groupBody->flags.binType))
	pcName = (char *)"skipped-registry";
	else if (!field->rStuff)    pcName = (char *)"NO-rSTUFF";
	else {
	GroupItem *(*pm)(GroupItem *) = field->rStuff->parseMethod;
	if      (!pm)                    pcName = (char *)"none";
	else if (pm == ::parseUpTo)      pcName = (char *)"parseUpTo";
	else if (pm == ::parseContainer) pcName = (char *)"parseContainer";
	else if (pm == ::parseCondition) pcName = (char *)"parseCondition";
	else if (pm == ::parseAction)    pcName = (char *)"parseAction";
	else if (pm == ::parseRule)      pcName = (char *)"parseRule";
	else if (pm == ::parseAny)       pcName = (char *)"parseAny";
	else if (pm == ::parseCharacter) pcName = (char *)"parseCharacter";
	else if (pm == ::parseSet)       pcName = (char *)"parseSet";
	else if (pm == ::parseString)    pcName = (char *)"parseString";
	}
	
	::fprintf(stderr,"PC %s %s\n",pcName,field->groupBody->tag);
	
	if ( field ) {
	const char *acted = "n/a", *hung = "n/a", *fires = "n/a";
	GroupItem *actor = field->get("builtinActoR");
	if ( field->rStuff ) {
	GroupItem *(*am)(GroupItem *) = field->rStuff->actionMethod;
	GroupItem *(*pm)(GroupItem *) = field->rStuff->parseMethod;
	acted = am ? "parked" : "none";
	hung  = actor ? "yes" : "no";
	if      ( !am )                  fires = "nothing-parked";
	else if ( pm == ::parseRule )    fires = "body";
	else if ( pm == ::parseAction )  fires = "self";
	else                             fires = "NEVER";
	}
	::fprintf(stderr,"PA act=%s hung=%s fires=%s %s\n",
	acted,hung,fires,field->groupBody->tag);
	}
	
	return field;
}

/*  reports POINTERS, never names -- two faces of one rule share a tag by
    construction, so names cannot answer identity.   measure.probeNode  */
extern "C" GroupItem *probeNode(GroupItem *argument)
{
GroupItem 	*probed = 0;
	if ( !argument )
		{
		::fprintf(stderr,"probeNode: no field passed in\n");
		return 0;
		}
	probed = argument;
	
	RuleStuff *rs = probed->rStuff;
	GroupItem *pl = rs ? rs->parentLabel : (GroupItem *)0;
	::fprintf(stderr,"PN %s node=%p body=%p gMethod=%p rStuff=%p parentLabel=%p %s\n",
	probed->groupBody->tag,
	(void*)probed,(void*)probed->groupBody,
	(void*)probed->groupBody->gMethod,
	(void*)rs,(void*)pl,
	pl ? pl->groupBody->tag : (char *)"(none)");
	
	return probed;
}

/*  an instrument, not a feature: every incant accessor is snapshot-by-value, so
    matching text proves text equality and never node identity.   measure.showBody  */
extern "C" GroupItem *showBody(GroupItem *field)
{
	if ( !field )
		{
		::fprintf(stderr,"showBody: no field\n");
		return 0;
		}
	/*  ⚠ NO WIDTH SPECIFIER IN THE FORMAT STRING. A printf width of the form
	percent-minus is the passthrough CLOSE delimiter, so it ends the block
	in the middle of a string literal: tok exits 139 with a zero-byte log
	and the extern canary drops to 0. Measured 2026-08-17. Pad by hand if
	alignment is ever wanted here.  */
	
	::fprintf(stderr,"BODY  %s  node=%p  groupBody=%p\n",
	field->groupBody->tag ? field->groupBody->tag : "(untagged)",
	(void*)field, (void*)field->groupBody);
	::fflush(stderr);
	
	return field;
}

void measure::run()
{
GroupItem 	*node = 0;
	if ( node )
		return;
	return;
}
