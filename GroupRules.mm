#include <Cocoa/Cocoa.h>
#include <dirent.h>
#include <dlfcn.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include "jitContext.h"
#include "OCroutines.h"
#include "StringRoutines.h"
#include "GroupItem.h"
#include "DoubleLinkList.h"
#include "Stak.h"
#include "Buffer.h"
#include "BitMAP.h"
#include "GroupControl.h"
#include "GroupList.h"
#include "GroupBody.h"
#include "regex.h"
#include "RuleStuff.h"
#include "GroupStak.h"
#include "PLGset.h"
#include "PLGrgx.h"
#include "Stylish.h"
#include "measure.h"
#include "GroupDraw.h"
#include "GroupRules.h"

/*******************************************************************************
	The ANYtoken rule action excludes key words and undefined token fields
*******************************************************************************/
extern "C" GroupItem *aCTionANYtoken(GroupItem *input)
{
GroupItem 	*token = 0;
	if ( isGROUP(input->groupBody->flags.data) )
		token = input->getGroup();
	else	token = input;
	if ( token && token->groupBody->registry == GroupControl::groupController->groupRules->keyWords && !token->groupBody->flags.noPrint )
		return 0;
	return input;
}

/*******************************************************************************
	The BlocK rule action.

    // bareReturnValue A BARE `return;` YIELDS THE PRIOR STATEMENT'S VALUE, not the keyword's tag, and the substitution MUST re-stamp isBranch or every break and continue dies. ruleActions.aCTionBlocK.bareReturnValue
*******************************************************************************/
extern "C" GroupItem *aCTionBlocK(GroupItem *input)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*grup = 0;
GroupItem 	*result = 0;
GroupItem 	*prior = 0;
	while ( grup = input->next(grup) )
		{
		prior = result;
		if ( isMethod(grup->groupBody->flags.instructType) )
			result = grup->groupBody->gMethod(grup);
		else	result = grup;
		/*  THE RESULT SLOT (Tony's ruling, 2026-07-31). Under jitting, every
		statement commits the value it just emitted. That is not a
		convenience: the interpreted rule is "an action's value is the LAST
		EXECUTED STATEMENT'S", so a store-on-`return` emitter would return
		garbage from every action that simply ends. Storing per statement is
		what makes the compiled answer match the interpreted one.  */
		if ( ruler->jitting )
			{
			 jitStoreResult(); 
			//  A3 + the statement-local gate: the check is emitted only for a
			//  statement that can actually refuse at RUN time, and the flag is
			//  cleared here so it cannot leak into the next statement.
			 jitEmitRefusedCheck(); gJitStmtCanRefuse = false; 
			}
		/*  ⚠ A REFUSAL STOPS THE BLOCK, and the jitting arm must NOT stop the
		EMIT walk -- same era split as the isBranch check below, and the
		same reason: at emit time the statements after a refusal are
		REACHABLE and must all be emitted. The emitted body does its own
		per-statement check at RUN time.   ruleActions.aCTionBlocK.refusalArm  */
		if ( ruler->refused )
			if ( !ruler->jitting )
				break;
		if ( result && result->groupBody->flags.isBranch )
			{
			if ( prior && result->groupBody->flags.isBranch == 3 && result->groupBody->registry == ruler->keyWords )
				{
				result = prior;
				result->groupBody->flags.isBranch = 3;
				}
			// ⚠ DO NOT let this break run under jitting -- it stops the COMPILER'S walk and
			// every statement after a branch vanishes from the IR   ruleActions.aCTionBlocK.emitWalkMustNotStop
			if ( ruler->jitting )
				continue;
			break;
			}
		}
	if ( result && isGROUP(result->groupBody->flags.data) )
		result = result->groupBody->gGroup;
	return result;
}

/*******************************************************************************
	Rule action for Braced rule.
        Braced      leftBrace="["- ExpressioN rightBrace="]"-;
*******************************************************************************/
extern "C" GroupItem *aCTionBraced(GroupItem *input)
{
GroupItem 	*ExpressioN = input->getLabelGroup("ExpressioN");
	input->clear();
	input->setGroup(ExpressioN);
	input->groupBody->flags.fLAG = 1;
	return input;
}

/*******************************************************************************
	Rule action for BrancH.
*******************************************************************************/
extern "C" GroupItem *aCTionBrancH(GroupItem *input)
{
GroupItem 	*BrancheS = input->getLabelGroup("BrancheS");
GroupItem 	*ExpressioN = input->getLabelGroup("ExpressioN");
GroupItem 	*arg = ExpressioN;
	if ( !arg )
		arg = BrancheS;
	else
	if ( isMethod(arg->groupBody->flags.instructType) )
		arg = arg->groupBody->gMethod(arg);
	// ⚠ THE LINE ABOVE CAN LEAVE arg NULL -- under jitting that method is an emitter
	// and null means I REFUSED, not a node   ruleActions.aCTionBrancH.ke3NullOperand
	if ( !arg )
		arg = BrancheS;
	switch (*BrancheS->groupBody->tag)
		{
		case 'b':
			arg->groupBody->flags.isBranch = 1;
			break;
		case 'c':
			arg->groupBody->flags.isBranch = 2;
			break;
		case 'r':
			arg->groupBody->flags.isBranch = 3;
		}
	// break and return DEGRADE LOUDLY here rather than emitting nothing, and the tag
	// is read DIRECTLY rather than off the flags set above   ruleActions.aCTionBrancH.branchesUnderJit
	/*  ⚠ RETURN IS EMITTED NOW (item 2, Tony 2026-08-05). The degrade arm below
	shrank from "break and return" to "break, and the ONE return case that is
	still unbuilt". jitEmitReturn answers 0 for a return inside an INLINED
	body -- E2, deferred with sanction -- and that is the only path that
	still counts, so the message says which case it was rather than leaving
	a reader to infer it from a construct name that is otherwise covered.  */
	if ( GroupControl::groupController->groupRules->jitting )
		{
		
		if (*BrancheS->groupBody->tag == 'c')       jitEmitContinue();
		else if (*BrancheS->groupBody->tag == 'r') {
		//  ⚠ A RETURN IS A POSITION THAT CONSUMES A VALUE, and jitEmitters'
		//  own standing rule (the note above jitEmitBareRead's callers) is
		//  that EVERY such position invokes the primitive when its operand
		//  is BARE. `return` was not on that list only because it did not
		//  exist when the list was written.
		//  Without this, `return someField;` emits NOTHING -- `if isMethod`
		//  is false for a bare read -- so jitStoreResult finds a null
		//  gJitResult, stores nothing, and the action returns whatever the
		//  PRIOR statement left in the slot. Measured 2026-08-05:
		//  `return ftAcc;` off a base case returned 0, silently, at degrade
		//  count 0. Exactly the shape gIF and both loops already carry.
		if (ExpressioN && !isMethod(ExpressioN->groupBody->flags.instructType))
		::jitEmitBareRead(ExpressioN);
		//  ⚠ E2 BUILT 2026-08-09 -- the rr==0 arm is GONE, not silenced.
		//  jitEmitReturn no longer has an "inside an inlined callee" answer:
		//  an inlined region now carries its own exit block and the return
		//  branches there. A degrade arm nothing can fire is an assertion
		//  nothing can fire, so it is removed rather than left to rot.
		//  -1 keeps its meaning exactly: a mis-sequenced caller, never a
		//  language gap.
		if (::jitEmitReturn() < 0)
		jitDegrade("return REFUSED -- no builder, no epilogue block, or "
		"inlining with no frame. A mis-sequenced caller", input); }
		else    jitDegrade("break under jit -- no emitter yet", input);
		
		}
	return arg;
}

/*******************************************************************************
    THE STDERR SINK. One print mechanism, several destinations -- PrintXP+ is fixed
    and only the sink varies. NO `generating` branch, and that is deliberate.
    ruleActions.aCTionCerR.stderrSink
*******************************************************************************/
extern "C" GroupItem *aCTionCerR(GroupItem *input)
{
GroupItem 	*stuff = input->getLabelGroup("stuff");
Buffer 		*buffer = (Buffer*)GroupControl::groupController->groupRules->bufferSTAK->pop();
	// ⚠ MUST SIT AFTER THE WHOLE DECLARATION BLOCK -- inside one, this line wiped
	// GroupRules.h's extern block to zero   ruleActions.degradeByDefault
	if ( GroupControl::groupController->groupRules->jitting )
		jitDegrade("cerr under jit -- no emitter, sink fires at emit time",input);
	if ( !buffer )
		buffer = new Buffer("cerr buffer");
	appendPrintXP(stuff,buffer);
	return ::opCerr(input,buffer);
}

/*******************************************************************************
    CheckFor is a debugging tool. It matches its text and returns null
    if it matches so it fails even if it succeeds.
    It should be entered as a rule attribute like: CheckFor?="some text".
    It enables you to stop the parse at some arbitrary point in the input
    stream and you can modify it to do whatever before it returns (like
    turn on debugAllRules). It runs in the parse not at runtime, unlike
    the similar opDoNothing operator that runs at code execution.
*******************************************************************************/
extern "C" GroupItem *aCTionCheckFor(GroupItem *input)
{
	GroupControl::groupController->groupRules->debugAllRules = 1;
	return 0;
}

/*******************************************************************************
	CodE rule action Note: box boundaries defined by its left and right attributes
*******************************************************************************/
extern "C" GroupItem *aCTionCodE(GroupItem *rule)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*lefty = rule->get(1);
GroupItem 	*righty = rule->get(2);
GroupItem 	*label = rule->getRStuff()->label;
	if ( lefty && righty )
		{
		char 	*atInput = ruler->atRuleMark;
		char 	*beginBox = 0;
		char 	*endBox = 0;
		char 	*left = lefty->getText();
		char 	*right = righty->getText();
		while ( *atInput && *atInput != *left )
			atInput++;
		if ( *atInput )
			{
			beginBox = atInput;
			atInput++;
			while ( *atInput && *atInput != *right )
				atInput++;
			if ( *atInput )
				endBox = atInput;
			}
		if ( beginBox && endBox++ )
			{
			label->setToken(beginBox,(int)(endBox - beginBox));
			ruler->atRuleMark = endBox;
			}
		else	::fprintf(stderr,"CodE action failed for %s\n",rule->groupBody->tag);
		}
	else	::fprintf(stderr,"CodE action did not find left and right attributes in %s\n",rule->groupBody->tag);
	return label;
}

/*******************************************************************************
    THE EXPLICIT STDOUT SINK. print is DIVERTIBLE, cout is not -- that is the whole
    reason it exists, and routing through opCout is what closes KANT-23.
    ruleActions.aCTionCouT.stdoutSink
*******************************************************************************/
extern "C" GroupItem *aCTionCouT(GroupItem *input)
{
GroupItem 	*stuff = input->getLabelGroup("stuff");
Buffer 		*buffer = (Buffer*)GroupControl::groupController->groupRules->bufferSTAK->pop();
	// ⚠ MUST SIT AFTER THE WHOLE DECLARATION BLOCK -- inside one, this line wiped
	// GroupRules.h's extern block to zero   ruleActions.degradeByDefault
	if ( GroupControl::groupController->groupRules->jitting )
		jitDegrade("cout under jit -- no emitter, sink fires at emit time",input);
	if ( !buffer )
		buffer = new Buffer("cout buffer");
	appendPrintXP(stuff,buffer);
	return ::opCout(input,buffer);
}

/*******************************************************************************
	Immediate method for DEBUG rule
        DEBUG       "debug"- followedBy rules?=NamE+;
*******************************************************************************/
extern "C" GroupItem *aCTionDEBUG(GroupItem *input)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*rules = input->getLabelGroup("rules");
GroupItem 	*GUARD = 0;
GroupItem 	*grup = 0;
	if ( rules )
		while ( grup = rules->next(grup) )
			{
			if ( ::compare(grup->getText(),"GUARD") == 0 )
				{
				GUARD = ruler->trueResult;
				continue;
				}
			if ( GUARD )
				grup->groupBody->flags.debugGuard = 1;
			grup->groupBody->flags.debugged = 1;
			}
	else	ruler->debugAllRules = !ruler->debugAllRules;
	return input;
}

/*******************************************************************************
	Sets the operator method in a do statement
        DO      do- BLOCKing StatemenT while- ExpressioN SemI-;
*******************************************************************************/
extern "C" GroupItem *aCTionDO(GroupItem *input)
{
GroupItem 	*StatemenT = input->getLabelGroup("StatemenT");
GroupItem 	*ExpressioN = input->getLabelGroup("ExpressioN");
GroupItem 	*result = 0;
	if ( GroupControl::groupController->groupRules->jitting )
		{
		 return jitEmitDO(input); 
		}
	do	{
		result = StatemenT->groupBody->gMethod(StatemenT);
		if ( result->groupBody->flags.isBranch )
			{
			// ⚠ TRAILING-CONTINUE GUARD -- one IDENTICAL body in DO, FOR and WhilE, and NOT
			// extractable: the arms are continue/return/break over THIS loop
			// ruleActions.trailingContinueGuard
			if ( isContinue(result->groupBody->flags.isBranch) )
				{
				result = GroupControl::groupController->groupRules->trueResult;
				continue;
				}
			else
			if ( isReturn(result->groupBody->flags.isBranch) )
				return result;
			// BREAK IS CONSUMED HERE -- clearing isBranch is what stops the enclosing
			// block breaking too   ruleActions.breakIsConsumed
			result->groupBody->flags.isBranch = 0;
			if ( result->groupBody->registry == GroupControl::groupController->groupRules->keyWords )
				result = 0;
			break;
			}
		}
	while ( ExpressioN->groupBody->gMethod(ExpressioN) );
	// labelNO, not falseResult: this construct executed NO statement, so it has no
	// value -- and 0 is a value   ruleActions.labelNoNotFalse
	if ( !result )
		result = GroupControl::groupController->groupRules->labelNO;
	return result;
}

/*******************************************************************************
	Immediate method for the Define rule that defines a rule.
*******************************************************************************/
extern "C" GroupItem *aCTionDefinE(GroupItem *input)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*NewGroup = input->get(1);
GroupItem 	*Attributes = input->getLabelGroup("Attributes");
GroupItem 	*CodE = 0;
GroupItem 	*MemberS = input->getLabelGroup("MemberS");
GroupItem 	*grup = 0;
GroupItem 	*item = 0;
	if ( isGROUP(NewGroup->groupBody->flags.data) )
		NewGroup = NewGroup->getGroup();
	/*  THIS IS THE OPERATOR-NAMING SITE. An operator is written in setup as a
	quoted literal, and the swap below is what gives it its symbol as its
	NAME, so it can be matched against the input stream by spelling.
	Measured 2026-08-16 over a whole grammar bootstrap: it fires 55 times,
	every firing is an Operators registry entry, and NOT ONE is a rule. So
	it looks like dead weight beside any literal-handling change and is the
	opposite -- delete it and every operator in the language unnames itself,
	silently. It reads NewGroup, the thing being DEFINED, never the terms
	inside it, which is why labelling literal terms does not reach it.  */
	if ( NewGroup->groupBody->flags.isLiteral )
		{
		NewGroup->groupBody->tag = NewGroup->getText();
		NewGroup->setText((char*)0);
		}
	if ( NewGroup )
		{
		/***********************************************************************
		If currentRegistry and NewGroup is not a registry, add it to the current registry.
		***********************************************************************/
		if ( !NewGroup->groupBody->registry )
			{
			NewGroup->options.affiliation = 0;
			NewGroup->parent = 0;
			}
		if ( ruler->currentRegistry )
			{
			if ( ruler->currentRegistry->groupBody->flags.isRule )
				{
				NewGroup = ruler->currentRegistry->addMember(NewGroup);
				if ( !NewGroup->groupBody->flags.binType )
					NewGroup->groupBody->flags.isRule = 1;
				if ( !NewGroup->getRStuff() )
					NewGroup->setRStuff(new RuleStuff(NewGroup));
				// ⚠ THE PRODUCER OWNS THE INVARIANT: every live rule carries rStuff. Assert here,
				// loudly -- do not soften this into a consumer-side guard   ruleActions.aCTionDefinE.producerOwnsInvariant
				if ( !NewGroup->getRStuff() )
					::fprintf(stderr,"REGISTER: INVARIANT BROKEN -- %s promoted to a rule in registry %s but carries no rStuff. Every live rule must carry rStuff (Mark 3); downstream guards will now read this broken rule as a lawful specimen.\n",NewGroup->groupBody->tag,ruler->currentRegistry->groupBody->tag);
				}
			else
			if ( NewGroup->groupBody->registry != ruler->currentRegistry )
				if ( ruler->currentDefine == NewGroup || !ruler->currentDefine || !ruler->currentDefine->groupBody->flags.addingMembers )
					NewGroup = ruler->currentRegistry->addMember(NewGroup);
			}
		}
	if ( !NewGroup->groupBody->flags.isRule )
		NewGroup->setRStuff((RuleStuff*)0);
	/***********************************************************************
	Process Attributes.
	***********************************************************************/
	if ( Attributes )
		while ( item = Attributes->next(item) )
			if ( item->groupBody->flags.noPrint && immediateACTION(item->groupBody->flags.methodType) )
				{
				/*******************************************************
				if item gets run but is not added to the new group.
				fLAG set so method can verify it is called from a
				definition (some commands can be run as define
				attributes or from the command line).
				*******************************************************/
				item->parent = NewGroup;
				item->groupBody->flags.fLAG = 1;
				item->groupBody->gMethod(item);
				item->groupBody->flags.fLAG = 0;
				}
			else {
				if ( ::compare(item->groupBody->tag,"code") == 0 )
					{
					CodE = item;
					CodE->groupBody->tag = "CodE";
					CodE->groupBody->flags.noPrint = 1;
					}
				/*  ⚠ A DECLARED `argument` IS A RETIRED SPELLING AND REFUSES BY
				NAME. runAction MINTS the binding slot now, so there is
				nothing left to declare. Same shape as iterate's old form:
				the retired spelling does not quietly do something slightly
				different, it says so and names the respell.
				⚠ THE REFUSAL ARMS, and the arm is cleared AT THE DEFINITION
				BOUNDARY rather than by aCTionBlocK -- a refusal is terminal
				for THE UNIT THAT RAISED IT, and at define time that unit is
				the DEFINITION, not the enclosing block. Arming without the
				boundary clear kills every later definition in the file:
				measured 2026-09-05, fleet 171 -> 107.
				ruleActions.aCTionDefinE.argumentRetired  */
				if ( ::compare(item->groupBody->tag,"argument") == 0 )
					::refuse(NewGroup,"a declared `argument` attribute is retired -- delete it; runAction mints the binding slot");
				if ( NewGroup->groupBody->flags.isMacro )
					item->groupBody->flags.noPrint = 1;
				item->groupBody->flags.isInitialized = 1;
				if ( NewGroup->groupBody->flags.isRule && !item->groupBody->flags.binType && !item->groupBody->flags.isRule )
					item->groupBody->flags.isRule = 1;
				if ( item->groupBody->flags.isRule )
					if ( !item->getRStuff() )
						item->setRStuff(new RuleStuff(item));
					else {
						item->setRStuff(new RuleStuff(item->getRStuff()));
						grup = item->parent;
						if ( grup && grup->getRStuff() )
							{
							item->getRStuff()->parentStuff = grup->getRStuff();
							item->getRStuff()->parentLabel = grup->getRStuff()->parentLabel;
							}
						item->getRStuff()->rule = item;
						}
				grup = NewGroup->addAttribute(item);
				}
	/***********************************************************************
	If there is code NewGroup is flagged as coded. The code gets processed
	by processCode() the first time NewGroup is included in an expression.
	***********************************************************************/
	if ( CodE )
		{
		grup = NewGroup->addString("this");
		grup->groupBody->flags.isLocal = 1;
		grup->groupBody->flags.noPrint = 1;
		grup->setGroup(NewGroup);
		grup = NewGroup->addString("tempField");
		grup->groupBody->flags.isLocal = 1;
		grup->groupBody->flags.noPrint = 1;
		if ( NewGroup->groupBody->flags.isMacro )
			{
			CodE->groupBody->gText++;
			CodE->groupBody->gCount -= 2;
			NewGroup->setText(CodE->getText());
			}
		else {
			NewGroup->groupBody->flags.actionType = 2;
			CodE->parent = 0;
			}
		}
	else
	if ( NewGroup->groupBody->flags.isMacro )
		::fprintf(stderr,"ERROR: A macro definition must have code specified as its body\n");
	/***********************************************************************
	Process Members.
	***********************************************************************/
	if ( MemberS )
		while ( item = MemberS->next(item) )
			{
			GroupItem 	*newMember = NewGroup->addMember(item);
			if ( newMember->groupBody->flags.isRule && newMember->getRStuff() && (!newMember->groupBody->flags.data || newMember->groupBody->flags.data > 3) )
				if ( newMember->getRStuff()->max != 1 || newMember->getRStuff()->min != 1 )
					{
					RuleStuff 	*fresh = new RuleStuff(newMember);
					newMember->setRStuff(fresh);
					}
			}
	/*******************************************************************************
	THE CODED TEST WINS -- the arms are ordered, not interchangeable.
	ruleActions.aCTionDefinE.ruleMethodCheck
	*******************************************************************************/
	if ( NewGroup->groupBody->flags.isRule )
		{
		if ( !isREGISTRY(NewGroup->groupBody->flags.binType) )
			{
			if ( isCoded(NewGroup->groupBody->flags.actionType) )
				NewGroup->setMethod(::processAction);
			else
			if ( !isMethod(NewGroup->groupBody->flags.instructType) )
				{
				char 	*methodName = ::concat(2,"aCTion",NewGroup->groupBody->tag);
				void 	*methodAddress = 0;
				if ( methodAddress = ::dlsym(RTLD_SELF,methodName) )
					NewGroup->setMethod((GroupItem*(*)(GroupItem*))methodAddress);
				::free(methodName);
				if ( NewGroup->groupBody->gMethod )
					NewGroup->groupBody->flags.methodType = 1;
				}
			}
		}
	/*******************************************************************************
	THE DEFINITION IS COMPLETE HERE, which is why a term's rStuff is materialised
	at this point and not per-attribute.
	ruleActions.aCTionDefinE.definitionComplete
	*******************************************************************************/
	/***********************************************************************
	DEFINITION MAKES STRUCTURE; RUNTIME MAKES REFERENCE. embedRule() copies an
	embedded RULE and stores anything else as it stands.
	ruleActions.aCTionDefinE.embeddedRuleCopy
	***********************************************************************/
GroupItem 	*term = 0;
int 		t = 1;
	while ( term = NewGroup->get(t) )
		{
		if ( isGROUP(term->groupBody->flags.data) )
			term->embedRule(term->groupBody->gGroup);
		t++;
		}
	// re-mention: the block above hijacks bare-field resolution   bear-trap #42
	input->clearList();
	NewGroup->groupBody->flags.isInitialized = 1;
	if ( NewGroup->groupBody->registry && !NewGroup->parent )
		NewGroup->parent = ruler->currentRegistry;
	if ( NewGroup->groupBody->flags.addingMembers )
		NewGroup->groupBody->flags.addingMembers = 0;
	if ( ruler->currentDefine && ruler->currentDefine->groupBody == NewGroup->groupBody )
		ruler->currentDefine = 0;
	input->setGroup(NewGroup);
	/*  ⚠ THE DEFINITION BOUNDARY. A refusal raised while defining is terminal
	for THE DEFINITION: it is not installed, and the arm is cleared here so
	the NEXT definition in the file is unaffected. One channel -- the same
	`refused` the run-time road uses -- and no non-arming sibling, because a
	second channel is how the two eras would drift.   Tony, 2026-09-05.
	ruleActions.aCTionDefinE.refusalBoundary  */
	if ( ruler->refused )
		{
		if ( ruler->currentRegistry )
			ruler->currentRegistry->remove(NewGroup->groupBody->tag);
		ruler->refused = 0;
		}
	return input;
}

/*******************************************************************************
	ExpressioN rule immediate action. Note: operators including unary operators
    have to preceed their arguments.
        ExpressioN      Token+ SemI?- defer;
*******************************************************************************/
extern "C" GroupItem *aCTionExpressioN(GroupItem *xpList)
{
	/* Thin dispatcher over two mode-handlers (jitXP folded out 2026-06-30, JIT
	unified-emit-on-walk pivot step 1): jitting now falls through to
	interpretXP. jitRunAction still raises generating alongside jitting, so
	generating is checked first — under jitting+generating, generateXP's
	by-reference revisedList still wins; interpretXP only fires under plain
	interpretation or, going forward, under jitting-without-generating. */
	if ( GroupControl::groupController->groupRules->generating )
		return generateXP(xpList);
	return interpretXP(xpList);
}

/*******************************************************************************
	Runs the action associated with a for statement
        Looper=ANYtoken;
        LoopRestrict:
            loopOnAttributes="attributes";
            loopOnMembers="members";;
        FOR         for- followedBy Looper in- reversE?="<-" ExpressioN SemI- LoopRestrict? StatemenT defer;
    At present no loopModifier condition to control loop direction???
*******************************************************************************/
extern "C" GroupItem *aCTionFOR(GroupItem *input)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*Looper = input->get("Looper");
GroupItem 	*ExpressioN = input->get("ExpressioN");
GroupItem 	*reversE = input->get("reversE");
GroupItem 	*LoopOn = 0;
GroupItem 	*LoopRestrict = input->getLabelGroup("LoopRestrict");
GroupItem 	*StatemenT = input->getLabelGroup("StatemenT");
GroupItem 	*grup = 0;
GroupItem 	*result = 0;
int 		restrict = 0;
	// ⚠ MUST SIT AFTER THE WHOLE DECLARATION BLOCK -- inside one, this line wiped
	// GroupRules.h's extern block to zero   ruleActions.degradeByDefault
	if ( ruler->jitting )
		jitDegrade("FOR under jit -- no emitter (iterate's disease, different keyword)",input);
	if ( isGROUP(Looper->groupBody->flags.data) )
		Looper = Looper->getGroup();
	Looper->clear();
	if ( LoopRestrict )
		{
		char 	*restriction = LoopRestrict->getText();
		if ( ::compare(restriction,"attributes") == 0 )
			restrict = 1;
		else
		if ( ::compare(restriction,"members") == 0 )
			restrict = 2;
		}
	LoopOn = ExpressioN;
	while ( isGROUP(LoopOn->groupBody->flags.data) )
		{
		LoopOn = LoopOn->getGroup();
		if ( LoopOn->groupBody->groupList )
			result = LoopOn;
		}
	if ( !LoopOn->groupBody->groupList && result )
		LoopOn = result;
	LoopRestrict = ruler->lastREF->getGroup();
	while ( grup = reversE ? LoopOn->prior(grup) : LoopOn->next(grup) )
		{
		result = 0;
		Looper->setGroup(grup);
		if ( restrict && grup->options.affiliation != restrict )
			continue;
		if ( !LoopOn->groupBody->flags.byRef )
			{
			ruler->lastREF->groupBody->gGroup = grup;
			ruler->lastREF->groupBody->flags.data = 6;
			}
		result = StatemenT->groupBody->gMethod(StatemenT);
		if ( result->groupBody->flags.byRef )
			grup = result->priorInParent;
		if ( result->groupBody->flags.isBranch )
			{
			// ⚠ TRAILING-CONTINUE GUARD -- one IDENTICAL body in DO, FOR and WhilE, and NOT
			// extractable: the arms are continue/return/break over THIS loop
			// ruleActions.trailingContinueGuard
			if ( isContinue(result->groupBody->flags.isBranch) )
				{
				result = ruler->trueResult;
				continue;
				}
			else
			if ( isReturn(result->groupBody->flags.isBranch) )
				return result;
			// BREAK IS CONSUMED HERE -- clearing isBranch is what stops the enclosing
			// block breaking too   ruleActions.breakIsConsumed
			result->groupBody->flags.isBranch = 0;
			if ( result->groupBody->registry == ruler->keyWords )
				result = 0;
			break;
			}
		}
	// labelNO, not falseResult: this construct executed NO statement, so it has no
	// value -- and 0 is a value   ruleActions.labelNoNotFalse
	if ( !result )
		result = ruler->labelNO;
	if ( LoopRestrict )
		if ( !LoopRestrict->groupBody->flags.byRef )
			{
			ruler->lastREF->groupBody->gGroup = LoopRestrict;
			ruler->lastREF->groupBody->flags.data = 6;
			}
		else	ruler->lastREF->clear();
	return result;
}

/*******************************************************************************
	If the parse gets here it failed.
*******************************************************************************/
extern "C" GroupItem *aCTionFailed(GroupItem *input)
{
GroupItem 	*lastStatement = GroupControl::groupController->groupRules->lastStatement;
	// lastStatement is a stable marker set in aCTionStatemenT only on confirmed
	// top-level statement execution (!processingCode) — it survives backtracking,
	// unlike ruleSTUFF.label. Top-level granularity for now; in-block is a future
	// refinement.
	// ⚠ THE LAST CODE ALLOWED TO CRASH IS THE CODE THAT REPORTS CRASHES -- failure
	// reporting must survive its own subject, so nothing here may deref unguarded   ruleActions.aCTionFailed.lastCodeToCrash
	::printf("Rule %s\n",input->groupBody->tag);
	if ( input->getRStuff() )
		::printf("\tFailed at:\t%s\n",::getDebugText(input->getRStuff()->failedAt,40));
	if ( !input->getRStuff() )
		::printf("\tFailed at:  <unavailable -- this subject carries no rStuff; see Ruling D>\n");
	::printf("\ton Line:\t\t%d \n",GroupControl::groupController->groupRules->sourceLINE);
	// added the gText guard (for cases that do not use StatemenT
	if ( lastStatement->groupBody->gText )
		::printf("  Last parsed:  %s\n",lastStatement->getText());
	::stopParsingInput(input);
	return input;
}

/*******************************************************************************
	IF rule action
        IF=if ExpressioN ';'? StatemenT ElsE?;
*******************************************************************************/
extern "C" GroupItem *aCTionIF(GroupItem *input)
{
GroupItem 	*ExpressioN = input->getLabelGroup("ExpressioN");
GroupItem 	*StatemenT = input->getLabelGroup("StatemenT");
GroupItem 	*ElsE = input->getLabelGroup("ElsE");
GroupItem 	*result = ExpressioN;
	if ( GroupControl::groupController->groupRules->jitting )
		{
		 return jitEmitGIF(input); 
		}
	if ( isMethod(result->groupBody->flags.instructType) )
		result = result->groupBody->gMethod(result);
	else	result = ExpressioN;
	// ⚠ REFUSE LOUDLY, NEVER CRASH -- unguarded, `if 1;` exits 139 with zero output   ruleActions.aCTionIF.refuseLoudly
	if ( result && result->groupBody->flags.isInitialized && !StatemenT )
		{
		::fprintf(stderr,"aCTionIF: REFUSING -- the condition parsed but its governed statement is MISSING. Common causes: a // between the condition and the statement (bear-trap #4), an `if <cond>;` with no statement at all, or a rule named in the condition consuming the statement as its input.\n");
		return GroupControl::groupController->groupRules->falseResult;
		}
	if ( result && result->groupBody->flags.isInitialized )
		result = StatemenT->groupBody->gMethod(StatemenT);
	else
	if ( ElsE )
		result = ElsE->groupBody->gMethod(ElsE);
	// labelNO, not falseResult: this construct executed NO statement, so it has no
	// value -- and 0 is a value   ruleActions.labelNoNotFalse
	if ( !result )
		result = GroupControl::groupController->groupRules->labelNO;
	return result;
}

/*******************************************************************************
	The rule action for the Iterate rule
        Iterate     iterate- ANYtoken on- ANYtoken attributes? members? defer;
*******************************************************************************/
extern "C" GroupItem *aCTionIterate(GroupItem *input)
{
GroupItem 	*attributes = input->getLabelGroup("attributes");
GroupItem 	*members = input->getLabelGroup("members");
GroupItem 	*IterSource = input->getLabelGroup("IterSource");
GroupItem 	*iterator = ::unWrap(input->get(1));
GroupItem 	*source = 0;
	// You cannot get here without an iterator, the rule stipulates it
	if ( IterSource )
		{
		// SOURCE REACHED BY LABEL, NEVER BY POSITION
		GroupItem *srcOp = IterSource->getLabelGroup("UnaryOPS");
		if ( source = srcOp ? IterSource->get(2) : IterSource->get(1) )
			if ( isGROUP(source->groupBody->flags.data) )
				source = source->getGroup();
		if ( srcOp )
			if ( ::compare(srcOp->groupBody->tag,"*") == 0 )
				source = ::opDeref(source);
			else	source = ::refuse(source,"iterate: only * may precede the source");
		}
	if ( !source )
		{
		// nullAfterStar    THE CONSUMER OF THE NULL REFUSES
		iterator->groupBody->flags.fLAG = 1;
		return ::refuse(IterSource,"iterate: the source is nothing -- a star on a field that holds no group yields null");
		}
	else
	if ( isGROUP(source->groupBody->flags.data) )
		{
		// argumentBINDING
		if ( source->groupBody->flags.isArgument )
			source = source->getGroup();
		else {
			char 	*why = ::concat(2,"iterate: it holds a pointer, not a list; write *",source->groupBody->tag);
			iterator->groupBody->flags.fLAG = 1;
			return ::refuse(source,why);
			}
		}
	if ( GroupControl::groupController->groupRules->jitting )
		{
		// emitThenFallThru -- the only gate in the tree that does not return, and deliberately so.
		::jitEmitIterate(input);
		}
	if ( iterator && source && source->groupBody->groupList )
		{
		// RESETiterator iterator gets a copy of the source groupList
		iterator->groupBody->groupList = source->groupBody->groupList;
		iterator->groupBody->flags.fLAG = 0;
		}
	else {
		// refusedSource A REFUSED SOURCE IS ANNOUNCED AND POISONED -- the poison is only thing between a refused iterate and an unbounded loop
		iterator->groupBody->flags.fLAG = 1;
		return ::refuse(source,"iterate: the source has no list");
		}
	// attributes and members filter overloaded on hasAttributes and hasMembers
	if ( attributes )
		iterator->groupBody->flags.hasAttributes = 1;
	else	iterator->groupBody->flags.hasAttributes = 0;
	if ( members )
		iterator->groupBody->flags.hasMembers = 1;
	else	iterator->groupBody->flags.hasMembers = 0;
	iterator->groupBody->flags.isIterator = 1;
	return iterator;
}

/*******************************************************************************
    BEAR COUNTRY: the virtual fork below is define-gated ON PURPOSE. Forking a
    virtual outside a defining context silently reads 0 and writes to a copy.
    ruleActions.aCTionNamE.bearCountryVirtual
*******************************************************************************/
extern "C" GroupItem *aCTionNamE(GroupItem *input)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*action = ruler->currentMETHOD;
GroupItem 	*grup = 0;
GroupItem 	*result = 0;
char 		*arg = input->getText();
	result = GroupControl::groupController->locateInMethod(arg);
	if ( result && result->parent == action )
		goto endName;
	if ( ruler->defining && result && result->groupBody->flags.isVirtual )
		result = ::copyOf(result);
	grup = new GroupItem(arg);
	if ( ruler->alphaSet->contains(*arg) && ruler->processingCode )
		if ( !result || (!result->groupBody->flags.isArgument && !result->groupBody->flags.isLocal) )
			if ( !(result && result->groupBody->registry == ruler->opFields) )
				if ( result )
					if ( action->groupBody->flags.isRule && result->groupBody->flags.isRule )
						{
						result = action->addAttribute(grup);
						result->groupBody->flags.isLocal = 1;
						}
					else	result = action->addAttribute(result);
				else {
					result = action->addAttribute(grup);
					result->groupBody->flags.isLocal = 1;
					}
	if ( !result )
		result = grup;
endName:
	input->setGroup(result);
	return input;
}

/*******************************************************************************
	The NewGroup action just sets the currentDefine field in GroupRules so
    that the MEMBERs case in processFlags can find it to set its addingMembers flag
*******************************************************************************/
extern "C" GroupItem *aCTionNewGroup(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*grup = field->getGroup();
	if ( !ruler->currentRegistry->groupBody->flags.isRule && !ruler->currentDefine )
		ruler->currentDefine = grup;
	return field;
}

/*******************************************************************************
	immediate method for the incant Number rule.
        NumbeR=[0-9]+               FloaT?:
            HeX='0'                 x=[xX] value=[0-9a-fA-F]+;;
        FloaT='.'                   float=[0-9]+ PoweR?;
        ⚠ The `tokenize` terms this shape used to carry were stripped
        2026-09-02 when tokenize retired. The flattening they describe still
        happens -- it is now the `tokened` bit and captureSpan. HeX is parked.
*******************************************************************************/
extern "C" GroupItem *aCTionNumbeR(GroupItem *input)
{
char 	*arg = input->getText();
	if ( arg )
		{
		// KANT'S NUMERIC TOWER IS count AND double. NO FLOATS, EVER -- a decimal point
		// mints isNUMBER here, at the literal's birth, and nothing rounds it   ruleActions.aCTionNumbeR.numericTower
		char *scan = arg;
		int sawDecimal = 0;
		while ( *scan )
			{
			if ( *scan == '.' )
				sawDecimal = 1;
			scan++;
			}
		if ( sawDecimal )
			input->setNumber(::atof(arg));
		else	input->setCount(::atoi(arg));
		input->groupBody->flags.isLiteral = 1;
		}
	return input;
}

/*******************************************************************************
	Rule action for Parens rule.
        Parens      leftParen="("- ExpressioN? rightParen=")"-;
*******************************************************************************/
extern "C" GroupItem *aCTionParens(GroupItem *input)
{
GroupItem 	*ExpressioN = input->getLabelGroup("ExpressioN");
	input->clear();
	if ( ExpressioN )
		input->setGroup(ExpressioN);
	return input;
}

/*******************************************************************************
	Immediate method for the Print rule or the StringXP rule.
        ToBuffer=">"    NamE@;
        PrinT           print ToBuffer? stuff=ExpressioN+  SemI-;
        StringXP        string stuff=ExpressioN+ ruleMethod=aCTionPrinT;
*******************************************************************************/
extern "C" GroupItem *aCTionPrinT(GroupItem *input)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*stuff = input->getLabelGroup("stuff");
GroupItem 	*grup = 0;
	/***********************************************************************
	Generating branch — currently UNUSED on the bytecode print path
	(gPrinT passes the statement to bcPrint; runPrint calls aCTionPrinT
	with generating false). Kept (a) because it's the future home for real
	operand compilation and (b) because its presence keeps stuff: resolving
	to `input` in codegen. Never entered while generating is false.
	***********************************************************************/
	if ( ruler->generating )
		{
		GroupItem 	*revisedList = new GroupItem("revisedList");
		while ( grup = stuff->nextAttribute(grup) )
			{
			if ( grup->groupBody->flags.noPrint )
				continue;
			GroupItem *FormaT = grup->getLabelGroup("FormaT");
			GroupItem *ExpressioN = grup->getLabelGroup("ExpressioN");
			GroupItem *result = 0;
			if ( ExpressioN )
				result = ExpressioN;
			else	result = grup;
			
			
			if ( FormaT )
				result->addMember(FormaT);
			revisedList->addMember(result);
			}
		input->setGroup(revisedList);
		return input;
		}
	// ⚠ THE EMIT-TIME WALK MUST BE EFFECT-FREE -- a print that fires at compile time
	// is worse than one that does not print, because it appears to work   ruleActions.aCTionPrinT.jittedPrint
	// ⚠ CALLED AT tok LEVEL, NOT FROM PASSTHROUGH -- as passthrough this hit both
	// bear-trap #13 and the type-alias hazard at once   ruleActions.aCTionPrinT.emittersAtTokLevel
	if ( ruler->jitting )
		{
		::jitPrintOpen(input);
		while ( grup = stuff->nextAttribute(grup) )
			{
			::jitPrintProbe(grup,0);
			if ( grup->groupBody->flags.noPrint )
				continue;
			GroupItem *FormaT = grup->getLabelGroup("FormaT");
			GroupItem *result = 0;
			GroupItem *ExpressioN = grup->getLabelGroup("ExpressioN");
			if ( ExpressioN )
				{
				::jitPrintArm();
				::jitPrintProbe(ExpressioN,1);
				/*  A MULTI-PART OPERAND is classified per part by constancy --
				see jitPrintList. Mentioning ExpressioN here also keeps the
				bare `isMethod` below bound to it (last-mentioned wins), which
				is the hazard this walk already paid for once.  */
				if ( isLIST(ExpressioN->groupBody->flags.binType) )
					::jitPrintList(ExpressioN,FormaT);
				else {
					/*  EMIT THE EXPRESSION through the existing emitters -- they
					leave the SSA value in gJitResult, which jitPrintItem picks
					up. No expression emitter is written or duplicated here.  */
					if ( isMethod(ExpressioN->groupBody->flags.instructType) )
						result = ExpressioN->groupBody->gMethod(ExpressioN);
					else {
						/*  ⚠ A BARE OPERAND. appendPrintXP's `else` branch makes NO
						CALL -- interpreted that is fine, because appendGroup
						then reads the field's own storage. Jitted, reading the
						field's own storage is exactly what we cannot do, and
						nothing had ever emitted a value here. This is the
						missing primitive, and it is why a jitted print carried
						a constant 0. (R3's printout, 2026-08-05.)  */
						result = ExpressioN;
						::jitEmitBareRead(ExpressioN);
						}
					::jitPrintProbe(result,2);
					/*  SAME NODE-ENTRY RULE AS jitPrintList's method arm: when the
					emitted op produced a GroupItem, hand the chain the NODE and
					let it format by the node's real datA at run time. The
					emitter cannot type the result -- opDot's gate returns before
					its interpreted body -- and guessing prints `taG` as a
					number. jitPrintNode clears the channel it consumes.  */
					if ( ::jitNodeInFlight() )
						::jitPrintNode(FormaT);
					else	::jitPrintItem(grup,FormaT,1);
					}
				}
			else {
				::jitPrintProbe(grup,3);
				::jitPrintItem(grup,FormaT,0);
				}
			}
		::jitPrintClose(input);
		return input;
		}
Buffer 		*buffer = (Buffer*)ruler->bufferSTAK->pop();
	if ( !buffer )
		buffer = new Buffer("print buffer");
	ruler->isPRINTING = 0;
	appendPrintXP(stuff,buffer);
	return ::opPrint(input,buffer);
}

/***************************************************************************
    QuotE rule action
        QuotE       tik=['"] isRule quoteBody}=tik;
***************************************************************************/
extern "C" GroupItem *aCTionQuotE(GroupItem *input)
{
GroupItem 	*tik = input->getLabelGroup("tik");
GroupItem 	*quoteBody = input->getLabelGroup("quoteBody");
char 		*body = quoteBody->getText();
	input->clear();
	quoteBody->clear();
	if ( *tik->groupBody->gText != '"' )
		if ( tik = GroupControl::groupController->groupRules->opFields->get(body) )
			input->setGroup(tik);
		else {
			if ( ::strlen(body) == 1 )
				input->setCharacter((char)*body);
			else	input->setText(body);
			input->groupBody->flags.isLiteral = 1;
			}
	else {
		input->setText(body);
		input->groupBody->flags.isLiteral = 1;
		}
	return input;
}

/*******************************************************************************
	runs the rule passed in, returns the rule result if it succeeds.
*******************************************************************************/
extern "C" GroupItem *aCTionRunRulE(GroupItem *input)
{
GroupItem 	*argument = 0;
GroupItem 	*InvokE = input->getLabelGroup("InvokE");
GroupItem 	*rule = input->get(1);
	if ( rule )
		{
		rule = rule->getGroup();
		input->clear();
		if ( InvokE )
			if ( argument = InvokE->get(1) )
				if ( isGROUP(argument->groupBody->flags.data) )
					argument = argument->getGroup();
		if ( !rule->groupBody->flags.isRule )
			{
			input->addMember(rule);
			if ( isMethod(rule->groupBody->flags.instructType) )
				input->setMethod(rule->groupBody->gMethod);
			if ( argument )
				input->addMember(argument);
			if ( isMethod(input->groupBody->flags.instructType) )
				if ( argument )
					input->groupBody->gMethod(argument);
				else	input->groupBody->gMethod(rule);
			else	::fprintf(stderr,"RunRulE: expected a method not %s\n",rule->groupBody->tag);
			}
		else	rule = ::runRule(argument,rule);
		}
	return input;
}

/***************************************************************************
    Process a scope expression. It is a convenient way to set local fields.
    The first field in the scope list becomes the lookin field searched for
    the fields that follow. Fields then found update local fields. The
    respective local fields then point to the found fields.
***************************************************************************/
extern "C" void aCTionScopeXP(GroupItem *input)
{
GroupItem 	*action = GroupControl::groupController->groupRules->currentMETHOD;
GroupItem 	*field = 0;
GroupItem 	*listItem = 0;
GroupItem 	*lookin = 0;
GroupItem 	*scopeList = input->getLabelGroup("scopeList");
GroupItem 	*grup = 0;
char 		*name = 0;
	while ( listItem = scopeList->next(listItem) )
		{
		if ( isGROUP(listItem->groupBody->flags.data) )
			grup = listItem->getGroup();
		else	grup = listItem;
		if ( !lookin )
			lookin = grup;
		else {
			name = grup->groupBody->tag;
			field = lookin->get(name);
			grup = action->get(name);
			if ( !grup )
				{
				grup = new GroupItem(name);
				grup->groupBody->flags.isLocal = 1;
				action->addAttribute(grup);
				}
			if ( field )
				{
				if ( field->groupBody == grup->groupBody )
					continue;
				if ( isGROUP(listItem->groupBody->flags.data) )
					listItem->setGroup(field);
				grup->setGroup(field);
				}
			else	grup->clear();
			}
		}
}

/*******************************************************************************
	Search rule action. List, setStakked, add to, or reset the SearchList.
*******************************************************************************/
extern "C" GroupItem *aCTionSearch(GroupItem *input)
{
GroupItem 	*searchLIST = GroupControl::groupController->groupRules->searchList;
GroupItem 	*base = 0;
GroupItem 	*grup = 0;
int 		setStakked = 0;
	// ⚠ MUST SIT AFTER THE WHOLE DECLARATION BLOCK -- inside one, this line wiped
	// GroupRules.h's extern block to zero   ruleActions.degradeByDefault
	if ( GroupControl::groupController->groupRules->jitting )
		jitDegrade("search under jit -- no emitter, mutates the search stack at emit time",input);
	while ( grup = input->next(grup) )
		if ( ::compare(grup->groupBody->tag,"reset") == 0 )
			searchLIST->clearList();
		else
		if ( ::compare(grup->groupBody->tag,"list") == 0 )
			if ( !searchLIST->groupBody->groupList->listLength )
				::printf("Search list is empty\n");
			else {
				::printf("Search list:");
				base = 0;
				while ( base = searchLIST->next(base) )
					::printf(" %s",base->groupBody->tag);
				::printf("\n");
				}
		else
		if ( ::compare(grup->groupBody->tag,"stack") == 0 )
			setStakked = 1;
		else
		if ( grup->groupBody->flags.binType )
			{
			if ( setStakked )
				if ( !grup->groupBody->groupList || grup->groupBody->groupList->listLength < 10 )
					::fprintf(stderr,"WARNING: %s list too short to stack\n",grup->groupBody->tag);
				else
				if ( !grup->groupBody->groupList->stakked )
					grup->groupBody->groupList->stakked = new GroupStak(grup);
			base = searchLIST->addMember(grup);
			}
		else	::printf("WARNING: %s must be a registry to add to searchlist\n",grup->groupBody->tag);
	return input;
}

/*******************************************************************************
	Create a set from the string passed in
*******************************************************************************/
extern "C" GroupItem *aCTionSetBrackets(GroupItem *group)
{
GroupItem 	*setText = group->get(1);
char 		*stuff = setText->getText();
PLGset 		*set = new PLGset(stuff);
	group->clear();
	group->setCharacterSet(set);
	return group;
}

/*******************************************************************************
	Process string shortcuts.
*******************************************************************************/
extern "C" GroupItem *aCTionShortcuT(GroupItem *group)
{
	if ( group->groupBody->gCount == 2 && GroupControl::groupController->groupRules->opFields->get(group->getText()) )
		return 0;
	group->groupBody->flags.isShortcut = 1;
	return group;
}

/*******************************************************************************
	Process a statement (if we are not parsing code), otherwise return it.
*******************************************************************************/
extern "C" GroupItem *aCTionStatemenT(GroupItem *input)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = input->getRStuff();
GroupItem 	*sourceFile = new GroupItem("sourceFile");
	ruleStuff->sourceLine = new GroupItem("sourceAt");
	ruleStuff->sourceLine->setCount(ruler->sourceLINE);
	sourceFile->setText(ruler->sourceFILE->groupBody->tag);
	ruleStuff->sourceLine->addAttribute(sourceFile);
	if ( !ruler->processingCode )
		{
		GroupItem 	*statement = input;
		if ( isGROUP(statement->groupBody->flags.data) )
			statement = statement->getGroup();
		ruler->lastStatement = statement;
		if ( statement->groupBody->gMethod )
			return statement->groupBody->gMethod(statement);
		}
	else
	if ( ruler->generating )
		if ( !input->groupBody->gText && isGROUP(input->groupBody->flags.data) )
			{
			GroupItem 	*xpStatement = input->getGroup();
			input->clear();
			xpStatement->setText("gXpress");
			input->addAttribute(xpStatement);
			}
		else
		if ( ::compare(input->groupBody->gText,"gFOR") == 0 )
			ruleStuff->doNothing = 0;
	return input;
}

/*******************************************************************************
	Immediate method for the StringXP rule.
        StringXP    pound="#"- stuff=PrintXP+ defer;
*******************************************************************************/
extern "C" GroupItem *aCTionStringXP(GroupItem *input)
{
GroupItem 	*stuff = input->getLabelGroup("stuff");
Buffer 		*buffer = (Buffer*)GroupControl::groupController->groupRules->bufferSTAK->pop();
	// ⚠ MUST SIT AFTER THE WHOLE DECLARATION BLOCK -- inside one, this line wiped
	// GroupRules.h's extern block to zero   ruleActions.degradeByDefault
	if ( GroupControl::groupController->groupRules->jitting )
		jitDegrade("string expression under jit -- no emitter, builds at emit time",input);
	if ( !buffer )
		buffer = new Buffer("print buffer");
	appendPrintXP(stuff,buffer);
	return ::opString(stuff,buffer);
}

/*******************************************************************************
	TokenXP returns a token or a token expression.
*******************************************************************************/
extern "C" GroupItem *aCTionTokenXP(GroupItem *xpress)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*arg = 0;
GroupItem 	*op = 0;
GroupItem 	*UnaryOPS = xpress->getLabelGroup("UnaryOPS");
GroupItem 	*InvokeArg = xpress->get("InvokeArg");
GroupItem 	*ANYtoken = xpress->get("ANYorNum");
	if ( ruler->generating && !ruler->isPRINTING )
		{
		// Bare the simple field-ref operand for the generating path: mirror the
		// non-generating normalization below (xpress.group = ANYtoken) so
		// aCTionExpressioN's unwrap (while grup.isGROUP grup = grup.group)
		// reaches the bare field instead of depositing the TokenXP wrapper.
		// Invoke / unary / dot operands are left raw for now (Brief 2026-06-04).
		if ( isGROUP(ANYtoken->groupBody->flags.data) )
			ANYtoken = ANYtoken->getGroup();
		if ( !InvokeArg && !UnaryOPS && ANYtoken->groupBody->registry != ruler->groupFields )
			xpress->setGroup(ANYtoken);
		return xpress;
		}
	xpress->clear();
	if ( isGROUP(ANYtoken->groupBody->flags.data) )
		ANYtoken = ANYtoken->getGroup();
	if ( !InvokeArg )
		{
		if ( UnaryOPS )
			goto handleUnary;
		if ( ANYtoken->groupBody->registry == ruler->groupFields )
			{
			op = ruler->opFields->get(".");
			xpress->addAttribute(op);
			xpress->addAttribute(ANYtoken);
			// w/no argument opDot will try to use lastREF
			xpress->groupBody->flags.invoke = 1;
			}
		else	xpress->setGroup(ANYtoken);
		}
	else {
		if ( InvokeArg->groupBody->groupList )
			{
			// this happens when InvokeArg is UnaryXP
			op = InvokeArg->groupBody->groupList->firstInList;
			arg = InvokeArg->groupBody->groupList->lastInList;
			if ( isGROUP(op->groupBody->flags.data) )
				op = op->getGroup();
			if ( isGROUP(arg->groupBody->flags.data) )
				arg = arg->getGroup();
			if ( UnaryOPS )
				{
				/*  THE STAR/DOT ROTATION. `*a.b` must mean `(*a).b`, so the star
				is applied to the dot's LEFT operand and the dot re-applied to
				the result -- not wrapped around the finished dot node.
				ruleActions.aCTionTokenXP.starDotRotation  */
				if ( ::compare(UnaryOPS->groupBody->tag,"*") == 0 )
					if ( ::compare(op->groupBody->tag,".") == 0 )
						{
						GroupItem 	*starred = new GroupItem("uxp");
						starred->addAttribute(ruler->opFields->get("deref"));
						starred->addAttribute(ANYtoken);
						starred->setMethod(::runOP);
						starred->groupBody->flags.invoke = 1;
						xpress->addAttribute(op);
						xpress->addAttribute(starred);
						xpress->addAttribute(arg);
						xpress->groupBody->flags.invoke = 1;
						xpress->setMethod(::runOP);
						goto endToken;
						}
				// this happens with two unary ops like: !field.someThing
				GroupItem *xp = new GroupItem("xp");
				xp->addAttribute(op);
				xp->addAttribute(ANYtoken);
				xp->addAttribute(arg);
				ANYtoken = xp;
				xp->setMethod(::runOP);
				xp->groupBody->flags.invoke = 1;
				goto handleUnary;
				}
			else {
				xpress->addAttribute(op);
				xpress->addAttribute(ANYtoken);
				xpress->addAttribute(arg);
				}
			}
		else {
			if ( InvokeArg->groupBody->flags.fLAG )
				op = ruler->opFields->get("=[");
			else {
				op = ruler->falseResult;
				if ( ruler->processingCode )
					if ( ANYtoken->groupBody == ruler->currentMETHOD->groupBody )
						ruler->currentMETHOD->groupBody->flags.recursive = 1;
				}
			if ( isGROUP(InvokeArg->groupBody->flags.data) )
				arg = InvokeArg->getGroup();
			if ( !arg )
				arg = InvokeArg;
			/*  THE STAR ROTATION, SUBSCRIPT HALF -- gated on `=[` so an INVOCATION
			`*fn(x)` is left alone   ruleActions.aCTionTokenXP.starDotRotation  */
			if ( UnaryOPS )
				if ( ::compare(UnaryOPS->groupBody->tag,"*") == 0 )
					if ( ::compare(op->groupBody->tag,"=[") == 0 )
						{
						GroupItem 	*starred = new GroupItem("uxp");
						starred->addAttribute(ruler->opFields->get("deref"));
						starred->addAttribute(ANYtoken);
						starred->setMethod(::runOP);
						starred->groupBody->flags.invoke = 1;
						xpress->addAttribute(op);
						xpress->addAttribute(starred);
						xpress->addAttribute(arg);
						xpress->groupBody->flags.invoke = 1;
						xpress->setMethod(::runOP);
						goto endToken;
						}
			xpress->addAttribute(op);
			xpress->addAttribute(ANYtoken);
			xpress->addAttribute(arg);
			}
		xpress->groupBody->flags.invoke = 1;
		}
handleUnary:
	if ( UnaryOPS )
		{
		// Prefix - routes to the named "negate" op (opUnaryMinus), keeping the
		// binary - slot (opMinus) completely isolated. Other unaries resolve
		// their method straight from their own Operators entry.
		if ( ::compare(UnaryOPS->groupBody->tag,"-") == 0 )
			UnaryOPS = ruler->opFields->get("negate");
		if ( ::compare(UnaryOPS->groupBody->tag,"*") == 0 )
			UnaryOPS = ruler->opFields->get("deref");
		op = new GroupItem("uxp");
		op->addAttribute(UnaryOPS);
		op->addAttribute(ANYtoken);
		op->setMethod(::runOP);
		op->groupBody->flags.invoke = 1;
		xpress->setGroup(op);
		goto endToken;
		}
	if ( xpress->groupBody->flags.invoke )
		xpress->setMethod(::runOP);
endToken:
	return xpress;
}

/*******************************************************************************
	Immediate method for the TraiT rule that defines an attribute. It can be
        TraiTdata="="       DatA Modifier? Limit?;
        TraiT               NamE@ Modifier? Limit? TraiTdata? TraiTlist?;
*******************************************************************************/
extern "C" GroupItem *aCTionTraiT(GroupItem *input)
{
GroupItem 	*Modifier = input->getLabelGroup("Modifier");
GroupItem 	*Limit = input->getLabelGroup("Limit");
GroupItem 	*TraiTdata = input->get("TraiTdata");
GroupItem 	*trait = input->get(1);
	/***************************************************************************
	A trait value can be a group or a literal. Limit and Modifier are passed
	to trait to be handled in DefinE. Same applies to TraiTdata.
	***************************************************************************/
	input->clearList();
	if ( isGROUP(trait->groupBody->flags.data) )
		trait = trait->getGroup();
	if ( Modifier || Limit )
		{
		trait->options.affiliation = 1;
		if ( trait->getRStuff() )
			trait = new GroupItem(trait);
		else	trait->setRuleStuff();
		if ( Modifier )
			::modify(trait,Modifier->getText());
		if ( Limit )
			::setLimits(trait,Limit);
		}
	if ( TraiTdata )
		trait->setContent(TraiTdata);
	input->setGroup(trait);
	return input;
}

/*******************************************************************************
    Immediate method for the TraiTdata rule.
*******************************************************************************/
extern "C" GroupItem *aCTionTraiTdata(GroupItem *input)
{
GroupItem 	*Modifier = input->getLabelGroup("Modifier");
GroupItem 	*Limit = input->getLabelGroup("Limit");
GroupItem 	*DatA = input->getLabelGroup("DatA");
	input->clear();
	if ( Modifier || Limit )
		{
		DatA->options.affiliation = 1;
		if ( DatA->getRStuff() )
			DatA = new GroupItem(DatA);
		else	DatA->setRuleStuff();
		if ( Modifier )
			::modify(DatA,Modifier->getText());
		if ( Limit )
			::setLimits(DatA,Limit);
		DatA->groupBody->flags.isRule = 1;
		}
	if ( (DatA->groupBody->flags.isRule && !DatA->groupBody->flags.isLiteral) || DatA->groupBody->registry == GroupControl::groupController->groupRules->opFields )
		input->setGroup(DatA);
	else	input->setContent(DatA);
	return input;
}

/*******************************************************************************
	Sets the operator method in a while statement
        WhilE   while- ExpressioN SemI-? BLOCKing StatemenT;
*******************************************************************************/
extern "C" GroupItem *aCTionWhilE(GroupItem *input)
{
GroupItem 	*ExpressioN = input->getLabelGroup("ExpressioN");
GroupItem 	*StatemenT = input->getLabelGroup("StatemenT");
GroupItem 	*looper = 0;
GroupItem 	*result = 0;
	if ( GroupControl::groupController->groupRules->jitting )
		{
		 return jitEmitWHILE(input); 
		}
	while ( looper = ExpressioN->groupBody->gMethod(ExpressioN) )
		{
		if ( looper->groupBody->flags.isIterator )
			looper = looper->getGroup();
		if ( result = StatemenT->groupBody->gMethod(StatemenT) )
			{
			if ( result->groupBody->flags.isBranch )
				{
				// ⚠ TRAILING-CONTINUE GUARD -- one IDENTICAL body in DO, FOR and WhilE, and NOT
				// extractable: the arms are continue/return/break over THIS loop
				// ruleActions.trailingContinueGuard
				if ( isContinue(result->groupBody->flags.isBranch) )
					{
					result = GroupControl::groupController->groupRules->trueResult;
					continue;
					}
				else
				if ( isReturn(result->groupBody->flags.isBranch) )
					return result;
				// BREAK IS CONSUMED HERE -- clearing isBranch is what stops the
				// enclosing block breaking too   ruleActions.breakIsConsumed
				result->groupBody->flags.isBranch = 0;
				if ( result->groupBody->registry == GroupControl::groupController->groupRules->keyWords )
					result = 0;
				break;
				}
			}
		else	break;
		}
	// labelNO, not falseResult: this construct executed NO statement, so it has no
	// value -- and 0 is a value   ruleActions.labelNoNotFalse
	if ( !result )
		result = GroupControl::groupController->groupRules->labelNO;
	return result;
}

/*******************************************************************************
	Xpress rule method.
*******************************************************************************/
extern "C" GroupItem *aCTionXpress(GroupItem *input)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*ExpressioN = input->getLabelGroup("ExpressioN");
	if ( !ruler->processingCode && ExpressioN->groupBody->gMethod )
		ExpressioN = ExpressioN->groupBody->gMethod(ExpressioN);
	else
	if ( ExpressioN )
		{
		input->clear();
		input->setGroup(ExpressioN);
		}
	return input;
}

/*******************************************************************************
    actK -- THE ACTION TAIL SHIM. The body carries ZERO information; the frame
    supplies WHICH rule and WHICH label, exactly as it supplies position and
    mark for litK and parseRK.

    ⚠ THE VERDICT IS THE SHIM'S, NEVER THE ACTION'S RETURN. Dispatch happened
    => trueResult, full stop. A datumless return is aCTionBraced doing its job
    correctly; it is not a failure and it must not become a TRUE-by-presence
    either. A missing symbol REFUSES and names what it looked for -- refuse,
    never substitute, because this family was measured failing SILENTLY.

    // actionTailShim  why a shim at all: both spellings of a bare aCTionBraced() call are unsound, and one of them clears the wrong node
    // shimRoute  resolves by dlsym at CALL time, not from a pointer stashed at mint -- cheap-to-remove beat cheap-to-run, and step 2 deletes the question
*******************************************************************************/
extern "C" GroupItem *actK(GroupItem *ignored)
{
GroupItem 	*label = 0;
GroupItem 	*rule = 0;
char 		*name = 0;
int 		fired = 0;
	/*  Passthrough for the same reason as parseRK's -- tok cannot see a
	hand-declared global in jitContext.h. Both locals are read OUTSIDE the
	block as well, which is what keeps bear-trap #13 from pruning them.  */
	
	label = gKantLabel;
	rule  = gKantRule;
	
	if ( !rule )
		{
		::fprintf(stderr,"actK: called outside a kant parse frame -- no rule to act for\n");
		return 0;
		}
	if ( !label )
		{
		::fprintf(stderr,"actK: no label in the kant parse frame for %s\n",rule->groupBody->tag);
		return 0;
		}
	name = ::concat(2,"aCTion",rule->groupBody->tag);
	fired = 0;
	
	GroupItem *(*action)(GroupItem *) =
	(GroupItem *(*)(GroupItem *))::dlsym(RTLD_DEFAULT,name);
	if ( action )
	{
	action(label);
	fired = 1;
	}
	
	if ( !fired )
		{
		::fprintf(stderr,"actK: REFUSING -- no C++ action named %s for rule %s\n",name,rule->groupBody->tag);
		::free(name);
		return 0;
		}
	if ( GroupControl::groupController->groupRules->parseTrace )
		::fprintf(stderr,"    actK %s -> %s\n",rule->groupBody->tag,name);
	::free(name);
	return GroupControl::groupController->groupRules->trueResult;
}

/*******************************************************************************
    genParse.rtn -- THE PARSE-METHOD EMITTER (genParseSpec §4). What it is and
    how it is measured: designDocs TokFiles -> genParse.

    THREE TRAPS THAT BITE THIS FILE SPECIFICALLY. All three cost a build cycle.

    1. A COMMENT CANNOT CONTAIN A STAR FOLLOWED BY A SLASH, and the modifier
       fold is the next thing anyone will document here -- its comments will
       want to quote the repetition modifiers by name. tok has no lexer, so the
       terminator is matched wherever it appears: writing the two of them as a
       pair inside a block comment CLOSES THE COMMENT EARLY and the rest of the
       prose is parsed as code, taking the following extern with it. Spell them
       out as "star" and "plus". (Cost one build, 2026-07-28.)
    2. JUXTAPOSED CONCAT DOES NOT WORK IN ARGUMENT POSITION. `f(a, b " ")`
       reads as THREE arguments and is caught only by the C++ compiler. In
       return position it is loud (FAIL Block / ERROR Inheritance, taking the
       extern with it); here it is SILENT. Concat into a local first, always.
       Assignment position is fine.
    3. A METHOD CALL CANNOT APPEAR IN AN `if` CONDITION --
       `if term.definingRule() != term` fails to parse. Assign it to a local.
*******************************************************************************/
/*******************************************************************************
    activateAll -- THE WHOLE-POPULATION FORM: walk the corpus and bind every
    PENDING entry to the rule it was filed against.

    ⚠ NO BACK-POINTER: it resolves the rule by NAME out of the live registry,
    and refuses by name PER ENTRY rather than aborting the sweep.

    // activateAll  why the rule is read back by name, and why one bad entry does not stop the walk
*******************************************************************************/
extern "C" GroupItem *activateAll(GroupItem *ignored)
{
GroupItem 	*reg = 0;
GroupItem 	*entry = 0;
GroupItem 	*rule = 0;
int 		done = 0;
	reg = GroupControl::groupController->getRegistry("GenBodies");
	if ( !reg->groupBody->groupList )
		{
		::fprintf(stderr,"CORPUS activated 0 -- the corpus is empty\n");
		return 0;
		}
	while ( entry = reg->next(entry) )
		if ( entry->getCount() == 3 )
			{
			rule = GroupControl::groupController->locate(entry->groupBody->tag);
			if ( !rule )
				::fprintf(stderr,"activateAll: REFUSING %s -- no live rule of that name\n",entry->groupBody->tag);
			else
			if ( ::activateBody(rule) )
				done = done + 1;
			}
	::fprintf(stderr,"CORPUS commissioned %s\n",::toStringFromInt(done));
	return GroupControl::groupController->groupRules->trueResult;
}

/*******************************************************************************
    activateBody -- BIND ONE STORED BODY TO ITS RULE'S LIVE SLOT.

    ⚠ THE ONLY WRITER OF THE LIVE SLOT among the corpus verbs -- CodE plus
    isCoded. Generation files PENDING; this is phase two.

    // activateBody  why this verb alone touches the live slot, and what phase two means for the corpus
*******************************************************************************/
extern "C" GroupItem *activateBody(GroupItem *rule)
{
GroupItem 	*reg = 0;
GroupItem 	*entry = 0;
GroupItem 	*body = 0;
GroupItem 	*hung = 0;
	if ( !rule )
		{
		::fprintf(stderr,"activateBody: no field\n");
		return 0;
		}
	reg = GroupControl::groupController->getRegistry("GenBodies");
	if ( !reg->groupBody->groupList )
		{
		::fprintf(stderr,"activateBody: REFUSING %s -- the corpus is empty\n",rule->groupBody->tag);
		return 0;
		}
	entry = reg->get(rule->groupBody->tag);
	if ( !entry )
		{
		::fprintf(stderr,"activateBody: REFUSING %s -- nothing stored for it\n",rule->groupBody->tag);
		return 0;
		}
	body = entry->getAttribute("StorE");
	if ( !body )
		{
		::fprintf(stderr,"activateBody: REFUSING %s -- the entry carries no body\n",rule->groupBody->tag);
		return 0;
		}
	hung = ::copyOf(body);
	hung->groupBody->tag = "CodE";
	hung->groupBody->flags.noPrint = 1;
	rule->addAttribute(hung);
	rule->groupBody->flags.actionType = 2;
	entry->setCount(2);
	return rule;
}

/*******************************************************************************
	Print the field passed in to the buffer passed in
*******************************************************************************/
extern "C" GroupItem *appendGroup(GroupItem *input, GroupItem *FormaT, Buffer *buffer)
{
char 		*atText = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
char 		*format = 0;
int 		indenting = 0;
GroupItem 	*grup = 0;
GroupItem 	*field = 0;
	field = input;
	/*  ⚠ A REFUSING OPERATOR HANDS THIS A NULL, AND DEREFERENCING IT WAS F-36's
	CRASH. Fixed 2026-09-01. A binary op that cannot apply prints its own
	named error and returns NULL -- opMultiply does exactly that
	(`ERROR Operator * failed on <a> and <b>`) and so do opPlus, opMinus and
	the rest. appendPrintXP then runs the expression and passes the result
	straight here, so every such refusal inside a `print`/`cerr` item list
	arrived as a null and died on the isShortcut read two lines below.
	⚠ THE REPORTED SYMPTOM WAS `* *x` AT EXIT 139 WITH NO SENTINEL, and the
	star was a red herring: with a SPACE the leading `*` is BINARY MULTIPLY
	against the preceding item, not a second unary. So the crash was never
	about composing unwraps -- it is every refusing binary operator in print
	position, and `*` was merely the one somebody typed.
	THE ERROR IS ALREADY NAMED BY THE OPERATOR, so this returns quietly
	rather than printing a second time. Skipping the item is the refusal.  */
	if ( !field )
		return 0;
	if ( FormaT )
		{
		format = FormaT->getText();
		*format = '%';
		}
	if ( !field->groupBody->flags.isShortcut )
		if ( isLIST(field->groupBody->flags.binType) )
			if ( field->groupBody->flags.reversePrint )
				while ( grup = field->next(grup) )
					::printField(grup,format,buffer);
			else
			while ( grup = field->prior(grup) )
				::printField(grup,format,buffer);
		else	::printField(field,format,buffer);
	else {
		/*******************************************************************
		The following treats field text as a string of print short cuts,
		each then gets processed to implement the short cut
		*******************************************************************/
		for ( atText = field->getText(); *atText; atText++ )
			switch (*atText)
				{
				case '~':
					indenting++;
					break;
				case '$':
					ruler->useDefaultSpace = !ruler->useDefaultSpace;
					break;
				case '_':
					buffer->appendChar(' ',0,0);
					break;
				case ':':
					buffer->appendChar('\n',0,0);
					break;
				case '+':
					ruler->inDENT->groupBody->gCount++;
					break;
				case '-':
					if ( ruler->inDENT->groupBody->gCount > 0 )
						ruler->inDENT->groupBody->gCount--;
					break;
				case '`':
					buffer->appendChar('\t',0,0);
					break;
				case ',':
					grup = 0;
				}
		if ( indenting && ruler->inDENT->groupBody->gCount > 0 )
			buffer->tabRight(ruler->inDENT->groupBody->gCount);
		}
	return field;
}

/*  a FRESH carrier per call -- a shared one would be a second name for a value in
    flight. i32 only; a double or string entry wants a rung.  jitEmitters.appendGroupValue  */
extern "C" GroupItem *appendGroupValue(int value, GroupItem *FormaT, Buffer *buffer)
{
GroupItem 	*carrier = new GroupItem("jitPrintValue");
	carrier->setCount(value);
	return ::appendGroup(carrier,FormaT,buffer);
}

/*******************************************************************************
    THE ONE PrintXP WALK. Callers: aCTionPrinT, aCTionStringXP, aCTionCerR,
    aCTionCouT. It exists because there were four copies of this loop.
    ruleActions.appendPrintXP.onePrintXPWalk
*******************************************************************************/
extern "C" void appendPrintXP(GroupItem *stuff, Buffer *buffer)
{
GroupItem 	*grup = 0;
	while ( grup = stuff->nextAttribute(grup) )
		{
		if ( grup->groupBody->flags.noPrint )
			continue;
		GroupItem *FormaT = grup->getLabelGroup("FormaT");
		GroupItem *result = 0;
		GroupItem *ExpressioN = grup->getLabelGroup("ExpressioN");
		if ( ExpressioN )
			{
			if ( isMethod(ExpressioN->groupBody->flags.instructType) )
				result = ExpressioN->groupBody->gMethod(ExpressioN);
			else	result = ExpressioN;
			::appendGroup(result,FormaT,buffer);
			}
		else	::appendGroup(grup,FormaT,buffer);
		}
}

/******************************************************************************
    This incant command method reads the field passed in as a file spec and
    loads the field buffer (creating it if necessary) with text read in from
    the file. Returns the loaded field. See DesignDocs entry: arrondirNote.
******************************************************************************/
/***************************************************************************
    arrondir -- EXPLICIT CONVERSION TO A COUNT (Tony's ruling, 2026-08-01,
    clause 2 / word 3). For when the user wants control instead of relying on
    implicit narrowing.

    ⚠ NAMED IN FRENCH ON PURPOSE, AND IT PAYS TWICE (Tony). `round` is libc
    <math.h>, and extern "C" strips overload resolution, so an extern named
    `round` is bear-trap #12 -- clean per file, `duplicate symbol` at Ld, no hint
    which incant file caused it. The first cut dodged that with a differently
    named extern plus the `=method` binding form (bear-trap #7). BORROWING A WORD
    FROM ANOTHER LANGUAGE INSTEAD REMOVES BOTH: the name is free at the C level,
    so the extern carries it directly and the indirection disappears. Cheaper
    than inventing a name, and it reads.

    HALF-UP, the same rule and the same spelling as everywhere else: >= .5 goes
    up, < .5 goes down, so -2.5 gives -2. ⚠ THAT DISTINCTION IS NOW LOAD-BEARING
    rather than academic -- under Word 2 the compound-assign family computes in
    doubles and narrows the RESULT, so negative halves actually reach a rounding
    decision. lround() would round half AWAY FROM ZERO and disagree here.

    ⚠ ROUTED THROUGH .count (getCount) DELIBERATELY, exactly as the compound
    arms are, so the half-up rule keeps ONE IMPLEMENTER. An inline floor(x+0.5)
    here would be a second copy of a rule whose whole history is copies
    disagreeing.

***************************************************************************/
extern "C" GroupItem *arrondir(GroupItem *field)
{
	if ( !field )
		{
		::fprintf(stderr,"arrondir: no argument provided\n");
		return 0;
		}
	GroupControl::groupController->groupRules->tempField->setCount(field->getCount());
	return GroupControl::groupController->groupRules->tempField;
}

/*  BOTH ROADS CALL THIS -- the interpreted `=` reaches it from opAssign, the
    emitted `=` through jitAssignNodeRT. One spelling, so they cannot drift.
    jitEmitters.jitAssignNodeRT  */
extern "C" int assignFieldCore(GroupItem *source, GroupItem *target)
{
	
	if ( !target )  return 0;
	if ( !source ) {
	::fprintf(stderr,"ERROR = on %s -- nothing on the right; stores nothing\n",
	target->groupBody->tag);
	return 0;
	}
	if ( isGROUP(source->groupBody->flags.data) ) {
	::fprintf(stderr,"ERROR = on %s -- holds a group; say *\n",
	target->groupBody->tag);
	return 0;
	}
	target->setContent(source);
	return 1;
	
}

/*******************************************************************************
    Commands.rtn
    Home for extern methods backing the cOMMANDs base registry. Commands fire
    C++ methods used to set flags or perform side effects; they are wired up
    via the immediateAction attribute in incant/setup.

    Externs are ordered alphabetically by method name (case-sensitive ASCII,
    matching tok's emit order so the .rtn order and .mm order line up).
    
    Note: incant commands are defined at setup in the cOMMANDs registry. They
    come in two flavors: commands with a noPrint attribute are invoked during
    field definition to modify the field being defined; the command is not
    added to the definition; it is fire and forget. Commands without a noPrint
    attribute are intended to be run on the command line.
*******************************************************************************/
/***************************************************************************
	The incant clear command invokes this. It clears its argument.
    If data is a buffer, it is reset. If data is a stak, it is cleared.
    Otherwise input is cleared wiping data and list.
***************************************************************************/
extern "C" GroupItem *cLEAR(GroupItem *input)
{
	if ( isBUFFER(input->groupBody->flags.data) )
		input->getBuffer()->reset();
	else
	if ( isSTAK(input->groupBody->flags.data) )
		input->getStak()->clear();
	else {
		input->clearData();
		input->clearList();
		}
	return input;
}

/***************************************************************************
	Returns a copy of the field passed in
***************************************************************************/
extern "C" GroupItem *cOPY(GroupItem *field)
{
GroupItem 	*newField = new GroupItem(field);
	return newField;
}

/***************************************************************************
    Close the file associated with the buffer. If no file has been set,
    fall back to using the field's tag as the filename — the tag is a
    handle the user already controls and serves no other purpose in this
    context, so it's a reasonable default destination.
***************************************************************************/
extern "C" int closeFile(GroupItem *bufField)
{
	if ( isBUFFER(bufField->groupBody->flags.data) )
		{
		if ( !bufField->getBuffer()->file )
			bufField->getBuffer()->setFile(bufField->groupBody->tag);
		return bufField->getBuffer()->closeFile();
		}
	return 0;
}

/*******************************************************************************
	Compile field action
*******************************************************************************/
extern "C" GroupItem *compile(GroupItem *field)
{
GroupItem 	*code = 0;
GroupItem 	*grup = 0;
	/*  ⚠ REFUSE LOUD ON A BODYLESS FIELD, AND RETURN null. SEQ 79 step 2,
	in-charter under R-4: compile owns the compilation preconditions, and
	"carries a body at all" is the first of them.
	
	WHAT THIS REPLACES IS WORSE THAN THE CRASH IT WAS CHARTERED AGAINST.
	The old spelling was `goto endCompile`, and endCompile is `return
	field` -- so compile on a rule with NO BODY returned the field, which
	is TRUTHY, and every caller tallying `if compile(x)` counted it as a
	SUCCESS. A bodyless rule did not fail to compile, it silently reported
	that it had. That is an absence passing for a value, rule H4's exact
	shape, and it was invisible for as long as every caller happened to
	pass coded fields.
	
	A SIBLING MESSAGE, NOT reportNoBody, per the F-18 standard: that one
	says a rule was reached THROUGH A BOUND PARSE METHOD and has no body,
	which is a different fact about a different path. Reusing it would put
	two meanings on one channel. Spelled as a cerr rather than a new
	extern deliberately -- it is greppable by text, and a sixth extern
	would move the canary pin again for a message.  */
	if ( !isCoded(field->groupBody->flags.actionType) )
		{
		return ::refuse(field,"compile: no compiled body");
		}
	/*  ⚠ COMPILE OWNS THE COMPILATION PRECONDITIONS, ENSURED IDEMPOTENTLY.
	R-4, Tony's ruling 2026-08-17.
	
	Every coded body is built with TWO HIDDEN LOCALS -- `this` and
	`tempField`. aCTionDefinE adds them at definition time when it sees a
	CodE, and genParse's kant door replicates them by hand for the same
	reason, its own comment calling them "the two hidden locals every coded
	body is built with". A body generated at RUN time gets a CodE attached
	and NEITHER local, so `runRuleAction(this)` names something that does
	not exist and processCode refuses the parse.
	
	PRESENT-CHECK PER MEMBER, so a define-door rule that already carries
	them is left ALONE -- not re-minted, not replaced. That idempotence is
	the whole point of putting this here rather than in the generator: the
	precondition belongs to compilation, so compile guarantees it for every
	caller instead of each generator remembering.
	
	⚠ `this` NEEDS THE BACK-POINTER, not just the two flags. Both minting
	sites set group to the owning field, which is what makes `this` resolve
	to the rule inside its own body. An ensure that created the member and
	stopped at isLocal/noPrint would look right and still fail.
	
	⚠ THE PRESENT-CHECK IS A SUBSCRIPT, NOT getMember, AND THE DIFFERENCE
	IS A BUG I ALREADY WROTE ONCE. These two are ATTRIBUTES, not members:
	tok's `+=` on a name routes through addString, which does
	`if binType addMember else addAttribute`, and a rule is not a bin. So
	getMember could never find them, the guard would miss every time, and
	compile would re-mint on every call -- the exact non-idempotence this
	block exists to prevent, behind a check that looked correct.
	The subscript runs get(String), which walks the whole list with next()
	and is agnostic between attributes and members, so it finds them.
	(addString is idempotent on its own -- getFromList first -- so this
	guard is belt and braces. It is kept because R-4 asks that an existing
	precondition be left untouched, not merely un-duplicated.)  */
	code = field->get("CodE");
	/*  ⚠ THE SECOND REFUSAL, AND IT IS DELIBERATELY NOT THE FIRST ONE'S
	MESSAGE. Ruling C, 2026-08-22: compile owns its preconditions BY FLAG
	AND BY ARTIFACT, and the two can disagree.
	
	isCoded IS actionType == 2 (GroupBody.h:75). Anything may set that
	flag; only activateBody and compileStored actually mint the CodE, as
	the last of the same three lines. So a caller that hand-sets the flag
	-- which incant/frontier did until 2026-08-22 -- arrives here claiming
	a body it does not have, and the lines below took `code` straight into
	addAttribute. That crashed: SIGSEGV at GroupItem.mm:212, no
	diagnostic, and from a shell it looked like a silent early exit
	because a crash eats buffered stdout.
	
	THE FLAG/ARTIFACT DISAGREEMENT IS ITSELF THE DIAGNOSTIC, which is why
	this must not collapse into the bodyless message above. That one says
	"you never claimed a body". This one says "you claimed one and it is
	not there" -- a different defect, in a different caller, and the two
	sentences send you to different places.  */
	if ( !code )
		{
		return ::refuse(field,"compile: isCoded is set but there is no CodE attribute; the flag and the artifact disagree");
		}
	grup = 0;
	while ( grup = field->next(grup) )
		if ( grup->groupBody->flags.noPrint )
			continue;
		else
		if ( grup->groupBody->flags.isRule )
			code->addAttribute(grup);
	grup = new GroupItem("this");
	grup->groupBody->flags.isLocal = 1;
	grup->groupBody->flags.noPrint = 1;
	grup->setGroup(field);
	grup->options.affiliation = 1;
	code->replace(grup);
	grup = field->get("tempField");
	grup = new GroupItem("tempField");
	grup->groupBody->flags.isLocal = 1;
	grup->groupBody->flags.noPrint = 1;
	grup->options.affiliation = 1;
	code->replace(grup);
	/*  ⚠ A REFUSED RULE MUST NOT TERMINATE THE RUN. Tony's ruling on F-17e,
	2026-08-19. This line was `exit(1)` and that was louder than ruled:
	R-4 asks compile to REPORT and REFUSE, and processCode has already
	reported through reportCodeFail by the time control arrives here, so
	exiting added nothing but the end of the process.
	
	WHAT IT COST is the reason the ruling exists: a flat sweep could never
	report more than its FIRST refusal, so the population figure everyone
	was quoting was a lower bound wearing the shape of a count, and the
	census that would have corrected it was the thing being terminated.
	Returning null makes a refusal a VALUE a caller can tally, which is
	what a per-rule failure report needs.
	
	NO DOUBLE REPORT: processCode owns the message (GroupActions.rtn), and
	compile owns only the verdict.
	
	⚠ THE TATTLE, Tony 2026-08-26 (refuse-loud on the compile road, R-2).
	processCode names its own failure and the position it stopped at, but
	it does NOT say who asked. A sweep over a hundred rules therefore
	produced a column of positions with no patient attached to any of
	them. This line names the rule compile was standing on when the
	refusal came back, so the two messages read as one chain: processCode
	says what broke and where, compile says whom it broke for.
	
	IT IS A NAMING, NOT A VERDICT, AND THE DISTINCTION IS F-17e's RULING
	STILL STANDING: a refused rule does not terminate the run, because a
	flat sweep that exits on its first refusal can never report more than
	one, and the census is the thing being terminated. Adding the name
	costs nothing a caller was relying on -- the return value is unchanged
	and every tally still counts a null as a refusal.  */
	
	gCompileAttempted++;
	
	if ( !::processCode(field) )
		{
		
		gCompileRefused++;
		
		return ::refuse(field,"compile: processCode would not parse the generated body; its message above names the position");
		}
endCompile:
	field->groupBody->flags.hasNewParse = 1;
	return field;
}

/*******************************************************************************
    compileStored -- PHASE 2 UNDER OPTION B: compile OUT OF the corpus, never
    over the live rule. Refuses by name on every missing precondition.

    // compileStored  the preconditions it refuses on, one by one, and why the corpus is the source
*******************************************************************************/
extern "C" GroupItem *compileStored(GroupItem *rule)
{
GroupItem 	*reg = 0;
GroupItem 	*entry = 0;
GroupItem 	*body = 0;
GroupItem 	*hung = 0;
GroupItem 	*out = 0;
	if ( !rule )
		return 0;
	reg = GroupControl::groupController->getRegistry("GenBodies");
	if ( !reg->groupBody->groupList )
		{
		::fprintf(stderr,"compileStored: REFUSING %s -- the corpus is empty\n",rule->groupBody->tag);
		return 0;
		}
	entry = reg->get(rule->groupBody->tag);
	if ( !entry )
		{
		::fprintf(stderr,"compileStored: REFUSING %s -- no stored body\n",rule->groupBody->tag);
		return 0;
		}
	body = entry->getAttribute("StorE");
	if ( !body )
		{
		::fprintf(stderr,"compileStored: REFUSING %s -- the entry carries no body\n",rule->groupBody->tag);
		return 0;
		}
	hung = ::copyOf(body);
	hung->groupBody->tag = "CodE";
	hung->groupBody->flags.noPrint = 1;
	entry->addAttribute(hung);
	entry->groupBody->flags.actionType = 2;
	out = ::compile(entry);
	entry->groupBody->flags.actionType = 0;
	if ( !out )
		return 0;
	entry->setCount(3);
	return GroupControl::groupController->groupRules->trueResult;
}

/* concatEQ  the runtime helper the string-+= JIT call lands on. All the member
   work (getText/setText) and the variadic concat happen here as ordinary C++ —
   this IS the interpreter's isSTRING += body (cf. GroupRules.mm string-concat
   site). Two real GroupItem pointers in, target (mutated in place) out. Its
   address is stable and directly addressable, so jitEmitStringPlusEQ can bake it
   as a constant callee — no variadic IR, no member-function-pointer IR. (One-arg
   parts-walking `concatenate` is the general primitive to follow; the += write-
   back needs target by identity, which two explicit pointers give for free.) */
extern "C" GroupItem *concatEQ(GroupItem *target, GroupItem *argument)
{
	
	target->setText(::concat(2, target->getText(), argument->getText()));
	return target;
	
}

/***************************************************************************
	copyOf() makes a copy of the field passed in. The copy groupBody is a copy.
    if the source isVirtual the copy will share the same list as grup (the source).
    If source is not isVirtual the copy list will be distinct but will have
    the same elements as the source. Difference is adding anything to the
    copy's list will not add anything to the source list.
***************************************************************************/
extern "C" GroupItem *copyOf(GroupItem *grup)
{
GroupItem 	*block = new GroupItem();
	*block->groupBody = *grup->groupBody;
	block->groupBody->flags.isLocal = 0;
	if ( block->groupBody->flags.isVirtual )
		block->groupBody->flags.isVirtual = 0;
	else
	if ( grup->groupBody->groupList )
		{
		block->groupBody->groupList = new GroupList();
		grup->copyListTo(block);
		}
	return block;
}

/*******************************************************************************
    countRuleTerms — how many REAL terms a rule has, by the same classifier the
    emitter walks with. ONE implementer, deliberately: the emitter bakes indices
    against this count and the binder re-checks it, and a check that used its
    own private notion of "real term" would be worth nothing.
*******************************************************************************/
extern "C" int countRuleTerms(GroupItem *rule)
{
GroupItem 	*term = 0;
int 		i = 1;
int 		n = 0;
	while ( term = rule->get(i) )
		{
		if ( !term->groupBody->flags.noPrint )
			n++;
		i++;
		}
	return n;
}

extern "C" char *dataName(int d)
{
	if ( !d )
		return "none";
	else
	if ( d == 1 )
		return "isANY";
	else
	if ( d == 2 )
		return "isCHAR";
	else
	if ( d == 3 )
		return "isSET";
	else
	if ( d == 4 )
		return "isBUFFER";
	else
	if ( d == 5 )
		return "isCOUNT";
	else
	if ( d == 6 )
		return "isGROUP";
	else
	if ( d == 7 )
		return "isITEM";
	else
	if ( d == 8 )
		return "isMAP";
	else
	if ( d == 9 )
		return "isNUMBER";
	else
	if ( d == 10 )
		return "isOBJECT";
	else
	if ( d == 11 )
		return "isREGEX";
	else
	if ( d == 12 )
		return "isSTAK";
	else
	if ( d == 13 )
		return "isSTRING";
	else
	if ( d == 14 )
		return "isTOKEN";
	return "unknown";
}

/***************************************************************************
	The incant debugGuard command invokes this to toggle the debugGuard
    flag in the argument passed in
***************************************************************************/
extern "C" GroupItem *debugOnGuard(GroupItem *input)
{
	if ( !input )
		GroupControl::groupController->groupRules->debugGuards = !GroupControl::groupController->groupRules->debugGuards;
	else
	if ( input->groupBody->flags.fLAG )
		input = input->parent;
	if ( input->groupBody->flags.isRule )
		input->groupBody->flags.debugGuard = !input->groupBody->flags.debugGuard;
	else	::fprintf(stderr,"debugOnGuard: expected a rule argument, got: %s\n",input->groupBody->tag);
	return GroupControl::groupController->groupRules->trueResult;
}

/***************************************************************************
	Searches all rule registries for the rule matching the name passed in
    and if found, toggles its debugRule.
***************************************************************************/
extern "C" void debugRuleNamed(char *name)
{
GroupItem 	*item = GroupControl::groupController->locateInMethod(name);
	if ( item )
		item->groupBody->flags.debugged = !item->groupBody->flags.debugged;
	else	::fprintf(stderr,"debugRuleNamed: could not find %s\n",name);
}

/***************************************************************************
	Print out debug info for the group passed in.
***************************************************************************/
extern "C" void debugText(GroupItem *debugStuff, int flag)
{
char 	*tagText = 0;
char 	*type = 0;
int 	length = 0;
	if ( debugStuff->groupBody->groupList )
		length = debugStuff->groupBody->groupList->listLength;
	/*
	if isCoded          cout ,alignLEFT("coded",10);
	if isMethod || isOperator   cout ,alignLEFT("has method",10);
	if isRule           cout ,alignLEFT("is rule",10);
	if isAction         cout ,alignLEFT("is action",10);
	if registry         cout ,"registry:",registry.tag;
	*/
	::printf("%s",::alignLEFT(debugStuff->groupBody->tag,20));
	if ( debugStuff->groupBody->flags.isPointer )
		tagText = "pointer";
	if ( debugStuff->groupBody->flags.data )
		{
		switch (debugStuff->groupBody->flags.data)
			{
			case 5:
				type = " int";
				break;
			case 9:
				type = " double";
				break;
			case 13:
				type = " string";
				break;
			case 6:
				type = " group";
				break;
			default:
				type = " other";
			}
		if ( !debugStuff->groupBody->flags.noPrint )
			tagText = ::concat(4,debugStuff->groupBody->tag,"=",debugStuff->getText(),type);
		else	tagText = ::concat(3,debugStuff->groupBody->tag," ",type);
		}
	else	tagText = "no data";
	if ( isAttribute(debugStuff->options.affiliation) )
		::printf(" %s",::alignLEFT("attribute",10));
	else
	if ( isMember(debugStuff->options.affiliation) )
		::printf(" %s",::alignLEFT("member",10));
	if ( debugStuff->groupBody->flags.isLocal )
		::printf(" is local");
	if ( debugStuff->groupBody->flags.noPrint )
		::printf(" noPrint");
	if ( length )
		::printf(" length %d",length);
	if ( isGROUP(debugStuff->groupBody->flags.data) && debugStuff->groupBody->gGroup )
		::printf(" %s",debugStuff->groupBody->gGroup->groupBody->tag);
	::printf("\t%s",tagText);
	if ( flag )
		::printf("\n");
}

/*******************************************************************************
    // invariantRprime  runs the two loop shapes side by side on one input so both clauses of R-prime are visible: a passing run alone proves neither
    // minTwoUnreachable  it is a controlled comparison and not a generated rule because the mark clause needs min >= 2, and min >= 2 cannot be reached through the grammar -- measured, the limit is silently not applied
*******************************************************************************/
extern "C" GroupItem *demoRprime(GroupItem *argument)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*rule = ::locateRule("ScafC");
GroupItem 	*term = 0;
GroupItem 	*label = 0;
char 		*entry = 0;
char 		*perPass = 0;
int 		baseStak = 0;
int 		kount = 0;
int 		kids = 0;
int 		going = 1;
	if ( !rule )
		{
		::fprintf(stderr,"demoRprime: no ScafC on the search list\n");
		return 0;
		}
	term = rule->get(1);
	if ( ruler->inputSTAK )
		baseStak = ruler->inputSTAK->length;
	ruler->pushInput(argument);
	entry = ruler->atRuleMark;
	label = new GroupItem("demoEntry");
	while ( ::parseR(term,label) )
		kount++;
	if ( kount >= 2 )
		::fprintf(stderr,"  R-prime MARK  entry-saved (emitted) : matched %s of 2 -- SUCCEEDED, no rewind due\n",::toStringFromInt(kount));
	else {
		ruler->atRuleMark = entry;
		if ( ruler->atRuleMark == entry )
			::fprintf(stderr,"  R-prime MARK  entry-saved (emitted) : matched %s of 2 -- REWOUND to loop entry\n",::toStringFromInt(kount));
		else	::fprintf(stderr,"  R-prime MARK  entry-saved (emitted) : matched %s of 2 -- input STRANDED\n",::toStringFromInt(kount));
		}
	while ( ruler->inputSTAK && ruler->inputSTAK->length > baseStak )
		ruler->popInput();
	kount = 0;
	ruler->pushInput(argument);
	entry = ruler->atRuleMark;
	perPass = entry;
	label = new GroupItem("demoPerPass");
	while ( going )
		{
		perPass = ruler->atRuleMark;
		going = ::parseR(term,label) != 0;
		if ( going )
			kount++;
		}
	if ( kount >= 2 )
		::fprintf(stderr,"  R-prime MARK  per-pass  (parse()) : matched %s of 2 -- SUCCEEDED, no rewind due\n",::toStringFromInt(kount));
	else {
		ruler->atRuleMark = perPass;
		if ( ruler->atRuleMark == entry )
			::fprintf(stderr,"  R-prime MARK  per-pass  (parse()) : matched %s of 2 -- REWOUND to loop entry\n",::toStringFromInt(kount));
		else	::fprintf(stderr,"  R-prime MARK  per-pass  (parse()) : matched %s of 2 -- rewound only to the FAILED PASS, input STRANDED\n",::toStringFromInt(kount));
		}
	while ( ruler->inputSTAK && ruler->inputSTAK->length > baseStak )
		ruler->popInput();
	kount = 0;
	ruler->pushInput(argument);
	label = new GroupItem("demoLabels");
	while ( ::parseR(term,label) )
		kount++;
	while ( label->get(kids + 1) )
		kids++;
	::fprintf(stderr,"  R-prime LABEL entry-saved (emitted) : %s passes attached %s fresh label(s)\n",::toStringFromInt(kount),::toStringFromInt(kids));
	while ( ruler->inputSTAK && ruler->inputSTAK->length > baseStak )
		ruler->popInput();
	return ruler->trueResult;
}

/*****************************************************************************
	The dispatcher is designed to take a group argument disguised as a void*
    The group argument is on the listener notifyLIST. The notifier is the
    notifyLIST parent. dispatcher then runs grup(notifier) in a separate thread.

            if !grup(notifier)  cerr "dispatcher:",grup.tag "(" notifier.tag ") failed":;
            else cout "dispatcher:",grup.tag "(" notifier.tag ") succeeded":;
*****************************************************************************/
extern "C" void dispatcher(void *stuff)
{
GroupItem 	*grup = (GroupItem*)stuff;
GroupItem 	*notifyLIST = grup->parent;
	if ( notifyLIST )
		{
		GroupItem 	*notifier = notifyLIST->parent;
		if ( notifier )
			::fprintf(stderr,"dispatcher: needs to be rewritten\n");
		else	::fprintf(stderr,"dispatcher: ERROR could not get notifier for %s\n",grup->groupBody->tag);
		}
}

/* displayFill  the incant-facing drawing command. THE GATE IS THE WHOLE POINT,
   and it is jitTrace's: under jitting, EMIT A CALL; otherwise DO THE WORK NOW.

   Without the gate a drawing command behaves like `print` under jitting -- it
   fires once at EMIT time, paints the bitmap during compilation, and then never
   runs again. That looks like success on a single-fire POP and is not. With the
   gate the call is emitted into the function body, so it runs PER FIRE, which
   is what DS-4(b) asserts by changing the colour between fires. */
extern "C" GroupItem *displayFill(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	if ( ruler->jitting )
		{
		 jitEmitFill(field); 
		return field;
		}
	 displayFillRT(field); 
	return field;
}

/*******************************************************************************
	Debug: setColor a field then print its resulting RGB components (0.0-1.0),
    to verify setColor's hex parse + scale. POP tool, not called from
    production paths.
*******************************************************************************/
extern "C" void dumpColorRGB(GroupItem *field)
{
	::setColor(field);
	
	NSColor *c = (NSColor*)field->getObject();
	if (c) {
	CGFloat r = 0, g = 0, b = 0, a = 0;
	[c getRed:&r green:&g blue:&b alpha:&a];
	fprintf(stderr,"dumpColorRGB %s: r=%.3f g=%.3f b=%.3f a=%.3f\n", field->getText(), r, g, b, a);
	} else fprintf(stderr,"dumpColorRGB %s: NULL\n", field->getText());
	
}

/***************************************************************************
	The incant dumpContents command runs this. It is used mostly for debugging.
    It lists out the componenst of the argument passed in.
***************************************************************************/
extern "C" GroupItem *dumpContents(GroupItem *stuff)
{
GroupItem 	*grup = 0;
	::debugText(stuff,1);
	while ( grup = stuff->next(grup) )
		{
		::printf("\t");
		//debugLink();
		::debugText(grup,1);
		}
	StringRoutines::debugIndent--;
	if ( isGROUP(stuff->groupBody->flags.data) && !stuff->groupBody->groupList )
		{
		stuff = stuff->getGroup();
		::dumpContents(stuff);
		}
	return GroupControl::groupController->groupRules->trueResult;
}

/*******************************************************************************
	Debug: setFont a field then print its resulting NSFont's displayName +
    bold/italic traits. POP tool, not called from production paths.
*******************************************************************************/
extern "C" void dumpFontInfo(GroupItem *field)
{
	::setFont(field);
	
	NSFont *f = (NSFont*)field->getObject();
	if (f) {
	NSFontSymbolicTraits t = f.fontDescriptor.symbolicTraits;
	fprintf(stderr,"dumpFontInfo %s: displayName='%s' size=%.1f bold=%d italic=%d\n",
	field->resolvedTag(), [f.displayName UTF8String], f.pointSize,
	(t & NSFontDescriptorTraitBold) != 0, (t & NSFontDescriptorTraitItalic) != 0);
	} else fprintf(stderr,"dumpFontInfo %s: NULL\n", field->resolvedTag());
	
}

/*******************************************************************************
    dumpPlanTally — print the two ruling-4 scalars. Called from incant/phaseA as
    the last statement before its sentinel, so a truncated walk cannot print a
    tally and a tally therefore means the walk finished.
*******************************************************************************/
extern "C" GroupItem *dumpPlanTally(GroupItem *argument)
{
	/*  ⚠ THE PREFIX IS `TALLY`, NOT `PLAN TALLY`, AND THAT IS NOT COSMETIC.
	phaseA's A1 completeness guard counts `PLAN <name>` against
	`DONE <name>`; a tally line beginning "PLAN " is counted as a walked
	rule and the guard reads 80 PLAN / 78 DONE -- i.e. THE INSTRUMENT THAT
	DETECTS A TRUNCATED WALK REPORTS A TRUNCATED WALK, caused by the
	instrument added beside it. Measured on the first run of this rung.  */
	::fprintf(stderr,"TALLY refusals = %s\n",::toStringFromInt(planTally(3)));
	::fprintf(stderr,"TALLY plannable = %s\n",::toStringFromInt(planTally(4)));
	return GroupControl::groupController->groupRules->trueResult;
}

/*******************************************************************************
    dumpRulePlans — the CENSUS FIXTURE (Clay SEQ 26). The ladder targets cannot
    test the classifier: Scaf/Scaf2/ScafA/ScafB exercise two kinds out of five
    and never carry an unmaterialised term. This runs the walk over the whole
    27-rule census and prints the plan or the refusal for every one, so the
    classifier gets the POP it otherwise lacks. The assertion is at PLAN level,
    so it is target-independent and survives the kant emitter unchanged.
*******************************************************************************/
extern "C" GroupItem *dumpRulePlans(GroupItem *argument)
{
GroupItem 	*rule = 0;
GroupItem 	*plan = 0;
	::fprintf(stderr,"PLAN %s\n",argument->getText());
	rule = ::ruleOrRefuse(argument->getText(),"  plan");
	if ( !rule )
		return 0;
	plan = ::planRule(rule);
	/*  THE RULING-4 TALLY, counted where the walk is DRIVEN rather than at
	seventeen refusal sites (planTally's header carries the measured
	invariant that licenses this). A refused rule contributed exactly one
	planRule line; a rule refused ON A TERM contributed one more, counted
	inside planRule.  */
	if ( plan )
		{
		planTally(2);
		::printPlan(plan,"  ");
		}
	else	planTally(1);
	return GroupControl::groupController->groupRules->trueResult;
}

/*******************************************************************************
    // termListShape  MEASUREMENT TOOL, not part of the emitter -- kept because it settled what a rule's term list actually holds (source order, the four noPrint code={} tail slots, attribute-vs-member, shared child lists) and re-measuring is one run
*******************************************************************************/
extern "C" GroupItem *dumpRuleTerms(GroupItem *argument)
{
GroupItem 	*rule = GroupControl::groupController->locate(argument->getText());
GroupItem 	*term = 0;
GroupItem 	*definer = 0;
RuleStuff 	*rs = 0;
RuleStuff 	*ruleStuff = 0;
int 		i = 1;
	if ( !rule )
		{
		::fprintf(stderr,"dumpRuleTerms: no rule named  %s\n",argument->getText());
		return 0;
		}
	ruleStuff = rule->getRStuff();
	::fprintf(stderr,"RULE %s fold=%s\n",rule->groupBody->tag,foldOf(rule));
	if ( rule->groupBody->flags.isRule )
		::fprintf(stderr,"     isRule\n");
	if ( !rule->groupBody->flags.isRule )
		::fprintf(stderr,"     NOT isRule\n");
	if ( rule->groupBody->registry )
		::fprintf(stderr,"     registry %s\n",rule->groupBody->registry->groupBody->tag);
	::fprintf(stderr,"     rule.data=%s\n",::dataName(rule->groupBody->flags.data));
	if ( ruleStuff && ruleStuff->onGroup )
		::fprintf(stderr,"     rule.onGroup=%s\n",ruleStuff->onGroup->groupBody->tag);
	if ( !ruleStuff )
		::fprintf(stderr,"     rule has NO rStuff\n");
	else
	if ( !ruleStuff->onGroup )
		::fprintf(stderr,"     rule.onGroup=NONE\n");
	while ( term = rule->get(i) )
		{
		rs = term->getRStuff();
		definer = term->definingRule();
		::fprintf(stderr,"    [%s] %s\n",::toStringFromInt(i),term->groupBody->tag);
		if ( term->groupBody->flags.noPrint )
			::fprintf(stderr,"         noPrint (SKIPPED by the walk)\n");
		else {
			::fprintf(stderr,"         ROW  %s\n",row42(term));
			if ( definer != term )
				::fprintf(stderr,"         REFERENCE -> %s\n",definer->groupBody->tag);
			::fprintf(stderr,"         data %s\n",::dataName(term->groupBody->flags.data));
			if ( isAttribute(term->options.affiliation) )
				::fprintf(stderr,"         attribute\n");
			if ( isMember(term->options.affiliation) )
				::fprintf(stderr,"         member\n");
			if ( rs )
				{
				::fprintf(stderr,"         min %s max %s\n",::toStringFromInt(rs->min),::toStringFromInt(rs->max));
				if ( rs->noLabel )
					::fprintf(stderr,"         noLabel\n");
				if ( rs->isTarget )
					::fprintf(stderr,"         isTarget\n");
				if ( rs->banged )
					::fprintf(stderr,"         banged\n");
				if ( rs->noAdvance )
					::fprintf(stderr,"         noAdvance\n");
				if ( rs->noSkip )
					::fprintf(stderr,"         noSkip\n");
				if ( rs->isOption )
					::fprintf(stderr,"         isOption\n");
				if ( rs->notifyFail )
					::fprintf(stderr,"        notifyFail\n");
				if ( rs->doNothing )
					::fprintf(stderr,"         doNothing\n");
				if ( rs->testMatch )
					::fprintf(stderr,"         testMatch SET\n");
				if ( !rs->testMatch )
					::fprintf(stderr,"         testMatch none\n");
				if ( rs->onGroup )
					::fprintf(stderr,"         onGroup %s\n",rs->onGroup->groupBody->tag);
				if ( !rs->onGroup )
					::fprintf(stderr,"         onGroup NONE\n");
				}
			if ( !rs )
				::fprintf(stderr,"         NO rStuff\n");
			}
		i++;
		}
	return GroupControl::groupController->groupRules->trueResult;
}

/*******************************************************************************
    // oracleIsTheReplaced  emitLeaf's own fixture: THE ORACLE IS THE FUNCTION BEING REPLACED, captured under both sinks while the C++ emitLeaf is still the only implementation, because LITTO is reached by no ladder rule and was ungated
*******************************************************************************/
extern "C" GroupItem *dumpSpellings(GroupItem *argument)
{
GroupItem 	*rule = 0;
GroupItem 	*plan = 0;
GroupItem 	*node = 0;
GroupItem 	*at = 0;
char 		*local = 0;
char 		*piece = 0;
	::fprintf(stderr,"SPELL %s\n",argument->getText());
	rule = ::ruleOrRefuse(argument->getText(),"  spell");
	if ( !rule )
		return 0;
	plan = ::planRule(rule);
	if ( !plan )
		{
		::fprintf(stderr,"  no plan\n");
		return 0;
		}
	::fprintf(stderr,"  fold %s\n",plan->groupBody->tag);
	while ( node = plan->nextMember(node) )
		{
		at = node->getAttribute("at");
		local = ::concat(2,"t",at->getText());
		piece = ::emitLeaf(node,local,"label");
		if ( !piece )
			piece = "REFUSED";
		::fprintf(stderr,"  %s sink=label %s\n",node->groupBody->tag,piece);
		piece = ::emitLeaf(node,local,"into");
		if ( !piece )
			piece = "REFUSED";
		::fprintf(stderr,"  %s sink=into  %s\n",node->groupBody->tag,piece);
		}
	return GroupControl::groupController->groupRules->trueResult;
}

/*******************************************************************************
    // leafIsTarget  one plan node -> one leaf expression string; everything here is about the TARGET and nothing about the rule, which is the whole reason the seam exists
*******************************************************************************/
extern "C" char *emitLeaf(GroupItem *node, char *local, char *sink)
{
GroupItem 	*speller = ::locateSpeller();
GroupItem 	*slot = 0;
GroupItem 	*site = 0;
GroupItem 	*inner = 0;
char 		dq = 34;
char 		*leaf = 0;
char 		*piece = 0;
	/*  IF A KANT SPELLER IS REGISTERED, ITS ANSWER IS AUTHORITATIVE — INCLUDING
	NULL. Falling back to the C++ body on a null would mean a kant refusal
	(or a kant bug) silently produced the right text, and the whole point of
	the handover is that a kant defect must be VISIBLE. So the lookup decides
	which implementation runs, and the result never does.
	
	Absent a speller this is byte-for-byte the function it always was, which
	is why every existing target still holds. Same shape as parseMethod's
	fork: bind if it is there, run the oracle if it is not.  */
	if ( speller )
		return ::spellKant(speller,node,sink);
	if ( ::compare(node->groupBody->tag,"OPT") == 0 )
		{
		inner = node->nextMember(inner);
		if ( !inner )
			{
			::fprintf(stderr,"emitLeaf: OPT node has no wrapped term\n");
			return 0;
			}
		piece = ::emitLeaf(inner,local,sink);
		if ( !piece )
			return 0;
		leaf = ::concat(3,"(",piece," || 1)");
		}
	else
	if ( ::compare(node->groupBody->tag,"MANY") == 0 )
		{
		site = node->getAttribute("site");
		leaf = ::concat(7,"many",site->getText(),"(",sink,",",local,")");
		}
	else
	if ( ::compare(node->groupBody->tag,"CONTAINER") == 0 )
		{
		slot = node->getAttribute("slot");
		leaf = ::concat(9,"containerTo(",local,",",sink,",",::toStringFromChar(dq),slot->getText(),::toStringFromChar(dq),")");
		}
	else
	if ( ::compare(node->groupBody->tag,"CALL") == 0 )
		leaf = ::concat(5,"parseR(",local,",",sink,")");
	else
	if ( ::compare(node->groupBody->tag,"LIT") == 0 )
		leaf = ::concat(7,"lit(",local,",",::toStringFromChar(dq),node->getText(),::toStringFromChar(dq),")");
	else
	if ( ::compare(node->groupBody->tag,"LITTO") == 0 )
		{
		slot = node->getAttribute("slot");
		if ( ::compare(sink,"into") == 0 )
			leaf = ::concat(7,"litOption(",local,",into,",::toStringFromChar(dq),node->getText(),::toStringFromChar(dq),")");
		else	leaf = ::concat(11,"litTo(",local,",label,",::toStringFromChar(dq),node->getText(),::toStringFromChar(dq),",",::toStringFromChar(dq),slot->getText(),::toStringFromChar(dq),")");
		}
	else {
		::fprintf(stderr,"emitLeaf: no emission for plan kind %s\n",node->groupBody->tag);
		return 0;
		}
	return leaf;
}

/*******************************************************************************
    // emitManyInvariantR  the repetition helper, and where invariant R-prime lives: `from` is captured ONCE at entry so a short run gives back the WHOLE run, and each pass builds a fresh label because nothing here touches fLAG
*******************************************************************************/
extern "C" int emitMany(GroupItem *node)
{
GroupItem 	*manier = ::locateManier();
GroupItem 	*site = node->getAttribute("site");
GroupItem 	*low = node->getAttribute("min");
char 		*name = 0;
	/*  THE FORK. Absent a kant emitMany this is the function it always was, so
	every existing target holds with or without incant/genMany present —
	which is emitLeaf's proven shape and the reason the C++ body is not
	deleted during a conversion round.  */
	if ( manier )
		return ::manyKant(manier,node);
	if ( !site || !low )
		{
		::fprintf(stderr,"emitMany: MANY node has no site/min\n");
		return 0;
		}
	name = ::concat(2,"many",site->getText());
	::fprintf(stderr,"extern int %s(GroupItem label, GroupItem term)\n",name);
	::fprintf(stderr,"{\n");
	::fprintf(stderr,"GroupRules  ruler = groupRules;\n");
	::fprintf(stderr,"String      from = atRuleMark;\n");
	::fprintf(stderr,"int         kount;\n");
	::fprintf(stderr,"    while parseR(term,label)    kount++;\n");
	::fprintf(stderr,"    if kount >= %s   return true;\n",low->getText());
	::fprintf(stderr,"    atRuleMark = from;\n");
	::fprintf(stderr,"    return false;\n");
	::fprintf(stderr,"}\n");
	return 1;
}

/*******************************************************************************
    emitPlan — a plan tree -> C++ text. The emitter side of the seam (§4): the
    frame preamble, joining conjuncts with &&, quoting. It reads the plan and
    NEVER the rule, which is the property that makes it replaceable.

    ALT is REFUSED rather than emitted. The old interleaved path would have
    written a SEQ frame with && joins for an alternation, which was simply
    wrong; a plan makes the fold explicit, so the wrongness became visible the
    moment there was something to look at. leaveAlt/|| emission arrives with the
    alternation rung.
*******************************************************************************/
extern "C" GroupItem *emitPlan(GroupItem *plan)
{
GroupItem 	*node = 0;
GroupItem 	*lab = 0;
GroupItem 	*at = 0;
char 		*tag = plan->getText();
char 		*terms = 0;
char 		*local = 0;
char 		*index = 0;
char 		*piece = 0;
char 		*sink = 0;
char 		*joiner = 0;
int 		isAlt = 0;
int 		first = 1;
int 		n = 0;
char 		dq = 34;
	if ( ::compare(plan->groupBody->tag,"ALT") == 0 )
		isAlt = 1;
	else
	if ( ::compare(plan->groupBody->tag,"SEQ") != 0 )
		{
		::fprintf(stderr,"emitPlan: REFUSING %s -- fold %s has no emitter\n",tag,plan->groupBody->tag);
		return 0;
		}
	// altBuildsNoLabel  the fold decides the sink and the joiner, and an ALT builds NO label of its own -- getting it wrong yields the right LANGUAGE over the WRONG TREE, which passes every win check
	if ( isAlt )
		{
		sink = "into";
		joiner = " || ";
		}
	else {
		sink = "label";
		joiner = " && ";
		lab = plan->getAttribute("label");
		}
	/*  FIRST PASS: validate every node, and emit the helpers §3.3 calls for.
	This is what the two-pass shape exists for — a helper is discovered
	mid-walk, and with text already going out you would have to buffer it or
	emit it out of order. With a plan you simply walk it again.  */
	while ( node = plan->nextMember(node) )
		{
		if ( isAlt )
			if ( ::compare(node->groupBody->tag,"CALL") != 0 && ::compare(node->groupBody->tag,"LITTO") != 0 )
				{
				::fprintf(stderr,"emitPlan: REFUSING %s -- %s as an alternation option (no census shape)\n",tag,node->groupBody->tag);
				return 0;
				}
		at = node->getAttribute("at");
		index = at->getText();
		local = ::concat(2,"t",index);
		piece = ::emitLeaf(node,local,sink);
		if ( !piece )
			{
			::fprintf(stderr,"emitPlan: REFUSING %s -- unemittable plan node\n",tag);
			return 0;
			}
		if ( ::compare(node->groupBody->tag,"MANY") == 0 )
			if ( !::emitMany(node) )
				{
				::fprintf(stderr,"emitPlan: REFUSING %s -- unemittable repetition helper\n",tag);
				return 0;
				}
		// zeroMeansSelfBind  the marker-0 node is NOT a term, so it must not reach the emitted parseTerms= count -- parseRuleMethod's staleness guard was right and the bind line was the thing telling an untruth
		if ( ::compare(index,"0") != 0 )
			{
			n++;
			}
		}
	::fprintf(stderr,"extern GroupItem parse%s(GroupItem rule)\n",tag);
	::fprintf(stderr,"{\n");
	::fprintf(stderr,"GroupItem   into  = rule.rStuff.parentLabel;\n");
	if ( !isAlt )
		::fprintf(stderr,"GroupItem   label = new(%c%s%c);\n",dq,lab->getText(),dq);
	node = 0;
	while ( node = plan->nextMember(node) )
		{
		at = node->getAttribute("at");
		index = at->getText();
		local = ::concat(2,"t",index);
		/*  ZERO MEANS SELF. Ruled 2026-08-24, rule-ladder rung two. Index 0 is
		the rule's OWN data rather than a term slot, so the local it names
		binds to the RULE NODE ITSELF -- not to rule[0], which indexes
		nothing because term indices are 1-based. The referent of "no term"
		is the rule whose own text carries the tag, via bear-trap 26's
		fallback (a field with no data reads back as its name).
		Term indices are untouched and stay 1-based.  */
		if ( ::compare(index,"0") == 0 )
			::fprintf(stderr,"GroupItem   %s = rule;\n",local);
		else	::fprintf(stderr,"GroupItem   %s = rule[%s];\n",local,index);
		piece = ::emitLeaf(node,local,sink);
		if ( first )
			terms = piece;
		else	terms = ::concat(3,terms,joiner,piece);
		first = 0;
		}
	::fprintf(stderr,"String      from  = atRuleMark;\n");
	if ( isAlt )
		::fprintf(stderr,"    return leaveAlt(rule,from, %s );\n",terms);
	else	::fprintf(stderr,"    return leaveRule(rule,into,label,from, %s );\n",terms);
	::fprintf(stderr,"}\n");
	::fprintf(stderr,"/*  bind:  %s parseTerms=%s parseMethod=parse%s;  */\n",tag,::toStringFromInt(n),tag);
	return GroupControl::groupController->groupRules->trueResult;
}

/***************************************************************************
	The fAIL method expects to have the name of the fail method passed in as
    text of the FAIL attribute.
***************************************************************************/
extern "C" GroupItem *fAIL(GroupItem *input)
{
char 	*name = input->getText();
	if ( input->groupBody->flags.fLAG )
		if ( name )
			{
			input->setMethod((GroupItem*(*)(GroupItem*))::dlsym(RTLD_SELF,name));
			if ( !input->groupBody->gMethod )
				::fprintf(stderr,"FAIL: could not find method: %s\n",name);
			else {
				input->setPointer((void*)0);
				input->groupBody->flags.instructType = 1;
				}
			}
		else	::fprintf(stderr,"FAIL: no fail method argument provided\n");
	else	::fprintf(stderr,"FAIL: should be a rule attribute\n");
	return GroupControl::groupController->groupRules->trueResult;
}

extern "C" GroupItem *fireNewParse(GroupItem *rule)
{
GroupItem 	*artifact = 0;
	if ( !rule )
		return 0;
	artifact = rule->getAttribute("ParsE");
	/*  THE DISCRIMINATOR, and it is why this line exists rather than being
	debug residue: with two arms live in the gate, a correct product proves
	nothing about WHICH MACHINERY MADE IT. Gated on the standing parseTrace
	flag so it joins the existing idiom instead of inventing a switch.  */
	if ( GroupControl::groupController->groupRules->parseTrace )
		::fprintf(stderr,"  fireNewParse ARTIFACT ARM on %s -> %s\n",rule->groupBody->tag,artifact->getText());
	/*  TWO ARTIFACT KINDS, ONE GATE, and the split is not an implementation
	detail -- the two generators produce different things:
	
	ParsE  -- a dlsym-able C++ METHOD NAME, parked by parkParse from the
	`parseMethod=` bind path. There is no node to park for a
	function pointer, so the artifact holds the name and this
	site resolves it.
	CodE   -- an INCANT BODY parked by a walking generator
	(IncantForms/WorkingOn/parser's genParseTest is the live
	one), compiled in place and fired as the rule's own action.
	
	⚠ THE FLAG MEANS "AN ARTIFACT IS PARKED", NEVER "WHICH KIND". Reading
	one channel for two facts is this project's most expensive recurring
	shape, so the KIND is answered by looking, not by the flag.  */
	if ( !artifact )
		{
		if ( rule->getAttribute("CodE") )
			{
			if ( GroupControl::groupController->groupRules->parseTrace )
				::fprintf(stderr,"  fireNewParse CODE ARM on %s\n",rule->groupBody->tag);
			return ::processAction(rule);
			}
		::fprintf(stderr,"fireNewParse: WRECKAGE on %s -- hasNewParse is set but there is neither a ParsE name nor a CodE body to fire. NOT falling through to the old parse.\n",rule->groupBody->tag);
		return 0;
		}
	
	void *address = ::dlsym(RTLD_DEFAULT,artifact->getText());
	if ( !address )
	{
	::fprintf(stderr,"fireNewParse: ERROR no method found %s\n",artifact->getText());
	return 0;
	}
	return ((GroupItem *(*)(GroupItem *))address)(rule);
	
}

/***************************************************************************
    Buffer-side mark machinery wrappers — thin passthroughs to Buffer's
    setMark/unMark/setFile/closeFile. Used by incant code that wants
    explicit control over the mark, and by applyTextDirective to
    arm/disarm Buffer.markIsSet around find-and-replace sweeps.
***************************************************************************/
extern "C" void flushBuffer(GroupItem *bufField)
{
	if ( isBUFFER(bufField->groupBody->flags.data) )
		bufField->getBuffer()->flush();
}

/*******************************************************************************
    foldOf — genParseSpec §4.1's fold selection, as a reportable value.
*******************************************************************************/
extern "C" char *foldOf(GroupItem *rule)
{
	if ( rule->groupBody->flags.isRule && rule->groupBody->flags.hasMembers && !rule->groupBody->flags.binType )
		return "ALT";
	return "SEQ";
}

/*****************************************************************************
	frameFind -- read-only twin. Returns null when no frame child exists, so
	restore can tell "never saved" from "saved nothing" without minting one.
*****************************************************************************/
extern "C" GroupItem *frameFind(GroupItem *action)
{
	return action->get("frameSTAK");
}

/*****************************************************************************
	frameStak -- THE FRAME BRACKET'S SAVE-STACK LIVES ON A noPrint CHILD OF THE
	ACTION, NEVER IN THE ACTION'S OWN DATA SLOT.

	THE DEFECT THIS REPAIRS, measured 2026-08-30. saveLocalFields opened with
	`action.stak = recurseSTAK`, which writes the action node's DATA slot. For
	an ordinary action that slot is empty and the write is free. For a field
	that carries BOTH DATA AND A CODE BLOCK -- `lefty=3 code={ lefty += 43; }`,
	the shape incant/unitTests documents as incant's distinguishing feature --
	that slot holds the VALUE, and the bracket destroyed it. Measured directly:

	    SLFENTRY action=spSelf data=5  text=3        <- the field holds 3
	    SLFAFTER action=spSelf data=12 text=spSelf   <- data 12 = isSTAK, value gone

	It read as CLAIM KANT-8's own symptom -- a field answering with its own tag
	-- which is why it hid: the KANT-8 family is green on every row while this
	is broken, because no K-row uses a data-carrying action.

	ONE CHANNEL, ONE MEANING. The node's data slot was carrying the FIELD'S
	VALUE and the FRAME'S SAVE-STACK. The cure is the standing one: a second
	channel, not a cleverer test.

	⚠ IT IS A REPAIR, NOT A SEMANTICS CHANGE, and rung B stands whole. The law
	is that the bracket touches exactly MINTED SCRATCH; a defined field's value
	was never its business. The recursive gates stay SHUT -- they are set at
	parse time BY IDENTITY so mutual recursion never sets them, and cleared at
	run time so behaviour follows invocation history. Both diseases documented.

	SEPARATE FUNCTION on purpose: a declaration introduced into a declared-field
	tok function re-binds every bare member name in scope, INCLUDING LINES ABOVE
	IT. A call introduces no declaration. Same shape as parkOnMaster/frameParent.
*****************************************************************************/
extern "C" GroupItem *frameStak(GroupItem *action)
{
GroupItem 	*frame = action->get("frameSTAK");
	if ( frame )
		return frame;
	frame = action->addString("frameSTAK");
	frame->groupBody->flags.noPrint = 1;
	return frame;
}

/*******************************************************************************
    ⚠ EMITTED TO stderr, NOT stdout, and that is bear-trap #14: a run that
    ends via stop() exits hard with no flush, so buffered stdout vanishes and
    looks exactly like an emitter that never ran.

    // kantRatchetOracle  emits a rule's kant parse body from its live terms -- a hand-written body is a manual run of this, and byte-identity with the certified hand body inherits its certification
    // liveTermsNotEye  walks planRule's classified plan, so indices and kinds come from the rule as it is in the tree right now
*******************************************************************************/
extern "C" GroupItem *genKant(GroupItem *argument)
{
GroupItem 	*rule = 0;
GroupItem 	*plan = 0;
GroupItem 	*node = 0;
GroupItem 	*at = 0;
char 		*body = 0;
char 		*piece = 0;
int 		n = 0;
	rule = ::ruleOrRefuse(argument->getText(),"  kant");
	if ( !rule )
		return 0;
	plan = ::planRule(rule);
	if ( !plan )
		{
		::fprintf(stderr,"genKant: REFUSING %s -- no plan\n",argument->getText());
		return 0;
		}
	// foldGateRepair  the join below is unconditionally " AND ", correct for a SEQ and WRONG for an ALT, so an ungated emitter produced bodies that parse and answer wrong -- and nothing caught it because a per-item guard does not see a whole-body property
	if ( ::compare(plan->groupBody->tag,"SEQ") != 0 )
		{
		::fprintf(stderr,"genKant: REFUSING %s -- fold is %s, and only SEQ has a kant spelling\n",argument->getText(),plan->groupBody->tag);
		return 0;
		}
	while ( node = plan->nextMember(node) )
		{
		at = node->getAttribute("at");
		piece = kantLeaf(node,at->getText());
		if ( !piece )
			{
			::fprintf(stderr,"genKant: REFUSING %s -- term %s is %s, which has no kant spelling\n",argument->getText(),at->getText(),node->groupBody->tag);
			return 0;
			}
		if ( n )
			body = ::concat(3,body," AND ",piece);
		else	body = piece;
		n = n + 1;
		}
	if ( !n )
		{
		::fprintf(stderr,"genKant: REFUSING %s -- plan has no terms\n",argument->getText());
		return 0;
		}
	::fprintf(stderr,"define\n");
	::fprintf(stderr,"    kp%s code={\n",argument->getText());
	::fprintf(stderr,"        return %s;\n",body);
	::fprintf(stderr,"        };\n");
	::fprintf(stderr,"    ;\n");
	return GroupControl::groupController->groupRules->trueResult;
}

/*******************************************************************************
    // twoPassesPlanThenWrite  two passes: planRule DECIDES and emitPlan WRITES, nothing between them knows about C++ -- and emitPlan walks the plan TWICE, once to validate and once to write, which is why the seam artifact is a plan and not a visitor
*******************************************************************************/
extern "C" GroupItem *genParse(GroupItem *argument)
{
GroupItem 	*rule = ::ruleOrRefuse(ruleNameArg(argument),"genParse");
GroupItem 	*plan = 0;
GroupItem 	*result = 0;
	if ( !rule )
		return 0;
	plan = ::planRule(rule);
	if ( !plan )
		return 0;
	
	// recordSite  the emitter writes the ParsE record because only the emitter has the text; parseRuleMethod binds the symbol and writes nothing
	// sinkNotTee  the capture swaps the SINK rather than teeing emitPlan's fourteen cerr sites, so record and emission are the same bytes
	/*  ⚠ THE SWAP MUST STAY AT THE `FILE *` LEVEL. tok's `cerr` keyword
	generates ::fprintf(stderr,...), NOT std::cerr, so an rdbuf() swap
	captures ZERO BYTES -- emission perfect, record empty, exit 0. Measured
	2026-08-06 by writing exactly that bug.
	⚠ ONE STRAIGHT LINE, NO EARLY RETURN between the swap and the restore.
	If that stops being true stderr stays redirected and the operator loses
	the emitter's output with no symptom but silence.  */
	// oneGate  one gate arms capture, the attribute AND the file sink together; an always-on attribute write moves the AUDIT lines
	char   *rp      = ::getenv("INCANT_PARSE_RECORD");
	/*  GX-6: the in-fixture door onto the SAME gate. Env var wins when both are
	set, because only it can carry a path.  */
	if (!rp && gParseRecordArmed)   rp = (char*)"1";
	char   *recBuf  = 0;
	size_t  recSize = 0;
	FILE   *ms      = rp ? ::open_memstream(&recBuf,&recSize) : 0;
	FILE   *wasErr  = stderr;
	if (ms) stderr  = ms;
	result = ::emitPlan(plan);
	if (ms) {
	stderr = wasErr;
	::fclose(ms);
	if (recBuf) {
	::fwrite(recBuf,1,recSize,stderr);
	::fflush(stderr); } }
	if (rp) {
	/*  strdup'd for the same reason jitRunAction strdups its IR: recBuf is
	malloc'd by open_memstream and is freed below.  */
	GroupItem  *pe = rule->get("ParsE");
	if (!pe) {
	pe = new GroupItem("ParsE");
	pe->groupBody->flags.noPrint = 1;
	pe->setText(::strdup(recBuf ? recBuf : ""));
	rule->addAttribute(pe); }
	else    pe->setText(::strdup(recBuf ? recBuf : ""));
	
	/*  ⚠ THE DUMP READS pe->getText() AND NEVER recBuf. The point is to
	prove what LANDED ON THE NODE -- dumping the local would pass even
	if addAttribute had silently done nothing.  */
	if (::compare(rp,"1") != 0) {
	if (FILE *f = ::fopen(rp,"w")) {
	char *got = pe->getText();
	if (got)    ::fwrite(got,1,::strlen(got),f);
	::fclose(f); }
	else ::fprintf(stderr,"genParse: ParsE record could not open %s\n",rp); } }
	if (recBuf) ::free(recBuf);
	
	return result;
}

/***************************************************************************
    runJSONblock (genParseSpec S5.3's entry wrapper) is RETIRED, genParseShape
    S1.7. Generated code emits no entry wrapper: invocation is JSONblock(...)
    through parse()'s fork, exactly as Start(). The wrapper called
    parseJSONblock directly, so it could have passed with the binding wholly
    unbuilt -- it exercised neither the fork, nor binding, nor dispatch, which
    are the three things the runtime loop exists to test. Its one real service,
    the Invariant R report, now lives in leaveRule (S1.8) where `from` and
    atRuleMark are both in hand. Restore from git history if a direct-call
    harness is ever wanted again; do not re-emit one.
***************************************************************************/
/*****************************************************************************
    This is the simplified generateCode command method that leaves dirty work
    to the incant actions in the incant generate file
*****************************************************************************/
extern "C" GroupItem *generateCode(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	if ( !ruler->generator )
		ruler->generator = GroupControl::groupController->locate("generator");
GroupItem 	*generate = ruler->generator->get("generatE");
	if ( isCoded(generate->groupBody->flags.actionType) )
		if ( !::processCode(generate) )
			return 0;
	ruler->generating = 1;
	if ( isCoded(field->groupBody->flags.actionType) )
		if ( !::processCode(field) )
			return 0;
	ruler->generating = 0;
GroupItem 	*BlocK = field->getLabelGroup("BlocK");
GroupItem 	*bcLIST = new GroupItem("bcLIST");
	bcLIST->groupBody->groupList = new GroupList();
	bcLIST->groupBody->flags.noPrint = 1;
	field->addAttribute(bcLIST);
	bcLIST = ruler->generator->replace(bcLIST);
	if ( !ruler->generator )
		::fprintf(stderr,"generateCode: could not find generator\n");
	else {
		generate = ruler->generator->get("generatE");
		if ( !generate )
			::fprintf(stderr,"generateCode: could not find generatE() action\n");
		else
		if ( BlocK )
			{
			::printf("generateCode: running on %s\n",field->groupBody->tag);
			::runAction(BlocK,generate);
			}
		}
	// Copy the accumulated instructions from generator's bcLIST back to the
	// action's own bcLIST. Both slots are kept by design; this just brings the
	// action's copy up to date after generation runs (emitBC accumulates into
	// generator's bcLIST via :generator bcLIST).
GroupItem 	*fieldList = field->getAttribute("bcLIST");
	::dumpContents(fieldList);
	fieldList->groupBody->flags.byRef = 1;
	return fieldList;
}

/*******************************************************************************
    generateXP — the `generating` mode: build a flat-RPN revisedList from the
    parsed expression and emit nothing (the bytecode walk emits later). Members
    are added BY REFERENCE; gXpress launders them with copyOf at bytecode-emit
    time. (jitXP, its copyOf-on-append twin for the JIT lowering, was folded out
    2026-06-30 — JIT now falls through to interpretXP per the unified
    emit-on-walk pivot; see docs/jitDesign.md.)
*******************************************************************************/
extern "C" GroupItem *generateXP(GroupItem *xpList)
{
GroupItem 	*op = 0;
GroupItem 	*target = 0;
GroupItem 	*arg = 0;
GroupItem 	*xl = 0;
GroupItem 	*token = 0;
GroupItem 	*revisedList = new GroupItem("revisedList");
GroupItem 	*grup = 0;
GroupItem 	*store = 0;
GroupItem 	*tgt = 0;
	if ( xpList->groupBody->groupList->listLength == 1 )
		{
		arg = xpList->groupBody->groupList->firstInList;
		
		
		revisedList->addMember(arg);
		}
	else {
		/******************************************************************
		Mirror the non-generating walk's op/target/arg identification
		(right-to-left, precedence-correct via the same state machine),
		but emit flat RPN instead of building the runOP tree: for each
		completed instruction emit target, then arg (when a leaf), then
		op; for '=' emit the value then a bcStoreField carrying target.
		*******************************************************************/
		// No-operator expression (a bare operand sequence, e.g. the print
		// operands `"hello" name`): the RPN walk below only emits when it
		// completes an op+target, so with no operator it produces an EMPTY
		// revisedList and the clear() below would destroy the tokens. Detect
		// that and leave xpList intact so aCTionPrinT/appendGroup can print
		// the operands directly. (Operator expressions fall through to RPN.)
		GroupItem *hasOp = 0;
		GroupItem *tk = 0;
		while ( tk = xpList->prior(tk) )
			if ( isOperator(tk->groupBody->flags.instructType) )
				hasOp = tk;
		if ( !hasOp )
			{
			xpList->groupBody->flags.binType = 3;
			xpList->groupBody->flags.reversePrint = 1;
			return xpList;
			}
		while ( token = xpList->prior(token) )
			{
			grup = token;
			// Operator-skip guard: never unwrap an operator. Operators carry
			// their interpret=/operateMethod= as attributes (e.g. > has
			// interpret=runGT), which is the dispatch handler gXpress/
			// interpretBC need — unwrapping would dis-member the op.
			if ( isGROUP(grup->groupBody->flags.data) && !isOperator(grup->groupBody->flags.instructType) )
				while ( isGROUP(grup->groupBody->flags.data) )
					grup = grup->getGroup();
			if ( isOperator(grup->groupBody->flags.instructType) )
				op = grup;
			else {
				if ( !arg )
					arg = grup;
				else
				if ( op )
					target = grup;
				}
			if ( op )
				if ( target )
					{
					if ( ::compare(op->groupBody->tag,"=") == 0 )
						{
						if ( !arg->groupBody->gMethod )
							revisedList->addMember(arg);
						store = ::copyOf(GroupControl::groupController->groupRules->bcOPs->get("bcStoreField"));
						tgt = new GroupItem("target");
						tgt->setGroup(target);
						store->addAttribute(tgt);
						revisedList->addMember(store);
						}
					else {
						revisedList->addMember(target);
						if ( !arg->groupBody->gMethod )
							revisedList->addMember(arg);
						revisedList->addMember(op);
						}
					xl = new GroupItem("xl");
					xl->setMethod(::runOP);
					op = 0;
					target = 0;
					arg = xl;
					}
			}
		}
	::dumpContents(revisedList);
	xpList->clear();
	xpList->setGroup(revisedList);
	return xpList;
}

/***************************************************************************
	Return a string from the stream passed in converting newLines to space
***************************************************************************/
extern "C" char *getDebugText(char *input, int length)
{
char 	*debugText = (char*)::calloc(length + 2,sizeof(char));
char 	*atInput = debugText;
int 	advance = 0;
	if ( input )
		while ( *input && length > advance )
			{
			if ( *input == '\n' )
				{
				*atInput++ = '#';
				input++;
				}
			else	*atInput++ = *input++;
			advance++;
			}
	if ( advance <= 1 )
		debugText = ":reached end of input";
	return debugText;
}

extern "C" GroupItem *getFile(GroupItem *filing)
{
GroupItem 	*File = filing->getLabelGroup("File");
long 		length = 0;
long 		increment = 0;
int 		file = 0;
char 		*fileName = 0;
Buffer 		*buffet = 0;
	if ( !filing )
		{
		::fprintf(stderr,"getFile: no file name provided\n");
		return 0;
		}
	if ( File )
		fileName = File->getText();
	else	fileName = filing->getText();
	file = ::open(fileName,O_RDWR);
	if ( file > 0 )
		{
		length = ::lseek(file,0,SEEK_END);
		increment = length + 500;
		/**********************************************************************
		Make sure filing has a buffer to stuff input into
		**********************************************************************/
		if ( !isBUFFER(filing->groupBody->flags.data) )
			{
			filing->setBuffer(new Buffer(filing->groupBody->tag,(int)increment));
			filing->getBuffer()->setFile(fileName);
			buffet = filing->getBuffer();
			}
		else {
			buffet = filing->getBuffer();
			buffet->reSize((int)increment);
			}
		::lseek(file,0,SEEK_SET);
		increment = read(file,buffet->start,length);
		if ( increment != length )
			::fprintf(stderr,"getFile: Problem reading in %s\n",filing->groupBody->tag);
		else	buffet->current = buffet->start + length;
		::close(file);
		}
	else {
		char 	*errorMessage = ::concat(2,"getFile: could not open file: ",fileName);
		::fprintf(stderr,"\tcurrent directory: ");
		::system("pwd");
		::checkSys(file,errorMessage);
		}
	return filing;
}

/*****************************************************************************
    The argument passed in to getMarkLineAt must have source and fromThis ƒ
    It returns the line wrapped in a GroupItem field using setToken (as a stream
    pointer into the buffer with a length). The field will only contain
    valid text as long as the buffer contains it in place. Note: getMarkLineAt
    calls findInBuffer to locate the matching line so if there is already
    a mark set, it will search for the matching line from that mark on.
    It then sets mark at beginning of the line in the source buffer. This
    method is called by the getLine incant command defined in setup.
*****************************************************************************/
extern "C" GroupItem *getMarkLineAt(GroupItem *argument)
{
GroupItem 	*source = argument->get("source");
GroupItem 	*fromThis = argument->get("fromThis");
GroupItem 	*result = 0;
	/*  ⚠ NOT A SENTINEL-AS-DATA SITE, and the 2026-09-05 table said it was.
	`result` is a bare local -- tok emits `GroupItem *result = 0` -- so both
	arms below ALREADY returned the testable nothing. What they did not do
	was ARM, so the caller carried on. Ordinary routing, not a promotion.
	⚠ AND THIS PROSE SITS ABOVE THE WHOLE CHAIN ON PURPOSE (bear-trap #29):
	the first cut put it between the arms, immediately before an `else`, and
	wiped the extern block to 36. Comments go above the chain or inside an
	arm, never in the gap between arms.   Instruct.getMarkLineAt.storeRuling  */
	if ( source && isBUFFER(source->groupBody->flags.data) )
		if ( fromThis )
			{
			Buffer 	*buffer = source->getBuffer();
			int 	matchLength = 0;
			char 	*lineStart = 0;
			if ( buffer )
				if ( matchLength = buffer->findInBuffer(fromThis->getText()) )
					{
					lineStart = buffer->mark;
					while ( lineStart != buffer->start && *lineStart != '\n' )
						lineStart--;
					if ( lineStart >= buffer->start )
						lineStart++;
					else	lineStart = buffer->start;
					buffer->mark = lineStart + matchLength;
					while ( buffer->mark < buffer->current && *buffer->mark != '\n' )
						buffer->mark++;
					buffer->mark++;
					result = new GroupItem("markLine");
					result->setToken(lineStart,(int)(buffer->mark - lineStart));
					buffer->mark = lineStart;
					}
			}
		else	::refuse(fromThis,"getLine: no match field provided");
	else	::refuse(source,"getLine: no source, or the source is not a buffer");
	return result;
}

/***************************************************************************
	Returns a type field (from types: defined in the Generating registry)
    based on the data of the field passed in.
***************************************************************************/
extern "C" GroupItem *getType(GroupItem *field)
{
GroupItem 	*type = 0;
GroupItem 	*types = GroupControl::groupController->locate("types");
	if ( !types )
		::fprintf(stderr,"getType: could not find types.\n");
	else {
		if ( field->groupBody->flags.isLocal )
			switch (field->groupBody->flags.data)
				{
				case 4:
					type = types->get("Buffer*");
					break;
				case 5:
					type = types->get("int");
					break;
				case 2:
					type = types->get("char");
					break;
				case 8:
					type = types->get("BitMAP*");
					break;
				case 9:
					type = types->get("double");
					break;
				case 10:
					type = types->get("NSObject*");
					break;
				case 3:
					type = types->get("PLGset*");
					break;
				case 12:
					type = types->get("Stak*");
					break;
				case 14:
				case 13:
					type = types->get("char*");
					break;
				case 6:
					type = types->get("GroupItem*");
				}
		if ( !type )
			type = types->get("GroupItem*");
		}
	return type;
}

/***************************************************************************
	guard command should be run as a rule attribute to specify a guard for
    a rule that has not been guarded.
    If the guard attribute contains:
        a set as data, the set becomes the rule guard set.
        a string, the string is used to create the guard set.
        a character will make the rule unguarded
        nothing will turn debugGuard on
    Run instead as a command on a rule -- guard(SomeRule) -- it CLEARS that
    rule's guardSet AND resets guarding to 0 so the parser re-derives the guard
    on the next parse (clearing the set alone leaves guarding=1, and the parser
    then dereferences a guardSet that is no longer there). This is needed after
    a live graft (Rule += newAlternative) adds an alternative whose first
    character is not in the cached guardSet: the member list grew but the stale
    guardSet would otherwise reject the new alternative's input.
***************************************************************************/
extern "C" GroupItem *guard(GroupItem *item)
{
	if ( item->groupBody->flags.fLAG )
		{
		GroupItem 	*target = item->parent;
		if ( !target->groupBody->flags.guarding )
			switch (item->groupBody->flags.data)
				{
				case 2:
					target->groupBody->flags.guarding = 2;
					break;
				case 3:
					target->groupBody->guardSet = item->getCharacterSet();
					target->groupBody->flags.guarding = 1;
					break;
				case 13:
				case 14:
					target->groupBody->guardSet = new PLGset(item->getText());
					target->groupBody->flags.guarding = 1;
					break;
				default:
					target->groupBody->flags.debugGuard = 1;
				}
		}
	else
	if ( item->groupBody->flags.isRule )
		if ( item->groupBody->guardSet )
			{
			item->groupBody->guardSet = 0;
			item->groupBody->flags.guarding = 0;
			}
		else	item->groupBody->flags.debugGuard = 1;
	else	::fprintf(stderr,"ERROR guard should be used as an attribute when defining\n");
	item->clearData();
	return item;
}

/*****************************************************************************
    interpretMethod — binds a bytecode op's interpret handler. Unlike
    operateMethod (which binds the op's own operat slot, then vanishes as a
    setter), this creates a PERSISTENT `interpret` child on the op and binds
    the named C++ handler as that child's method, so interpretBC can dispatch
    it in place via grup.interpret(grup). The op's own flags/slots stay clear.
*****************************************************************************/
extern "C" GroupItem *interpretMethod(GroupItem *input)
{
char 		*name = input->getText();
GroupItem 	*interp = 0;
	if ( input->groupBody->flags.fLAG )
		if ( name )
			{
			GroupItem 	*grup = input->parent;
			if ( grup )
				{
				interp = grup->addString("interpret");
				interp->setMethod((GroupItem*(*)(GroupItem*))::dlsym(RTLD_SELF,name));
				}
			else	::fprintf(stderr,"interpretMethod: no parent to attach interpret to\n");
			}
		else	::fprintf(stderr,"interpretMethod: expected a handler name in text\n");
	else	::fprintf(stderr,"interpretMethod: should be invoked as a definition attribute\n");
	return input->getGroup();
}

/*******************************************************************************
    interpretXP — the interpret/run mode: build the left-associative runOP tree
    the interpreter walks. (Split out of aCTionExpressioN 2026-06-30; was the
    fallthrough below the generating/jitting branches.)
*******************************************************************************/
extern "C" GroupItem *interpretXP(GroupItem *xpList)
{
GroupItem 	*op = 0;
GroupItem 	*target = 0;
GroupItem 	*arg = 0;
GroupItem 	*xl = 0;
GroupItem 	*token = 0;
	if ( xpList->groupBody->groupList->listLength == 1 )
		{
		arg = xpList->groupBody->groupList->firstInList;
		
		
		goto finishXP;
		}
	while ( token = xpList->prior(token) )
		{
		if ( token->groupBody->registry == GroupControl::groupController->groupRules->opFields )
			op = token;
		else {
			if ( !arg )
				arg = token;
			else
			if ( op )
				{
				target = token;
				if ( xl )
					xl = 0;
				}
			else {
				if ( !xl )
					{
					xl = new GroupItem("xl1");
					xl->groupBody->flags.binType = 3;
					}
				if ( arg != xl )
					xl->addMember(arg);
				xl->addMember(token);
				arg = xl;
				}
			}
		if ( op )
			if ( arg )
				{
				if ( arg->groupBody->flags.actionType || arg->groupBody->flags.instructType )
					arg->groupBody->flags.invoke = 1;
				if ( target )
					{
					xl = new GroupItem("xl2");
					xl->addMember(op);
					xl->addMember(target);
					xl->addMember(arg);
					// TIER-3 BINDING, AND THIS LINE IS THE TIER-3 SET -- see the three-way operator
					// split before changing it   ruleActions.interpretXP.tier3Binding
					if ( ::compare(op->groupBody->tag,"AND") == 0 || ::compare(op->groupBody->tag,"OR") == 0 )
						xl->setMethod(::runShortCircuit);
					else	xl->setMethod(::runOP);
					xl->groupBody->flags.invoke = 1;
					op = 0;
					target = 0;
					arg = xl;
					}
				}
		}
finishXP:
	xpList->clear();
	xpList->setGroup(arg);
	return xpList;
}

/*  the ruling lives in assignFieldCore and BOTH roads call it -- do not inline it
    here, or the emitted `=` and the interpreted `=` drift.  jitEmitters.jitAssignNodeRT  */
extern "C" GroupItem *jitAssignNodeRT(GroupItem *source, GroupItem *target)
{
	
	/*  THE STORE RULING on the emitted road (Tony, 2026-09-05): an armed
	statement stores nothing. The interpreted twin is runOP's check before
	dispatch; this is the same rule where the emitted road actually does its
	storing.   jitEmitters.jitAssignNodeRT.storeRuling  */
	if ( GroupControl::groupController->groupRules->refused ) return 0;
	if ( ::assignFieldCore(source,target) )  return target;
	return 0;
	
}

/*******************************************************************************
    jitBindArgRT -- runAction's OWN binding lines, lifted verbatim.

    ⚠ THE UNWRAP IS NOT OPTIONAL. What the callee must receive is a RUN-TIME
    fact -- the node the operand currently points at -- not the operand's
    emit-time target.

    // jitBindArgRT  the gap it closes, why the lines are lifted rather than reimplemented, and the iterator case that makes the unwrap load-bearing
*******************************************************************************/
extern "C" GroupItem *jitBindArgRT(GroupItem *argument, GroupItem *field)
{
GroupItem 	*arg = argument;
GroupItem 	*ruleArg = 0;
	// codedPathHalf  the exemption above was the wrapper's fingerprint and retires WITH the wrapper, not before it
	
	{
	// argChannel obituary: the union tripwire and its bind-by-body fallback, removed 2026-09-05
	/*  ⚠ THE PENDING SLOT IS THE EMITTED PATH'S CHANNEL BRACKET, paired with
	jitSaveFrameRT/jitRestoreFrameRT across three functions. It is not
	the retired tripwire and does not retire with it.  */
	if (( ruleArg = field->get("argument") )) {
	gChanPendBody  = ruleArg->groupBody;
	gChanPendGroup = ruleArg->groupBody->gGroup;
	gChanPendData  = ruleArg->groupBody->flags.data;
	ruleArg->setGroup(arg);
	GroupControl::groupController->groupRules->chanBinds++;
	if ( ruleArg->groupBody->gGroup == arg ) GroupControl::groupController->groupRules->chanSame++;
	}
	}
	
	return arg;
}

/*******************************************************************************
    jitBuildFunction -- ONE FUNCTION, START TO FINISH. It owns the shell, entry
    block, result alloca, frame prologue, body walk, frame epilogue, ret,
    verifier and mem2reg; jitRunAction owns everything MODULE-scoped either
    side.

    ⚠ RETURN CODES ARE SHARED WITH jitRunAction AND MUST NOT BE RENUMBERED --
    -2 nothing emitted, -5 verifier refused, -6 no context/module, -9 duplicate
    function name. Callers and rungs read these.

    // liftNotMigration  why the sixteen globals stay put, and the one future change that would owe a context object
    // buildFunctionCodes  what each negative code means and which of them only a mis-sequenced caller can produce
*******************************************************************************/
extern "C" int jitBuildFunction(GroupItem *action)
{
	
	if (!gJitCtx || !gJitModule) {
	printf("=== jitBuildFunction: no context/module -- jitRunAction owns those ===\n");
	fflush(stdout); return -6; }
	llvm::LLVMContext &C = *gJitCtx;
	//  THE BUILDER IS THIS ROUTINE'S OWN LOCAL, and gJitBuilder points at it for
	//  the duration. That is the same lifetime the stack-local in jitRunAction
	//  used to have -- one function's build -- which is why the extraction does
	//  not change when it dies. jitRunAction still nulls gJitBuilder on the way
	//  out so it never dangles at a destroyed frame.
	llvm::IRBuilder<> B(C);
	
	llvm::Type *i32 = llvm::Type::getInt32Ty(C);
	//  ⚠⚠ S2 (AMENDED, Tony 2026-08-05): THE NAME DERIVES FROM ACTION IDENTITY,
	//  NOT FROM A PER-PROCESS COUNTER. It used to be `jitFn%d` off a static
	//  jitFnSeq, and that was fine for exactly as long as a compiled function
	//  died with the process.
	//
	//  WHY IT CANNOT STAY A COUNTER. The IR-persistence arc stashes a compiled
	//  function beside its definition and REHYDRATES it in a later incantation by
	//  LOOKING IT UP BY NAME. A counter-derived name is a fact about the ORDER
	//  THINGS HAPPENED TO BE COMPILED IN THIS PROCESS -- change a fixture, add a
	//  rung, compile two actions in the other order, and `jitFn1` names something
	//  else. A stashed name that means a different function next time is not a
	//  key, it is a collision waiting for a quiet afternoon.
	//  The action's tag is the same in every incarnation, which is the whole
	//  property the stash needs. See docs/jitDesign.md, "IR persistence -- the
	//  premise", name-stability clause.
	//
	//  SANITISED because an LLVM identifier is not an incant one. Anything
	//  outside [A-Za-z0-9_] becomes '_'; the `jit_` prefix keeps emitted names in
	//  one namespace and out of the way of the runtime symbols the IR already
	//  calls into by address.
	char fnName[128];
	{
	const char *tag = action->groupBody->tag;
	if (!tag || !*tag) tag = "anon";
	size_t n = 0;
	fnName[n++] = 'j'; fnName[n++] = 'i'; fnName[n++] = 't'; fnName[n++] = '_';
	for (const char *p = tag; *p && n < sizeof(fnName) - 1; p++)
	fnName[n++] = ((*p >= 'A' && *p <= 'Z') || (*p >= 'a' && *p <= 'z') ||
	(*p >= '0' && *p <= '9') || *p == '_') ? *p : '_';
	fnName[n] = 0;
	}
	//  ⚠ COLLISION-FREE PER COMPILE IS STILL REQUIRED and is now CHECKED rather
	//  than guaranteed by a counter. Two functions in one module must not share a
	//  name, and with identity-derived names that can only happen if one action's
	//  function is built twice in a compile -- which the build loop does not do
	//  (a discarded partial is ERASED, freeing its name, before the rebuild).
	//  So this is a LOUD REFUSAL for a condition that should be unreachable,
	//  which is the right shape for exactly that: if it ever fires, the build
	//  loop has stopped erasing and a silent LLVM auto-rename would have hidden
	//  it behind a name nobody looks up.
	if (gJitModule->getFunction(fnName)) {
	fprintf(stderr,
	"=== jitBuildFunction: NAME COLLISION on %s -- a function for this "
	"action already exists in this module ===\n", fnName);
	fflush(stderr);
	return -9; }
	llvm::Function *fn = llvm::Function::Create(
	llvm::FunctionType::get(i32, false),
	llvm::Function::ExternalLinkage, fnName, gJitModule);
	B.SetInsertPoint(llvm::BasicBlock::Create(C, "entry", fn));
	
	gJitBuilder = &B;
	gJitCurrentAction = action;      // so a self-call emits a CALL, not an inline
	gJitCurrentFn     = fn;
	//  WHAT THIS BUILD PRODUCED, carried by name as well as by pointer. S4 looks
	//  the driver up BY NAME; "the last function created" is correct only while
	//  there is one, which is the accident this whole arc exists to remove.
	gJitBuiltFn       = fn;
	gJitBuiltName     = fnName;
	gJitResult  = nullptr;
	// THE RESULT SLOT. Initialised to 0 so an action that emits nothing still
	// returns a defined value rather than whatever was last in flight.
	gJitEmitted = false;
	gJitResultSlot = B.CreateAlloca(i32, nullptr, "result");
	B.CreateStore(llvm::ConstantInt::get(i32, 0), gJitResultSlot);
	
	GroupRules *ruler = GroupControl::groupController->groupRules;
	// Unified JIT emit-on-walk (pivot, 2026-06-30): jitting ONLY — generating stays
	// OFF so aCTionExpressioN's dispatcher routes to interpretXP (runOP trees), NOT
	// generateXP (flat revisedLists). Parsing builds the runOP trees; EXECUTING the
	// BlocK runs them, and each opMethod's jitting gate emits LLVM in place (the
	// runOP seeding gate seeds leaves first). The interpret walk owns its traversal
	// and never re-parents live nodes — the structural cure for the by-reference
	// operand-stack corruption the deferred jitXpress path hit.
	ruler->jitting = 1;
	ruler->generating = 0;
	//  R1's ONE MECHANISM, first of its two call sites. Between functions the
	//  obligation is identical to the one gJitSeeded's header states between
	//  compiles -- an llvm::Value is valid only inside the function that defined
	//  it -- and S3 mints more than one function per compile, so "between
	//  compiles" stopped being a fine enough grain the day the map landed.
	
	jitFlushTransient();
	
	//  ⚠ THE EPILOGUE BLOCK IS CREATED **AFTER** THE FLUSH, AND THAT ORDER IS
	//  THE WHOLE OF ITS CORRECTNESS. Created above with the entry block -- where
	//  it reads like it belongs -- it was silently nulled two lines later by the
	//  flush that clears it between functions, and every `return` in the run then
	//  refused for want of a block that had been built and thrown away.
	//  A per-function global must be set after the thing that clears
	//  per-function globals, not beside the thing it is conceptually part of.
	//  THE EPILOGUE IS PARENTED LATER, at the foot, so it lists after the body
	//  blocks in a dump. Every exit -- falling off the end, or any `return` --
	//  branches here, so the frame writeback and the ret exist exactly once.
	gJitEpilogueBB = llvm::BasicBlock::Create(C, "epilogue");
	if (isCoded(action->groupBody->flags.actionType))
	::processCode(action);
	
	// ⚠ THE PROLOGUE RUNS *AFTER* processCode AND THAT PLACEMENT IS LOAD-BEARING.
	// It was written above the parse first, and the frame came out EMPTY: a local
	// is BORN BY BEING PARSED -- aCTionNamE's processingCode branch is what stamps
	// isLocal and adds the field to the action -- so before processCode the
	// action's field list does not yet contain them. The rung caught it (correct
	// values, zero allocas), which is precisely the job a structure assertion has
	// that a value net does not.
	// ================= FRAME PROLOGUE (Increment 1, 2026-08-01) =================
	// THE SCHEMA IS INHERITED, NOT INVENTED. `(isArgument || isLocal) && !noPrint`
	// is verbatim the predicate saveLocalFields walks forward and
	// restoreLocalFields walks backward (GroupActions.rtn). Taking the
	// interpreter's own enumeration is model-not-oracle: the two cannot drift,
	// and the alternative -- a parallel test that means the same thing today --
	// is how they would.
	//
	// WHAT THIS REPLACES: recurseSTAK's manual heap push/pop of whole GroupBodys.
	// Same schema, same discipline, different storage -- which is why the death
	// warrant on saveLocalFields could be written without redesigning semantics.
	// ⚠ INHERIT THE SCHEMA, NOT THE BUG: saveLocalFields also copied the groupList
	// POINTER and then cleared the shared object in place, so no local carrying a
	// list survived recursion (CLAIM KANT-8's neighbour). Nothing here copies a
	// body at all, so that whole failure mode is unconstructable rather than
	// avoided.
	//
	// THE PROLOGUE IS THE SEED. runOP's gate only seeds a node with no jitData
	// (bear-trap #9 -- never re-seed an inner op-result), so pre-seeding a local
	// here means jitSeedField NEVER sees it and never bakes it an absolute
	// address. That is the whole mechanism: one `if` in a gate that already
	// existed, rather than a new branch inside jitSeedField.
	//
	// GLOBALS ARE UNTOUCHED and keep baked addresses with immediate store-through
	// (Part III's phase scope). Only locals move, and a local is invisible outside
	// the action, so deferring ITS writeback to the epilogue is not observable --
	// which is exactly why this increment is behaviour-neutral and cannot certify
	// itself.
	{
	GroupItem *fld = 0;
	while ((fld = action->next(fld))) {
	GroupBody *fb = fld->groupBody;
	if (!(fb->flags.isLocal || fb->flags.isArgument)) continue;
	if (fb->flags.noPrint) continue;
	if (fld->jitData) continue;          // already seeded this compile
	llvm::Type *ty;
	void       *addr;
	if (isNUMBER(fb->flags.data)) { ty = llvm::Type::getDoubleTy(C); addr = &(fb->gNumber); }
	else                          { ty = llvm::Type::getInt32Ty(C);  addr = &(fb->gCount);  }
	if (jitFrameFind(addr)) continue;    // one slot per field, not per node
	llvm::Value *slot = B.CreateAlloca(ty, nullptr, fb->tag);
	llvm::Value *home = B.CreateIntToPtr(
	llvm::ConstantInt::get(llvm::Type::getInt64Ty(C), (uint64_t)addr),
	llvm::PointerType::getUnqual(C));
	B.CreateStore(B.CreateLoad(ty, home, "prolog"), slot);
	JitFrameSlot fs; fs.home = addr; fs.slot = slot; fs.ty = ty;
	gJitFrame.push_back(fs);
	}
	}
	// =========================== end frame prologue ===========================
	// Execute the parsed BlocK under jitting: runOP/op-gates emit straight-line IR;
	// control flow lands via aCTionIF's jitting gate -> jitEmitGIF.
	jitExecBlock(action);
	ruler->jitting = 0;
	
	//  "DID ANYTHING EMIT" is now gJitEmitted, NOT a non-null gJitResult. The
	//  result slot falsified the old test: a bracketing emitter commits its
	//  arms and then deliberately clears gJitResult, so an action ending in
	//  control flow legitimately has nothing in flight -- and the old guard
	//  read that as "the gate never fired" and bailed before emitting the ret,
	//  which silently un-jitted every if/else. Measured the moment the clear
	//  landed.
	if (!gJitEmitted) {
	printf("=== jitRunAction: no result emitted (gate did not fire?) ===\n");
	fflush(stdout); return -2; }
	// THE CAP IS NOW A LOAD OF THE RESULT SLOT, not the last value in flight.
	// The old form retted whatever gJitResult happened to hold after the walk,
	// which on a two-armed if was the last ARM EMITTED regardless of which one
	// RAN -- and in every fixture dumped it was a CONSTANT. Storing per
	// statement and loading here is what makes the returned value path-correct.
	jitStoreResult();
	
	//  ============ FALL-THROUGH JOINS THE RETURNS (item 2, 2026-08-05) ========
	//  jitStoreResult above committed the last statement's value INTO THE
	//  CURRENT BLOCK, which is right: falling off the end of an action yields
	//  the last executed statement's value. Now that path becomes one exit among
	//  several -- it branches to the epilogue exactly as a `return` does.
	//
	//  ⚠ THE TERMINATOR TEST IS NOT DEFENSIVE, IT IS THE NORMAL CASE. An action
	//  whose last statement is a `return` leaves the builder parked in
	//  jitEmitReturn's unreachable continuation block, which has no terminator
	//  and needs this branch; an action that ends inside emitted control flow may
	//  already be terminated. Both are ordinary.
	if (!B.GetInsertBlock()->getTerminator())
	B.CreateBr(gJitEpilogueBB);
	gJitEpilogueBB->insertInto(fn);
	B.SetInsertPoint(gJitEpilogueBB);
	
	//  ⚠ THE ARM IS CLEARED AT THE EMITTED FUNCTION'S EPILOGUE, MIRRORING
	//  runAction (Tony, 2026-09-05). The emitted function IS the activation, so
	//  this is the same boundary the interpreted road clears at -- and without
	//  it the arm LEAKS: a run-time refusal inside an emitted body would still
	//  be set when the next inlined check anywhere reads it, and that check
	//  would fire on someone else's refusal.
	//  ⚠ IT IS UNREACHABLE TODAY AND IS LANDING AHEAD OF ITS NEED, deliberately.
	//  Nothing sets the arm at run time on this road yet, because no run-time
	//  emitted-road helper calls refuse() -- measured, all six. Routing the
	//  three gated sites (jitDerefRT x2, jitPrintNodeRT) is what makes the leak
	//  reachable, so the clear lands FIRST and those follow.
	{
	void *armAddr = (void*)&(GroupControl::groupController->groupRules->refused);
	llvm::Value *armP = B.CreateIntToPtr(
	llvm::ConstantInt::get(llvm::Type::getInt64Ty(C), (uint64_t)armAddr),
	llvm::PointerType::getUnqual(C));
	B.CreateStore(llvm::ConstantInt::get(llvm::Type::getInt32Ty(C), 0), armP);
	}
	
	// ================= FRAME EPILOGUE (Increment 1, 2026-08-01) =================
	// Store each frame slot back to the field's own storage, so the interpreter
	// and every later run see the action's effect. Walk order is the prologue's;
	// restoreLocalFields walks BACKWARD because it pops a stack, and this does
	// not -- each slot has its own address, so there is no ordering to honour.
	// That asymmetry is the point: the stack discipline was the bug surface, and
	// it is gone rather than reimplemented.
	for (JitFrameSlot &f : gJitFrame) {
	llvm::Value *home = B.CreateIntToPtr(
	llvm::ConstantInt::get(llvm::Type::getInt64Ty(C), (uint64_t)f.home),
	llvm::PointerType::getUnqual(C));
	B.CreateStore(B.CreateLoad(f.ty, f.slot, "epilog"), home);
	}
	// =========================== end frame epilogue ===========================
	
	B.CreateRet(B.CreateLoad(i32, gJitResultSlot, "retval"));
	
	// ------------------------------------------------------------------
	// THE VERIFIER. Added 2026-07-30. Until now NOTHING in the live tree
	// called verifyFunction or verifyModule -- the only occurrences were in
	// docs and in the archived XML/LLVM/codeGenerator. The consequence was
	// measured, not supposed: INVALID IR COMPILED AND RETURNED GARBAGE.
	// testIfElse on a false condition returned 83623936 and EXITED 0, with
	// no diagnostic on any stream, because jitEmitGIF has no else arm and
	// nothing ever asked LLVM whether the result was well-formed.
	//
	// Placed BEFORE mem2reg deliberately, for two reasons: it catches the
	// EMITTER's own output rather than the optimiser's view of it, and it
	// avoids running a transform pass over IR already known to be broken.
	//
	// REFUSES rather than warning. Loud refusal over quiet default, the same
	// rule the genParse walk follows -- running a function LLVM has just
	// called invalid is how the garbage return above happened. -5 is distinct
	// from the existing -1..-4 so a caller can tell "IR was invalid" from
	// "the engine failed".
	// verifyFunction returns TRUE when the function is BROKEN.
	//  PRE-OPTIMISATION DUMP, added 2026-07-31 and it is the more useful of the
	//  two. INCANT_JIT_DUMP=2 shows the EMITTER'S OWN OUTPUT, before mem2reg has
	//  promoted or folded anything. The post-mem2reg dump alone cannot answer
	//  "did the emitter emit this, or did the optimiser produce it" -- and that
	//  is exactly the question a result-slot or a phi raises. =1 keeps the old
	//  post-pass behaviour; =2 gives both.
	if (::getenv("INCANT_JIT_DUMP") && ::atoi(::getenv("INCANT_JIT_DUMP")) >= 2) {
	llvm::errs() << "=== IR " << fnName << " (PRE-mem2reg, emitter output) ===\n";
	gJitModule->print(llvm::errs(), nullptr);
	llvm::errs() << "=== end PRE IR " << fnName << " ===\n";
	llvm::errs().flush(); }
	
	//  THE MESSAGE STILL SAYS jitRunAction ON PURPOSE. It is the string every POP
	//  and every ladder rung greps for, and the extraction is required to be
	//  INVISIBLE -- renaming it would make an S1 that changed nothing look like an
	//  S1 that changed something, which is the one outcome the step's POP cannot
	//  tell apart from a real regression.
	if (llvm::verifyFunction(*fn, &llvm::errs())) {
	fprintf(stderr,
	"=== jitRunAction: INVALID IR for %s -- REFUSING to run it ===\n",
	fnName);
	fflush(stderr);
	gJitBuilder = nullptr;
	gJitResult  = nullptr;
	gJitResultSlot = nullptr;
	return -5; }
	
	// mem2reg: promote field-slot allocas to SSA registers and let LLVM insert
	// phi nodes at merge points. A no-op on the current alloca-free straight-line
	// IR (the 24-POP battery proves it non-destructive) — the foundation gIF's
	// then/else `CreateStore`-to-slot strategy relies on, so the manual jitPhi
	// machinery never has to come back.
	{
	llvm::PassBuilder PB;
	llvm::LoopAnalysisManager LAM;
	llvm::FunctionAnalysisManager FAM;
	llvm::CGSCCAnalysisManager CGAM;
	llvm::ModuleAnalysisManager MAM;
	PB.registerModuleAnalyses(MAM);
	PB.registerCGSCCAnalyses(CGAM);
	PB.registerFunctionAnalyses(FAM);
	PB.registerLoopAnalyses(LAM);
	PB.crossRegisterProxies(LAM, FAM, CGAM, MAM);
	llvm::FunctionPassManager FPM;
	FPM.addPass(llvm::PromotePass());
	FPM.run(*fn, FAM);
	}
	//  ONE FUNCTION IS BUILT. gJitBuiltFn/gJitBuiltName carry it out; the caller
	//  owns the module from here.
	return 0;
	
}

/*******************************************************************************
    jitDegrade -- THE CROSSOVER PRIMITIVE, lifted 2026-07-30. It ANNOUNCES and
    RETURNS; the caller then does the interpreted thing.

    ⚠ A DEGRADE LINE ASSERTS THAT A FALLBACK OCCURRED, NEVER THAT IT WAS SOUND.
    A tail return and a mid-body return both report 2, and only one of them is
    correct. Do not read the counter as a safety property.

    // crossoverPolicy  the §0 open ruling this answers, and why the pattern was lifted before the code carrying it could be deleted
    // counterIsThePoint  the ~53 silent emit-time fallbacks the counter was built to make countable
    // degradeNotRefuse  why this announces where jitRunAction's verifier refuses
    // staticNotSlot  why the counter is a C++ static and the notice goes to stderr
*******************************************************************************/
extern "C" int jitDegrade(char *what, GroupItem *node)
{
	if ( !GroupControl::groupController->groupRules->jitting )
		return 0;
	
	++gJitDegradeCount;
	::fprintf(stderr,
	"=== JIT DEGRADE #%d: %s -- not JIT-supported yet, running INTERPRETED: %s ===\n",
	gJitDegradeCount, what ? what : "(unnamed construct)",
	node ? node->groupBody->tag : "(no node)");
	::fflush(stderr);
	return gJitDegradeCount;
	
}

/*  opDeref's own lines, lifted verbatim. ONE LEVEL, no composition -- and a run-time
    helper rather than an emit-time fold.   jitEmitters.jitDerefRT  */
extern "C" GroupItem *jitDerefRT(GroupItem *operand)
{
	
	/*  ⚠ THE STAR RULING ON THE EMITTED ROAD (Tony, 2026-09-05). `*x` on a
	field that holds no group YIELDS NULL and does not refuse -- and these
	two lines exist to mirror opDeref, so they take the same ruling or the
	two roads answer differently for the same source text. They were on the
	gated list as sites to ROUTE; STAR reclassified them, because refusal is
	for CATEGORY errors and this is a legitimate question with a legitimate
	empty answer. The CONSUMER of the null refuses, on both roads.
	jitEmitters.jitDerefRT.starRuling  */
	if ( !operand )                                  return 0;
	if ( isGROUP(operand->groupBody->flags.data) )   return operand->getGroup();
	return 0;
	
}

/* jitDiscardPartial  ERASE THE FUNCTION UNDER CONSTRUCTION AND FLUSH BEHIND IT.
   (S3 rider R1.) The build just discovered that a callee it was inlining needs
   its own function, so what is in the module is wrong by construction. Erase it
   -- do not leave it to be overwritten, because an abandoned function still
   verifies, still compiles, and still exports a symbol.

   Operates on gJitBuiltFn rather than taking a parameter, for the same reason
   jitBuildFunction returns an int: an llvm type in a tok-extern signature
   poisons the generated header. */
extern "C" void jitDiscardPartial()
{
	
	if (gJitBuiltFn) gJitBuiltFn->eraseFromParent();
	gJitBuiltFn = nullptr;
	gJitBuiltName.clear();
	
	jitFlushTransient();
	
	//  These two point INTO the function just erased (or at its dead stack
	//  builder), so nulling them is not tidiness either.
	gJitBuilder    = nullptr;
	gJitResultSlot = nullptr;
	gJitEmitted    = false;
	
}

/* jitDoBegin / jitDoCond / jitDoEnd  the `do` bracket -- a while with the branch
   MOVED, which is the whole difference and the whole point.

     while:  entry -> cond -> (body -> cond)*        condition FIRST
     do:     entry -> body -> cond -> (body ...)     BODY FIRST

   So a do's body runs ONCE EVEN WHEN THE CONDITION STARTS FALSE, and that edge
   is what rung J4 asserts. The topology difference is one branch target: a
   while's back edge goes to `cond`, a do's goes to `body`. */
extern "C" void jitDoBegin()
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	llvm::LLVMContext &ctx = b->getContext();
	llvm::Function *fn = b->GetInsertBlock()->getParent();
	llvm::BasicBlock *bodyBB = llvm::BasicBlock::Create(ctx, "dobody", fn);
	llvm::BasicBlock *condBB = llvm::BasicBlock::Create(ctx, "docond", fn);
	llvm::BasicBlock *exitBB = llvm::BasicBlock::Create(ctx, "doexit", fn);
	b->CreateBr(bodyBB);            // straight into the body: that is `do`
	b->SetInsertPoint(bodyBB);
	gLoopBodyBlocks.push_back(bodyBB);
	gLoopCondBlocks.push_back(condBB);
	gLoopExitBlocks.push_back(exitBB);
	
}

extern "C" void jitDoCond()
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	llvm::BasicBlock *condBB = gLoopCondBlocks.back();
	b->CreateBr(condBB);
	b->SetInsertPoint(condBB);
	
}

extern "C" void jitDoEnd()
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	llvm::Value *cond = gJitResult;
	llvm::BasicBlock *bodyBB = gLoopBodyBlocks.back();
	llvm::BasicBlock *exitBB = gLoopExitBlocks.back();
	gLoopBodyBlocks.pop_back();
	gLoopCondBlocks.pop_back();
	gLoopExitBlocks.pop_back();
	if (!cond) { b->CreateBr(exitBB); b->SetInsertPoint(exitBB); return; }
	if (!cond->getType()->isIntegerTy(1))
	cond = b->CreateICmpNE(cond,
	llvm::ConstantInt::get(cond->getType(), 0), "tobool");
	b->CreateCondBr(cond, bodyBB, exitBB);   // <-- back edge targets BODY
	b->SetInsertPoint(exitBB);
	
}

extern "C" GroupItem *jitEmitAdd(GroupItem *argument, GroupItem *target)
{
	 return jitEmitBinary(argument, target, jitAdd); 
}

/*******************************************************************************
    jitEmitAssign -- the store-back emitter. SKELETON: not wired, no gate, no
    fixtures.

    // storeOnlyByDesign  what the store destination resolves to, and why a literal target correctly has no slot
    // compoundIsComposed  why += and friends are composed at the gate rather than branched here
*******************************************************************************/
extern "C" GroupItem *jitEmitAssign(GroupItem *argument, GroupItem *target)
{
	
	// ⚠ A NODE ON THE RIGHT GOES THROUGH THE RUN-TIME HELPER (SEQ 138). A star
	// publishes a NODE, not a scalar, and storing its SSA value put the node's
	// ADDRESS into the target's slot -- which is how starT's jitted road read
	// 5560000 where the interpreted road read LEAF. jitAssignNodeRT carries
	// F-48's ruling for BOTH roads: copy the value, or refuse by name and store
	// nothing. The flag is cleared here because this is the consumer.
	if (gJitLastIsNode && gJitResultNode && target) {
	gJitLastIsNode = false;
	llvm::IRBuilder<> *nb = gJitBuilder;
	llvm::LLVMContext &nctx = nb->getContext();
	llvm::Type *nptr = llvm::PointerType::getUnqual(nctx);
	llvm::Type *ni64 = llvm::Type::getInt64Ty(nctx);
	llvm::Value *tgtAddr = nb->CreateIntToPtr(
	llvm::ConstantInt::get(ni64, (uint64_t)(void*)target), nptr, "assignTgt");
	llvm::Value *fn = nb->CreateIntToPtr(
	llvm::ConstantInt::get(ni64, (uint64_t)(void*)&jitAssignNodeRT), nptr, "assignNodeFn");
	llvm::FunctionType *ty = llvm::FunctionType::get(nptr, {nptr, nptr}, false);
	nb->CreateCall(ty, fn, {gJitResultNode, tgtAddr}, "assignNode");
	gJitFieldResident.insert((void*)target->groupBody);
	return target;
	}
	// ⚠ THE SEED GATE (F-47, Tony SEQ 134) -- jitEmitUnary's own guard, copied.
	// BOTH operands were dereferenced unguarded here, so an unseeded one was a
	// bad pointer dereference at 0x28 rather than a named degrade. The sibling
	// has had this gate all along and its comment argues the case: a quiet
	// null-check returning target would be worse than the crash it replaces --
	// exit 0 with wrong IR. So this DEGRADES, countably, and gJitDegradeCount is
	// asserted 0 by every rung, which is what stops it passing silently.
	if (!argument || !argument->jitData || !target || !target->jitData) {
	jitDegrade("assign operand reached jitEmitAssign unseeded", target);
	return target;
	}
	llvm::IRBuilder<> *b = gJitBuilder;
	// Plain `=`: pure store-back of the source operand's SSA value into the
	// target's slot. No arithmetic.
	b->CreateStore(argument->jitData->jitValue, target->jitData->jitSlot);
	// Compound (+= *= ...) is NOT a second branch here — it is the composition
	// done by the opMethod gate: jitEmitBinary(argument,target,<jitOp>) first,
	// which writes the result into target->jitData->jitValue, then a store-back
	// of THAT value. Left to the gate by design.
	gJitResult = argument->jitData->jitValue;
	return target;
	
}

/*******************************************************************************
    jitEmitBareRead -- THE MISSING PRIMITIVE: materialize a bare read. Tony's
    ruling via Clay, 2026-08-05. Returns 0 and emits nothing if there is no
    builder.

    ⚠ FOR A JIT-TRACKED LOCAL THE LOAD IS OF THE ALLOCA, NEVER OF THE FIELD'S
    OWN MEMORY. The epilogue has not written the field yet, so a load there
    reads a stale frame slot and is silently wrong.

    // bareReadMissing  why the JIT went this long without one, and the three holes it closes at once
    // bareReadTwoArms  the emit-time fork, and why jitSeedField keys on the HOME ADDRESS and not node identity
    // bareReadThirdCategory  the run-time pointer-walk this deliberately does not handle, and what to do if a fourth turns up
*******************************************************************************/
extern "C" int jitEmitBareRead(GroupItem *token)
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	if (!b || !token) return 0;
	//  argument is a BINDING: an isArgument token yields what it holds. PRINT
	//  ITEMS ARE SEEDED HERE, not through runOP, so the rule must be stated a
	//  THIRD time -- without this line a jitted `print argument` reads the
	//  holder's storage and prints an address at degrade count 0, which is this
	//  function's own 75102656 one road over   ArgBinding.ArgBindingSites
	if ( token->groupBody->flags.isArgument && isGROUP(token->groupBody->flags.data) )
	token = token->getGroup();
	if (!token) return 0;
	//  ⚠ REFUSE ANYTHING THAT IS NOT A SCALAR READ, and this guard is not
	//  defensive padding -- its absence is what printed 75102656. Handed a LIST
	//  node (a multi-part expression), the primitive below dutifully emitted a
	//  load of that node's gCount, which is not a number anybody wrote. Garbage,
	//  degrade count 0, and it looked like data.
	//  A scalar read is a node whose VALUE lives in its own storage. A list's
	//  does not: its value is its parts, and classifying those is the caller's
	//  job (jitPrintList does it for print items).
	//  Refuse loudly -- the counter is asserted at zero by every rung, so a
	//  refusal is a red and a wrong constant is nothing.
	if (token->groupBody->groupList) {
	jitDegrade("bare read of a LIST -- parts must be classified by the caller", token);
	return 0; }
	//  Already seeded this compile? Then the value is in hand -- and re-seeding
	//  is bear-trap #9 (never re-seed an inner op-result).
	if (!token->jitData)    jitSeedField(token);
	if (!token->jitData)    return 0;
	llvm::Value *v = token->jitData->getJitter();
	if (!v) return 0;
	gJitResult  = v;
	gJitEmitted = true;
	return 1;
	
}

/* jitEmitBinary  the shared binary-arithmetic emitter. Each arithmetic opMethod's
   jitting gate is one line onto this — jitEmitBinary(argument, target, jitAdd) —
   so the boilerplate (operand load, result store, gJitResult stash, return) lives
   once. The int/float variant of the instruction is picked from the operand's LLVM
   type; operands are assumed matched (same type) per the target-drives-representation
   model. `op` is a jitOp (jitContext.h). Header-clean signature (no llvm:: types);
   the LLVM lives in the passthrough body, the jitSeedLiteral pattern. */
extern "C" GroupItem *jitEmitBinary(GroupItem *argument, GroupItem *target, int op)
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	llvm::Value *l = target->jitData->jitValue;
	llvm::Value *r = argument->jitData->jitValue;
	// Numeric promotion: if either operand is double, the op is floating-point and
	// the integer operand is promoted (CreateSIToFP) before it. This is where
	// "assume operands match" comes due — mixed count+number now coerces cleanly.
	bool fp = l->getType()->isDoubleTy() || r->getType()->isDoubleTy();
	if (fp) {
	llvm::Type *d = llvm::Type::getDoubleTy(b->getContext());
	if (l->getType() != d) l = b->CreateSIToFP(l, d, "promo");
	if (r->getType() != d) r = b->CreateSIToFP(r, d, "promo");
	}
	llvm::Value *res = nullptr;
	switch (op) {
	case jitAdd:  res = fp ? b->CreateFAdd(l,r,"add") : b->CreateAdd(l,r,"add");  break;
	case jitSub:  res = fp ? b->CreateFSub(l,r,"sub") : b->CreateSub(l,r,"sub");  break;
	case jitMul:  res = fp ? b->CreateFMul(l,r,"mul") : b->CreateMul(l,r,"mul");  break;
	case jitSDiv: res = fp ? b->CreateFDiv(l,r,"div") : b->CreateSDiv(l,r,"div"); break;
	}
	target->jitData->setJitter(res);
	gJitResult = res;
	return target;
	
}

/*******************************************************************************
    jitEmitCompare -- the shared relational emitter for the six predicates.

    ⚠ WIRING IT INTO AN opMethod GATE NEEDS TWO THINGS FIRST: jitRunAction's
    return-cap needs an i1 -> i32 ZExt branch (it only widens double -> i32),
    and a groups.ext extern decl is required.

    // cmpIsI1  the two differences from jitEmitBinary, and why the promotion block is retained rather than dropped
*******************************************************************************/
extern "C" GroupItem *jitEmitCompare(GroupItem *argument, GroupItem *target, int op)
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	llvm::Value *l = target->jitData->jitValue;
	llvm::Value *r = argument->jitData->jitValue;
	// Identical promotion to jitEmitBinary: if either operand is double the
	// compare is floating-point and the integer operand is SIToFP-promoted so
	// both sides share a type. A same-type pair (both i32 or both double) skips
	// this untouched. This block is NOT optional for compare — ICmp/FCmp require
	// matched operand types, so a mixed count/number compare must unify here.
	bool fp = l->getType()->isDoubleTy() || r->getType()->isDoubleTy();
	if (fp) {
	llvm::Type *d = llvm::Type::getDoubleTy(b->getContext());
	if (l->getType() != d) l = b->CreateSIToFP(l, d, "promo");
	if (r->getType() != d) r = b->CreateSIToFP(r, d, "promo");
	}
	llvm::Value *res = nullptr;
	if (fp) {
	switch (op) {
	case jitEQ: res = b->CreateFCmpOEQ(l,r,"cmp"); break;
	case jitNE: res = b->CreateFCmpONE(l,r,"cmp"); break;
	case jitLT: res = b->CreateFCmpOLT(l,r,"cmp"); break;
	case jitLE: res = b->CreateFCmpOLE(l,r,"cmp"); break;
	case jitGT: res = b->CreateFCmpOGT(l,r,"cmp"); break;
	case jitGE: res = b->CreateFCmpOGE(l,r,"cmp"); break;
	}
	} else {
	switch (op) {
	case jitEQ: res = b->CreateICmpEQ(l,r,"cmp");  break;
	case jitNE: res = b->CreateICmpNE(l,r,"cmp");  break;
	case jitLT: res = b->CreateICmpSLT(l,r,"cmp"); break;
	case jitLE: res = b->CreateICmpSLE(l,r,"cmp"); break;
	case jitGT: res = b->CreateICmpSGT(l,r,"cmp"); break;
	case jitGE: res = b->CreateICmpSGE(l,r,"cmp"); break;
	}
	}
	target->jitData->setJitter(res);
	gJitResult = res;
	return target;
	
}

/*******************************************************************************
    jitEmitContinue -- `continue`, EMITTED. Work item 2 of the convergence rung.
    Returns 0 when there is no enclosing loop, so a stray continue cannot
    silently branch to whatever happens to be on the stack.

    ⚠ THE UNREACHABLE BLOCK AFTER THE BRANCH IS DELIBERATE. LLVM requires one
    terminator per block and forbids code after it, so the builder parks in a
    fresh block nothing branches to. Emitting the following statements into the
    block just terminated would be INVALID IR.

    // correctByAccident  why it looked like it already worked, and why that is worse than a missing feature
    // innermostLoop  the gLoopCondBlocks stack, and where a `do` loop's continue lands
*******************************************************************************/
extern "C" int jitEmitContinue()
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	if (!b) return 0;
	if (gLoopCondBlocks.empty()) {
	::fprintf(stderr, "=== jitEmitContinue: no enclosing loop -- REFUSING ===\n");
	::fflush(stderr);
	return 0; }
	llvm::LLVMContext &ctx = b->getContext();
	llvm::Function *fn = b->GetInsertBlock()->getParent();
	b->CreateBr(gLoopCondBlocks.back());
	llvm::BasicBlock *dead = llvm::BasicBlock::Create(ctx, "afterContinue", fn);
	b->SetInsertPoint(dead);
	gJitEmitted = true;
	gJitResult  = nullptr;
	return 1;
	
}

/*******************************************************************************
    jitEmitDO -- the do-while emitter (rung J4). Body first, condition second.

    ⚠ THE STORE MUST HAPPEN BEFORE jitDoCond MOVES THE INSERT POINT, or the
    body's value is committed into the CONDITION block.

    // storeBeforeCondMoves  the ordering trap, and the E1 clear every bracketing emitter owes
*******************************************************************************/
extern "C" GroupItem *jitEmitDO(GroupItem *input)
{
GroupItem 	*ExpressioN = input->getLabelGroup("ExpressioN");
GroupItem 	*StatemenT = input->getLabelGroup("StatemenT");
GroupItem 	*result = 0;
	::jitDoBegin();
	if ( StatemenT )
		result = StatemenT->groupBody->gMethod(StatemenT);
	/*  ⚠ THE EXPLICIT COMMIT IS REQUIRED HERE AND MUST NOT BE REMOVED.  */
	// doCommitAsymmetry  the measured asymmetry with jitEmitWHILE, whose body aCTionBlocK commits
	jitStoreResult();
	::jitDoCond();
	result = ExpressioN;
	/*  BARE CONDITION OPERAND -- see the note in jitEmitGIF. `if isMethod` is
	false for a bare read, so without this the condition emits nothing and
	the loop branches on whatever was last in flight.  */
	if ( isMethod(result->groupBody->flags.instructType) )
		result = result->groupBody->gMethod(result);
	else	::jitEmitBareRead(ExpressioN);
	::jitDoEnd();
	 gJitResult = nullptr; 
	return result;
}

/* jitEmitDeref  THE PREFIX `*`, EMITTED. SEQ 132 item 3, Tony's ruling.
   One level, no composition. The operand NODE is baked -- it is a parse-time
   constant -- and the FOLLOW is deferred to jitDerefRT at run time, because what
   a field points at is not knowable at emit time. Publishes on gJitResultNode,
   the GroupItem channel opDot already uses; a star has no scalar to publish and
   deliberately does not touch gJitResult.  */
extern "C" int jitEmitDeref(GroupItem *operand)
{
	
	if (!gJitBuilder || !operand) return 0;
	llvm::IRBuilder<> *b = gJitBuilder;
	llvm::LLVMContext &ctx = b->getContext();
	llvm::Type *ptr = llvm::PointerType::getUnqual(ctx);
	llvm::Type *i64 = llvm::Type::getInt64Ty(ctx);
	llvm::Value *argAddr = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)operand), ptr, "derefArg");
	llvm::Value *derefFn = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)&jitDerefRT), ptr, "derefFn");
	llvm::FunctionType *derefTy = llvm::FunctionType::get(ptr, {ptr}, false);
	llvm::Value *res = b->CreateCall(derefTy, derefFn, {argAddr}, "derefRes");
	gJitResultNode = res;
	gJitLastIsNode = true;
	gJitEmitted    = true;
	return 1;
	
}

extern "C" GroupItem *jitEmitDiv(GroupItem *argument, GroupItem *target)
{
	 return jitEmitBinary(argument, target, jitSDiv); 
}

/*******************************************************************************
    jitEmitDot -- THE ACCESSOR ARM. Two legs, jitEmitRem's shape: call opDot,
    then jitUnboxCount. `.` is registered operateMethod, so it is two-arg.

    // accessorFamilyOneGate  why one gate closes the whole accessor family, and why opDot's ~40 cases are called rather than reimplemented
    // finding3NotACondition  why a missing emitter here presented as a wrong test, which is where a reader looks first
*******************************************************************************/
extern "C" GroupItem *jitEmitDot(GroupItem *argument, GroupItem *target, GroupItem *resultNode)
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	llvm::LLVMContext &ctx = b->getContext();
	llvm::Type *ptr = llvm::PointerType::getUnqual(ctx);
	llvm::Type *i32 = llvm::Type::getInt32Ty(ctx);
	llvm::Type *i64 = llvm::Type::getInt64Ty(ctx);
	
	llvm::Value *argAddr = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)argument), ptr, "dotArg");
	llvm::Value *tgtAddr = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)target), ptr, "dotTgt");
	llvm::Value *callee = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)&opDot), ptr, "dotFn");
	llvm::FunctionType *opTy = llvm::FunctionType::get(ptr, {ptr, ptr}, false);
	llvm::Value *res = b->CreateCall(opTy, callee, {argAddr, tgtAddr}, "dotRes");
	
	llvm::Value *unboxFn = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)&jitUnboxCount), ptr, "dotUnboxFn");
	llvm::FunctionType *unboxTy = llvm::FunctionType::get(i32, {ptr}, false);
	llvm::Value *val = b->CreateCall(unboxTy, unboxFn, {res}, "dotVal");
	//  PUBLISH THE NODE TOO. A consumer that wants a COUNT reads gJitResult; one
	//  that wants the GroupItem -- the print path, which must not guess a type --
	//  reads gJitResultNode. Two facts, two channels.
	gJitResultNode = res;
	//  ⚠ THE ELEMENT IS A NODE RESULT (Tony, SEQ 142). A subscript yields a
	//  FIELD, and print must take that field rather than the unboxed count
	//  below -- which is why pointerT's jitted rows came out empty while its
	//  one scalar row printed. The scalar stays published for consumers that
	//  want a count; print does not consult it.
	gJitLastIsNode = true;
	
	if (resultNode) {
	if (!resultNode->jitData) resultNode->jitData = new JitData();
	resultNode->jitData->setJitter(val);
	gJitSeeded.push_back(resultNode); }
	gJitResult  = val;
	gJitEmitted = true;
	return resultNode;
	
}

extern "C" GroupItem *jitEmitEQ(GroupItem *argument, GroupItem *target)
{
	 return jitEmitCompare(argument, target, jitEQ); 
}

/*******************************************************************************
    jitEmitFill -- DS-4(b), THE DRAWING COMMAND, CALLABLE FROM COMPILED CODE. A
    carbon copy of jitEmitTrace's shape.

    ⚠ NO STRUCT OFFSETS BAKED, AND THE CALL IS LEFT UNTAGGED -- jitEmitTrace's
    two reasons apply here unchanged. See noBakedOffsets.

    // drawingIsCallable  why the fallback column was the right route, and what FR §4 predicted
*******************************************************************************/
extern "C" void jitEmitFill(GroupItem *field)
{
	
	if (!gJitBuilder || !field) return;
	llvm::IRBuilder<> *b = gJitBuilder;
	llvm::LLVMContext &ctx = b->getContext();
	llvm::Type *ptr = llvm::PointerType::getUnqual(ctx);
	llvm::Type *i64 = llvm::Type::getInt64Ty(ctx);
	
	llvm::Value *fieldAddr = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)field), ptr, "fillArg");
	llvm::Value *callee = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)&displayFillRT), ptr, "fillFn");
	llvm::FunctionType *fnTy = llvm::FunctionType::get(ptr, {ptr}, false);
	b->CreateCall(fnTy, callee, {fieldAddr});
	gJitEmitted = true;
	
}

/*******************************************************************************
    jitEmitGE -- batch one of the slot sweep. Three lines, like every shim.

    ⚠ DO NOT ADD A COUNTER INCREMENT TO ANY SHIM. The slot count lives at the
    fork in runOP precisely so a shim author cannot forget it.

    // sweepBatches  the two batches, what closing at 10 of 10 does and does not mean, and why never-null stays open
*******************************************************************************/
extern "C" GroupItem *jitEmitGE(GroupItem *argument, GroupItem *target)
{
	 return jitEmitCompare(argument, target, jitGE); 
}

/*******************************************************************************
    jitEmitGIF -- THE gIF EMITTER, riding the INTERPRET walk (pivot,
    2026-06-30). Called from aCTionIF's jitting gate with the live if-node.

    // gifRidesTheWalk  the five-step bracket, and why owning the traversal is the structural cure for the deferred path's stack corruption
*******************************************************************************/
extern "C" GroupItem *jitEmitGIF(GroupItem *input)
{
GroupItem 	*ExpressioN = input->getLabelGroup("ExpressioN");
GroupItem 	*StatemenT = input->getLabelGroup("StatemenT");
GroupItem 	*ElsE = input->getLabelGroup("ElsE");
GroupItem 	*result = ExpressioN;
	/*  ⚠ A BARE CONDITION OPERAND MUST BE MATERIALIZED -- `if isMethod` is
	FALSE for a bare read, so without the call below the condition emits
	nothing and the compare branches on whatever was last in flight.  */
	// everyValuePosition  finding #3, the three value-consuming positions that share this hole, and why assignment RHS needs nothing
	if ( isMethod(result->groupBody->flags.instructType) )
		result = result->groupBody->gMethod(result);
	else {
		result = ExpressioN;
		::jitEmitBareRead(ExpressioN);
		}
	jitIfBegin();
	if ( StatemenT )
		result = StatemenT->groupBody->gMethod(StatemenT);
	/*  Commit the then-arm's value INSIDE thenBB, and the else-arm's INSIDE
	elseBB. This is the merge: the exit block's load reads whichever arm
	ran. Must sit BEFORE jitIfElse/jitIfEnd, which move the insert point. */
	jitStoreResult();
	jitIfElse();
	/*  ⚠ THIS CLEAR IS LOAD-BEARING. Without it, an `if` with NO else commits
	a then-block value inside elseBB -- a dominance violation the verifier
	refuses. THE EMITTER THAT COMMITS OWNS THE CLEARING.  */
	// absentElseDominance  the measured IR, and why no ladder rung had the shape that exposes it
	 gJitResult = nullptr; 
	if ( ElsE )
		result = ElsE->groupBody->gMethod(ElsE);
	jitStoreResult();
	jitIfEnd();
	/*  ⚠ NOTHING IS LEFT IN FLIGHT. Both arms already committed inside their
	own block -- that IS the merge. Leaving a value here makes every path
	return the last arm EMITTED rather than the one that RAN.  */
	// bracketingLeavesNothing  the measured double-store, and why this is a rule for every bracketing emitter
	 gJitResult = nullptr; 
	return result;
}

/*******************************************************************************
    jitEmitGT -- OP TWO of the slot migration, a jitCmp deliberately rather than
    a second arithmetic. Three lines, the same as jitEmitMul.

    // secondFamilyOnPurpose  why the second specimen exercises a different family, and the assumption it went looking for and did not find
*******************************************************************************/
extern "C" GroupItem *jitEmitGT(GroupItem *argument, GroupItem *target)
{
	 return jitEmitCompare(argument, target, jitGT); 
}

/*******************************************************************************
    jitEmitIterStep -- THE JITTED ITERATOR ADVANCE. Tony's ruling, 2026-08-04:
    the interpreter's measured behaviour is the intended semantics and THE
    JIT'S 0-VISIT WALK IS THE DEFECT.

    // iterStepDefect  why opPlusPlus emitted nothing, and the two legs that put the loop back at run time
    // modelNotOracle  why the emitted call is to opPlusPlus itself, and the bare names that make re-hosting hazardous
*******************************************************************************/
extern "C" GroupItem *jitEmitIterStep(GroupItem *result)
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	llvm::LLVMContext &ctx = b->getContext();
	llvm::Type *ptr = llvm::PointerType::getUnqual(ctx);
	llvm::Type *i32 = llvm::Type::getInt32Ty(ctx);
	llvm::Type *i64 = llvm::Type::getInt64Ty(ctx);
	
	llvm::Value *resAddr = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)result), ptr, "iterNode");
	llvm::Value *callee = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)&opPlusPlus), ptr, "iterFn");
	llvm::FunctionType *stepTy = llvm::FunctionType::get(ptr, {ptr}, false);
	llvm::Value *nxt = b->CreateCall(stepTy, callee, {resAddr}, "iterNext");
	
	//  THE CONDITION. opPlusPlus returns the iterator node while it is advancing
	//  and NULL when the list is spent, so the loop test is a null test -- the
	//  same fact the interpreted `while ++g` reads, expressed as IR.
	llvm::Value *live = b->CreateICmpNE(
	b->CreatePtrToInt(nxt, i64),
	llvm::ConstantInt::get(i64, 0), "iterLive");
	llvm::Value *val = b->CreateZExt(live, i32, "iterCond");
	
	gJitResult  = val;
	gJitEmitted = true;
	return result;
	
}

/*******************************************************************************
    jitEmitIterStepBack -- THE JITTED ITERATOR RETREAT. F-53, Tony's ruling
    2026-09-04. jitEmitIterStep's twin, one token different: it bakes
    &opMinusMinus where that bakes &opPlusPlus.

    // twinNotParameter  why a second emitter rather than widening the signature, which is a groups.ext mirror change
    // unaryHasNoSlot  why the jitEmitter slot would have inverted the fix -- a unary carrying one is refused and runs interpreted
*******************************************************************************/
extern "C" GroupItem *jitEmitIterStepBack(GroupItem *result)
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	llvm::LLVMContext &ctx = b->getContext();
	llvm::Type *ptr = llvm::PointerType::getUnqual(ctx);
	llvm::Type *i32 = llvm::Type::getInt32Ty(ctx);
	llvm::Type *i64 = llvm::Type::getInt64Ty(ctx);
	
	llvm::Value *resAddr = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)result), ptr, "iterNodeB");
	llvm::Value *callee = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)&opMinusMinus), ptr, "iterFnB");
	llvm::FunctionType *stepTy = llvm::FunctionType::get(ptr, {ptr}, false);
	llvm::Value *nxt = b->CreateCall(stepTy, callee, {resAddr}, "iterPrev");
	
	llvm::Value *live = b->CreateICmpNE(
	b->CreatePtrToInt(nxt, i64),
	llvm::ConstantInt::get(i64, 0), "iterLiveB");
	llvm::Value *val = b->CreateZExt(live, i32, "iterCondB");
	
	gJitResult  = val;
	gJitEmitted = true;
	return result;
	
}

/*******************************************************************************
    jitEmitIterate -- THE ITERATOR SETUP, EMITTED. Work item 1 of the
    convergence rung, 2026-08-04.

    ⚠ THIS GATE EMITS AND THEN FALLS THROUGH. It does NOT return, and that is
    the one place it differs from every other jitting gate in the tree --
    gate-and-return would leave the node un-flagged and the advance would emit
    against the DATA arm.

    // iterateGapClosed  the gap it closes, and why setup and advance living at two different times is the displayForm hang
    // emitThenFallThrough  why falling through does not break the effect-free-emit law, stated rather than assumed
    // modelNotOracle  why the emitted call is to aCTionIterate itself
*******************************************************************************/
extern "C" void jitEmitIterate(GroupItem *input)
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	if (!b) return;
	llvm::LLVMContext &ctx = b->getContext();
	llvm::Type *ptr = llvm::PointerType::getUnqual(ctx);
	llvm::Type *i64 = llvm::Type::getInt64Ty(ctx);
	
	llvm::Value *inAddr = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)input), ptr, "iterStmt");
	llvm::Value *callee = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)&aCTionIterate), ptr, "iterSetFn");
	llvm::FunctionType *ty = llvm::FunctionType::get(ptr, {ptr}, false);
	b->CreateCall(ty, callee, {inAddr}, "iterSetup");
	
	gJitEmitted = true;
	gJitResult  = nullptr;
	
}

extern "C" GroupItem *jitEmitLE(GroupItem *argument, GroupItem *target)
{
	 return jitEmitCompare(argument, target, jitLE); 
}

extern "C" GroupItem *jitEmitLT(GroupItem *argument, GroupItem *target)
{
	 return jitEmitCompare(argument, target, jitLT); 
}

/*******************************************************************************
    jitEmitMul -- THE STEP-2 PATHFINDER: the emitter for `*`, installed on the
    op node's gJitEmitter slot and called by runOP's fork.

    ⚠ THE BODY IS ONE LINE ONTO jitEmitBinary AND MUST NOT GROW. A shim that
    starts deciding things is a second home for the op's identity.

    // namedForCollision  why it cannot be called jitMul -- an unscoped enum constant of that name already exists
    // shimStaysThin  what the slot model buys, and why the selector parameter can eventually retire
*******************************************************************************/
extern "C" GroupItem *jitEmitMul(GroupItem *argument, GroupItem *target)
{
	 return jitEmitBinary(argument, target, jitMul); 
}

/*  BATCH TWO OF THE SWEEP, 2026-08-17 -- the last four of the strict
    binary/comparison population: !=, and the three remaining arithmetic.

    THIS CLOSES THE STRICT SWEEP AT 10 OF 10. Everything still carrying an
    `if jitting` gate from here is out-by-SHAPE rather than unswept:
    jitEmitDot and jitEmitRem take a third argument (ruler->tempField), three
    are jitEmitUnary, and jitEmitAssign is a shape fit parked for other reasons.
    Each waits on its own specimen. See docs/jitSlotMigration.md.

    ⚠ NEVER-NULL STAYS OPEN, DELIBERATELY. The strict population being complete
    is NOT the sweep closing: ops remain without slots, so the null case still
    means "not yet migrated" and hardening now would fail on every one of them.
    The sweep-close obligations are unchanged and unclaimed.

    Same three lines each, and no counter increment -- that lives at the fork.  */
extern "C" GroupItem *jitEmitNE(GroupItem *argument, GroupItem *target)
{
	 return jitEmitCompare(argument, target, jitNE); 
}

/*******************************************************************************
    jitEmitRefusedCheck -- A3, THE PER-STATEMENT REFUSAL CHECK, EMITTED. Tony's
    ruling 2026-09-05.

    ⚠ THE TARGET IS E2's INLINE EXIT, NEVER gJitEpilogueBB. A callee branching
    to the enclosing epilogue returns from the CALLER -- a wrong answer wearing
    valid IR.

    // inlineExitNotEpilogue  why the target selection is jitEmitReturn's, so the two cannot drift
    // namedGapNotImplied  the top-level statements this does not yet cover, named rather than implied
*******************************************************************************/
extern "C" int jitEmitRefusedCheck()
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	if (!b) return 0;
	if (gJitInlining.empty()) return 0;
	//  ⚠ THE STATEMENT-LOCAL GATE. Nothing in this statement can refuse at RUN
	//  time, so the check would be dead weight -- and A3 measured that weight at
	//  double the lines and triple the blocks. Cleared per statement by the
	//  caller so the flag cannot leak forward into the next one.
	if (!gJitStmtCanRefuse) return 0;
	if (gJitInlineFrames.empty() || !gJitInlineFrames.back().exitBB) return 0;
	llvm::LLVMContext &ctx = b->getContext();
	llvm::Function  *fn  = b->GetInsertBlock()->getParent();
	llvm::Type      *i32 = llvm::Type::getInt32Ty(ctx);
	void *addr = (void*)&(GroupControl::groupController->groupRules->refused);
	llvm::Value *p = b->CreateIntToPtr(
	llvm::ConstantInt::get(llvm::Type::getInt64Ty(ctx),(uint64_t)addr),
	llvm::PointerType::getUnqual(ctx));
	llvm::Value *v = b->CreateLoad(i32, p, "refusedArm");
	llvm::Value *c = b->CreateICmpNE(v, llvm::ConstantInt::get(i32,0), "isRefused");
	JitInlineFrame &f = gJitInlineFrames.back();
	if (!f.used) { fn->insert(fn->end(), f.exitBB); f.used = true; }
	llvm::BasicBlock *cont = llvm::BasicBlock::Create(ctx,"notRefused",fn);
	b->CreateCondBr(c, f.exitBB, cont);
	b->SetInsertPoint(cont);
	return 1;
	
}

/*******************************************************************************
    jitEmitRem -- the first emitted call to an EXISTING operator rather than a
    purpose-built helper. Two legs: opRem(argument,target) then jitUnboxCount.

    ⚠ TWO-ARG, BECAUSE `%` IS REGISTERED operateMethod. runOP has two calling
    conventions and this is the isOperator one; J6's one-argument finding was
    true of the isMethod arm only. Check the registration before assuming arity.

    // twoArities  the two conventions side by side, and what the signature-kind table column now means
*******************************************************************************/
extern "C" GroupItem *jitEmitRem(GroupItem *argument, GroupItem *target, GroupItem *resultNode)
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	llvm::LLVMContext &ctx = b->getContext();
	llvm::Type *ptr = llvm::PointerType::getUnqual(ctx);
	llvm::Type *i32 = llvm::Type::getInt32Ty(ctx);
	llvm::Type *i64 = llvm::Type::getInt64Ty(ctx);
	
	llvm::Value *argAddr = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)argument), ptr, "remArg");
	llvm::Value *tgtAddr = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)target), ptr, "remTgt");
	llvm::Value *callee = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)&opRem), ptr, "remFn");
	llvm::FunctionType *opTy = llvm::FunctionType::get(ptr, {ptr, ptr}, false);
	llvm::Value *res = b->CreateCall(opTy, callee, {argAddr, tgtAddr}, "remRes");
	
	llvm::Value *unboxFn = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)&jitUnboxCount), ptr, "unboxFn");
	llvm::FunctionType *unboxTy = llvm::FunctionType::get(i32, {ptr}, false);
	llvm::Value *val = b->CreateCall(unboxTy, unboxFn, {res}, "remVal");
	
	if (resultNode) {
	if (!resultNode->jitData) resultNode->jitData = new JitData();
	resultNode->jitData->setJitter(val);
	gJitSeeded.push_back(resultNode);
	}
	gJitResult = val;
	gJitEmitted = true;
	return resultNode;
	
}

/*******************************************************************************
    jitEmitReturn -- `return`, EMITTED. Item 2, Tony's ruling 2026-08-05.

    THE GAP IT CLOSES: return called jitDegrade. That is why EVERY green rung in
    the ladder asserts a FIELD's value after the action and never a RETURNED one,
    and why CLAIM KANT-8's jitted parity was not merely unanswered but NOT YET
    ASKABLE. This makes it askable.

    ⚠ RETURNS 1 EMITTED or -1 REFUSED, and -1 is always a MIS-SEQUENCED CALLER --
    no builder, no epilogue block, or inlining with no frame -- never a language
    gap. Do not add an arm for 0; it is retired and nothing produces it.

    // bareReturnFree  why a bare `return;` needs no test for bareness anywhere in this function
    // deadContinuation  why the unreachable block after the branch is required, and why it matters more here than for continue
    // inlineEpilogue  E2: why a callee's return must not branch to gJitEpilogueBB, and what one JitInlineFrame per inline buys
    // tailWasSurvivable  why the whole fleet stayed green without it, and the degrade counter that could not tell the two positions apart
    // returnCodes  the retired third value, and the one-channel-one-meaning defect that forced the split
*******************************************************************************/
extern "C" int jitEmitReturn()
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	if (!b) return -1;
	if (!gJitEpilogueBB) {
	::fprintf(stderr, "=== jitEmitReturn: no epilogue block -- REFUSING ===\n");
	::fflush(stderr);
	return -1; }
	llvm::LLVMContext &ctx = b->getContext();
	llvm::Function *fn = b->GetInsertBlock()->getParent();
	//  ⚠ E2, BUILT 2026-08-09. An inlined callee's return terminates THE INLINED
	//  REGION, never the enclosing function. Same three moves as the ordinary
	//  path below -- commit the value, branch, park in a dead block -- with the
	//  branch aimed at this inline frame's own exit instead of gJitEpilogueBB.
	//  The frame's block is inserted HERE, on first use, which is what keeps a
	//  return-free callee's IR byte-identical (JitInlineFrame's H7 note).
	if (!gJitInlining.empty()) {
	if (gJitInlineFrames.empty() || !gJitInlineFrames.back().exitBB) {
	::fprintf(stderr, "=== jitEmitReturn: inlining with no frame -- REFUSING ===\n");
	::fflush(stderr);
	return -1; }
	JitInlineFrame &f = gJitInlineFrames.back();
	
	jitStoreResult();
	
	if (!f.used) { fn->insert(fn->end(), f.exitBB); f.used = true; }
	b->CreateBr(f.exitBB);
	llvm::BasicBlock *idead = llvm::BasicBlock::Create(ctx, "afterInlineReturn", fn);
	b->SetInsertPoint(idead);
	gJitEmitted = true;
	gJitResult  = nullptr;
	return 1; }
	
	/*  COMMIT THE RETURNED VALUE THE SAME WAY EVERY OTHER STATEMENT COMMITS
	ITS OWN -- shared implementation, so a return cannot drift from the
	block walk's idea of what a value is (the double and i1 coercions live
	in one place). A no-op for a bare return, which is E3 above.  */
	jitStoreResult();
	
	b->CreateBr(gJitEpilogueBB);
	llvm::BasicBlock *dead = llvm::BasicBlock::Create(ctx, "afterReturn", fn);
	b->SetInsertPoint(dead);
	gJitEmitted = true;
	/*  THE EMITTER THAT COMMITS OWNS THE CLEARING (rule E1 of the bracketing
	emitters). aCTionBlocK calls jitStoreResult again right after this
	statement returns, and that call must be a no-op -- it would otherwise
	emit a store into the dead block above.  */
	gJitResult  = nullptr;
	return 1;
	
}

/*******************************************************************************
    jitEmitSelfCall -- THE RECURSIVE CALL, emitted rather than inlined. Returns
    1 when it emitted, 0 when it did not -- and 0 is the common, CORRECT
    answer, because an ordinary call still inlines.

    // inliningStopsHere  why a self-call cannot be inlined, and why the cached SSA state fires before non-termination does
    // selfCallSignature  what a no-argument self-call proves and what it does not
*******************************************************************************/
extern "C" int jitEmitSelfCall(GroupItem *argument, GroupItem *action)
{
	
	// ⚠ COMPARED ON groupBody, NOT ON THE NODE POINTER, AND THAT IS THE SAME
	// FINDING AS INCREMENT 1's: STORAGE IS IDENTITY, NODES ARE OCCURRENCES. The
	// first cut tested `action != gJitCurrentAction` and never matched --
	// measured, `callee=jrFact current=jrFact match=0`. The jrFact node
	// referenced INSIDE the body is a different GroupItem from the one
	// jitRunAction was handed, exactly as each occurrence of a local is its own
	// node. Second instance of this in one day; cross-filed to the name-scope
	// pack, which is where node-identity/copy behaviour accumulates.
	if (!gJitCurrentFn) return 0;
	//  A SELF-CALL IS A CALL TO ANY ACTION CURRENTLY ON THE WALK, not only to
	//  the one the function was built for. An inlined callee that calls itself
	//  is recursion just as much as the outermost action calling itself, and
	//  treating it as an ordinary call inlines it AGAIN over nodes that already
	//  carry jitData -- see gJitInlining's note.
	//
	//  ⚠⚠ WHAT THIS CALL TARGETS IS NOW A DECISION, NOT A CONSTANT (S3, ruled
	//  by Tony 2026-08-05). It used to be gJitCurrentFn unconditionally, and
	//  THAT WAS THE DEFECT: emit-on-walk inlines an ordinary callee into the
	//  CALLER's builder, so a self-call inside that inlined body had no separate
	//  function to name and got the ENCLOSING one -- re-entering the driver's
	//  entry block and replaying its whole preamble on every recursion
	//  (incant/inlineSelfT; measured on the IR, `%selfcall = call i32 @jitFn0()`
	//  where @jitFn0 is the DRIVER's).
	//  displayForm survived it only because dfDrive's body is exactly ONE
	//  statement, so re-entering the function happened to equal re-entering the
	//  callee. Rung JC was green for a reason true of its driver, not of the
	//  mechanism.
	llvm::Function *target = nullptr;
	{
	//  1. THE MAP IS THE PREDICATE. If this callee already has its own
	//     function, call it -- no inlining, no self-test needed, and this
	//     is the arm that fires on the REBUILD and for every A->B->A leg.
	target = jitFnMapFind(action->groupBody);
	
	bool self = gJitCurrentAction &&
	action->groupBody == gJitCurrentAction->groupBody;
	bool inlined = false;
	if (!self)
	for (GroupBody *b : gJitInlining)
	if (b == action->groupBody) { inlined = true; break; }
	
	//  2. NOT IN THE MAP AND NOT ON THE WALK: an ordinary call. INLINE, and
	//     that is still the calling convention (ruled 2026-08-01).
	if (!target && !self && !inlined) return 0;
	
	//  3. NOT IN THE MAP, BUT IT IS THE ACTION THIS VERY FUNCTION IS BEING
	//     BUILT FOR. gJitCurrentFn is then genuinely the right target -- it
	//     is this action's own function. This is J-R's arm and it is
	//     unchanged; it is also how a callee built as its own function
	//     resolves its OWN recursion, which is why building a callee needs
	//     no pre-registration in the map.
	if (!target && self) target = gJitCurrentFn;
	
	//  4. NOT IN THE MAP, AND SELF ONLY BECAUSE IT IS BEING INLINED. THIS IS
	//     THE DISCOVERY, and it is the first moment in the whole walk that
	//     the fact exists. The enclosing function is now known to be wrong,
	//     so record the callee and ask for a restart; the build loop erases
	//     what has been emitted so far and builds this callee first.
	//     ⚠ IT STILL EMITS, and deliberately: the function must reach its
	//     ret and verify so the loop gets control back cleanly. gJitCurrentFn
	//     is the OLD, WRONG target -- which does not matter, because
	//     jitDiscardPartial erases this function before anything runs it.
	//     Emitting a placeholder instead would be a second shape to be right
	//     about for no gain.
	if (!target) {
	if (!jitPendingHas(action->groupBody)) {
	JitPending p; p.body = action->groupBody; p.action = action;
	gJitNeedOwnFn.push_back(p);
	//  ⚠ STDOUT, AND THE SAME `=== jit<Name>: ... ===` SHAPE AS
	//  EVERY OTHER COMPILE-TIME REPORT IN THIS FILE. One channel,
	//  one meaning, one convention: these three S3 lines are compile
	//  NARRATION, not walk output, and rung JC's filter is written
	//  against exactly that prefix. Splitting them across stdout and
	//  stderr would make a byte-diff instrument's contents depend on
	//  whether the harness merged the streams.
	printf("=== jitEmitSelfCall: DISCOVERED %s needs its own function ===\n",
	action->groupBody->tag);
	fflush(stdout); }
	gJitRestartNeeded = true;
	target = gJitCurrentFn; }
	}
	llvm::IRBuilder<> *b = gJitBuilder;
	//  ⚠ BIND THE ARGUMENT FIRST, AT RUN TIME. runAction's gate returns here,
	//  ABOVE its own binding lines, so without this the emitted self-call bound
	//  nothing and every depth saw whatever node emit time left behind --
	//  recursion with an argument could not work at all.
	//  The callee and the caller's OPERAND are baked; what is NOT baked is which
	//  node the operand points at, because for an iterator that changes per
	//  iteration. jitBindArgRT does the unwrap and the bind at run time, using
	//  runAction's own lines, so the emitted call binds exactly as the
	//  interpreted call does.
	//  The CALL STAYS NULLARY: the argument travels through the callee's
	//  `argument` field, which is where the callee's body already looks for it.
	//  Adding a real parameter would change the compiled signature -- and
	//  rStuff.jitMethod with it, a layout change -- while the body would still
	//  read the field, so the parameter would carry nothing anyone reads.
	if (argument) {
	llvm::LLVMContext &ctx = b->getContext();
	llvm::Type *ptr = llvm::PointerType::getUnqual(ctx);
	llvm::Type *i64 = llvm::Type::getInt64Ty(ctx);
	llvm::Value *argAddr = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)argument), ptr, "callArg");
	llvm::Value *fldAddr = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)action), ptr, "callee");
	llvm::Value *bindFn = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)&jitBindArgRT), ptr, "bindFn");
	llvm::FunctionType *bindTy = llvm::FunctionType::get(ptr, {ptr, ptr}, false);
	b->CreateCall(bindTy, bindFn, {argAddr, fldAddr}, "bindArg"); }
	//  ⚠ THE FRAME BRACKET, in runAction's OWN ORDER: bind, save, body, restore.
	//  (GroupActions.rtn -- the gate at :705-707, bind :708-711, save :713, body
	//  :721, restore :725 as of 2026-08-05. The earlier :670/:677/:685/:689 in
	//  this comment were b7a01c1 line numbers and went stale when jitSaveFrameRT
	//  was inserted above runAction; corrected as S3's ride-along.)
	//  The gate returns above the last three, so without this an emitted
	//  self-call runs unbracketed and any
	//  NODE-RESIDENT local -- an iterator's cursor above all -- is shared with
	//  the caller. Scalars are per-activation for free because they are allocas
	//  in this function; nodes are baked and shared, which is the whole defect.
	//  ⚠ MEASUREMENT, NOT ARCHITECTURE: this depends on saveLocalFields, which
	//  §0 sentences to deletion. Tony rules on whether the shape stays.
	{
	llvm::LLVMContext &ctx = b->getContext();
	llvm::Type *ptr = llvm::PointerType::getUnqual(ctx);
	llvm::Type *i64 = llvm::Type::getInt64Ty(ctx);
	llvm::FunctionType *frameTy =
	llvm::FunctionType::get(llvm::Type::getVoidTy(ctx), {ptr}, false);
	llvm::Value *calleeAddr = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)action), ptr, "frameCallee");
	llvm::Value *saveFn = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)&jitSaveFrameRT), ptr, "saveFn");
	b->CreateCall(frameTy, saveFn, {calleeAddr});
	//  ⚠ `target`, NOT gJitCurrentFn. See the four-arm decision above -- the
	//  whole of S3 is the difference between those two expressions.
	llvm::Value *v = b->CreateCall(target, {}, "selfcall");
	llvm::Value *restoreFn = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)&jitRestoreFrameRT), ptr, "restoreFn");
	b->CreateCall(frameTy, restoreFn, {calleeAddr});
	gJitResult  = v;
	gJitEmitted = true;
	return 1; }
	
}

/*******************************************************************************
    jitEmitShortCircuit -- TIER 3 UNDER THE JIT. 2026-08-11, docs/andOrRung.md
    §3 part 2, ruling SEQ 32.

    ⚠ THE DEGRADE LINE HERE MEANS "NOT EMITTED", NEVER "SOUND". For an AND/OR
    inside a multi-fire jitted action the fallback is NOT safe -- an emit-time
    fold returns fire 1's answer forever. Rungs assert the VALUES on both
    fires; they must not accept the counter as the proof.

    // crashTradedForSilence  what promoting AND/OR fixed, and the silent wrong answer it introduced at degrade count 0
    // unboxedCannotSee  which of truthOf's four rows an unboxed i32 can represent, and why the other three are refused rather than guessed
*******************************************************************************/
extern "C" GroupItem *jitEmitShortCircuit(GroupItem *field)
{
GroupItem 	*op = field->get(1);
GroupItem 	*target = field->get(2);
GroupItem 	*arg = field->get(3);
int 		isAND = 0;
	if ( ::compare(op->groupBody->tag,"AND") == 0 )
		isAND = 1;
	if ( isMethod(target->groupBody->flags.instructType) && target->groupBody->flags.invoke )
		target->groupBody->gMethod(target);
	else	::jitEmitBareRead(target);
	/*  gJitResult is a C++ global in jitContext.h and is NOT a field, so it
	is unreadable at tok level -- tok emits
	`ERROR FieldBody: could not find gJitResult` straight into the .mm,
	which fails at the C++ step with `use of undeclared identifier`
	pointing at a word from the error TEXT. Every test of it therefore
	lives in passthrough. (Three-languages-share-the-tree, and the
	generated line is the only place that says which one you were in.)  */
	
	if (!gJitResult) {
	jitDegrade("AND/OR LEFT operand produced no value", target);
	return nullptr;
	}
	
	jitScBegin(isAND);
	if ( isMethod(arg->groupBody->flags.instructType) && arg->groupBody->flags.invoke )
		arg->groupBody->gMethod(arg);
	else	::jitEmitBareRead(arg);
	
	if (!gJitResult)
	jitDegrade("AND/OR RIGHT operand produced no value", arg);
	
	jitScEnd(field);
	return field;
}

/* jitEmitStringPlusEQ  the FIRST CreateCall in the JIT layer, and the proof-of-
   concept for jitEmitCall. Bakes target's and argument's stable GroupItem
   addresses as constant ptrs (jitSeedField pattern), then emits a single call to
   concatEQ (callee baked by address) — GroupItem(GroupItem,GroupItem). The +=
   side effect (setText through to target's real storage) is the payload; the
   i32() driver can't ret a pointer, so cap gJitResult with a constant 0 and verify
   by reading target's text back in interpreted incant (the jitAssign readback
   pattern). The call is left untagged (NOT readnone) so LLVM can't DCE a callee it
   can't see into. */
extern "C" GroupItem *jitEmitStringPlusEQ(GroupItem *argument, GroupItem *target)
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	llvm::LLVMContext &ctx = b->getContext();
	llvm::Type *ptr = llvm::PointerType::getUnqual(ctx);
	llvm::Type *i32 = llvm::Type::getInt32Ty(ctx);
	llvm::Type *i64 = llvm::Type::getInt64Ty(ctx);
	
	llvm::Value *targetAddr = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)target), ptr);
	llvm::Value *argAddr = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)argument), ptr);
	
	llvm::FunctionType *fnTy = llvm::FunctionType::get(ptr, {ptr, ptr}, false);
	llvm::Value *callee = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)&concatEQ), ptr);
	b->CreateCall(fnTy, callee, {targetAddr, argAddr});
	
	gJitResult = llvm::ConstantInt::get(i32, 0);
	return target;
	
}

extern "C" GroupItem *jitEmitSub(GroupItem *argument, GroupItem *target)
{
	 return jitEmitBinary(argument, target, jitSub); 
}

/*******************************************************************************
    jitEmitTrace -- THE EMITTER HALF. Bakes the field's stable GroupItem address
    and jitTraceRT's address as constants, then emits ONE CreateCall of
    GroupItem*(GroupItem*).

    ⚠ THE CALL IS LEFT UNTAGGED, not readnone, so LLVM cannot DCE a callee it
    cannot see into -- the concatEQ lesson.

    // fallbackSignature  the convention, and that it was verified against runOP's dispatch rather than adopted from the design
    // noBakedOffsets  why GEP arithmetic over GroupBody is refused, and what it would cost in emitted code
*******************************************************************************/
extern "C" void jitEmitTrace(GroupItem *field)
{
	
	if (!gJitBuilder || !field) return;
	llvm::IRBuilder<> *b = gJitBuilder;
	llvm::LLVMContext &ctx = b->getContext();
	llvm::Type *ptr = llvm::PointerType::getUnqual(ctx);
	llvm::Type *i64 = llvm::Type::getInt64Ty(ctx);
	
	llvm::Value *fieldAddr = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)field), ptr, "traceArg");
	llvm::Value *callee = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)&jitTraceRT), ptr, "traceFn");
	llvm::FunctionType *fnTy = llvm::FunctionType::get(ptr, {ptr}, false);
	b->CreateCall(fnTy, callee, {fieldAddr});
	gJitEmitted = true;
	
}

/* jitEmitUnary  the in-place increment/decrement emitter — the unary sibling of
   jitEmitBinary. ++/-- read the operand, add or subtract a literal 1 (int or
   float per the operand's LLVM type), and WRITE BACK to the operand's slot, since
   ++/-- mutate in place (like a compound assign on a single operand). The operand
   must already be seeded (jitSeedField) so jitData->jitValue holds the load and
   jitData->jitSlot the store destination. `op` is a jitUnary (jitContext.h).
   NOTE: not wired yet — the unary expression flows through aCTionTokenXP -> a uxp
   node -> runOP, bypassing aCTionExpressioN's binary-shaped jitting gate, so no
   gate currently reaches opPlusPlus/opMinusMinus under jitting (see report). */
extern "C" GroupItem *jitEmitUnary(GroupItem *target, int op)
{
	
	// The operand MUST arrive seeded (runOP's gate). If it does not, degrade
	// LOUDLY and countably rather than dereferencing null -- gJitDegradeCount
	// is asserted 0 by every jitLadder rung, so this cannot pass silently. A
	// quiet null-check returning target would be worse than the crash it
	// replaces: exit 0 with wrong IR. See GroupActions.rtn's seed gate.
	if (!target || !target->jitData) {
	jitDegrade("unary operand reached jitEmitUnary unseeded", target);
	return target;
	}
	llvm::IRBuilder<> *b = gJitBuilder;
	llvm::Value *v = target->jitData->jitValue;
	llvm::Value *res = nullptr;
	// Unary minus: value-producing (0 - operand). No store-back — the operand
	// is not mutated; the negated SSA value flows up as the result.
	if (op == jitNeg) {
	res = v->getType()->isDoubleTy() ? b->CreateFNeg(v, "neg") : b->CreateNeg(v, "neg");
	target->jitData->setJitter(res);
	gJitResult = res;
	return target;
	}
	if (v->getType()->isDoubleTy()) {
	llvm::Value *one = llvm::ConstantFP::get(v->getType(), 1.0);
	res = (op == jitDec) ? b->CreateFSub(v, one, "dec") : b->CreateFAdd(v, one, "inc");
	} else {
	llvm::Value *one = llvm::ConstantInt::get(v->getType(), 1);
	res = (op == jitDec) ? b->CreateSub(v, one, "dec") : b->CreateAdd(v, one, "inc");
	}
	target->jitData->setJitter(res);
	if (target->jitData->jitSlot)   b->CreateStore(res, target->jitData->jitSlot);
	gJitResult = res;
	return target;
	
}

/*******************************************************************************
    jitEmitWHILE -- the while emitter (rung J3). Mirrors jitEmitGIF's shape:
    gate in aCTionWhilE, bracket the sub-walks, let the runOP walk own its
    traversal.

    ⚠ IT CLEARS gJitResult BEFORE RETURNING. A bracketing emitter leaves
    nothing in flight, or the enclosing walk commits the stale body value again
    in the exit block.

    // e1FirstCustomer  E1's first audit customer, and the gIF clobber it exists to avoid
    // conditionWalkedOnce  the old 134 abort, and why walking the condition once is the honest retest
*******************************************************************************/
extern "C" GroupItem *jitEmitWHILE(GroupItem *input)
{
GroupItem 	*ExpressioN = input->getLabelGroup("ExpressioN");
GroupItem 	*StatemenT = input->getLabelGroup("StatemenT");
GroupItem 	*result = 0;
	jitLoopBegin();
	result = ExpressioN;
	/*  BARE CONDITION OPERAND -- see the note in jitEmitGIF. `if isMethod` is
	false for a bare read, so without this the condition emits nothing and
	the loop branches on whatever was last in flight.  */
	if ( isMethod(result->groupBody->flags.instructType) )
		result = result->groupBody->gMethod(result);
	else	::jitEmitBareRead(ExpressioN);
	jitLoopBody();
	if ( StatemenT )
		result = StatemenT->groupBody->gMethod(StatemenT);
	/*  NO jitStoreResult() HERE, and that is a correction rather than an
	omission. aCTionBlocK already commits EVERY statement under jitting, and
	a loop body is always block-wrapped -- measured on rung J5, whose
	two-statement body emitted THREE stores to the result slot: one per
	statement plus this one, duplicating the last. One committer per value
	(the one-channel family's cousin: two writers, one location, benign only
	while they agree).  */
	jitLoopEnd();
	 gJitResult = nullptr; 
	return result;
}

/*  IT SETS NO FLAG, deliberately -- presence of the slot is the only signal, and that
    is what lets runOP's fork be a null test.   jitEmitters.jitEmitter  */
extern "C" GroupItem *jitEmitter(GroupItem *input)
{
char 	*name = input->getText();
	if ( input->groupBody->flags.fLAG )
		if ( name )
			{
			GroupItem 	*grup = input->parent;
			void 		*sym = ::dlsym(RTLD_SELF,name);
			if ( grup )
				{
				/*  The symbol is tested, not the slot: GroupItem carries no
				jitEmitter member (it is a GroupBody slot reached by alias),
				and a failed dlsym must be LOUD rather than installing null
				and leaving the op silently unmigrated.  */
				if ( sym )
					grup->setJitEmitter(sym);
				else	::fprintf(stderr,"jitEmitter: could not find emitter: %s\n",name);
				}
			else	::fprintf(stderr,"jitEmitter: no parent to attach the emitter to\n");
			}
		else	::fprintf(stderr,"jitEmitter: expected an emitter name in jitEmitter text\n");
	else	::fprintf(stderr,"jitEmitter: should be invoked as an attribute when its parent is defined\n");
	return input->getGroup();
}

extern "C" void *jitEngine()
{
	
	static std::unique_ptr<llvm::orc::LLJIT> theJIT;
	if (!theJIT) {
	jitInitOnce();
	auto created = llvm::orc::LLJITBuilder().create();
	if (created) theJIT = std::move(*created);
	}
	return theJIT.get();
	
}

/* jitExecBlock  the JIT body driver (pivot, 2026-06-30) — replaces the deferred
   jitWalkBlock walk. Hoists the action's parsed BlocK and runs its gMethod, which
   EXECUTES the statement runOP trees under jitting so each opMethod gate emits LLVM
   in place. Control flow lands through aCTionIF's jitting gate -> jitEmitGIF. The
   BlocK hoist is tok-native so it's reliable; jitRunAction calls it after
   processCode has built the BlocK. */
extern "C" GroupItem *jitExecBlock(GroupItem *input)
{
GroupItem 	*BlocK = input->getLabelGroup("BlocK");
	if ( BlocK )
		BlocK->groupBody->gMethod(BlocK);
	return input;
}

/*  jitFieldMethod -- set-then-call dispatch for a field's compiled method.
    see DesignDocs: JitFieldMethod
*******************************************************************************/
extern "C" GroupItem *jitFieldMethod(GroupItem *field)
{
	
	GroupRules *ruler   = GroupControl::groupController->groupRules;
	//  THE CANONICAL NODE. Everything below reads and writes THIS, never the
	//  arriving wrapper -- see the definingRule() block in the header.
	GroupItem  *definer = field->definingRule();
	RuleStuff  *stuff   = definer->rStuff;
	char       *name    = definer->groupBody->tag;
	
	if (::getenv("INCANT_SLOT_PROBE"))
	fprintf(stderr,
	"=== SLOTPROBE %s: field=%p definer=%p body=%p rStuff=%p jitMethod=%p ===\n",
	name, (void*)field, (void*)definer, (void*)definer->groupBody,
	(void*)stuff, stuff ? (void*)stuff->jitMethod : (void*)0);
	
	/*  PATH 1 -- THE SLOT. This is the only dispatch in the function. */
	if (stuff && stuff->jitMethod) {
	int r = stuff->jitMethod();
	printf("=== jitFieldMethod: %s THROUGH THE SLOT, result = %d ===\n", name, r);
	//  Both counters on EVERY fire, with their values. The slot path cannot
	//  raise the degrade count (it re-enters no emitter), and printing it
	//  anyway is the point: H4 wants the quantity compared, not its message
	//  absent. A rung asserting "degrade 0 on every fire" must have a line
	//  to read on every fire, or it is asserting over the compile fire only
	//  and quietly saying nothing about the others.
	printf("=== jitDegrade count = %d ===\n", gJitDegradeCount);
	printf("=== jitCompile count = %d ===\n", gJitCompileCount);
	fflush(stdout);
	return ruler->trueResult; }
	
	/*  PATH 2 -- FIRST FIRE. Compile-on-first-fire is the ruling (Clay SEQ 27
	v2), consistent with R2's convert-at-first-application: the artifact is
	made where it is first needed, not at definition. */
	printf("=== jitFieldMethod: %s FIRST FIRE -- compiling ===\n", name);
	fflush(stdout);
	int r = jitRunAction(definer);
	if (r < 0) {
	printf("=== jitFieldMethod: %s COMPILE REFUSED (%d) -- slot left empty ===\n",
	name, r);
	fflush(stdout);
	return 0; }
	
	if (!stuff) {
	stuff = new RuleStuff(definer);
	definer->setRStuff(stuff); }
	stuff->jitMethod = gJitLastFn;
	if (::getenv("INCANT_SLOT_PROBE"))
	fprintf(stderr,
	"=== SLOTPROBE %s STORED: rStuff=%p jitMethod=%p  readback rStuff=%p jitMethod=%p ===\n",
	name, (void*)stuff, (void*)stuff->jitMethod,
	(void*)definer->rStuff,
	definer->rStuff ? (void*)definer->rStuff->jitMethod : (void*)0);
	
	/*  THE RECORD IS NOT WRITTEN HERE ANY MORE -- jitRunAction hangs `JiT` at
	the capture site, and the call above (`jitRunAction(definer)`) has
	already done it against this exact node. Writing it again here would be
	the second of two paths to one record, which is the thing PJ-2 forbids;
	the record's home is the compiler, not this caller. The byte count below
	still reads gJitLastIR, which is a READ of the same fact, not a second
	write of it. */
	
	printf("=== jitFieldMethod: %s COMPILED, result = %d, slot set, JiT %zu bytes ===\n",
	name, r, gJitLastIR.size());
	printf("=== jitCompile count = %d ===\n", gJitCompileCount);
	fflush(stdout);
	return ruler->trueResult;
	
}

/*******************************************************************************
    jitFlushTransient -- THE TRANSIENT-STATE FLUSH, ONE MECHANISM, TWO CALL
    SITES. S3 rider R1, Tony 2026-08-05.

    ⚠ IT DOES NOT TOUCH gJitBuilder OR gJitResultSlot. jitBuildFunction sets
    those for itself immediately after calling this, and the discard path nulls
    them separately because there the function they point into is gone.

    // transientOneMechanism  what it clears, and why two copies of five lines would have drifted into an SSA-staleness bug
*******************************************************************************/
extern "C" void jitFlushTransient()
{
	
	for (GroupItem *seeded : gJitSeeded) seeded->jitData = nullptr;
	gJitSeeded.clear();
	gJitFrame.clear();
	gJitResult     = nullptr;
	gJitResultNode = nullptr;
	gJitPrintBuf   = nullptr;
	gIfEndBlocks.clear();
	gIfElseBlocks.clear();
	gLoopCondBlocks.clear();
	gLoopExitBlocks.clear();
	gLoopBodyBlocks.clear();
	gJitInlining.clear();
	//  ⚠ THE EPILOGUE BLOCK BELONGS TO THE FUNCTION THAT IS BEING ABANDONED, so
	//  it is transient in exactly the sense this flush exists for. On a DISCARD
	//  it is a pointer into a block whose function was just erased -- worse than
	//  stale -- and on the boundary between two functions it would let the
	//  second one's returns branch into the first one's exit.
	gJitEpilogueBB = nullptr;
	
}

/***************************************************************************
    jitEmitters dot rtn  Phase JIT engine and emitters. Written tok native
    using the declarations in jitExterns; passthrough used only for the one
    time ORCv2 engine setup. Mirrors the retired emitter file from Tokf.
    NOTE keep passthrough markers and declared type names out of comments.
***************************************************************************/
/* Pulls jitContext.h into GroupRules.mm: a tok-native use of an external type
   (plain signature, so the generated header stays llvm-clean). The real emitters
   will use the externs in their bodies; until then this forces the include. */
extern "C" void jitForceInclude()
{
llvm::IRBuilder<> 	*b = 0;
	b = 0;
}

/* jitIfBegin  the gIF condition-to-blocks seam. Reads the condition value the
   just-emitted ExpressioN left in gJitResult (an i1 from jitEmitCompare — the
   compare-operator design plugs in HERE, this only requires an i1), creates the
   then + endif blocks in the current function, emits the CreateCondBr, sets the
   builder to the then block, and stacks the endif for jitIfEnd. Defensive: a
   non-i1 condition is coerced with CreateICmpNE 0 (so a value-shaped condition
   still branches). The one LLVM-native half of the otherwise tok-native gIF. */
extern "C" void jitIfBegin()
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	llvm::LLVMContext &ctx = b->getContext();
	llvm::Function *fn = b->GetInsertBlock()->getParent();
	llvm::Value *cond = gJitResult;
	if (!cond->getType()->isIntegerTy(1))
	cond = b->CreateICmpNE(cond,
	llvm::ConstantInt::get(cond->getType(), 0), "tobool");
	llvm::BasicBlock *thenBB = llvm::BasicBlock::Create(ctx, "then", fn);
	llvm::BasicBlock *elseBB = llvm::BasicBlock::Create(ctx, "else", fn);
	llvm::BasicBlock *endBB  = llvm::BasicBlock::Create(ctx, "endif", fn);
	b->CreateCondBr(cond, thenBB, elseBB);
	b->SetInsertPoint(thenBB);
	gIfElseBlocks.push_back(elseBB);
	gIfEndBlocks.push_back(endBB);
	
}

/*******************************************************************************
    jitIfElse -- closes the THEN arm and opens the ELSE arm. Called
    UNCONDITIONALLY by jitEmitGIF, with or without a source `else`.

    // oneTopologyAlways  why the missing else was a second topology rather than a bug, and what branching on hasElse would recreate
*******************************************************************************/
extern "C" void jitIfElse()
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	llvm::BasicBlock *endBB  = gIfEndBlocks.back();
	llvm::BasicBlock *elseBB = gIfElseBlocks.back();
	b->CreateBr(endBB);
	b->SetInsertPoint(elseBB);
	
}

/*******************************************************************************
    jitIfEnd -- closes the ELSE arm and resumes at the endif merge block,
    popping BOTH stacks in lockstep.

    // fieldStoresNeedNoPhi  why no phi is needed, why the old comment's PromotePass reason was wrong, and which thing genuinely has no merge
*******************************************************************************/
extern "C" void jitIfEnd()
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	llvm::BasicBlock *endBB = gIfEndBlocks.back();
	gIfEndBlocks.pop_back();
	gIfElseBlocks.pop_back();
	b->CreateBr(endBB);
	b->SetInsertPoint(endBB);
	
}

extern "C" void jitInitOnce()
{
	
	static bool done = false;
	if (done) return;
	llvm::InitializeNativeTarget();
	llvm::InitializeNativeTargetAsmPrinter();
	llvm::InitializeNativeTargetAsmParser();
	done = true;
	
}

/*******************************************************************************
    jitInlinePop -- CLOSE THE INLINED REGION, and if any return branched out of
    it, land the builder on the region's own exit with the callee's value in
    hand.

    ⚠ IT TAKES `resultNode` BECAUSE gJitResult IS NOT THE CHANNEL THE CALLER
    READS. An enclosing assignment reads its operand's jitData->jitValue, so
    the merged value must be STAMPED on the node, not left in the global.

    // returnedValueChannel  how the value used to arrive by accident, and the IR dump that corrected the assumption
    // gatedNoChange  why a callee with no return emits byte-identical IR, which is the H7 obligation
*******************************************************************************/
extern "C" void jitInlinePop(GroupItem *resultNode)
{
	
	if (!gJitInlineFrames.empty()) {
	JitInlineFrame f = gJitInlineFrames.back();
	gJitInlineFrames.pop_back();
	llvm::IRBuilder<> *b = gJitBuilder;
	if (f.used && b && b->GetInsertBlock()) {
	//  The fall-through path still needs to reach the merge. A block
	//  already terminated (the dead block parked after a return) does
	//  not, and must not be given a second terminator.
	if (!b->GetInsertBlock()->getTerminator())
	b->CreateBr(f.exitBB);
	//  ⚠ NO INSERT HERE. `used` means jitEmitReturn ALREADY parented
	//  this block on first use, and inserting a block that is already in
	//  the function corrupts the ilist -- it surfaces far away, as
	//  "pointer being freed was not allocated" inside ~Function() at
	//  module teardown, with a backtrace pointing at LLJIT::lookup and
	//  naming nothing of ours. Moved rather than inserted, so the exit
	//  reads after the body it closes.
	f.exitBB->moveAfter(b->GetInsertBlock());
	b->SetInsertPoint(f.exitBB);
	if (gJitResultSlot) {
	llvm::Type *i32 = llvm::Type::getInt32Ty(b->getContext());
	llvm::Value *merged =
	b->CreateLoad(i32, gJitResultSlot, "inlineRet");
	gJitResult  = merged;
	gJitEmitted = true;
	if (resultNode) {
	if (!resultNode->jitData) resultNode->jitData = new JitData();
	resultNode->jitData->setJitter(merged);
	gJitSeeded.push_back(resultNode); } } }
	else if (f.exitBB && !f.used)
	delete f.exitBB; }
	if (!gJitInlining.empty()) gJitInlining.pop_back();
	
}

/* jitInlinePush / jitInlinePop  bracket an INLINED callee so a recursive call
   inside it is recognised as recursion. See gJitInlining in jitContext.h. */
extern "C" void jitInlinePush(GroupItem *action)
{
	
	if (!action) return;
	gJitInlining.push_back(action->groupBody);
	//  E2. The frame is pushed for EVERY inline, but its block is created
	//  UNPARENTED and stays out of the function until a return actually wants
	//  it -- see JitInlineFrame's note on why that laziness is an H7 obligation
	//  rather than a saving.
	JitInlineFrame f;
	if (gJitBuilder && gJitBuilder->GetInsertBlock())
	f.exitBB = llvm::BasicBlock::Create(gJitBuilder->getContext(), "inlineExit");
	gJitInlineFrames.push_back(f);
	
}

/*******************************************************************************
    jitLoopBegin -- open a loop: create cond/body/exit, branch into cond, and
    set the insert point THERE so the condition sub-walk emits inside it.

    ⚠ THE ORDER IS THE OPPOSITE OF gIF. Get it backwards and the condition is
    evaluated once, ahead of the loop: infinite, or never entered.

    // loopOrderInverted  why an if emits its condition first and a loop cannot
*******************************************************************************/
extern "C" void jitLoopBegin()
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	llvm::LLVMContext &ctx = b->getContext();
	llvm::Function *fn = b->GetInsertBlock()->getParent();
	llvm::BasicBlock *condBB = llvm::BasicBlock::Create(ctx, "cond", fn);
	llvm::BasicBlock *exitBB = llvm::BasicBlock::Create(ctx, "loopexit", fn);
	b->CreateBr(condBB);            // preheader falls into cond
	b->SetInsertPoint(condBB);
	gLoopCondBlocks.push_back(condBB);
	gLoopExitBlocks.push_back(exitBB);
	
}

/* jitLoopBody  close the condition and open the body. Reads the i1 the
   condition sub-walk left in gJitResult, emits the CondBr to body/exit, and
   sets the insert point to body.

   ⚠ THE gJitResult READ MUST BE IMMEDIATE -- no emission may sit between the
   condition walk and this call. gJitResult is a single-slot channel and a
   clobber does not announce itself. Same rule jitIfBegin obeys. */
extern "C" void jitLoopBody()
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	llvm::LLVMContext &ctx = b->getContext();
	llvm::Function *fn = b->GetInsertBlock()->getParent();
	llvm::Value *cond = gJitResult;
	if (!cond) return;
	if (!cond->getType()->isIntegerTy(1))
	cond = b->CreateICmpNE(cond,
	llvm::ConstantInt::get(cond->getType(), 0), "tobool");
	llvm::BasicBlock *bodyBB = llvm::BasicBlock::Create(ctx, "body", fn);
	b->CreateCondBr(cond, bodyBB, gLoopExitBlocks.back());
	b->SetInsertPoint(bodyBB);
	
}

/* jitLoopEnd  close the body with the BACK EDGE and resume at exit, popping
   both stacks. The back edge is what makes it a loop rather than a one-shot
   guarded block, and it is the whole difference from jitIfEnd. */
extern "C" void jitLoopEnd()
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	llvm::BasicBlock *condBB = gLoopCondBlocks.back();
	llvm::BasicBlock *exitBB = gLoopExitBlocks.back();
	gLoopCondBlocks.pop_back();
	gLoopExitBlocks.pop_back();
	b->CreateBr(condBB);            // <-- the back edge
	b->SetInsertPoint(exitBB);
	
}

/* jitNodeInFlight  is there a GroupItem result waiting? The tok-level test for
   the node channel, so the print walk can ask without a passthrough. */
extern "C" int jitNodeInFlight()
{
	 return gJitResultNode ? 1 : 0; 
}

/*******************************************************************************
    jitPrintArm -- CLEAR THE IN-FLIGHT VALUE before an item's expression emits.

    ⚠ WITHOUT THIS AN ITEM THAT EMITS NOTHING INHERITS THE PREVIOUS ITEM'S
    VALUE, and a stale read is worse than a zero because it looks like data.

    // staleReadLooksLikeData  the measured 0-then-80329152, and why the defect got worse as the emitters got better
*******************************************************************************/
extern "C" void jitPrintArm()
{
	/*  ⚠ IT CLEARS THE NODE CHANNEL TOO (SEQ 142). The arm exists so that "THIS
	item emitted nothing" is answerable rather than "nobody ever did"; once
	print consults gJitResultNode as well, a stale node from an EARLIER item
	would be taken and the arm's whole purpose defeated. Both channels, one
	clearing.   jitEmitters.jitPrintArm  */
	 gJitResult = nullptr; gJitResultNode = nullptr; gJitLastIsNode = false; 
}

/*  aCTionPrinT's own three lines. There is deliberately no jitPrintEnd -- opPrint is
    the closing bracket.   jitEmitters.jitPrintBegin  */
extern "C" Buffer *jitPrintBegin(GroupItem *input)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
Buffer 		*buffer = (Buffer*)ruler->bufferSTAK->pop();
	if ( !buffer )
		buffer = new Buffer("print buffer");
	ruler->isPRINTING = 0;
	return buffer;
}

/* The sink. opPrint ITSELF -- there is no jitPrintEnd, because inventing one
   would put a second sink beside the real one and the whole point of entering at
   the seam is that the chain below it stays single-sourced. */
extern "C" void jitPrintClose(GroupItem *input)
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	if (!b || !gJitPrintBuf) return;
	llvm::LLVMContext &ctx = b->getContext();
	llvm::Type *ptr = llvm::PointerType::getUnqual(ctx);
	llvm::Type *i64 = llvm::Type::getInt64Ty(ctx);
	llvm::Value *inAddr = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)input), ptr, "printStmtEnd");
	llvm::Value *callee = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)&opPrint), ptr, "printSinkFn");
	llvm::FunctionType *ty = llvm::FunctionType::get(ptr, {ptr, ptr}, false);
	b->CreateCall(ty, callee, {inAddr, gJitPrintBuf}, "printSink");
	/*  E1: NOTHING LEFT IN FLIGHT. The buffer belonged to this statement and the
	sink has consumed it; leaving it set would let a later print append into
	a buffer that has already been flushed.  */
	gJitPrintBuf = nullptr;
	gJitResult   = nullptr;
	gJitEmitted  = true;
	
}

/* One item. `value` is the SSA register the expression emitters just produced;
   when the item carries no expression it is a literal or a shortcut and the
   carried value is unused, so a zero immediate is passed and the token's own
   text does the work. */
/*******************************************************************************
    jitPrintItem -- one item of a jitted print, one of the three emitted calls.

    ⚠ IT CALLS THE VALUE ENTRY, NEVER THE POINTER ENTRY. A local's live value
    sits in a frame slot until the epilogue, so handing appendGroup a field
    pointer mid-function reads storage nothing has written yet.

    // printEffectFree  what a jitted print did before 2026-08-04, and why firing once at compile time is worse than not firing
    // printSeamAppendGroup  where the seam is and how it was read rather than assumed
    // valueNotPointer  why the value entry is forced, and the rejected spill-before-every-print alternative
    // shortcutImmediates  why shortcut tokens travel as immediates and nothing is baked at emit time
*******************************************************************************/
extern "C" void jitPrintItem(GroupItem *token, GroupItem *FormaT, int hasValue)
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	if (!b || !gJitPrintBuf) return;
	llvm::LLVMContext &ctx = b->getContext();
	llvm::Type *ptr = llvm::PointerType::getUnqual(ctx);
	llvm::Type *i32 = llvm::Type::getInt32Ty(ctx);
	llvm::Type *i64 = llvm::Type::getInt64Ty(ctx);
	
	llvm::Value *fmtAddr = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)FormaT), ptr, "printFmt");
	
	if (hasValue) {
	//  AN EXPRESSION ITEM: the emitters just left its SSA value in
	//  gJitResult -- which jitPrintArm cleared beforehand, so a null here
	//  means THIS item emitted nothing rather than that nobody ever did.
	//  ⚠ REFUSE, DO NOT SUBSTITUTE. Passing a constant here is how a print
	//  of an un-emittable expression came out as 0 and then, once real
	//  values were flowing, as 80329152 -- a stale read wearing the shape of
	//  data. The degrade counter is asserted at zero by every rung, so this
	//  turns an invisible wrong answer into a red.
	//  ⚠ A NODE RESULT PRINTS AS A NODE (SEQ 141, F-50). The value arm below
	//  can only carry an i32, so a field printed as whatever its slot held --
	//  starT's `4` -- or as nothing at all. When a node is in flight, hand it
	//  to jitPrintNodeRT, which delegates to appendGroup, the INTERPRETED
	//  walk's own call. One spelling; the roads cannot say different things.
	//  The flag is cleared here because this is the consumer.
	//  ⚠ A FIELD-RESIDENT TARGET PRINTS AS A NODE. Its value went through
	//  assignFieldCore into the FIELD, not into a jitSlot, so the scalar arm
	//  below would read a stale register -- starT's `4`. jitPrintNodeRT
	//  delegates to appendGroup, the interpreted walk's own call.
	//  ⚠ SCALAR PRINTS ARE UNTOUCHED: a target whose value went to its slot
	//  is not in this set, and takes the arm it always took.
	if (token && gJitFieldResident.count((void*)token->groupBody)) {
	llvm::Value *tAddr = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)token), ptr, "printFieldNode");
	llvm::Value *tfn = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)&jitPrintNodeRT), ptr, "printNodeFn2");
	gJitStmtCanRefuse = true;   // this statement emits a refusing run-time call
	llvm::FunctionType *tty = llvm::FunctionType::get(ptr, {ptr, ptr, ptr}, false);
	b->CreateCall(tty, tfn, {tAddr, fmtAddr, gJitPrintBuf}, "printFieldNodeCall");
	return; }
	if (gJitLastIsNode && gJitResultNode) {
	gJitLastIsNode = false;
	llvm::Value *pfn = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)&jitPrintNodeRT), ptr, "printNodeFn");
	gJitStmtCanRefuse = true;   // this statement emits a refusing run-time call
	llvm::FunctionType *pty = llvm::FunctionType::get(ptr, {ptr, ptr, ptr}, false);
	b->CreateCall(pty, pfn, {gJitResultNode, fmtAddr, gJitPrintBuf}, "printNode");
	return; }
	if (!gJitResult) {
	jitDegrade("print operand: expression emitted no value", token);
	return; }
	llvm::Value *val = gJitResult;
	llvm::Value *callee = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)&appendGroupValue), ptr, "printValFn");
	llvm::FunctionType *ty = llvm::FunctionType::get(ptr, {i32, ptr, ptr}, false);
	b->CreateCall(ty, callee, {val, fmtAddr, gJitPrintBuf}, "printVal"); }
	else {
	//  A LITERAL OR A SHORTCUT: it contributes ITSELF, so the node goes
	//  straight to appendGroup -- the same call the interpreted walk makes,
	//  with the same node. Nothing about shortcuts or literals is decided
	//  here; the chain's own switch reads the characters.
	llvm::Value *tokAddr = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)token), ptr, "printTok");
	llvm::Value *callee = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)&appendGroup), ptr, "printTokFn");
	llvm::FunctionType *ty = llvm::FunctionType::get(ptr, {ptr, ptr, ptr}, false);
	b->CreateCall(ty, callee, {tokAddr, fmtAddr, gJitPrintBuf}, "printTok"); }
	gJitEmitted = true;
	
}

/*******************************************************************************
    jitPrintList -- A MULTI-PART PRINT OPERAND, CLASSIFIED BY CONSTANCY. Tony's
    ruling via Clay, 2026-08-05.

    ⚠ A CONSTANT MAY TRAVEL AS A POINTER; A COMPUTED PART MAY NOT. A literal is
    immutable and baked, so it cannot catch the stale-frame disease the value
    entry exists to dodge.

    // constancySplit  the measured two-part example, and why the split needs no new evaluation machinery
    // priorNotNext  why the walk is prior() -- appendGroup's own order, because the list is built in reverse
*******************************************************************************/
extern "C" void jitPrintList(GroupItem *ExpressioN, GroupItem *FormaT)
{
	
	if (!gJitBuilder || !ExpressioN) return;
	GroupItem *part = 0;
	while ((part = ExpressioN->prior(part))) {
	GroupBody *pb = part->groupBody;
	if (pb->flags.isLiteral || isSTRING(pb->flags.data) || isTOKEN(pb->flags.data)) {
	//  CONSTANT: hand the chain the baked node. No evaluation, no value.
	jitPrintItem(part, FormaT, 0);
	continue; }
	//  ⚠ A PART MAY BE A COMPUTED SUB-EXPRESSION, not a bare read. `print
	//  ~`taG "has method":;` carries one constant part and one part that is
	//  itself a dot expression (isMethod). Handing that to the bare-read
	//  primitive is a category error -- it is a LIST, so the primitive
	//  correctly refused and the tag never printed. DISPATCH ITS METHOD,
	//  exactly as appendPrintXP's own `if isMethod` arm does one level up;
	//  the op gates emit and leave the value in gJitResult.
	if (isMethod(pb->flags.instructType)) {
	jitPrintArm();
	if (pb->gMethod)    pb->gMethod(part);
	//  ⚠ THE NODE IS TAKEN FIRST AND THE SCALAR IS NOT CONSULTED BY
	//  PRINT (Tony, SEQ 142). A subscript yields a FIELD; opDot
	//  publishes it on gJitResultNode and also unboxes a count, and the
	//  count is right for noPrinT and wrong for a field. This check used
	//  to sit BELOW the gJitResult degrade, so a method that emitted a
	//  node and no scalar degraded before it could be reached -- which
	//  is why pointerT's jitted rows printed empty.
	if (gJitResultNode) { jitPrintNode(FormaT); continue; }
	if (!gJitResult) {
	jitDegrade("print operand part: method emitted no value", part);
	continue; }
	//  ⚠ COMPUTED STRINGS ARE OUT OF PHASE SCOPE AND MUST DEGRADE, NOT
	//  PRINT A NUMBER. opDot unboxes its result as a COUNT, which is
	//  right for noPrinT/isMethoD and wrong for taG -- a string-valued
	//  accessor. Without this the tag printed as `6`: silently wrong,
	//  degrade 0, the exact class this project has paid for all week.
	//  The kind is read off the emit-time result, which is legitimate
	//  because datA is stable for the lifetime of jitted code that
	//  observed it (premise 1) -- a type, not a value.
	//  ⚠ HAND THE CHAIN THE NODE, NOT A NUMBER, AND DO NOT TYPE IT
	//  HERE. gJitResultNode carries the GroupItem the emitted op
	//  produced; appendGroup formats it by its REAL datA at run time,
	//  which is the only place that fact exists. The first cut tried to
	//  classify at emit time by reading tempField -- and could not,
	//  because opDot's gate returns before its interpreted body, so
	//  tempField is never populated and the accessor's own datA
	//  describes the accessor rather than its result. `taG` printed as
	//  `6` for exactly that reason.
	//  The pointer is safe here where it is not safe for a field: this
	//  node is FRESHLY COMPUTED by the emitted call, not a field whose
	//  live value sits in an unflushed frame slot.
	if (gJitResultNode) { jitPrintNode(FormaT); continue; }
	jitPrintItem(part, FormaT, 1);
	continue; }
	//  COMPUTED SCALAR: materialize it, then route through the value entry.
	jitPrintArm();
	if (jitEmitBareRead(part))  jitPrintItem(part, FormaT, 1);
	else jitDegrade("print operand part: not a constant and not a scalar read", part); }
	
}

/* jitPrintNode  APPEND THE NODE THE LAST EMITTED OP PRODUCED. The pointer entry
   of the print seam, used where the value's TYPE is a run-time fact the emitter
   cannot know -- a GroupField accessor being the case that forced it. Calls
   appendGroup directly, so formatting, shortcuts and datA dispatch all stay in
   the chain exactly as the interpreted walk leaves them. */
extern "C" void jitPrintNode(GroupItem *FormaT)
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	if (!b || !gJitPrintBuf || !gJitResultNode) return;
	llvm::LLVMContext &ctx = b->getContext();
	llvm::Type *ptr = llvm::PointerType::getUnqual(ctx);
	llvm::Type *i64 = llvm::Type::getInt64Ty(ctx);
	llvm::Value *fmtAddr = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)FormaT), ptr, "nodeFmt");
	llvm::Value *callee = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)&appendGroup), ptr, "nodeFn");
	llvm::FunctionType *ty = llvm::FunctionType::get(ptr, {ptr, ptr, ptr}, false);
	b->CreateCall(ty, callee, {gJitResultNode, fmtAddr, gJitPrintBuf}, "printNode");
	gJitResultNode = nullptr;
	gJitEmitted = true;
	
}

/*  delegates to appendGroup, the interpreted walk's OWN call. Do not re-implement
    value-versus-tag here.   jitEmitters.jitPrintNodeRT  */
extern "C" GroupItem *jitPrintNodeRT(GroupItem *node, GroupItem *FormaT, Buffer *buffer)
{
	
	if ( !node ) {
	/*  ROUTED 2026-09-05, and it is the ONLY one of the three gated sites
	that is a refusal: print is a CONSUMER of the null, and a consumer
	that cannot do its job with what it was handed is exactly what the
	ruling means. Reachable at RUN time from emitted code, which is why
	the epilogue clear landed first.
	jitEmitters.jitPrintNodeRT.storeRuling  */
	::refuse(0,"print: the item produced no node; nothing printed");
	return 0;
	}
	return ::appendGroup(node,FormaT,buffer);
	
}

extern "C" void jitPrintOpen(GroupItem *input)
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	if (!b) return;
	llvm::LLVMContext &ctx = b->getContext();
	llvm::Type *ptr = llvm::PointerType::getUnqual(ctx);
	llvm::Type *i64 = llvm::Type::getInt64Ty(ctx);
	llvm::Value *inAddr = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)input), ptr, "printStmt");
	llvm::Value *callee = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)&jitPrintBegin), ptr, "printBeginFn");
	llvm::FunctionType *ty = llvm::FunctionType::get(ptr, {ptr}, false);
	gJitPrintBuf = b->CreateCall(ty, callee, {inAddr}, "printBuf");
	gJitEmitted  = true;
	
}

/*******************************************************************************
    jitPrintProbe -- COMPILE-TIME DIAGNOSTIC for the jitted print walk. Off
    unless INCANT_PRINT_PROBE is set; it never appears in the IR.

    ⚠ NO LEFT-JUSTIFY FORMAT IN THIS printf. The first draft of this very
    function re-tripped that trap -- canary 238 to 235, hours after it was
    documented two functions up. Plain %s. Bear-trap #40.

    // compileTimeExempt  why compile-time logging does not breach the effect-free-emit law
    // probeQuestion  the two symptoms it was aimed at, and what each phase reports
*******************************************************************************/
extern "C" void jitPrintProbe(GroupItem *node, int phase)
{
	
	if (!::getenv("INCANT_PRINT_PROBE")) return;
	const char *tag  = (node && node->groupBody) ? node->groupBody->tag : "(null)";
	const char *txt  = node ? node->getText() : 0;
	const char *what = "part seen";
	if (phase == 1) what = "expr: about to emit";
	if (phase == 2) what = "expr: emitted";
	if (phase == 3) what = "token (no expression)";
	::fprintf(stderr,
	"  PRINTPROBE p%d [%s] tag=%s text=[%s] noPrint=%d shortcut=%d literal=%d gJitResult=%s\n",
	phase, what, tag ? tag : "(untagged)", txt ? txt : "",
	(node && node->groupBody->flags.noPrint) ? 1 : 0,
	(node && node->groupBody->flags.isShortcut) ? 1 : 0,
	(node && node->groupBody->flags.isLiteral) ? 1 : 0,
	gJitResult ? "SET" : "null");
	//  When the node carries a LIST, enumerate it. The per-item classification
	//  ruled for print (constant operand vs computed operand) has to happen at
	//  whatever granularity the parts actually live at, and a PrintXP item's
	//  ExpressioN can be a multi-part expression list -- so the granularity is a
	//  measurement, not an assumption.
	if (node && node->groupBody && node->groupBody->groupList) {
	GroupItem *kid = 0;
	int n = 0;
	while ((kid = node->next(kid))) {
	GroupBody *kb = kid->groupBody;
	const char *kt = kid->getText();
	::fprintf(stderr,
	"      part %d: tag=%s text=[%s] literal=%d shortcut=%d data=%d isMethod=%d\n",
	n++, kb->tag ? kb->tag : "(untagged)", kt ? kt : "",
	kb->flags.isLiteral ? 1 : 0, kb->flags.isShortcut ? 1 : 0,
	(int)kb->flags.data, isMethod(kb->flags.instructType) ? 1 : 0); } }
	::fflush(stderr);
	
}

/*******************************************************************************
    jitRefire -- FIRE THE LAST COMPILED FUNCTION AGAIN, without recompiling.
    Returns trueResult on a fire, null if nothing has been compiled yet -- LOUD,
    because a silent no-op would make a rung green for the wrong reason.

    // rightAnswerWrongUniverse  why a compile-fire-check POP proves nothing on its own, and what a second fire settles
*******************************************************************************/
extern "C" GroupItem *jitRefire(GroupItem *input)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	
	if (!gJitLastFn) {
	printf("=== jitRefire: NOTHING COMPILED YET (call testing() first) ===\n");
	fflush(stdout);
	return 0; }
	int r = gJitLastFn();
	printf("=== jitRefire result = %d ===\n", r); fflush(stdout);
	
	return ruler->trueResult;
}

/*  pairs with jitSaveFrameRT's unconditional push.   jitEmitters.jitSaveFrameRT  */
extern "C" void jitRestoreFrameRT(GroupItem *field)
{
	::restoreLocalFields(field);
	/*  Pop, and restore only a non-empty entry -- an argument-less jitted call
	pushed an empty one and has nothing to give back.   jitContext.gChan  */
	
	if ( gChanStkTop > 0 ) {
	gChanStkTop--;
	if ( gChanStkBody[gChanStkTop] ) {
	gChanStkBody[gChanStkTop]->gGroup     = gChanStkGroup[gChanStkTop];
	gChanStkBody[gChanStkTop]->flags.data = gChanStkData[gChanStkTop];
	}
	}
	
}

/*******************************************************************************
    jitRunAction -- THE GENERIC COMPILE DRIVER. It owns the engine, the
    LLVMContext and the Module; jitBuildFunction owns each function in them.

    ⚠ THE S1 SPLIT IS BEHAVIOUR-NEUTRAL, so its POP is "every baseline
    byte-identical" and ANYTHING THAT MOVES IS A DEFECT, not an improvement.

    // behaviourNeutralSplit  what it owns either side of jitBuildFunction, and why nothing here may change order
*******************************************************************************/
extern "C" int jitRunAction(GroupItem *action)
{
	
	printf("=== jitRunAction: entering on %s ===\n", action->groupBody->tag);
	fflush(stdout);
	/*  ⚠ CLEARED ON ENTRY, WRITTEN AT THE FOOT, and the gap is the point: a
	refused compile leaves NO record rather than the previous one's.
	setText("") and not clear() -- a dataless field reads back as "JiT".  */
	// stalenessPrecluded  why staleness is precluded by lifecycle rather than detected
	if (action) {
	GroupItem *stale = action->get("JiT");
	if (stale)  stale->setText(::strdup("")); }
	jitInitOnce();
	llvm::orc::LLJIT *jit = (llvm::orc::LLJIT*)jitEngine();
	if (!jit) { printf("=== JIT engine null ===\n"); fflush(stdout); return -1; }
	
	auto ctx = std::make_unique<llvm::LLVMContext>();
	auto mod = std::make_unique<llvm::Module>("jitMod", *ctx);
	gJitCtx    = ctx.get();
	gJitModule = mod.get();
	
	// ============ THE BUILD LOOP (S3, build-on-discovery with restart) ========
	//  ⚠ WHY A LOOP AND NOT A PRE-PASS. The correct predicate -- "an inlined
	//  callee is calling itself" -- is only answerable AT the inner self-call,
	//  by which time the enclosing function is half-built. There is no earlier
	//  moment to consult, so the earlier moment is MANUFACTURED: walk, discover,
	//  throw the partial away, build what was discovered, walk again. The second
	//  walk's outer call sites find the callee IN THE MAP and emit a real call.
	//  A static pre-pass was rejected (Tony, 2026-08-05) because it invents a
	//  second traversal inside a system whose entire model is emit-on-walk.
	//
	//  ⚠ SEQUENTIAL, NOT NESTED, AND THAT IS CHECKABLE FROM OUTSIDE: every
	//  jitBuildFunction call below returns before the next begins, so the sixteen
	//  globals are never re-entered and need no save/restore. gJitCompileCount is
	//  NOT touched in here -- it stays one-per-compile below -- which is why the
	//  ladder's JA/JI "compile count = 1" rungs remain the discriminator between
	//  a sequenced implementation and a nested one.
	gJitFnMap.clear();
	gJitNeedOwnFn.clear();
	int  restarts = 0;
	int  built    = 0;
	for (;;) {
	//  R2's BOUND, CHECKED BEFORE THE WORK RATHER THAN AFTER. Each restart
	//  is caused by at least one NOVEL callee entering gJitNeedOwnFn, which
	//  never shrinks -- so restarts can never exceed its size. A violation
	//  means the monotone growth argument is false, and it is reported as a
	//  RED (-7) rather than allowed to spin: a hang is not a wrong answer,
	//  it is the absence of a run, and nobody parked that (rule H5).
	if (restarts > (int)gJitNeedOwnFn.size()) {
	fprintf(stderr,
	"=== jitRunAction: RESTART BOUND BROKEN -- %d restarts, %zu pending ===\n",
	restarts, gJitNeedOwnFn.size());
	fflush(stderr);
	gJitCtx = nullptr; gJitModule = nullptr;
	gJitBuilder = nullptr; gJitResult = nullptr;
	return -7; }
	
	//  1. BUILD EVERY DISCOVERED CALLEE THAT HAS NO FUNCTION YET, each one
	//     start to finish. A callee build can itself discover a further
	//     novel callee (its own inlined callee self-calling), so it gets the
	//     same discard-and-restart treatment as the driver.
	bool restarted = false;
	for (size_t i = 0; i < gJitNeedOwnFn.size(); i++) {
	GroupBody *pb = gJitNeedOwnFn[i].body;
	GroupItem *pa = gJitNeedOwnFn[i].action;
	if (jitFnMapFind(pb)) continue;
	gJitRestartNeeded = false;
	int cr = jitBuildFunction(pa);
	if (gJitRestartNeeded) { jitDiscardPartial(); restarted = true; break; }
	if (cr < 0) {
	gJitCtx = nullptr; gJitModule = nullptr;
	gJitBuilder = nullptr; gJitResult = nullptr;
	return cr; }
	JitFnSlot s; s.body = pb; s.action = pa; s.fn = gJitBuiltFn;
	gJitFnMap.push_back(s);
	printf("=== jitRunAction: callee %s built as %s ===\n",
	pb->tag, gJitBuiltName.c_str());
	fflush(stdout); }
	if (restarted) { restarts++; continue; }
	
	//  2. THE DRIVER, ALWAYS LAST, so its name is the one gJitBuiltName
	//     carries out of the loop and S4's lookup uses.
	gJitRestartNeeded = false;
	built = jitBuildFunction(action);
	if (gJitRestartNeeded) { jitDiscardPartial(); restarts++; continue; }
	break; }
	if (restarts)
	printf("=== jitRunAction: %d restart(s), %zu callee function(s) ===\n",
	restarts, gJitFnMap.size()), fflush(stdout);
	// ========================= end the build loop =============================
	if (built < 0) {
	gJitCtx = nullptr; gJitModule = nullptr;
	gJitBuilder = nullptr; gJitResult = nullptr;
	return built; }
	//  ⚠ THE DRIVER'S NAME IS TAKEN BY COPY, HERE, AND NOT READ BACK LATER.
	//  gJitBuiltName is overwritten by the NEXT jitBuildFunction call, and from
	//  S3 there ARE more. Copying at the moment of truth is what makes the
	//  lookup below "the driver" rather than "whatever was built last".
	//
	//  ⚠⚠ S4 -- ENTRY BY NAME, AND THE POINT IS THAT IT IS NO LONGER THE SAME
	//  THING AS ENTRY BY POSITION. Before S3 the module held exactly one
	//  function, so "look up the last one built" and "look up the driver" were
	//  the same string and nothing could tell a right answer from a lucky one.
	//  That is the identical shape as rung JC being green because its driver
	//  happens to be one statement long -- correct-by-accident-of-topology --
	//  and the cure is the same: make the mechanism name what it means.
	//  The loop above builds the driver LAST precisely so this copy is its name;
	//  if that order ever changes, this line must change with it and not merely
	//  keep working.
	std::string     driverName = gJitBuiltName;
	if (driverName.empty()) {
	//  H4: assert the quantity, do not assume it. An empty name would make
	//  the lookup below fail with -4 and read as an engine problem.
	fprintf(stderr, "=== jitRunAction: NO DRIVER NAME RECORDED ===\n");
	fflush(stderr);
	gJitCtx = nullptr; gJitModule = nullptr;
	gJitBuilder = nullptr; gJitResult = nullptr;
	return -8; }
	const char     *fnName = driverName.c_str();
	
	// ------------------------------------------------------------------
	// THE MODULE DUMP. The other half of the instrument, and the half that
	// actually produces bones. The verifier above answers "is this IR
	// well-formed"; it does NOT answer "is this IR the program I meant".
	// Measured 2026-07-30: the verifier is SILENT on jitGifScratch and
	// jitIfScratch, both exit 0 -- because a branch with a missing else arm
	// is perfectly VALID IR that computes the wrong thing. Validity and
	// correctness are different questions and only the dump reaches the
	// second one.
	//
	// docs/jit.md S0 argues textual IR gives the JIT "a census, which it has
	// never had". This is that census: until now there was no way to see the
	// emitted IR at all, so every claim about what the emitters produce was
	// read off the emitter source rather than off its output.
	//
	// OFF BY DEFAULT, and gated on an ENVIRONMENT VARIABLE rather than a
	// GroupBody flag ON PURPOSE -- a new flag would shift the bitfield and
	// drag in bear-trap #10's whole apparatus (groups.ext sync + tokall) for
	// a debug switch. An env var costs nothing, touches no layout, and cannot
	// move a baseline. Dumped AFTER mem2reg so what is printed is what runs.
	//     INCANT_JIT_DUMP=1 <binary> incant/<fixture> 2>&1
	if (::getenv("INCANT_JIT_DUMP")) {
	llvm::errs() << "=== IR " << fnName << " (post-mem2reg) ===\n";
	mod->print(llvm::errs(), nullptr);
	llvm::errs() << "=== end IR " << fnName << " ===\n";
	llvm::errs().flush(); }
	
	// CAPTURE THE IR AS TEXT, and this line CANNOT move below addIRModule --
	// that call std::move()s both the module and the context into the JIT, so
	// after it there is nothing left to print. Post-mem2reg on purpose: the
	// record should be what RUNS, not what the emitter first wrote (=2 is the
	// dump for the emitter's own output, and it is a different question).
	// THE `JiT` RECORD IS HUNG HERE, and here is the ONLY place it is hung.
	//
	// PJ-2, one path two effects: jitRunAction is the ONLY function in the tree
	// that compiles, so making the record a second effect of THIS function means
	// every compile records, by construction, whoever drove it. It used to be
	// hung by jitFieldMethod instead -- which compiles by CALLING this function,
	// so the record existed only on the fallback-column route and every rung
	// that reaches jitRunAction directly (testing(), the whole jit ladder) left
	// no record at all. Two callers, one of which recorded, is exactly the
	// writer/installer split PJ-2 forbids: the record could lie by omission.
	//
	// strdup'd, not aliased: gJitLastIR is overwritten by the next compile of
	// ANY action, so handing the node a pointer into it would make every
	// action's record silently become the last one compiled.
	{
	std::string             irText;
	llvm::raw_string_ostream irOut(irText);
	mod->print(irOut, nullptr);
	irOut.flush();
	gJitLastIR = irText;
	
	if (action) {
	GroupItem *jt = action->get("JiT");
	if (!jt) {
	jt = new GroupItem("JiT");
	jt->groupBody->flags.noPrint = 1;
	jt->setText(::strdup(gJitLastIR.c_str()));
	action->addAttribute(jt); }
	else    jt->setText(::strdup(gJitLastIR.c_str()));
	
	/*  THE POP HOOK, twin of genParse's INCANT_PARSE_RECORD and
	env-gated for the same measured reason: an unconditional marker
	on stderr is what broke three POP targets on 2026-08-02. Unset,
	this writes nothing and no baseline can move.
	
	Reads jt->getText(), NOT gJitLastIR -- the point is to prove
	what LANDED ON THE NODE. Dumping the global would pass even if
	addAttribute had silently done nothing, which is the whole
	failure this hook exists to detect.  */
	if (char *jp = ::getenv("INCANT_JIT_RECORD")) {
	if (FILE *f = ::fopen(jp,"w")) {
	char *got = jt->getText();
	if (got)    ::fwrite(got,1,::strlen(got),f);
	::fclose(f); }
	else ::fprintf(stderr,"jitRunAction: JiT record could not open %s\n",jp); } }
	}
	//  ONE COMPILE HAPPENED. Counted here rather than at entry so a run that
	//  refuses (-1..-5) does not inflate the count -- the POP asserts exactly
	//  one compile across two fires, and a refusal is not a compile.
	gJitCompileCount++;
	
	if (auto err = jit->addIRModule(
	llvm::orc::ThreadSafeModule(std::move(mod), std::move(ctx)))) {
	llvm::consumeError(std::move(err));
	gJitCtx = nullptr; gJitModule = nullptr;
	printf("=== JIT addIRModule failed ===\n"); fflush(stdout); return -3; }
	//  BOTH ARE DEAD THE INSTANT THE MOVE ABOVE COMPLETES -- the JIT owns them
	//  now. Nulling is not tidiness: a stale gJitModule is a pointer into a
	//  freed module, and jitBuildFunction's own no-context guard would happily
	//  wave it through.
	//  ⚠ AND SO IS EVERY Function* IN THE CALLEE MAP, for the same reason: a
	//  function belongs to its module. A surviving entry is a pointer into dead
	//  IR wearing the shape of a cache hit, and the map IS the predicate -- a
	//  false hit there would emit a call to a function that no longer exists.
	gJitCtx = nullptr; gJitModule = nullptr;
	gJitFnMap.clear();
	gJitNeedOwnFn.clear();
	gJitBuiltFn = nullptr;
	auto sym = jit->lookup(fnName);
	if (!sym) { llvm::consumeError(sym.takeError());
	printf("=== JIT lookup failed ===\n"); fflush(stdout); return -4; }
	int (*fp)() = sym->toPtr<int(*)()>();
	gJitLastFn = fp;          // keep it: the ladder fires it again, uncompiled
	int r = fp();
	printf("=== jitRunAction result = %d ===\n", r); fflush(stdout);
	//  Reported UNCONDITIONALLY and with its value, so a rung can assert it.
	//  A presence-with-value line cannot pass by being deleted, which an
	//  absence check on the degrade message could.
	printf("=== jitDegrade count = %d ===\n", gJitDegradeCount); fflush(stdout);
	//  Same H4 discipline as the degrade line above, and the POP's central
	//  quantity: compile-on-first-fire means the SECOND fire must not move this.
	printf("=== jitCompile count = %d ===\n", gJitCompileCount); fflush(stdout);
	//  Step 2's discriminator. Same H4 discipline, and it is the ONLY quantity
	//  that separates a migrated op from an unmigrated one -- the values and the
	//  IR are identical by design, so nothing else can.
	printf("=== jitSlot count = %d ===\n", gJitSlotCount); fflush(stdout);
	//  The unary-edge guard, reported the same way and for the same reason: a
	//  refusal that is only visible on stderr is a refusal a rung cannot assert.
	//  Expected ZERO until the unary specimen lands; non-zero means an op was
	//  given a slot it is not yet certified to use.
	printf("=== jitSlotUnaryRefused = %d ===\n", gJitSlotUnaryRefused); fflush(stdout);
	gJitBuilder = nullptr;   // don't leave it dangling at this run's destroyed stack B
	gJitResult  = nullptr;
	return r;
	
}

/* Pipeline proof: hand-build the IR for an addTwo-shaped function
   ( i32 f(){ return 3 + 5; } ), JIT-compile it via the engine, call it, and
   return the result. Proves emit -> ORCv2 compile -> lookup -> native call.
   The generic body-walk + tok-native emitters replace the hand-built IR next. */
extern "C" int jitRunAddTwo()
{
	
	printf("=== jitRunAddTwo: entering ===\n"); fflush(stdout);
	jitInitOnce();
	llvm::orc::LLJIT *jit = (llvm::orc::LLJIT*)jitEngine();
	if (!jit) { printf("=== JIT engine null ===\n"); fflush(stdout); return -1; }
	
	auto ctx = std::make_unique<llvm::LLVMContext>();
	auto mod = std::make_unique<llvm::Module>("addTwoMod", *ctx);
	llvm::IRBuilder<> B(*ctx);
	
	llvm::Type *i32 = llvm::Type::getInt32Ty(*ctx);
	llvm::Function *fn = llvm::Function::Create(
	llvm::FunctionType::get(i32, false),
	llvm::Function::ExternalLinkage, "addTwo", mod.get());
	B.SetInsertPoint(llvm::BasicBlock::Create(*ctx, "entry", fn));
	
	// Hand-built add: a low-level ORC smoke test, independent of the gate and
	// the opMethod emitters. Proves emit -> compile -> lookup -> call in isolation.
	B.CreateRet(B.CreateAdd(
	llvm::ConstantInt::get(i32, 3), llvm::ConstantInt::get(i32, 5), "add"));
	
	if (auto err = jit->addIRModule(
	llvm::orc::ThreadSafeModule(std::move(mod), std::move(ctx)))) {
	llvm::consumeError(std::move(err));
	printf("=== JIT addIRModule failed ===\n");
	return -2;
	}
	auto sym = jit->lookup("addTwo");
	if (!sym) { llvm::consumeError(sym.takeError());
	printf("=== JIT lookup failed ===\n"); return -3; }
	int (*fp)() = sym->toPtr<int(*)()>();
	int r = fp();
	printf("=== JIT addTwo result = %d ===\n", r); fflush(stdout);
	return r;
	
}

/*******************************************************************************
    jitRunIfTest -- CONTROL-FLOW SMOKE TEST, and the first multi-basic-block IR
    in the JIT layer. Field assumed a count (i32 gCount); drive with
    testing(<count field>).

    // smokeBranchIR  what it hand-builds, and why a hand-built icmp makes it independent of the walk driver
*******************************************************************************/
extern "C" int jitRunIfTest(GroupItem *fld)
{
	
	printf("=== jitRunIfTest on %s ===\n", fld->groupBody->tag); fflush(stdout);
	jitInitOnce();
	llvm::orc::LLJIT *jit = (llvm::orc::LLJIT*)jitEngine();
	if (!jit) { printf("=== JIT engine null ===\n"); fflush(stdout); return -1; }
	
	auto ctx = std::make_unique<llvm::LLVMContext>();
	auto mod = std::make_unique<llvm::Module>("ifMod", *ctx);
	llvm::IRBuilder<> B(*ctx);
	llvm::Type *i32 = llvm::Type::getInt32Ty(*ctx);
	llvm::Type *i64 = llvm::Type::getInt64Ty(*ctx);
	
	static int ifSeq = 0;
	char fnName[32];
	snprintf(fnName, sizeof(fnName), "ifFn%d", ifSeq++);
	llvm::Function *fn = llvm::Function::Create(
	llvm::FunctionType::get(i32, false),
	llvm::Function::ExternalLinkage, fnName, mod.get());
	B.SetInsertPoint(llvm::BasicBlock::Create(*ctx, "entry", fn));
	
	// Bake the field's gCount storage address as a stable pointer (jitSeedField
	// pattern); load it, compare < 0 to drive the branch.
	void *addr = &(fld->groupBody->gCount);
	llvm::Value *slot = B.CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)addr),
	llvm::PointerType::getUnqual(*ctx));
	llvm::Value *v = B.CreateLoad(i32, slot, "load");
	llvm::Value *cond = B.CreateICmpSLT(v, llvm::ConstantInt::get(i32, 0), "cond");
	
	// Three-block topology: entry -> (then | end). The then block stores 99 to
	// the field slot and falls through to end; end reloads and returns.
	llvm::BasicBlock *thenBB = llvm::BasicBlock::Create(*ctx, "then", fn);
	llvm::BasicBlock *endBB  = llvm::BasicBlock::Create(*ctx, "endif", fn);
	B.CreateCondBr(cond, thenBB, endBB);
	
	B.SetInsertPoint(thenBB);
	B.CreateStore(llvm::ConstantInt::get(i32, 99), slot);
	B.CreateBr(endBB);
	
	B.SetInsertPoint(endBB);
	llvm::Value *out = B.CreateLoad(i32, slot, "out");
	B.CreateRet(out);
	
	if (auto err = jit->addIRModule(
	llvm::orc::ThreadSafeModule(std::move(mod), std::move(ctx)))) {
	llvm::consumeError(std::move(err));
	printf("=== jitRunIfTest addIRModule failed ===\n"); fflush(stdout); return -2; }
	auto sym = jit->lookup(fnName);
	if (!sym) { llvm::consumeError(sym.takeError());
	printf("=== jitRunIfTest lookup failed ===\n"); fflush(stdout); return -3; }
	int (*fp)() = sym->toPtr<int(*)()>();
	int r = fp();
	printf("=== jitRunIfTest result = %d ===\n", r); fflush(stdout);
	return r;
	
}

/*  UNGATED on both roads since 2026-08-10 -- `field.recursive` was the defect, not
    the guard, and ungating both keeps them from drifting.  jitEmitters.jitSaveFrameRT  */
extern "C" void jitSaveFrameRT(GroupItem *field)
{
	/*  Push the channel bracket's pending entry -- or an EMPTY one -- so the push
	is unconditional and pairs with jitRestoreFrameRT's pop.   jitContext.gChan  */
	
	if ( gChanStkTop < GCHAN_DEPTH ) {
	gChanStkBody[gChanStkTop]  = gChanPendBody;
	gChanStkGroup[gChanStkTop] = gChanPendGroup;
	gChanStkData[gChanStkTop]  = gChanPendData;
	gChanStkTop++;
	}
	gChanPendBody = 0; gChanPendGroup = 0; gChanPendData = 0;
	
	::saveLocalFields(field);
}

/*******************************************************************************
    jitScBegin -- opens the short-circuit diamond. Leaves insertion in scRhs so
    the right-arm walk emits there.

    ⚠ THE MERGE ALLOCA GOES IN THE ENTRY BLOCK, NOT HERE. A conditionally
    entered alloca is not promotable and mem2reg leaves it as memory.

    // allocaInEntryBlock  why entry placement is what makes "mem2reg inserts the phi itself" true rather than hoped for
*******************************************************************************/
extern "C" void jitScBegin(int isAND)
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	llvm::LLVMContext &ctx = b->getContext();
	llvm::Type *i32 = llvm::Type::getInt32Ty(ctx);
	llvm::Function *fn = b->GetInsertBlock()->getParent();
	
	llvm::IRBuilder<> entryB(&fn->getEntryBlock(),
	fn->getEntryBlock().getFirstInsertionPt());
	llvm::Value *slot = entryB.CreateAlloca(i32, nullptr, "scSlot");
	b->CreateStore(llvm::ConstantInt::get(i32, isAND ? 0 : 1), slot);
	
	llvm::Value *lv = gJitResult;
	if (!lv->getType()->isIntegerTy(1))
	lv = b->CreateICmpNE(lv,
	llvm::ConstantInt::get(lv->getType(), 0), "scLeft");
	
	llvm::BasicBlock *rhsBB = llvm::BasicBlock::Create(ctx, "scRhs", fn);
	llvm::BasicBlock *endBB = llvm::BasicBlock::Create(ctx, "scEnd", fn);
	if (isAND)  b->CreateCondBr(lv, rhsBB, endBB);
	else        b->CreateCondBr(lv, endBB, rhsBB);
	b->SetInsertPoint(rhsBB);
	
	gScSlots.push_back(slot);
	gScEndBlocks.push_back(endBB);
	gJitResult = nullptr;
	
}

/*******************************************************************************
    jitScEnd -- closes the diamond: store the RIGHT arm's truth, branch to the
    merge, leave the loaded result in flight as the conjunction's value.

    ⚠ A RIGHT ARM THAT EMITTED NOTHING IS A REFUSAL, NOT A ZERO. Storing a
    constant substitutes an answer the emitter does not have.

    // refusalNotZero  why the slot keeps its pre-stored answer and degrades instead
*******************************************************************************/
extern "C" void jitScEnd(GroupItem *resultNode)
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	llvm::LLVMContext &ctx = b->getContext();
	llvm::Type *i32 = llvm::Type::getInt32Ty(ctx);
	llvm::Value *slot = gScSlots.back();
	llvm::BasicBlock *endBB = gScEndBlocks.back();
	gScSlots.pop_back();
	gScEndBlocks.pop_back();
	
	if (gJitResult) {
	llvm::Value *rv = gJitResult;
	if (!rv->getType()->isIntegerTy(1))
	rv = b->CreateICmpNE(rv,
	llvm::ConstantInt::get(rv->getType(), 0), "scRight");
	b->CreateStore(b->CreateZExt(rv, i32, "scRv"), slot);
	}
	b->CreateBr(endBB);
	b->SetInsertPoint(endBB);
	llvm::Value *out = b->CreateLoad(i32, slot, "scOut");
	
	/*  ⚠ SEED THE NODE, DO NOT ONLY LEAVE THE VALUE IN FLIGHT. This is
	section 3 part 2's "value rides the OPERAND'S jitValue channel, not
	gJitResult", and skipping it is measurable rather than theoretical:
	with the diamond emitting correctly and the arms ticking correctly,
	`x2Out = x2L AND x2R` still returned 0 on every fire, because the
	enclosing opAssign reads its argument's jitData and found none.
	The topology was right and the value had nowhere to go.
	jitEmitRem's tail is the shape being copied.  */
	if (resultNode) {
	if (!resultNode->jitData) resultNode->jitData = new JitData();
	resultNode->jitData->setJitter(out);
	gJitSeeded.push_back(resultNode);
	}
	gJitResult = out;
	gJitEmitted = true;
	
}

/*******************************************************************************
    jitSeedField -- unbox a real count/number field operand, past constant
    folding: bake the stable GroupItem address, load gCount/gNumber, and stash
    the address into jitData->jitSlot so an assign has a destination.

    // bakedAddressIsSound  why baking the address is sound, and why a literal correctly gets no slot
*******************************************************************************/
extern "C" GroupItem *jitSeedField(GroupItem *token)
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	llvm::LLVMContext &ctx = b->getContext();
	JitData *d = new JitData();
	// ---- FRAME FIRST (Increment 1). If this field's STORAGE is in the current
	// frame, its operand is the alloca, not a baked address. Keyed on the home
	// address because node identity does not survive to here: each occurrence of
	// a local in the body is its own GroupItem (measured), so `token` is never
	// the node the prologue walked. Globals fall through and bake, unchanged.
	{
	GroupBody *tb = token->groupBody;
	void *home = isNUMBER(tb->flags.data) ? (void*)&(tb->gNumber) : (void*)&(tb->gCount);
	JitFrameSlot *f = jitFrameFind(home);
	if (f) {
	d->jitSlot = f->slot;
	d->jitType = f->ty;
	d->setJitter(b->CreateLoad(f->ty, f->slot, "frame"));
	token->jitData = d;
	gJitSeeded.push_back(token);
	return token;
	}
	}
	if (isNUMBER(token->groupBody->flags.data)) {
	void *addr = &(token->groupBody->gNumber);
	llvm::Value *p = b->CreateIntToPtr(
	llvm::ConstantInt::get(llvm::Type::getInt64Ty(ctx), (uint64_t)addr),
	llvm::PointerType::getUnqual(ctx));
	d->setJitter(b->CreateLoad(llvm::Type::getDoubleTy(ctx), p, "unbox"));
	d->jitSlot = p;   // stash field-storage address as the store-back slot
	} else {
	void *addr = &(token->groupBody->gCount);
	llvm::Value *p = b->CreateIntToPtr(
	llvm::ConstantInt::get(llvm::Type::getInt64Ty(ctx), (uint64_t)addr),
	llvm::PointerType::getUnqual(ctx));
	d->setJitter(b->CreateLoad(llvm::Type::getInt32Ty(ctx), p, "unbox"));
	d->jitSlot = p;   // stash field-storage address as the store-back slot
	}
	token->jitData = d;
	gJitSeeded.push_back(token);
	return token;
	
}

/* jitSeedLiteral  give a literal operand node a JitData carrying a ConstantInt of
   its count value, so opPlus's jitting branch has an SSA operand to read. Phase 1
   = i32 counts; number/string literals widen the type switch here later. */
extern "C" GroupItem *jitSeedLiteral(GroupItem *token)
{
	
	llvm::LLVMContext &ctx = gJitBuilder->getContext();
	JitData *d = new JitData();
	if (isNUMBER(token->groupBody->flags.data))
	d->setJitter(llvm::ConstantFP::get(
	llvm::Type::getDoubleTy(ctx), token->getNumber()));
	else
	d->setJitter(llvm::ConstantInt::get(
	llvm::Type::getInt32Ty(ctx), (long)token->getCount(), false));
	token->jitData = d;
	gJitSeeded.push_back(token);
	return token;
	
}

/*******************************************************************************
    jitShowRecord -- READ-ONLY. Print what is CORESIDENT on a field's canonical
    node: every attribute by name, with its size, INCLUDING the noPrint ones.

    ⚠ NO printf LEFT-JUSTIFY FORMAT INSIDE THE PASSTHROUGH BELOW -- percent,
    hyphen, width, s. It breaks the tok pass and surfaces three files away as
    `use of undeclared identifier` in genParse.rtn. Bear-trap #40.

    // fidelityGap  why this exists as a probe rather than a print family, and the ruling that makes it temporary
    // percentHyphenTrap  the four reproductions, the negative control, and Tony's mechanism for it
*******************************************************************************/
extern "C" GroupItem *jitShowRecord(GroupItem *field)
{
	
	GroupRules *ruler   = GroupControl::groupController->groupRules;
	GroupItem  *definer = field->definingRule();
	GroupItem  *att     = 0;
	int         kount   = 0;
	
	printf("=== RECORD for %s ===\n", definer->groupBody->tag);
	while ((att = definer->nextAttribute(att))) {
	char *t = att->groupBody->tag;
	char *x = att->getText();
	/*  PLAIN %s HERE, AND NO LEFT-JUSTIFY FORMAT -- see this function's
	header for the measurement. Do not write the percent-then-hyphen
	sequence anywhere inside this passthrough, INCLUDING IN A COMMENT
	LIKE THIS ONE, which is why this note spells it out in words.  */
	printf("  %s  noPrint=%d  %zu bytes\n",
	t ? t : "(untagged)",
	att->groupBody->flags.noPrint ? 1 : 0,
	x ? ::strlen(x) : (size_t)0);
	kount++; }
	printf("=== RECORD %s: %d attributes ===\n", definer->groupBody->tag, kount);
	fflush(stdout);
	return ruler->trueResult;
	
}

/*******************************************************************************
    jitStoreResult -- COMMIT THE VALUE JUST EMITTED into the result slot. Tony's
    ruling 2026-07-31: the compiled action returns what the interpreted action
    returns, so every statement stores here and the cap loads.

    ⚠ A NULL gJitResult IS A NO-OP, NOT AN ERROR. A statement that emitted
    nothing simply does not move the result, which is the interpreted
    behaviour.

    // mergeIsTheMemory  why the store is the merge on a two-armed if, and why no phi is written
*******************************************************************************/
extern "C" void jitStoreResult()
{
	
	if (!gJitResultSlot || !gJitResult) return;
	llvm::IRBuilder<> *b = gJitBuilder;
	llvm::Type *i32 = llvm::Type::getInt32Ty(b->getContext());
	llvm::Value *v = gJitResult;
	if (v->getType()->isDoubleTy())            v = b->CreateFPToSI(v, i32, "res");
	else if (v->getType()->isIntegerTy(1))     v = b->CreateZExt(v, i32, "res");
	else if (v->getType() != i32)              return;
	b->CreateStore(v, gJitResultSlot);
	gJitEmitted = true;
	
}

/* jitTrace  the incant-facing command. THE GATE IS THE POINT: under jitting it
   EMITS a call; interpreted it traces directly. Same shape as every opMethod's
   gate, and the reason it is the print that survives jitting --

   ⚠ opPrint is UNGATED, so a `print` inside a jitted body fires at EMIT time
   (jit.md S2.2, measured). Print-debugging a jitted action therefore reports
   COMPILE-TIME state ONCE instead of run-time state PER FIRE: it appears to
   work and it lies. jitTrace reports per fire because the call is emitted into
   the function rather than executed during compilation. */
extern "C" GroupItem *jitTrace(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	if ( ruler->jitting )
		{
		 jitEmitTrace(field); 
		return field;
		}
	 jitTraceRT(field); 
	return field;
}

/* jitTraceRT  THE RUNTIME HALF OF jitTrace -- the print that survives jitting.
   Plain C++, stable address, one field in. Called from EMITTED CODE at RUN time,
   once per fire, so it reports the value the compiled function is actually
   working with.

   fprintf(stderr) and not print: bear-trap #14 -- stdout is block-buffered and a
   run ending via stop() loses it, so a trace would vanish exactly when a crash
   made it most valuable. */
extern "C" GroupItem *jitTraceRT(GroupItem *field)
{
	
	::fprintf(stderr, "=== JIT TRACE: %s = %d ===\n",
	field ? field->groupBody->tag : "(null)",
	field ? field->groupBody->gCount : 0);
	::fflush(stderr);
	return field;
	
}

/*******************************************************************************
    jitUnboxCount -- THE RETURN-VALUE UNBOX. An emitted call hands back a
    GroupItem*; this turns it into the i32 emitted code works in.

    ⚠ A CALL, NOT GEP ARITHMETIC, ON PRINCIPLE. Any future GEP-for-speed
    proposal argues against this in writing.

    // callNotGep  what baked offsets would cost in emitted code, where no compiler catches them
*******************************************************************************/
extern "C" int jitUnboxCount(GroupItem *node)
{
	
	return node ? node->groupBody->gCount : 0;
	
}

/*******************************************************************************
    ⚠ THE DOOR CLEARS gMethod / isMethod / immediateACTION. "The method slot
    stays empty" needs an ACTIVE CLEAR, not merely not binding -- Braced
    arrives with gMethod already set, and left alone fireLabelMethod fires it
    AND actK fires it. This clear is what starves the C++ arm.

    // kantDoorDuties  kantDoor's three duties, lifted out of aCTionDefinE so the hunk there is three lines and the revert is one: mint kp<Tag>, hang the CodE on it, set rStuff.parseMethod = parseViaKant
    // kantDoorGuards  two measured hazards the skeleton does not cover -- where the isCoded test must sit, and why scoping is a real conditional
*******************************************************************************/
extern "C" int kantDoor(GroupItem *rule, GroupItem *code)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*kantReg = 0;
GroupItem 	*mint = 0;
GroupItem 	*grup = 0;
char 		*mintName = 0;
int 		want = 0;
int 		live = 0;
	if ( !code )
		{
		::fprintf(stderr,"kantDoor: %s has no CodE -- nothing to hang\n",rule->groupBody->tag);
		return 0;
		}
	/*  BOUNDS FIRST, so a stale body never reaches the slot. Scan is plain C
	over the body text: find every "K(" and read the integer after it,
	which covers litK(n) and parseRK(n) with one pass and no table.  */
	live = ::countRuleTerms(rule);
	want = 0;
	
	{
	char *scan = code->getText();
	while ( scan && *scan )
	{
	if ( scan[0] == 'K' && scan[1] == '(' )
	{
	int n = ::atoi(scan + 2);
	if ( n > want )  want = n;
	}
	scan++;
	}
	}
	
	if ( want > live )
		{
		::fprintf(stderr,"kantDoor: REFUSING %s -- body names term %s but the rule has %s\n",rule->groupBody->tag,::toStringFromInt(want),::toStringFromInt(live));
		return 0;
		}
	if ( !want )
		::fprintf(stderr,"kantDoor: WARNING %s body names no term positions\n",rule->groupBody->tag);
	/*  THE MINT. Its own registry, in the search list, so locate() finds it
	the way parseViaKant already looks for it -- and so the kant parse
	methods are a countable population rather than scattered. NOT Grokking:
	setRuleStuff turns anything whose registry isRule into a rule, and the
	mint must not be one.  */
	kantReg = GroupControl::groupController->getRegistry("KantParse");
	if ( !ruler->searchList->get("KantParse") )
		ruler->searchList->addMember(kantReg);
	mintName = ::concat(2,"kp",rule->groupBody->tag);
	/*  The groupList guard is not decoration: on the FIRST kant doored rule
	the registry has just been created and indexing an empty one prints
	`nextGroup: ERROR ... does not contain a list`. See kantDoored below.  */
	if ( kantReg->groupBody->groupList )
		mint = kantReg->get(mintName);
	if ( !mint )
		mint = kantReg->addMember(new GroupItem(mintName));
	/*  Hang the CodE, and give the mint the two hidden locals every coded body
	is built with -- aCTionDefinE adds them to the definee, and the mint is
	the definee now.  */
	mint->addAttribute(code);
	grup = mint->addString("this");
	grup->groupBody->flags.isLocal = 1;
	grup->groupBody->flags.noPrint = 1;
	grup->setGroup(mint);
	grup = mint->addString("tempField");
	grup->groupBody->flags.isLocal = 1;
	grup->groupBody->flags.noPrint = 1;
	mint->groupBody->flags.actionType = 2;
	mint->groupBody->flags.noPrint = 1;
	/*  STARVE :1230. See note (2) above -- this is the clear, not an omission. */
	rule->setMethod((GroupItem*(*)(GroupItem*))0);
	rule->groupBody->flags.methodType = 0;
	rule->groupBody->flags.actionType = 0;
	/*  ⚠ ensureRStuff(), NEVER THE RAW rStuff FIELD. (Spelled getRStuff()
	until 2026-08-31, when the getter was split into a pure read and an
	explicit ensure; this site was always relying on the CONSTRUCTION half,
	which is why it moved and the reasoning below is unchanged.)
	The first cut used
	`if !rStuff rStuff = new(rule)` and the bind SILENTLY DID NOT TAKE:
	parse() forks on definingRule().rStuff.parseMethod, and the raw field
	is not necessarily the materialised stuff that fork reads. The trace
	said it plainly -- no `parseViaKant Braced` line at all, and
	`attachLabel lab=Braced promote=1`, which is the INTERPRETED arm.
	Meanwhile the method-slot clear HAD landed, so nothing built the
	result and the consumer dereferenced a null.
	parseRuleMethod -- the working parseMethod= door -- has always used
	the same door. Copy the working door rather than inventing a second one. */
	setParseMethod(rule->ensureRStuff(),"parseViaKant");
	::parkParse(rule,"parseViaKant");
	::fprintf(stderr,"kantDoor: %s -> %s via parseViaKant, %s terms\n",rule->groupBody->tag,mintName,::toStringFromInt(live));
	::free(mintName);
	return 1;
}

/*******************************************************************************
    kantDoored — the TRIPWIRE's question, and the census's. A rule is kant
    doored when its mint exists. No new flag: the mint IS the record.
*******************************************************************************/
extern "C" int kantDoored(GroupItem *rule)
{
GroupItem 	*kantReg = 0;
GroupItem 	*mint = 0;
char 		*mintName = 0;
	/*  ⚠ locate, NOT getRegistry. getRegistry is a FACTORY -- it creates the
	registry when it is missing, and the first cut of this function called
	it on every rule that took the dlsym arm. That minted an empty
	KantParse and then indexed it, and an empty registry has no list, so
	oneTest's stderr grew four `nextGroup: ERROR KantParse does not contain
	a list` lines. Caught by diffing stderr against the banked baseline
	before landing anything -- stdout was identical throughout, so a
	stdout-only comparison would have missed it entirely.  */
	kantReg = GroupControl::groupController->locate("KantParse");
	if ( !kantReg )
		return 0;
	if ( !kantReg->groupBody->groupList )
		return 0;
	mintName = ::concat(2,"kp",rule->groupBody->tag);
	mint = kantReg->get(mintName);
	::free(mintName);
	if ( mint )
		return 1;
	return 0;
}

/*******************************************************************************
    // refusingIsTheFeature  the kant twin of emitLeaf, spelling only the kinds the shim vocabulary HAS -- everything else returns null and the caller refuses loudly, because an emitter that guessed would parse and answer wrong
*******************************************************************************/
extern "C" char *kantLeaf(GroupItem *node, char *at)
{
char 		*leaf = 0;
GroupItem 	*inner = 0;
	/*  ⚠ BUILT INTO A LOCAL AND RETURNED ONCE, and `null` rather than `0`.
	Both are emitLeaf's spelling copied exactly, and neither is taste. The
	first cut returned the concatenation straight out of the `if` and used
	`return 0` for the refusal; tok exited 139 and CASCADED, wiping the
	entire extern block from the regenerated header -- 274 externs to ZERO,
	which surfaces three files away as `no member named opEQ` in Bytecode.
	Bear-trap #24's signature exactly, and the detector that named it in one
	command is `grep -c '^extern' GroupRules.h` after every retok.  */
	/*  ⚠ OPT ARM ADDED SEQ-NEXT (the OPT charter, rung one). An OPT plan node
	WRAPS its inner node as a member, and the inner kind decides the shim:
	a reference optional is optRK, a LITERAL optional wants optLK which IS
	NOT BUILT. So this arm reads the inner kind and REFUSES the unbuilt one
	BY NAME rather than spelling optRK over it — which would emit a body
	that calls parseR on a literal term: a body that parses and answers
	wrong, the exact shape the ALT fold gate was added for one dispatch
	ago. Refuse-by-kind is what caught that, and this is the same guard
	applied to the kind being introduced rather than to the ones already
	known.  */
	if ( ::compare(node->groupBody->tag,"LIT") == 0 )
		leaf = ::concat(3,"litK(",at,")");
	else
	if ( ::compare(node->groupBody->tag,"LITTO") == 0 )
		leaf = ::concat(3,"litToK(",at,")");
	else
	if ( ::compare(node->groupBody->tag,"CALL") == 0 )
		leaf = ::concat(3,"parseRK(",at,")");
	else
	if ( ::compare(node->groupBody->tag,"OPT") == 0 )
		{
		inner = node->nextMember(inner);
		if ( !inner )
			{
			::fprintf(stderr,"  REFUSE OPT at %s -- plan node wraps nothing\n",at);
			return 0;
			}
		if ( ::compare(inner->groupBody->tag,"CALL") == 0 )
			leaf = ::concat(3,"optRK(",at,")");
		else {
			::fprintf(stderr,"  REFUSE OPT at %s -- optional wraps %s, and only CALL has a kant spelling (optLK is not built)\n",at,inner->groupBody->tag);
			return 0;
			}
		}
	else	return 0;
	return leaf;
}

extern "C" void limitWriteCheck(GroupItem *target, int priorLimit)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	if ( target->groupBody == ruler->repeatLimit->groupBody )
		{
		if ( (isCOUNT(ruler->repeatLimit->groupBody->flags.data) || isNUMBER(ruler->repeatLimit->groupBody->flags.data)) && ruler->repeatLimit->getCount() > 0 )
			return;
		::fprintf(stderr,"REFUSED repeatLimit write: %s is not a usable limit\n",ruler->repeatLimit->getText());
		::fprintf(stderr,"    keeping repeatLimit %s\n",::toStringFromInt(priorLimit));
		::fprintf(stderr,"    limits already stamped are unchanged\n");
		ruler->repeatLimit->setCount(priorLimit);
		return;
		}
	if ( (isCOUNT(ruler->maxLimit->groupBody->flags.data) || isNUMBER(ruler->maxLimit->groupBody->flags.data)) && ruler->maxLimit->getCount() > 0 )
		return;
	::fprintf(stderr,"REFUSED maxLimit write: %s is not a usable limit\n",ruler->maxLimit->getText());
	::fprintf(stderr,"    keeping maxLimit %s\n",::toStringFromInt(priorLimit));
	::fprintf(stderr,"    limits already stamped are unchanged\n");
	ruler->maxLimit->setCount(priorLimit);
}

/*****************************************************************************
    reportMaxLimit -- THE THIRD REFUSAL, and it states a fact neither sibling
    can. reportCodeFail says a body was parsed and the parse failed;
    reportNoBody says a rule was reached with no compiled body. This one says
    a match ran into the maxLimit ceiling with input still matching, so what
    was about to be returned is a TRUNCATION.

    ⚠ IT REFUSES RATHER THAN TRUNCATING, and that is the whole point of it.
    Silently returning the first N characters of a longer token is
    parse-succeeded-with-wrong-content, which is the worst failure genre on
    this project's books -- every downstream reader believes a token that was
    never in the input. A limit hit means either a defect or a genuinely large
    token, and both deserve to be named at the moment they happen.

    ⚠ ONE IMPLEMENTER, WHICH IS HOW THE TWO ENGINES ARE KEPT HONEST. The
    interpretive loop (testMacro, RuleStuff.twk) and the generated-parse loops
    (parseAny/parseCharacter/parseSet, Generate.rtn) both call THIS function,
    so "same behaviour, same words" is true by construction rather than by two
    copies being carefully matched. The convergence note on reportCodeFail
    applies to all three.

    ⚠ WHAT IT IS NOT ALLOWED TO FIRE ON. max is not only the ceiling: it is 1
    by default and it is whatever an explicit [min max] Limit sets. Both of
    those hit `counter >= max` in the ordinary course of a correct parse -- a
    one-character rule followed by another matching character reaches it on
    every single match. So the callers gate on `max > 1 && !limitsSet`, which
    is true only for the ceiling modify() stamps. Ungated, this would reject
    every name longer than one letter.

    cerr for its siblings' reason: a refusal that vanishes into a diverted
    print buffer is not loud.
*****************************************************************************/
/*****************************************************************************
    limitWriteGuard / limitWriteCheck -- F-27's ruling: a bad write to maxLimit
    is refused AT THE WRITE, and the assignment does not take.

    ⚠ THE SITE IS THE RULING. Tony, 2026-08-19: catching a bad limit at its one
    write site is cheaper than diagnosing a million silent zero-matches at parse
    time, and a stamped max = 0 is the succeed-without-advancing family wearing a
    configuration costume. So this does NOT live in modify() -- by the time
    modify() reads a poisoned count the write has already got away, and every
    rule defined since carries it.

    ⚠ WHY IT IS TWO FUNCTIONS AND NOT ONE. Refusing requires the value the write
    is about to destroy, so half of it has to run BEFORE opAssign's setContent
    and half after. The guard returns the prior count and doubles as the "is this
    even maxLimit" test: a non-zero return means both "this write is to maxLimit"
    and "here is what to put back", so opAssign pays one int test on every other
    assignment in the system and nothing else.

    ⚠ THE TEST IS ON THE DATA TYPE, NOT ONLY ON THE COUNT, and that is not
    belt-and-braces. `maxLimit = "big"` leaves an isSTRING, and getCount reads
    `count` straight out of the union for an isSTRING -- which overlaps the text
    pointer, so it comes back LARGE and non-zero rather than 0. A count-only test
    would wave that through and stamp a garbage ceiling. Only a genuine isCOUNT
    or isNUMBER above zero is a usable limit.

    The message names all three things the ruling asked for: the rejected value,
    the retained value, and that repetition limits are unchanged.
*****************************************************************************/
extern "C" int limitWriteGuard(GroupItem *target)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	if ( !target )
		return 0;
	if ( target->groupBody == ruler->maxLimit->groupBody )
		return ruler->maxLimit->getCount();
	if ( target->groupBody == ruler->repeatLimit->groupBody )
		return ruler->repeatLimit->getCount();
	return 0;
}

/*****************************************************************************
	The input argument is expected to be a listenTo attribute that contains
    a group, the notifier, that will be listened to by listenTo's parent, the
    listener. The listenTo attribute is noPrint and runs when its parent gets
    defined. A field can have more than one listenTo attribute (listenTo is a
    noPrint command so fire and forget; does not matter if its data changes
    every time it gets processed in a field definition.
    
    Here listener gets added to the notifyList of the notifier; notifyList
    is an attribute of notifier, the field being listened to. If notifier
    changes, it runs updateListeners(), which runs listener.runNotified(notifier)
    to deal with the notification.
    
    The GroupItem method runNotified looks for an onNotify attribute in
    the listener. onNotify, if it exists, should contain in its text, the
    name of a field. runNotified locates that field, and runs its method
    passing in the notifier. If there is no onNotify attribute, or runNotified
    cannot locate the field named in onNotify, it copies the notifier data
    into the listener using setContent().
    
    Note: the listener does not remember the field or fields it listens to.
*****************************************************************************/
extern "C" GroupItem *listenTo(GroupItem *input)
{
GroupItem 	*listener = input->parent;
GroupItem 	*grup = input->getGroup();
GroupItem 	*notifyList = 0;
	if ( grup && input->groupBody->flags.fLAG )
		{
		grup->groupBody->flags.hasListeners = 1;
		notifyList = grup->getAttribute("notifyLIST");
		if ( !notifyList )
			{
			notifyList = new GroupItem("notifyLIST");
			notifyList->groupBody->flags.noPrint = 1;
			grup->addAttribute(notifyList);
			}
		notifyList->addAttribute(listener);
		}
	else	::fprintf(stderr,"listenTo: should be invoked as an attribute when its parent is defined\n");
	return GroupControl::groupController->groupRules->trueResult;
}

/*******************************************************************************
    ⚠ RETURN CONTRACT IS truthOf's, deliberately: non-null for success, null
    for failure, so an AND chain short-circuits on exactly the same contract
    both engines already share. No new notion of truth enters with the parser.

    // kantBodyNamesTerm  litK/parseRK take a term POSITION, one argument: a kant body names a term and nothing else, and position, label and invariant all belong to the frame
*******************************************************************************/
extern "C" GroupItem *litK(GroupItem *idx)
{
GroupItem 	*term = 0;
int 		n = 0;
	if ( !idx )
		return 0;
	n = ::atoi(idx->getText());
	
	term = gKantRule ? gKantRule->get(n) : 0;
	
	if ( !term )
		{
		::fprintf(stderr,"litK: no term %s in the current kant parse frame\n",idx->getText());
		return 0;
		}
	if ( ::lit(term,term->groupBody->tag) )
		return GroupControl::groupController->groupRules->trueResult;
	return 0;
}

/*******************************************************************************
    // zeroMeansSelf  litToK is litK's labelled twin: at >= 1 the slot is term.tag, at == 0 there is NO term and the slot is rule.tag -- `break` plans at 0, so an unconditional rule[n] would refuse the very subject the citizen drives
    // tagDivergence  the term-position literal is term.tag, copied from litK not emitLeaf; the divergence is litK's, predates this, and is a docs/fixIts.md row rather than a repair here
*******************************************************************************/
extern "C" GroupItem *litToK(GroupItem *idx)
{
GroupItem 	*into = 0;
GroupItem 	*term = 0;
GroupItem 	*rule = 0;
int 		n = 0;
	if ( !idx )
		return 0;
	n = ::atoi(idx->getText());
	/*  Passthrough for parseRK's reason -- tok cannot see a hand-declared
	global. All three locals are referenced OUTSIDE the block as well, which
	is what keeps bear-trap #13 from pruning them.  */
	
	into = gKantLabel;
	rule = gKantRule;
	term = gKantRule ? gKantRule->get(n) : 0;
	
	if ( !into )
		{
		::fprintf(stderr,"litToK: called outside a kant parse frame -- no label to attach under\n");
		return 0;
		}
	if ( n == 0 )
		{
		if ( !rule )
			{
			::fprintf(stderr,"litToK: marker 0 outside a kant parse frame -- no rule to spell\n");
			return 0;
			}
		if ( ::litTo(rule,into,rule->getText(),rule->groupBody->tag) )
			return GroupControl::groupController->groupRules->trueResult;
		return 0;
		}
	if ( !term )
		{
		::fprintf(stderr,"litToK: no term %s in the current kant parse frame\n",idx->getText());
		return 0;
		}
	if ( ::litTo(term,into,term->groupBody->tag,term->groupBody->tag) )
		return GroupControl::groupController->groupRules->trueResult;
	return 0;
}

/***************************************************************************
	The incant load command, a noPrint command designed used as an
    attribute invokes loadDirectory to read in a directory and for every file
    in the directory creates an entry in the input parent group.
    DOES NOT HANDLE FILE MASKS??? It used to I think.
***************************************************************************/
extern "C" GroupItem *loadDirectory(GroupItem *input)
{
dirent 		*direct = 0;
DIR 		*atDirect = 0;
GroupItem 	*target = input->parent;
GroupItem 	*directory = target->getLabelGroup("directory");
GroupItem 	*group = 0;
char 		*directoryName = 0;
char 		*name = 0;
	if ( input->groupBody->flags.fLAG )
		{
		if ( !target )
			target = input;
		if ( directory )
			directoryName = directory->getText();
		else
		if ( isSTRING(target->groupBody->flags.data) )
			directoryName = target->getText();
		else	directoryName = target->groupBody->tag;
		if ( atDirect = ::opendir(directoryName) )
			{
			//cout "Directory",directoryName:;
			while ( direct = ::readdir(atDirect) )
				{
				if ( *direct->d_name == '.' )
					continue;
				if ( ::containsString(direct->d_name,".") )
					name = direct->d_name;
				if ( !name && *direct->d_name >= 'a' )
					name = direct->d_name;
				if ( name )
					{
					//cout `name:;
					group = new GroupItem(name);
					target->addMember(group);
					name = 0;
					}
				}
			}
		else {
			::perror("loadDirectory");
			::fprintf(stderr,"load: could not open %s\n",directoryName);
			target = 0;
			}
		}
	else	::fprintf(stderr,"loadDirectory: should be invoked as an attribute when its parent is defined\n");
	return target;
}

/*****************************************************************************
	The incant include command call this method to read in file to be processed.
    It does not specify what rule to run on the new input.
*****************************************************************************/
extern "C" GroupItem *loadInputFromFile(GroupItem *source)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	if ( ::getFile(source) )
		{
		ruler->pushInput(source);
		return source;
		}
	else	::fprintf(stderr,"\t\tloadInputFromFile: failed getting file from %s\n",source->groupBody->tag);
	return ruler->falseResult;
}

/*******************************************************************************
	Load a registry (create it if necessary) from a string. It does not deal
    w/attributes, just loads any field of non-space characters.
*******************************************************************************/
extern "C" void loadRegistryFromString(char *name, char *content)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
Buffer 		*buffer = ruler->stringBUFFER;
GroupItem 	*target = GroupControl::groupController->getRegistry(name);
GroupItem 	*field = 0;
char 		*input = content;
char 		*strung = 0;
PLGset 		*fieldSet = new PLGset("^ \n\r\t");
	::printf("%s\n",target->groupBody->tag);
	while ( input && *input )
		{
		field = 0;
		if ( fieldSet->contains(*input) )
			{
			buffer->reset();
			while ( fieldSet->contains(*input) )
				{
				buffer->appendChar(*input,0,0);
				input++;
				}
			strung = buffer->toString();
			field = new GroupItem(strung);
			//target    += field;
			::printf("\t%s\n",field->groupBody->tag);
			}
		else	input++;
		}
}

/*******************************************************************************
    // manierRegistry  mirrors locateSpeller one registry over, and the SEPARATE registry is the point: sharing `Spellers` would tie the kant emitMany and the kant spellLeaf to one switch
*******************************************************************************/
extern "C" GroupItem *locateManier()
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*registri = 0;
GroupItem 	*hit = 0;
	while ( registri = ruler->searchList->next(registri) )
		if ( ::compare(registri->groupBody->tag,"Maniers") == 0 )
			{
			hit = registri->get("spellMany");
			if ( hit )
				return hit;
			}
	return 0;
}

/*******************************************************************************
    // ruleLookupScope  resolves on the SEARCH LIST only and only isRule hits -- a bare locate() falls through to the base registries and silently mis-targets any rule sharing a name with a keyword or command
*******************************************************************************/
extern "C" GroupItem *locateRule(char *name)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*registri = 0;
GroupItem 	*hit = 0;
	while ( registri = ruler->searchList->next(registri) )
		{
		hit = registri->get(name);
		if ( hit )
			if ( hit->groupBody->flags.isRule )
				return hit;
		}
	return 0;
}

/*******************************************************************************
    // spellerScope  scoped on purpose: only a registry literally named `Spellers` supplies it, and only as `spellLeaf` -- a bare locate() would resolve down the general stack and silently mis-target
*******************************************************************************/
extern "C" GroupItem *locateSpeller()
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*registri = 0;
GroupItem 	*hit = 0;
	while ( registri = ruler->searchList->next(registri) )
		if ( ::compare(registri->groupBody->tag,"Spellers") == 0 )
			{
			hit = registri->get("spellLeaf");
			if ( hit )
				return hit;
			}
	return 0;
}

/***************************************************************************
    makeDataType sets target to the data type specified in argument.
    It is invoked in setInternalType
***************************************************************************/
extern "C" GroupItem *makeDataType(GroupItem *target, GroupItem *argument)
{
GroupItem 	*fILE = 0;
char 		*fileName = 0;
	switch (*argument->groupBody->tag)
		{
		case 'b':
			if ( ::compare(argument->groupBody->tag,"buffer") == 0 )
				{
				target->setBuffer(new Buffer());
				target->groupBody->flags.data = 4;
				if ( isFile(target->groupBody->flags.fileType) )
					{
					fILE = target->get("file");
					fileName = fILE ? fILE->getText() : (char*)0;
					if ( fileName )
						target->getBuffer()->setFile(fileName);
					else	::fprintf(stderr,"could not set file for buffer %s\n",target->groupBody->tag);
					}
				}
			else {
				target->groupBody->gMap = new BitMAP();
				target->groupBody->flags.data = 8;
				}
			break;
		case 'f':
			target->groupBody->flags.fileType = 3;
			target->addAttribute(argument);
			// adds a file attribute
			if ( isBUFFER(target->groupBody->flags.data) )
				{
				fileName = argument->getText();
				if ( fileName )
					target->getBuffer()->setFile(fileName);
				else	::fprintf(stderr,"expected a file name in %s\n",argument->groupBody->tag);
				}
			break;
		case 'r':
			target->groupBody->flags.data = 11;
			if ( isSTRING(argument->groupBody->flags.data) )
				target->setRegex(new PLGrgx(argument->getText()));
			else	::fprintf(stderr,"%smust include regex data as text\n",argument->groupBody->tag);
			break;
		case 's':
			target->setStak(new Stak());
			break;
		default:
			::fprintf(stderr,"%s is not a known type\n",argument->groupBody->tag);
		}
	return target;
}

/*****************************************************************************
	Command to make a new field w/tag set from input text. The GroupItem(String)
	constructor seeds BOTH tag and text from the string; we clear the text so a
	freshly-made field starts empty — the tag carries the name, the value does
	not. (Without this, new("x") yields text "x", which rides along through <:
	retags as a stale "=x" content artifact. Igor minion absorb, 2026-06-29.)
*****************************************************************************/
extern "C" GroupItem *makeNew(GroupItem *input)
{
char 		*strung = input->getText();
GroupItem 	*grup = new GroupItem(strung);
	grup->setText((char*)0);
	grup->groupBody->flags.isInitialized = 1;
	return grup;
}

/*******************************************************************************
    // textNotPointer  the answer is TEXT and not a pointer, and that is forced: a kant action cannot return null across runAction and getText falls back to the tag, so a null-test would read a refusal as a success
*******************************************************************************/
extern "C" int manyKant(GroupItem *manier, GroupItem *node)
{
GroupItem 	*result = ::runAction(node,manier);
	if ( !result )
		return 0;
	if ( ::compare(result->getText(),"1") == 0 )
		return 1;
	return 0;
}

/*******************************************************************************
    manyMode — WHICH implementation is live, and it is the acceptance test.

    Same argument as spellMode one registry over: emitMany's fork is SILENT by
    design, so a round that never registered its action would be just as green as
    one that did, and the POP could not tell them apart. This prints the answer
    and pop.sh pins it. It reads `c++` until the kant emitMany is on the search
    list and `kant` afterwards; whoever flips it accounts for the flip.
*******************************************************************************/
extern "C" GroupItem *manyMode(GroupItem *argument)
{
	if ( ::locateManier() )
		::fprintf(stderr,"MANIER kant\n");
	else	::fprintf(stderr,"MANIER c++\n");
	return GroupControl::groupController->groupRules->trueResult;
}

/*******************************************************************************
    RUNTIME LOOP (Clay 2026-07-27) — close the loop ONCE on rung 1's scaffold
    before climbing. Text-diff proves genParse emits what a human wrote; it says
    nothing about whether the emitted code compiles, links, binds, or RUNS (the
    invocation-blocker failure class was invisible to any source comparison).

    NO ENTRY WRAPPER (genParseShape §1.7). runScaf/runScaf2 are RETIRED. The
    invocation is `Scaf('x')`, exactly as `Start()` — which exercises emission,
    the fork, binding and dispatch. A bespoke wrapper exercised none of them: it
    called parseScaf directly, so it could have passed with the binding wholly
    unbuilt, which is precisely the blind spot the runtime loop exists to close.
    What the wrappers WERE good for — the Invariant R report — moved into
    leaveRule (§1.8), where `from` and atRuleMark are both in hand at the moment
    the question is asked.

    parseScaf/parseScaf2 below are the VERBATIM output of genParse. They call
    lit and leaveRule from the RuleStuff support library (cross-file via
    groups.ext).
*******************************************************************************/
/*  === GENERATED by genParse('ScafC'), pasted verbatim (rung-5 emission) ===
    ScafC isRule ScafA+ "c"-;  — one helper per repeated term, min baked in,
    the term arriving as the frame's term local. Invariant R′ is structural
    here: `from` is captured ONCE at helper entry (mark clause), and each pass
    goes through parseR -> parse() and builds a fresh label, with no fLAG
    anywhere (label clause).  */
extern "C" int manyScafC1(GroupItem *label, GroupItem *term)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
char 		*from = ruler->atRuleMark;
int 		kount = 0;
	while ( ::parseR(term,label) )
		kount++;
	if ( kount >= 1 )
		return 1;
	ruler->atRuleMark = from;
	return 0;
}

/***************************************************************************
	window attribute handler. A form field carries `window` as an attribute;
    this fires at parent-define time (fLAG set) and marks the parent form
    field as a window (isWindow). Define-then-show: it does NOT open the
    window -- openWindow(form) is the separate explicit raise trigger,
    called by name when the window should appear.
***************************************************************************/
extern "C" GroupItem *markWindow(GroupItem *input)
{
GroupItem 	*form = input->parent;
	if ( input->groupBody->flags.fLAG )
		form->groupBody->flags.isWindow = 1;
	else	::fprintf(stderr,"window: should be invoked as an attribute when its parent is defined\n");
	return GroupControl::groupController->groupRules->trueResult;
}

extern "C" int materialiseRegistry(GroupItem *registry)
{
GroupItem 	*rule = 0;
int 		made = 0;
	while ( rule = registry->next(rule) )
		made += ::materialiseTerms(rule);
	return made;
}

/*****************************************************************************
    materialiseTerms — rStuff at DEFINE TIME, not lazily on first access
    (Clay SEQ 27). By genParseSpec §7.4's taxonomy rStuff is SHAPE: one per
    rule, knowable at definition. Lazy materialisation was a cache for something
    that was never in doubt.

    MEASURED FIRST, and it narrows the job considerably. Terms defined FROM
    INCANT SOURCE already materialise at definition — `modify` calls
    setRuleStuff, and even an unmodified term comes back with rStuff. The gap is
    the BOOTSTRAPPER, which hand-builds rules in C++: GroupMain's `Limit` adds
    "[" and "]" with no modify() call at all, and applies its `+`/`*` to
    `item.group` (the shared counter rule) rather than to the min/max terms. So
    those terms had no rStuff to hold anything.

    That is also why `Limit`'s `']'-` looked like a term whose modifier had
    nowhere to live: THE MODIFIER WAS NEVER APPLIED. incant/grammar:52 lists
    `Limit '['- min=[0-9]+ max?=[0-9]+ ']'- noPrint;` — with the `-` — and the
    bootstrapper adds "[" and "]" with no modify() call at all. A real
    divergence between the documented grammar and the built one, and
    materialisation is what makes it visible instead of unknown.

    CodE is NOT such a case, and the distinction is worth keeping: incant/
    grammar:42 lists `CodE "{" "}" parseAction;` with no modifiers, so its terms
    planning as LITTO rather than LIT is the listing being followed, not
    departed from.

    USES setRuleStuff, WHICH ALSO SETS isRule — Tony's ruling, 2026-07-28:
    setRuleStuff only ever applies to rules anyway, so the propagation is
    correct rather than a side effect to be worked around. It is also what keeps
    this to ONE implementer: `modify` already calls setRuleStuff on every
    modified term, so a bootstrap term materialised here ends up in exactly the
    same state as an incant-defined one instead of a near-miss of it.

    Worth knowing why the isRule propagation matters, since it looks cosmetic: a
    reference term SHARES the referenced rule's member list, so `isRule &&
    hasMembers` on that term is precisely how parse() dispatches into a
    referenced alternation (GroupItem.twk:1062), and how checkInput knows to
    suppress its label (RuleStuff.twk:139). Terms defined from incant source
    already get it via modify; this closes the gap for the hand-built ones.
*****************************************************************************/
extern "C" int materialiseTerms(GroupItem *rule)
{
GroupItem 	*term = 0;
int 		i = 1;
int 		made = 0;
	if ( !rule->getRStuff() )
		{
		rule->setRuleStuff();
		made++;
		}
	while ( term = rule->get(i) )
		{
		if ( !term->getRStuff() )
			{
			term->setRuleStuff();
			made++;
			}
		i++;
		}
	return made;
}

/*****************************************************************************
	modify processes modifiers for field passed in updating the field RuleStuff
*****************************************************************************/
extern "C" void modify(GroupItem *field, char *modifier)
{
	field->setRuleStuff();
	while ( *modifier )
		switch ( *(modifier++) )
			{
			case '+':
				field->getRStuff()->max = GroupControl::groupController->groupRules->maxLimit->getCount();
				field->getRStuff()->maxRepeat = GroupControl::groupController->groupRules->repeatLimit->getCount();
				break;
			case '*':
				field->getRStuff()->min = 0;
				field->getRStuff()->max = GroupControl::groupController->groupRules->maxLimit->getCount();
				field->getRStuff()->maxRepeat = GroupControl::groupController->groupRules->repeatLimit->getCount();
				break;
			case '?':
				field->getRStuff()->min = 0;
				break;
			case '!':
				field->getRStuff()->banged = 1;
				break;
			case '<':
				field->getRStuff()->noAdvance = 1;
				break;
			case '%':
				field->groupBody->flags.isPercent = 1;
				break;
			case '&':
				field->groupBody->flags.isPointer = 1;
				break;
			case '@':
				field->getRStuff()->isTarget = 1;
				break;
			case '-':
				field->getRStuff()->noLabel = 1;
				break;
			case '_':
				field->groupBody->flags.guarding = 2;
				break;
			case '^':
				field->getRStuff()->noSkip = 1;
				break;
			case '{':
				field->getRStuff()->overTo = 1;
				field->groupBody->flags.guarding = 2;
				break;
			case '}':
				field->getRStuff()->overTo = 2;
				field->groupBody->flags.guarding = 2;
				break;
			case '$':
				field->groupBody->flags.isMacro = 1;
			}
}

/***************************************************************************
	Rule action for the AND operator

    ⚠ THE SHORT-CIRCUIT DOES NOT LIVE HERE AND CANNOT. runOP evaluates
    both operands BEFORE it dispatches, so by the time this is entered the
    right arm has already run, side effects included (docs/andOrRung.md
    section 1a). Declining to evaluate is not available at this position at
    all -- runShortCircuit in GroupActions.rtn is where AND/OR are actually
    reached from, and it intercepts ABOVE the resolution lines.

    This handler remains as the STRICT fallback for any path that reaches
    the operator table directly, and it is brought up to the ruling: it
    returns 1 or 0, never null, and it tests both operands through the one
    contract. Before 2026-08-11 it returned trueResult or NULL, and opOR
    returned trueResult/falseResult -- the two were not even consistent
    with each other, so nothing here is changing behaviour anyone could
    have relied on.
***************************************************************************/
extern "C" GroupItem *opAND(GroupItem *argument, GroupItem *target)
{
	if ( ::truthOf(target) && ::truthOf(argument) )
		return GroupControl::groupController->groupRules->trueResult;
	return GroupControl::groupController->groupRules->falseResult;
}

/***************************************************************************
	Rule action for the +% operator
***************************************************************************/
extern "C" GroupItem *opAddAttribute(GroupItem *argument, GroupItem *target)
{
GroupItem 	*grup = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	/*  THE STORE RULING: an armed statement stores nothing.
	Instruct.opAddAttribute.storeRuling  */
	if ( ruler->refused )
		return 0;
	if ( isLIST(argument->groupBody->flags.binType) )
		while ( grup = argument->prior(grup) )
			target->addAttribute(grup);
	else	target->addAttribute(argument);
	return target;
}

/***************************************************************************
	Rule action for the +* add-pointer operator
***************************************************************************/
extern "C" GroupItem *opAddPointer(GroupItem *argument, GroupItem *target)
{
GroupItem 	*ptr = 0;
	/*  `a +* b` -- ADD A POINTER. The sibling of `+%`, and the whole difference
	is copy versus reference: `a +% b` adds a COPY of b, `a +* b` adds an
	attribute that POINTS AT b. Read it back with `*`; `**` is `*` twice.
	Minted 2026-09-01 (SEQ 111), taking the `+*` slot from opCopyList, which
	had ZERO call sites and retires with it. copyListTo is frozen substrate
	and did not move -- anything wanting a list copy calls it on GroupItem.
	⚠ THE LIFETIME RULE IS A LAW, NOT A GUARD (Tony): the target is a real
	field, so its contents are safe. Point at a tempField and it changes
	underneath you -- user beware, exactly as for any post-definition write.
	Nothing here checks, deliberately, and incant/pointerT carries a row that
	WITNESSES the tempField case rather than forbidding it.
	⚠ AND IT REFUSES A NULL OPERAND BY NAME, F-41's shape, because
	`a +* *b` is now an ordinary thing to type.  */
	if ( !argument )
		{
		/*  F-43: name TARGET explicitly. Bare `tag` resolved to `ptr` -- declared
		above and still null here -- so this guard crashed instead of refusing.   Instruct.opAddPointer.f43  */
		/*  ⚠ PROMOTED 2026-09-05 FROM SENTINEL-AS-DATA. This returned `target`
		after announcing a failure -- a VALUE that looks like a successful
		answer, so a caller could not tell the refusal from a result. It now
		refuses: null out, arm set, and the statement after does not run.
		Instruct.opAddPointer.f43  */
		return ::refuse(target,"Operator +* -- an operand that is nothing");
		}
	ptr = new GroupItem(argument->groupBody->tag);
	ptr->groupBody->gGroup = argument;
	ptr->groupBody->flags.data = 6;
	ptr->groupBody->flags.isInitialized = 1;
	target->addAttribute(ptr);
	return target;
}

/***************************************************************************
	Rule action for the = assign operator. A byRef argument is stored BY
	REFERENCE so the `=` does not undo the reference via setContent.
	Everything else copies via setContent.

    ⚠ THIS ARM IS REACHABLE ONLY BY AN EXPLICIT `:. byRef`. `:=` does NOT
    stamp byRef and has not since 2026-06-14; the header said it did until
    R3.   Instruct.opAssign.byRefProvenance
***************************************************************************/
extern "C" GroupItem *opAssign(GroupItem *argument, GroupItem *target)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
int 		priorLimit = ::limitWriteGuard(target);
	if ( ruler->jitting )
		{
		 return jitEmitAssign(argument, target); 
		}
	/*  ⚠ THE STORE RULING (Tony, 2026-09-05): AN ARMED STATEMENT STORES NOTHING.
	AND THE CHECK HAS TO BE HERE RATHER THAN AT runOP's ENTRY, which is where
	it was first put and where it does not work. MEASURED: an assignment
	DISPATCHES BEFORE ITS OWN RIGHT-HAND SIDE -- a STORECAM trace reads
	`op== refused=0` and only then `op=+*`, with the refusal firing later
	still, inside the +* dispatch. So the enclosing operator is entered while
	the arm is clear and an entry check can never see its own operand refuse.
	⚠ AND WITHOUT THIS THE REFUSAL DESTROYS ITS TARGET: a refused right-hand
	side is null, and opAssign's `else target.clearData()` below is what
	BLANKS the field. sentinelT ST-1 read its own tag instead of the 111 it
	went in with, for exactly that reason.   Instruct.opAssign.storeRuling  */
	if ( ruler->refused )
		return 0;
	if ( argument )
		if ( argument->groupBody->flags.byRef )
			target->setGroup(argument);
		else {
			/*  ⚠ F-48 FOR THE INTERPRETER (Tony, SEQ 139), through the SAME core
			the emitted road uses -- assignFieldCore -- so the two cannot
			drift. A holder on the right refuses by name and stores nothing.
			⚠ IT WAS GATED, AND THE GATE IS GONE (2026-09-05). The bare arm
			was a plain setContent, kept only while the auto-unwrap still
			stood and a holder legitimately resolved to its value. The trunk
			is the flip; assignFieldCore is now unconditional.
			Instruct.opAssign.holderRefusal  */
			 ::assignFieldCore(argument,target); 
			}
	else	target->clearData();
	/*  F-27, Tony's ruling 2026-08-19. Non-zero priorLimit means the target IS
	maxLimit and here is what to restore, so every other assignment in the
	system pays one int test. See limitWriteGuard's header in
	GroupActions.rtn for why the refusal has to be here rather than in
	modify(), and why it takes two halves.
	⚠ THE GUARD CALL SITS ABOVE THE jitting ARM DELIBERATELY: it must run on
	the same passes the write does, and it mentions `target` so the bare
	`group` below still resolves to target -- verified in the generated .mm,
	which is the only way that question has ever been answerable here.  */
	if ( priorLimit )
		::limitWriteCheck(target,priorLimit);
	return target;
}

/***************************************************************************
	operator method for the cerr rule -- THE STDERR SINK, added 2026-08-01.

    opPrint above is a TWO-arm choice (diverted buffer, else stdout) and there
    was no third arm to select; that absence is what grammar-minion round 1
    refused on with evidence (docs/grammarCorpus.md CLAIM GRAM-4), and it is
    what held minionA round 2 -- genParse's emitters write their PRODUCT via
    cerr, so a kant version could not reproduce its own target.

    ⚠ DELIBERATELY A SIBLING, NOT A THIRD ARM IN opPrint. Two reasons:
      1. It follows Tony's own precedent. aCTionStringXP was split out of the
         print action rather than folded into it -- "it duplicates much of the
         print action, but no biggie it is short, and no if statement needed to
         figure out what print method to invoke."
      2. It does NOT preempt `sink=`. Selecting a sink per statement is an OPEN
         design item Tony owns (GRAM-P1, the replacement for the first-character
         test). A sibling rule needs no selector at all, so it leaves that
         decision exactly where it was.

    NOTE the toBUFFER asymmetry, and it is intentional: cerr does NOT honour the
    print diversion. `printTO` exists to capture program output; a diagnostic
    that silently vanished into a capture buffer would be the opposite of what a
    diagnostic is for. If that turns out to be wrong it is a one-line change.
***************************************************************************/
extern "C" GroupItem *opCerr(GroupItem *target, Buffer *buffer)
{
char 	*printText = buffer->string();
	if ( printText )
		::fprintf(stderr,"%s",printText);
	else	::fprintf(stderr,"cerr: recieved no print text\n");
	buffer->reset();
	GroupControl::groupController->groupRules->bufferSTAK->push(buffer);
	return GroupControl::groupController->groupRules->trueResult;
}

/***************************************************************************
	operator method for the cout rule -- THE EXPLICIT STDOUT SINK, 2026-08-01.

    opPrint above consults toBUFFER and so is DIVERTIBLE. This one does not,
    and that is its entire reason for existing (Tony): once you have diverted
    `print` with printTO(), you invariably need to reach the terminal anyway,
    and there was no way to. `cout` is that way.

    ⚠ THE MISSING toBUFFER TEST IS THE FEATURE, NOT AN OVERSIGHT, and it is
    the line that closes KANT-23 -- the pinned defect where a grafted `cout`
    was swallowed by an armed diversion. Do not "fix" this by adding the
    toBUFFER arm back; that would restore the defect exactly.
***************************************************************************/
extern "C" GroupItem *opCout(GroupItem *target, Buffer *buffer)
{
char 	*printText = buffer->string();
	if ( printText )
		::printf("%s",printText);
	else	::fprintf(stderr,"cout: recieved no print text\n");
	buffer->reset();
	GroupControl::groupController->groupRules->bufferSTAK->push(buffer);
	return GroupControl::groupController->groupRules->trueResult;
}

/***************************************************************************
	Rule action for the $$ debug marker. Spelled ** until 2026-09-01, when Tony
    freed that token so ** could become the fixpoint unwrap without being
    claimed by this marker first.

    ⚠ THE UNWRAP STRIP IS RULED AND STAGED, NOT LANDED. It was ruled to RIDE
    WITH the gNoUnwrap flip on 2026-09-01; the flip reverted on the acceptance
    failure, so the strip reverted with it rather than shipping half a stroke.
    It re-rides with the next flip attempt, unchanged. The argument for it, from
    the marker's side, stands: a
    breakpoint marker that quietly unwrapped its subject was auto-unwrap wearing
    a debugger's hat, so it retires in the stroke that retires auto-unwrap. The
    marker's whole job is to be a NAMED PLACE TO STOP, and a place to stop must
    not change what you are stopping to look at.

    ⚠ IF YOU WANTED THE OLD BEHAVIOUR, SPELL IT: `$$*x` -- marker, then an
    explicit deref. That is the migration's entire thesis in one line, applied
    to itself: the unwrap does not vanish, it becomes VISIBLE at the site that
    wanted it.
***************************************************************************/
extern "C" GroupItem *opDebug(GroupItem *result)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*field = 0;
GroupItem 	*lastRef = 0;
	lastRef = ruler->lastREF;
	field = result;
	if ( isGROUP(result->groupBody->flags.data) )
		result = ::unWrap(result);
	return result;
}

/***************************************************************************
	opDeref -- the prefix unary * . Hands back the GROUP a field contains,
	explicitly, where runOP used to do it silently for everything.

	Routed here from handleUnary via the named "deref" op, keeping the binary
	* slot (opMultiply, which carries all three of operateMethod,
	interpretMethod and jitEmitter) completely isolated -- the same two-slot
	separation prefix - has from opMinus, and for the same reason.

	IT REFUSES RATHER THAN SUBSTITUTES. A * on a field holding no group is a
	user error under the new algebra, and handing the field back would make
	*field and field indistinguishable at exactly the sites the migration is
	trying to tell apart. Null is the honest answer and it is loud.

	NO JIT EMITTER YET, ruled: interpreter-only is fine for the facility, so
	the jitting arm degrades by name rather than folding a value at emit time.
***************************************************************************/
extern "C" GroupItem *opDeref(GroupItem *result)
{
	if ( GroupControl::groupController->groupRules->jitting )
		{
		 if (!::jitEmitDeref(result))
		::jitDegrade("unary * under jit -- emitter refused",result); 
		}
	/*  ⚠ THE STAR RULING (Tony, 2026-09-05). `*x` ON A FIELD THAT HOLDS NO
	GROUP YIELDS NULL -- the testable nothing -- AND DOES NOT REFUSE.
	REFUSAL IS FOR CATEGORY ERRORS; asking a field for what it holds is a
	legitimate question with a legitimate empty answer, and `if *x` must be
	able to take its else arm without ending the activation.
	⚠ THE CONSUMER OF THE NULL REFUSES, and that is where the name belongs:
	an iterate handed nothing says so about the ITERATE, which is the
	statement the writer actually typed. f31's spin was diagnosed for a day
	as a star problem because the star was the thing shouting.
	Instruct.opDeref.starRuling  */
	if ( isGROUP(result->groupBody->flags.data) )
		return result->getGroup();
	return 0;
}

/***************************************************************************
	Rule action for the / divide operator
***************************************************************************/
extern "C" GroupItem *opDiv(GroupItem *argument, GroupItem *target)
{
	if ( GroupControl::groupController->groupRules->jitting )
		{
		 return jitEmitBinary(argument, target, jitSDiv); 
		}
	/*  `/` PROMOTES (Tony's ruling, 2026-08-01, clause 1). DIVISION MEANS
	DIVISION -- the same operator never silently changes mathematical
	meaning by operand type, so count-over-count yielding a fraction gives a
	DOUBLE: 10 / 4 is 2.5, not 3 and not 2. The old arm was wrong twice,
	truncating AND count-typing.
	⚠ ALWAYS A DOUBLE, INCLUDING THE EXACT CASE (8 / 4). Tony left the
	exact-result behaviour open; this is the proposal and its reason is the
	JIT rather than taste. Premise 1 is the datA-stability contract: a
	field's datA is fixed for the lifetime of jitted code that observed it.
	Making the RESULT TYPE depend on whether the division happens to come out
	even makes it depend on runtime VALUES, so the emitter could not know it
	at emit time and the table arc's promote leaf would have no static
	answer. One arm is also the cheapest thing in the file. */
	if ( isCOUNT(argument->groupBody->flags.data) || isNUMBER(argument->groupBody->flags.data) )
		GroupControl::groupController->groupRules->tempField->setNumber(target->getNumber() / argument->getNumber());
	if ( !GroupControl::groupController->groupRules->tempField->groupBody->flags.data )
		{
		return ::refuse(target,"Operator / -- not supported for these operands");
		}
	return GroupControl::groupController->groupRules->tempField;
}

/***************************************************************************
	Rule action for the /= slash equal operator
***************************************************************************/
extern "C" GroupItem *opDivEQ(GroupItem *argument, GroupItem *target)
{
GroupItem 	*result = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	/*  THE STORE RULING: an armed statement stores nothing.
	Instruct.opDivEQ.storeRuling  */
	if ( ruler->refused )
		return 0;
	if ( ruler->jitting )
		{
		 jitEmitBinary(argument, target, jitSDiv);
		return jitEmitAssign(target, target); 
		}
	if ( (isCOUNT(target->groupBody->flags.data) || isNUMBER(target->groupBody->flags.data)) && (isCOUNT(argument->groupBody->flags.data) || isNUMBER(argument->groupBody->flags.data)) )
		{
		/*  `/=` divides as `/` does (clause 1) and then NARROWS into whatever
		slot the target already is (clause 3). A count target therefore
		rounds half-up rather than truncating; a double target keeps the
		fraction. Written through the same floor(x+0.5) as getCount so the
		two cannot drift. */
		if ( isCOUNT(target->groupBody->flags.data) )
			target->setCount((int)floor((target->getNumber() / argument->getNumber()) + 0.5));
		else
		if ( isNUMBER(target->groupBody->flags.data) )
			target->setNumber(target->getNumber() / argument->getNumber());
		result = target;
		if ( !result )
			::fprintf(stderr,"ERROR Operator /= failed on %s and %s\n",target->groupBody->tag,argument->groupBody->tag);
		}
	else
	if ( isLIST(argument->groupBody->flags.binType) )
		while ( result = argument->prior(result) )
			::opDivEQ(result,target);
	return result;
}

/***************************************************************************
	Dot operator method returns the field referenced in a dot product
    expression like: field, IWC field can be a group field or the
    name (in field.tag) of a component of target that may or may not exist.
    Note: local fields are ignored
***************************************************************************/
extern "C" GroupItem *opDot(GroupItem *argument, GroupItem *target)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*product = 0;
	// ONE gate for the whole accessor family; remove it and a jitted `if noPrinT`
	// branches on whatever was last in flight   Instruct.opDot.accessorGate
	if ( ruler->jitting )
		{
		 return jitEmitDot(argument, target, ruler->tempField); 
		}
	if ( !argument )
		if ( ruler->lastREF )
			{
			argument = target;
			target = ruler->lastREF->getGroup();
			}
		else	::fprintf(stderr,"opDot: lastREF not set\n");
	if ( argument )
		{
		if ( argument->groupBody->registry != ruler->groupFields )
			product = target->get(argument->getText());
		else {
			if ( !target )
				return 0;
			product = new GroupItem(argument->groupBody->tag);
			switch (argument->groupBody->gCount)
				{
				case 1:
					product->setText(target->groupBody->tag);
					break;
				case 2:
					if ( !target->parent )
						product = 0;
					else	product = target->parent;
					break;
				case 3:
					if ( !target->groupBody->registry )
						product = 0;
					else	product = target->groupBody->registry;
					break;
				case 4:
					product->setText(target->getText());
					break;
				case 5:
					if ( target->groupBody->groupList )
						product->setCount(target->groupBody->groupList->listLength);
					else	product = 0;
					break;
				case 6:
					product->setCount((int)target->groupBody->flags.data);
					break;
				case 7:
					if ( target->groupBody->flags.hasAttributes )
						product->setCount(1);
					else	product = 0;
					break;
				case 8:
					if ( target->groupBody->flags.hasMembers )
						product->setCount(1);
					else	product = 0;
					// NOT case 7: setParse makes hasAttributes TRUE for every walked
					// rule, so only this one discriminates   Instruct.opDot.case42hasTraits
					break;
				case 42:
					if ( target->groupBody->flags.hasTraits )
						product->setCount(1);
					else	product = 0;
					break;
				case 9:
					if ( target->groupBody->flags.isLocal )
						product->setCount(1);
					break;
				case 10:
					if ( target->groupBody->flags.isArgument )
						product->setCount(1);
					break;
				case 11:
					if ( target->groupBody->flags.invoke )
						product->setCount(1);
					break;
				case 12:
					if ( target->groupBody->flags.fLAG )
						product->setCount(1);
					break;
				case 17:
					if ( target->groupBody->flags.isLiteral )
						product->setCount(1);
					break;
				case 19:
					if ( isMethod(target->groupBody->flags.instructType) )
						product->setCount(1);
					break;
				case 20:
					if ( isOperator(target->groupBody->flags.instructType) )
						product->setCount(1);
					break;
				case 23:
					if ( target->groupBody->flags.isRule )
						product->setCount(1);
					break;
				case 24:
					if ( target->groupBody->flags.isShortcut )
						product->setCount(1);
					break;
				case 28:
					if ( target->getRStuff() && target->getRStuff()->noLabel )
						product->setCount(1);
					break;
				case 29:
					if ( target->groupBody->flags.noPrint )
						product->setCount(1);
					break;
				case 34:
					if ( isAttribute(target->options.affiliation) )
						product->setCount(1);
					break;
				case 35:
					if ( isMember(target->options.affiliation) )
						product->setCount(1);
					break;
				case 36:
					if ( target->getRStuff() && target->getRStuff()->actionMethod )
						product->setCount(1);
					break;
				case 40:
					if ( isCoded(target->groupBody->flags.actionType) )
						product->setCount(1);
					break;
				case 41:
					if ( target->groupBody->flags.hasNewParse )
						product->setCount(1);
					break;
				case 401:
					if ( !target->nextInParent )
						product = 0;
					else {
						product = target->nextInParent;
						product->groupBody->flags.isInitialized = 1;
						}
					break;
				case 402:
					if ( !target->priorInParent )
						product = 0;
					else {
						product = target->priorInParent;
						product->groupBody->flags.isInitialized = 1;
						}
					// ⚠ THE `groupList &&` PREFIX IS LOAD-BEARING. Without it these
					// SEGFAULT on a listless node -- the guard dereferenced the very
					// pointer it guarded   Instruct.opDot.cases403to404
					break;
				case 403:
					if ( !target->groupBody->groupList || !target->groupBody->groupList->firstInList )
						product = 0;
					else	product = target->groupBody->groupList->firstInList;
					break;
				case 404:
					if ( !target->groupBody->groupList || !target->groupBody->groupList->lastInList )
						product = 0;
					else	product = target->groupBody->groupList->lastInList;
					// affiliation-FILTERED first, unlike `.firsT`, which returns the
					// ATTRIBUTE on an attribute-first node   Instruct.opDot.case405firstMember
					break;
				case 405:
					if ( !target->groupBody->groupList )
						product = 0;
					else	product = target->nextMember(0);
					break;
				case 406:
					if ( target->groupBody->flags.actionType )
						product->setCount(1);
					// binType is an ENUM, so nonzero means ANY container kind --
					// deliberately wider than isBIN||isREGISTRY   Instruct.opDot.case407binType
					break;
				case 407:
					if ( target->groupBody->flags.binType )
						product->setCount(1);
					// 406 cannot witness isCoded -> isAction; this tests isAction
					// SPECIFICALLY, as parseRule does   Instruct.opDot.case408isAction
					break;
				case 408:
					if ( isAction(target->groupBody->flags.actionType) )
						product->setCount(1);
					// READ half; the WRITE half is opSetFlag case 41 -- they ship
					// together or the flag is unassertable   Instruct.opDot.case41hasNewParse
					break;
				default:
					product->setText(::concat(3,"access to ",argument->groupBody->tag," not supported yet"));
				}
			if ( product && !product->parent )
				product->parent = target;
			}
		}
	return product;
}

/***************************************************************************
	Rule action for the == operator
***************************************************************************/
extern "C" GroupItem *opEQ(GroupItem *argument, GroupItem *target)
{
	if ( GroupControl::groupController->groupRules->jitting )
		{
		 return jitEmitCompare(argument, target, jitEQ); 
		}
	/*  F-41 null-operand guard -- see the note on opPlus.  */
	if ( !argument )
		{
		return ::refuse(target,"Operator == -- an operand that is nothing");
		}
	if ( target && !target->groupBody->flags.data )
		{
		if ( isCOUNT(argument->groupBody->flags.data) || isNUMBER(argument->groupBody->flags.data) )
			if ( argument->groupBody->gCount == 0 )
				return GroupControl::groupController->groupRules->trueResult;
		}
	else
	if ( argument && !argument->groupBody->flags.data )
		{
		if ( isCOUNT(target->groupBody->flags.data) || isNUMBER(target->groupBody->flags.data) )
			if ( target->groupBody->gCount == 0 )
				return GroupControl::groupController->groupRules->trueResult;
		}
	else
	if ( !::compareValues(target,argument) )
		return GroupControl::groupController->groupRules->trueResult;
	return 0;
}

/***************************************************************************
	Rule action for =] operator that returns the last item on the arguments
    list
***************************************************************************/
extern "C" GroupItem *opEnd(GroupItem *argument, GroupItem *target)
{
	if ( argument->groupBody->groupList )
		{
		target->setGroup(argument->groupBody->groupList->lastInList);
		return target;
		}
	return 0;
}

/***************************************************************************
	Rule action for the >= operator
***************************************************************************/
extern "C" GroupItem *opGE(GroupItem *argument, GroupItem *target)
{
	if ( GroupControl::groupController->groupRules->jitting )
		{
		 return jitEmitCompare(argument, target, jitGE); 
		}
	/*  F-41 null-operand guard -- see the note on opPlus.  */
	if ( !argument )
		{
		return ::refuse(target,"Operator >= -- an operand that is nothing");
		}
	if ( target && !target->groupBody->flags.data )
		{
		if ( isCOUNT(argument->groupBody->flags.data) || isNUMBER(argument->groupBody->flags.data) )
			if ( argument->groupBody->gCount <= 0 )
				return GroupControl::groupController->groupRules->trueResult;
		}
	else
	if ( argument && !argument->groupBody->flags.data )
		{
		if ( isCOUNT(target->groupBody->flags.data) || isNUMBER(target->groupBody->flags.data) )
			if ( target->groupBody->gCount >= 0 )
				return GroupControl::groupController->groupRules->trueResult;
		}
	else
	if ( ::compareValues(target,argument) >= 0 )
		return GroupControl::groupController->groupRules->trueResult;
	return 0;
}

/***************************************************************************
	Rule action for the > operator
***************************************************************************/
extern "C" GroupItem *opGT(GroupItem *argument, GroupItem *target)
{
	if ( GroupControl::groupController->groupRules->jitting )
		{
		 return jitEmitCompare(argument, target, jitGT); 
		}
	/*  F-41 null-operand guard -- see the note on opPlus.  */
	if ( !argument )
		{
		return ::refuse(target,"Operator > -- an operand that is nothing");
		}
	if ( target && !target->groupBody->flags.data )
		{
		if ( isCOUNT(argument->groupBody->flags.data) || isNUMBER(argument->groupBody->flags.data) )
			if ( argument->groupBody->gCount < 0 )
				return GroupControl::groupController->groupRules->trueResult;
		}
	else
	if ( argument && !argument->groupBody->flags.data )
		{
		if ( isCOUNT(target->groupBody->flags.data) || isNUMBER(target->groupBody->flags.data) )
			if ( target->groupBody->gCount > 0 )
				return GroupControl::groupController->groupRules->trueResult;
		}
	else
	if ( ::compareValues(target,argument) > 0 )
		return GroupControl::groupController->groupRules->trueResult;
	return 0;
}

/***************************************************************************
	Rule action that handles [argument] references.
***************************************************************************/
extern "C" GroupItem *opGet(GroupItem *argument, GroupItem *target)
{
GroupItem 	*result = 0;
char 		*txt = 0;
	// null target is a lawful empty answer, as in opDot   Instruct.opGet.nullTarget
	if ( !target )
		return 0;
	if ( isGROUP(argument->groupBody->flags.data) && argument->groupBody->gText )
		txt = argument->groupBody->gText;
	else	txt = argument->getText();
	if ( isCOUNT(argument->groupBody->flags.data) )
		result = target->get(argument->getCount());
	else	result = target->get(txt);
	return result;
}

/***************************************************************************
	Rule action for the =% getAttribute operator
***************************************************************************/
extern "C" GroupItem *opGetAttribute(GroupItem *argument, GroupItem *target)
{
char 	*strung = argument->getText();
	return target->getAttribute(strung);
}

/***************************************************************************
	Rule action for the =/ getMember operator
***************************************************************************/
extern "C" GroupItem *opGetMember(GroupItem *argument, GroupItem *target)
{
char 	*strung = argument->getText();
	return target->getMember(strung);
}

/***************************************************************************
	Rule action for the IN operator.
        If argument is a set return true if target contains any character in it
        If target is a set return true if every character in argument is in the set
            REWRITE THIS ONCE WE HAVE SET OPERATORS need to know for any target
                is first character in
                is any character in argument set
                are all characters in argument set
***************************************************************************/
extern "C" GroupItem *opIN(GroupItem *argument, GroupItem *target)
{
PLGset 		*set = 0;
GroupItem 	*result = 0;
	if ( isSET(argument->groupBody->flags.data) )
		{
		if ( set = argument->getCharacterSet() )
			if ( set->foundIn(target->getText()) )
				result = GroupControl::groupController->groupRules->trueResult;
		}
	else
	if ( isSET(target->groupBody->flags.data) )
		{
		if ( set = target->getCharacterSet() )
			if ( set->contains(argument->getText()) )
				result = GroupControl::groupController->groupRules->trueResult;
		}
	else
	if ( isBUFFER(argument->groupBody->flags.data) )
		{
		/* Text-substrate find: argument is a string field, target is a
		buffer field. On match, buffer's mark is set to start of match
		(side effect); we return argument so caller has the matched
		string for length-of-match computations (argument.count). */
		if ( argument->getBuffer()->findInBuffer(target->getText()) )
			result = target;
		}
	else
	if ( argument->groupBody->groupList )
		result = argument->get(target->groupBody->tag);
	return result;
}

/***************************************************************************
	Rule action for the <= operator
***************************************************************************/
extern "C" GroupItem *opLE(GroupItem *argument, GroupItem *target)
{
	if ( GroupControl::groupController->groupRules->jitting )
		{
		 return jitEmitCompare(argument, target, jitLE); 
		}
	/*  F-41 null-operand guard -- see the note on opPlus.  */
	if ( !argument )
		{
		return ::refuse(target,"Operator <= -- an operand that is nothing");
		}
	if ( target && !target->groupBody->flags.data )
		{
		if ( isCOUNT(argument->groupBody->flags.data) || isNUMBER(argument->groupBody->flags.data) )
			if ( argument->groupBody->gCount >= 0 )
				return GroupControl::groupController->groupRules->trueResult;
		}
	else
	if ( argument && !argument->groupBody->flags.data )
		{
		if ( isCOUNT(target->groupBody->flags.data) || isNUMBER(target->groupBody->flags.data) )
			if ( target->groupBody->gCount <= 0 )
				return GroupControl::groupController->groupRules->trueResult;
		}
	else
	if ( ::compareValues(target,argument) <= 0 )
		return GroupControl::groupController->groupRules->trueResult;
	return 0;
}

/***************************************************************************
	Rule action for the < operator
***************************************************************************/
extern "C" GroupItem *opLT(GroupItem *argument, GroupItem *target)
{
	if ( GroupControl::groupController->groupRules->jitting )
		{
		 return jitEmitCompare(argument, target, jitLT); 
		}
	/*  F-41 null-operand guard -- see the note on opPlus.  */
	if ( !argument )
		{
		return ::refuse(target,"Operator < -- an operand that is nothing");
		}
	if ( target && !target->groupBody->flags.data )
		{
		if ( isCOUNT(argument->groupBody->flags.data) || isNUMBER(argument->groupBody->flags.data) )
			if ( argument->groupBody->gCount > 0 )
				return GroupControl::groupController->groupRules->trueResult;
		}
	else
	if ( argument && !argument->groupBody->flags.data )
		{
		if ( isCOUNT(target->groupBody->flags.data) || isNUMBER(target->groupBody->flags.data) )
			if ( target->groupBody->gCount < 0 )
				return GroupControl::groupController->groupRules->trueResult;
		}
	else
	if ( ::compareValues(target,argument) < 0 )
		return GroupControl::groupController->groupRules->trueResult;
	return 0;
}

/***************************************************************************
	Rule action for @ operator
***************************************************************************/
extern "C" GroupItem *opLastREF(GroupItem *result)
{
	GroupControl::groupController->groupRules->lastREF->groupBody->gGroup = result;
	GroupControl::groupController->groupRules->lastREF->groupBody->flags.data = 6;
	return result;
}

/***************************************************************************
	Rule action for ~= match operator
***************************************************************************/
extern "C" GroupItem *opMatch(GroupItem *argument, GroupItem *target)
{
	if ( !::compare(target->getText(),argument->getText()) )
		return GroupControl::groupController->groupRules->trueResult;
	return 0;
}

/***************************************************************************
	Rule action for the - operator
***************************************************************************/
extern "C" GroupItem *opMinus(GroupItem *argument, GroupItem *target)
{
	if ( GroupControl::groupController->groupRules->jitting )
		{
		 return jitEmitBinary(argument, target, jitSub); 
		}
	/*  F-41 null-operand guard -- see the note on opPlus.  */
	if ( !argument )
		{
		return ::refuse(target,"Operator - -- an operand that is nothing");
		}
	if ( (isCOUNT(target->groupBody->flags.data) || isNUMBER(target->groupBody->flags.data)) && (isCOUNT(argument->groupBody->flags.data) || isNUMBER(argument->groupBody->flags.data)) )
		{
		/*  BINARY FAMILY PROMOTES (Tony, 2026-08-01, greenlight after Word 2).
		`.count` on a double operand narrowed it AT ENTRY, so 0 - 2.5 gave
		-3 as a COUNT before anything else ran. ⚠ THE FIX IS PROMOTION, NOT
		THE COMPOUND FAMILY'S NARROW-AT-RESULT: a binary op has NO COUNT SLOT
		to narrow into -- its result is a fresh temp -- so the ruling's POP
		(`0 - 2.5 -> -2.5 TYPED DOUBLE`) is asking for premise 2's
		promotion-first rule applied in the interpreter. Count OP count stays
		a count, so nothing that was already integral moves.  */
		if ( isNUMBER(target->groupBody->flags.data) || isNUMBER(argument->groupBody->flags.data) )
			GroupControl::groupController->groupRules->tempField->setNumber(target->getNumber() - argument->getNumber());
		else	GroupControl::groupController->groupRules->tempField->setCount(target->groupBody->gCount - argument->getCount());
		}
	else
	if ( (isSTRING(target->groupBody->flags.data) || isTOKEN(target->groupBody->flags.data)) && argument->getCount() > 0 )
		if ( target->groupBody->gCount > argument->getCount() )
			GroupControl::groupController->groupRules->tempField->setText(::headToCount(target->getText(),target->groupBody->gCount - argument->getCount()));
	if ( !GroupControl::groupController->groupRules->tempField->groupBody->flags.data )
		{
		return ::refuse(target,"Operator - -- cannot apply to these operands");
		}
	return GroupControl::groupController->groupRules->tempField;
}

/***************************************************************************
	Rule action for the -= operator
***************************************************************************/
extern "C" GroupItem *opMinusEQ(GroupItem *argument, GroupItem *target)
{
GroupItem 	*result = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	/*  THE STORE RULING: an armed statement stores nothing.
	Instruct.opMinusEQ.storeRuling  */
	if ( ruler->refused )
		return 0;
	if ( ruler->jitting )
		{
		 jitEmitBinary(argument, target, jitSub);
		return jitEmitAssign(target, target); 
		}
	if ( target->groupBody->groupList )
		result = target->remove(argument->groupBody->tag);
	else
	if ( target->groupBody->flags.data && argument->groupBody->flags.data )
		{
		result = target;
		switch (target->groupBody->flags.data)
			{
				/*  WORD 2 (Tony, 2026-08-01): COMPUTE IN DOUBLES, NARROW AT THE
				RESULT. The narrowing point moves off OPERAND-ENTRY and onto
				RESULT-COMMIT for the whole compound-assign family. It used to
				read `gCount -= argument.count`, and `.count` on a double
				operand narrowed it BEFORE the arithmetic -- so 0 -= 2.5 went
				0 - 3 = -3 where the ruling wants 0 - 2.5 = -2.5 -> -2.
				⚠ ROUTED THROUGH tempField.count ON PURPOSE, so the half-up rule
				keeps ONE IMPLEMENTER: getCount. Writing floor(x+0.5) inline
				here would make a second copy that can drift from the first, and
				this family exists precisely because two copies of one rule
				disagreed. Same shape in opPlusEQ and opMultiplyEQ; opDivEQ
				already computed in doubles.
				`+=` CANNOT DISCRIMINATE the two readings (0 + 2.5 gives 3 under
				both), so only a subtraction with a fractional operand shows the
				difference -- incant/divT's c4 row is that test.  */
				break;
			case 5:
				ruler->tempField->setNumber(target->getNumber() - argument->getNumber());
				target->groupBody->gCount = ruler->tempField->getCount();
				break;
			case 9:
				target->groupBody->gNumber -= argument->getNumber();
				break;
			case 4:
				target->getBuffer()->deleteFromBuffer(argument->getCount());
				break;
			case 13:
			case 14:
				target->setText(::headToCount(target->getText(),target->groupBody->gCount - argument->getCount()));
				break;
			default:
				result = 0;
			}
		if ( !result )
			::fprintf(stderr,"ERROR Operator -= failed on %s and %s\n",target->groupBody->tag,argument->groupBody->tag);
		}
	else
	if ( isLIST(argument->groupBody->flags.binType) )
		while ( result = argument->prior(result) )
			::opMinusEQ(result,target);
	return result;
}

/***************************************************************************
	Rule action for -- operator
***************************************************************************/
extern "C" GroupItem *opMinusMinus(GroupItem *result)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	/*  THE STORE RULING: an armed statement stores nothing.
	Instruct.opMinusMinus.storeRuling  */
	if ( ruler->refused )
		return 0;
	if ( result->groupBody->flags.isIterator )
		{
		/*******************************************************************
		note: because result is an iterator it is not unwrapped in runOP()
		also -- does not differentiate between members and attributes
		because GroupItem does not offer priorMember() or priorAttribute().
		*******************************************************************/
		/*  ⚠ PLACEMENT IS THE FIX, and this gate is INSIDE the arm and ABOVE
		the return for the same reason opPlusPlus's is. F-53, 2026-09-04.
		The old order returned from this arm before the gate below, so an
		iterator under `--` never reached it: the walk ran once at EMIT
		time and the compiled function contained NO LOOP -- silently, with
		no refusal and no degrade line. opPlusPlus was fixed this way on
		2026-08-04 and `--` was left behind; C-158a's JIT census found it.
		The arm below is untouched and remains the definition of correct;
		jitEmitIterStepBack emits a CALL TO THIS FUNCTION so the two cannot
		drift.   Instruct.opMinusMinus.iterGate  */
		if ( ruler->jitting )
			{
			 return jitEmitIterStepBack(result); 
			}
		GroupItem *iterator = 0;
		if ( !result->groupBody->flags.data )
			iterator = result->groupBody->groupList->lastInList;
		else {
			iterator = result->getGroup();
			iterator = iterator->priorInParent;
			}
		ruler->lastREF->groupBody->gGroup = iterator;
		ruler->lastREF->groupBody->flags.data = 6;
		result->setGroup(iterator);
		if ( !iterator )
			result = 0;
		return result;
		}
	if ( ruler->jitting )
		{
		 return jitEmitUnary(result, jitDec); 
		}
	if ( isCOUNT(result->groupBody->flags.data) )
		result->groupBody->gCount--;
	else
	if ( isNUMBER(result->groupBody->flags.data) )
		result->groupBody->gNumber -= 1.0;
	else
	if ( isSTRING(result->groupBody->flags.data) || isTOKEN(result->groupBody->flags.data) )
		if ( result->groupBody->flags.isPointer )
			{
			result->groupBody->gText--;
			result->groupBody->gCount++;
			}
		else
		if ( result->groupBody->gText && result->groupBody->gCount > 0 )
			{
			result->groupBody->gCount--;
			*(result->groupBody->gText + result->groupBody->gCount) = 0;
			}
		else	result->setText((char*)0);
	else
	if ( isSTAK(result->groupBody->flags.data) )
		result = (GroupItem*)result->groupBody->gStak->pop();
	else
	if ( result->groupBody->groupList )
		result->pop();
	else	return ::refuse(result,"Operator -- -- not supported for this data type");
	return result;
}

/***************************************************************************
	Rule action for the * multiply operator
***************************************************************************/
extern "C" GroupItem *opMultiply(GroupItem *argument, GroupItem *target)
{
	if ( GroupControl::groupController->groupRules->jitting )
		{
		 return jitEmitBinary(argument, target, jitMul); 
		}
	/*  BINARY FAMILY PROMOTES (Tony, 2026-08-01, greenlight after Word 2).
	`.count` on a double operand narrowed it AT ENTRY, so 0 - 2.5 gave
	-3 as a COUNT before anything else ran. ⚠ THE FIX IS PROMOTION, NOT
	THE COMPOUND FAMILY'S NARROW-AT-RESULT: a binary op has NO COUNT SLOT
	to narrow into -- its result is a fresh temp -- so the ruling's POP
	(`0 - 2.5 -> -2.5 TYPED DOUBLE`) is asking for premise 2's
	promotion-first rule applied in the interpreter. Count OP count stays
	a count, so nothing that was already integral moves.  */
	/*  ⚠ A NULL OPERAND IS REACHABLE AND WAS F-36's SECOND CRASH. Guarded
	2026-09-01. A refusing UNARY returns null -- `*x` on a field holding no
	group prints `ERROR unary * on x` and returns null -- and that null
	arrives here as the right operand of the very next operator. Reading
	`argument.isCOUNT` on it dies at 139.
	This is why `* *x` crashed in PRINT-ITEM position: the leading spaced `*`
	is BINARY MULTIPLY (there is an operand to its left), and its right
	operand is the refused inner unary. The star was never the subject; a
	refusing operand feeding the next operator is.
	REFUSE BY NAME, which is what the operator already does for a wrong TYPE
	-- a missing operand is simply the other way it cannot apply.  */
	if ( !argument )
		{
		return ::refuse(target,"Operator * -- an operand that is nothing");
		}
	if ( isCOUNT(argument->groupBody->flags.data) || isNUMBER(argument->groupBody->flags.data) )
		if ( isNUMBER(target->groupBody->flags.data) || isNUMBER(argument->groupBody->flags.data) )
			GroupControl::groupController->groupRules->tempField->setNumber(target->getNumber() * argument->getNumber());
		else
		if ( isCOUNT(target->groupBody->flags.data) )
			GroupControl::groupController->groupRules->tempField->setCount(target->getCount() * argument->getCount());
	if ( !GroupControl::groupController->groupRules->tempField->groupBody->flags.data )
		{
		return ::refuse(target,"Operator * -- cannot apply to these operands");
		}
	return GroupControl::groupController->groupRules->tempField;
}

/***************************************************************************
	Rule action for the *= operator
***************************************************************************/
extern "C" GroupItem *opMultiplyEQ(GroupItem *argument, GroupItem *target)
{
GroupItem 	*result = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	/*  THE STORE RULING: an armed statement stores nothing.
	Instruct.opMultiplyEQ.storeRuling  */
	if ( ruler->refused )
		return 0;
	if ( ruler->jitting )
		{
		 jitEmitBinary(argument, target, jitMul);
		return jitEmitAssign(target, target); 
		}
	if ( target->groupBody->flags.data && argument->groupBody->flags.data )
		{
		if ( isCOUNT(target->groupBody->flags.data) )
			{
			ruler->tempField->setNumber(target->getNumber() * argument->getNumber());
			target->groupBody->gCount = ruler->tempField->getCount();
			}
		else
		if ( isNUMBER(target->groupBody->flags.data) )
			target->groupBody->gNumber *= argument->getNumber();
		result = target;
		if ( !result )
			::fprintf(stderr,"ERROR Operator += failed on %s and %s\n",target->groupBody->tag,argument->groupBody->tag);
		}
	else
	if ( isLIST(argument->groupBody->flags.binType) )
		while ( result = argument->prior(result) )
			::opMultiplyEQ(result,target);
	return result;
}

/***************************************************************************
	Rule action for ! operator
***************************************************************************/
extern "C" GroupItem *opNOT(GroupItem *result)
{
	if ( !result->contents() )
		return GroupControl::groupController->groupRules->trueResult;
	return 0;
}

/***************************************************************************
	Rule action for the != operator
***************************************************************************/
extern "C" GroupItem *opNotEQ(GroupItem *argument, GroupItem *target)
{
	if ( GroupControl::groupController->groupRules->jitting )
		{
		 return jitEmitCompare(argument, target, jitNE); 
		}
	if ( target && !target->groupBody->flags.data )
		{
		if ( isCOUNT(argument->groupBody->flags.data) || isNUMBER(argument->groupBody->flags.data) )
			if ( argument->groupBody->gCount != 0 )
				return GroupControl::groupController->groupRules->trueResult;
		}
	else
	if ( argument && !argument->groupBody->flags.data )
		{
		if ( isCOUNT(target->groupBody->flags.data) || isNUMBER(target->groupBody->flags.data) )
			if ( target->groupBody->gCount != 0 )
				return GroupControl::groupController->groupRules->trueResult;
		}
	else
	if ( ::compareValues(target,argument) )
		return GroupControl::groupController->groupRules->trueResult;
	return 0;
}

/***************************************************************************
	Rule action for the OR operator
***************************************************************************/
extern "C" GroupItem *opOR(GroupItem *argument, GroupItem *target)
{
	if ( ::truthOf(target) || ::truthOf(argument) )
		return GroupControl::groupController->groupRules->trueResult;
	return GroupControl::groupController->groupRules->falseResult;
}

/***************************************************************************
	Rule action for the + operator
***************************************************************************/
extern "C" GroupItem *opPlus(GroupItem *argument, GroupItem *target)
{
	if ( GroupControl::groupController->groupRules->jitting )
		{
		 return jitEmitBinary(argument, target, jitAdd); 
		}
	/*  ⚠⚠ F-41, 2026-09-01: A REFUSED OPERAND IS NOT A NUMBER, AND READING IT
	WAS A LATENT 139 IN SEVEN OPERATORS AT ONCE. A refusing unary returns
	null -- `*x` on a field holding no group prints its own error and hands
	back nothing -- and that null arrives here as the right operand. Every
	`argument.` read below dies on it.
	Measured on opMultiply during F-36 (opMultiply+76, GroupRules.mm:9903,
	from runOP <- appendPrintXP <- aCTionPrinT); the other six were censused
	structurally -- zero `if !argument` guards against 3 to 6 dereferences
	each -- and are guarded here on that basis rather than on seven separate
	crashes.
	⚠ WHY NOW RATHER THAN WHEN IT BITES: unary `*` is quarantined from the
	corpus until the flip, so refused operands are rare TODAY. The flip makes
	them ordinary, and `a + *b` is a spelling the +* fixture is about to put
	in front of people. This is the arm-the-latent-bug pattern caught one
	stroke early instead of one stroke late.
	REFUSE BY NAME. A missing operand is simply the other way an operator
	cannot apply, beside the wrong-type case each already names.  */
	if ( !argument )
		{
		return ::refuse(target,"Operator + -- an operand that is nothing");
		}
	if ( target->groupBody->flags.data && (isCOUNT(argument->groupBody->flags.data) || isNUMBER(argument->groupBody->flags.data)) )
		{
		/*  BINARY FAMILY PROMOTES (Tony, 2026-08-01, greenlight after Word 2).
		`.count` on a double operand narrowed it AT ENTRY, so 0 - 2.5 gave
		-3 as a COUNT before anything else ran. ⚠ THE FIX IS PROMOTION, NOT
		THE COMPOUND FAMILY'S NARROW-AT-RESULT: a binary op has NO COUNT SLOT
		to narrow into -- its result is a fresh temp -- so the ruling's POP
		(`0 - 2.5 -> -2.5 TYPED DOUBLE`) is asking for premise 2's
		promotion-first rule applied in the interpreter. Count OP count stays
		a count, so nothing that was already integral moves.  */
		if ( isNUMBER(target->groupBody->flags.data) || isNUMBER(argument->groupBody->flags.data) )
			GroupControl::groupController->groupRules->tempField->setNumber(target->getNumber() + argument->getNumber());
		else
		if ( isCOUNT(target->groupBody->flags.data) )
			GroupControl::groupController->groupRules->tempField->setCount(target->groupBody->gCount + argument->getCount());
		else
		if ( isSTRING(target->groupBody->flags.data) || isTOKEN(target->groupBody->flags.data) )
			if ( target->groupBody->gCount > argument->getCount() )
				GroupControl::groupController->groupRules->tempField->setText(target->groupBody->gText + argument->getCount());
			else	::fprintf(stderr,"opPlus WARNING: tried to advance a string past its length on %s -- the value stands\n",target->groupBody->tag);
		}
	if ( !GroupControl::groupController->groupRules->tempField->groupBody->flags.data )
		{
		return ::refuse(target,"Operator + -- cannot apply to these operands");
		}
	return GroupControl::groupController->groupRules->tempField;
}

/***************************************************************************
	Rule action for the += operator.

    ⚠⚠ THE TABLE-ARC PROBE (T1, 2026-08-01): SHARED DISPATCH, FORKED LEAVES.
    This op is the worked example for the whole table arc, so the shape matters
    more than the op does.

    WHAT CHANGED: the `if jitting` gate USED TO SIT AT THE TOP OF THE FUNCTION
    and re-decide isSTRING/isTOKEN/isCOUNT/isNUMBER -- the very question the
    switch below already answers from the carried `datA`. Two decisions, one
    fact, and they can disagree. That disagreement is not hypothetical: it is
    exactly why jit.md S3.5 can list SEVEN ops whose gate fires assuming a
    numeric target, and why the same list called the compound family
    "list-blind" -- the top gate never saw the list arms above the switch.

    NOW: ONE dispatch tree, and each LEAF forks do-vs-emit. A forked leaf cannot
    disagree with itself, because there is only one place the type is read.

    THE THREE LEAF KINDS, per T1:
      scalar  count/number  -> emit (jitEmitBinary + store-back)
              string/token  -> emit (jitEmitStringPlusEQ, the ruled two-arg
                               exception and the layer's only CreateCall)
      fallback / uncovered  -> DEGRADE LOUDLY. Buffer, Stak and the default arm
                               call jitDegrade and then RUN THE INTERPRETED BODY.
    ⚠ THE DEGRADE ARMS ARE THE POINT, not decoration. jitDegrade had ZERO call
    sites after the iterator rework, so every ladder rung's `degrade count = 0`
    was VACUOUS -- true, but unable to move. These are its first real citizens:
    the counter can now be moved by a construct, so the assertion means something
    again.

    ⚠ THE DEGRADE IS NOW EXHAUSTIVE, and that is what turns it into a guarantee.
    The first cut covered only the switch's leaves and left the three arms ABOVE
    it (35a list-concat, copyListTo, the `binType || groupList` append) plus the
    two tail arms silent. They are list/structure shaped, have no emitter, and
    under jitting would EXECUTE AT EMIT TIME -- the side effect happening once at
    compile time while the compiled code does nothing, which is the "it appears
    to work and it lies" failure. The old top gate HID that by returning before
    them for scalar targets; it never fixed it.
    EVERY arm of this function now either EMITS or DEGRADES LOUDLY. A partial
    guarantee is not one: with any arm left silent, "no degrade fired" would mean
    "covered OR silently fell through", which is precisely the ambiguity T1 was
    written to remove.
    ⚠ NOTE WHAT A DEGRADE ON A SIDE-EFFECTING ARM ACTUALLY BUYS. It does not make
    emit-time execution correct -- it makes it COUNTED. That is S0's crossover
    policy exactly: degrade to the oracle LOUDLY. The divergence is still
    divergence; it is no longer invisible.
***************************************************************************/
extern "C" GroupItem *opPlusEQ(GroupItem *argument, GroupItem *target)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	/*  THE STORE RULING: an armed statement stores nothing.
	Instruct.opPlusEQ.storeRuling  */
	if ( ruler->refused )
		return 0;
	if ( isLIST(argument->groupBody->flags.binType) && (!target->groupBody->flags.data || isSTRING(target->groupBody->flags.data) || isTOKEN(target->groupBody->flags.data)) )
		{
		if ( ruler->jitting )
			jitDegrade("+= list-concat into a string target",target);
		Buffer *concatBuf = (Buffer*)ruler->bufferSTAK->pop();
		if ( !concatBuf )
			concatBuf = new Buffer("concat buffer");
		if ( target->groupBody->flags.data )
			::appendGroup(target,0,concatBuf);
		::appendGroup(argument,0,concatBuf);
		return ::opString(target,concatBuf);
		}
	if ( isLIST(argument->groupBody->flags.binType) )
		{
		if ( ruler->jitting )
			jitDegrade("+= copyListTo a list argument",target);
		argument->copyListTo(target);
		}
	else
	if ( !target->groupBody->flags.isRule && !target->groupBody->flags.actionType && (target->groupBody->flags.binType || target->groupBody->groupList) )
		{
		if ( ruler->jitting )
			jitDegrade("+= structural append (binType/groupList)",target);
		target->addMember(argument);
		}
	else
	if ( argument->groupBody->flags.data )
		if ( target->groupBody->flags.data )
			switch (target->groupBody->flags.data)
				{
				case 5:
					if ( ruler->jitting )
						{
						 jitEmitBinary(argument, target, jitAdd);
						return jitEmitAssign(target, target); 
						}
					ruler->tempField->setNumber(target->getNumber() + argument->getNumber());
					target->groupBody->gCount = ruler->tempField->getCount();
					break;
				case 9:
					if ( ruler->jitting )
						{
						 jitEmitBinary(argument, target, jitAdd);
						return jitEmitAssign(target, target); 
						}
					target->groupBody->gNumber += argument->getNumber();
					break;
				case 13:
				case 14:
					if ( ruler->jitting )
						return jitEmitStringPlusEQ(argument,target);
					target->setText(::concat(2,target->getText(),argument->getText()));
					break;
				case 4:
					if ( ruler->jitting )
						jitDegrade("+= on a Buffer target",target);
					target->getBuffer()->appendString(argument->getText(),0,0);
					// if buffer mark is set, argument is inserted into buffer at mark
					// otherwise it is appended at end of buffer. mark is left as is
					break;
				case 12:
					if ( ruler->jitting )
						jitDegrade("+= on a Stak target",target);
					target->groupBody->gStak->push(argument);
					break;
				default:
					if ( ruler->jitting )
						jitDegrade("+= on an unhandled datA",target);
					else	::fprintf(stderr,"ERROR Operator += failed on %s and %s\n",target->groupBody->tag,argument->groupBody->tag);
				}
		else {
			if ( ruler->jitting )
				jitDegrade("+= into a target with no datA",target);
			target->copyData(argument);
			}
	else {
		if ( ruler->jitting )
			jitDegrade("+= with a dataless argument",target);
		target->addMember(argument);
		}
	return target;
}

/***************************************************************************
	Rule action for ++ operator
***************************************************************************/
extern "C" GroupItem *opPlusPlus(GroupItem *result)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	/*  THE STORE RULING: an armed statement stores nothing.
	Instruct.opPlusPlus.storeRuling  */
	if ( ruler->refused )
		return 0;
	/*  POISONED ITERATOR (Tony's ruling, 2026-08-02). Its only reader is here.
	The refusal was already announced once at the Iterate; this is silent
	and simply does not move, so the enclosing `while` exits on the false
	it already trusts -- the loop needed no change at all.  */
	if ( result->groupBody->flags.fLAG )
		return 0;
	if ( result->groupBody->flags.isIterator )
		{
		/*  ⚠ THE JITTING GATE IS INSIDE THE ITERATOR ARM, NOT BELOW IT, AND THE
		PLACEMENT IS THE FIX. Tony's ruling 2026-08-04: an unqualified
		iterate visits EVERY DECLARED CHILD, the interpreter is right, and
		the JIT's 0-visit walk is the defect.
		The old order tested isIterator FIRST and returned, so an iterator
		under ++ never reached the jitting gate below -- it took the
		interpreted arm and EMITTED NOTHING, which is why the compiled
		function contained no loop and visited 0 where the interpreter
		visited 3. The arm below is untouched and remains the definition of
		correct; jitEmitIterStep emits a CALL TO THIS FUNCTION so the two
		cannot drift.  */
		if ( ruler->jitting )
			{
			 return jitEmitIterStep(result); 
			}
		/*  POISONED ITERATOR (Tony's ruling, 2026-08-02). Its only reader is
		here. The refusal was already announced once at the Iterate; this is
		silent and simply does not move, so the enclosing `while` exits on
		the false it already trusts -- the loop needed no change at all.
		
		⚠ MOVED BELOW THE JITTING GATE, 2026-08-05, by the run-time-flag
		census. It used to sit ABOVE it, at the top of the function, where it
		was a RUN-TIME FLAG STEERING THE EMIT WALK -- the sixth member of the
		one-channel-one-meaning family and the same class as aCTionBlocK's
		isBranch break. `fLAG` means "the LAST iterate on this node was
		refused", which is a fact about execution; read at EMIT time, a
		poisoned node would have produced a compiled loop containing NO
		ADVANCE INSTRUCTION AT ALL -- silent, permanent, baked into the
		function.
		It did not bite, and the reason is the danger: aCTionIterate clears
		fLAG on its success path, which happened to run first. Correct by
		accident of ordering, which is exactly what the census was for.
		Below the gate, the poison is evaluated at RUN time inside the
		emitted call to this very function -- which re-enters with jitting
		down and reaches this line properly.  */
		if ( result->groupBody->flags.fLAG )
			return 0;
		//note: because result is an iterator it is not unwrapped in runOP()
		GroupItem *iterator = result->getGroup();
		if ( result->groupBody->flags.hasAttributes )
			iterator = result->nextAttribute(iterator);
		else
		if ( result->groupBody->flags.hasMembers )
			iterator = result->nextMember(iterator);
		else
		if ( !iterator )
			iterator = result->groupBody->groupList->firstInList;
		else	iterator = iterator->nextInParent;
		if ( iterator )
			{
			ruler->lastREF->groupBody->gGroup = iterator;
			ruler->lastREF->groupBody->flags.data = 6;
			iterator->groupBody->flags.isInitialized = 1;
			result->setGroup(iterator);
			}
		else {
			result->setGroup((GroupItem*)0);
			result = 0;
			}
		return result;
		}
	if ( ruler->jitting )
		{
		 return jitEmitUnary(result, jitInc); 
		}
	if ( !result->groupBody->flags.data )
		result->setCount(1);
	else
	if ( isCOUNT(result->groupBody->flags.data) )
		result->groupBody->gCount++;
	else
	if ( isNUMBER(result->groupBody->flags.data) )
		result->groupBody->gNumber++;
	else
	if ( isSTRING(result->groupBody->flags.data) || isTOKEN(result->groupBody->flags.data) )
		if ( result->groupBody->gCount == 0 )
			result->setText((char*)0);
		else {
			result->groupBody->gText++;
			result->groupBody->gCount--;
			}
	else	return ::refuse(result,"Operator ++ -- not supported for this data type");
	return result;
}

/*****************************************************************************
	=* as unary op to make its argument a pointer
*****************************************************************************/
extern "C" GroupItem *opPointer(GroupItem *field)
{
	// Fired as a noPrint definition attribute (setPointer), fLAG is set on the
	// command node — redirect to its parent (the field being defined), a la
	// processFlags/rEGISTER. As the =* unary op, fLAG is clear and we mark the
	// operand directly.
	if ( field->groupBody->flags.fLAG )
		field = field->parent;
	field->groupBody->flags.isPointer = 1;
	return field;
}

/***************************************************************************
	operator method for the print rule.
***************************************************************************/
extern "C" GroupItem *opPrint(GroupItem *target, Buffer *buffer)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
char 		*printText = buffer->string();
	if ( printText )
		if ( ruler->toBUFFER )
			ruler->toBUFFER->appendString(printText,0,0);
		else	::printf("%s",printText);
	else	::fprintf(stderr,"print: recieved no print text\n");
	buffer->reset();
	ruler->bufferSTAK->push(buffer);
	ruler->useDefaultSpace = 1;
	return ruler->trueResult;
}

/***************************************************************************
	Rule action for the <- rebind operator — the clean slot rebind.
    Sets the LHS local's group to the evaluated RHS node, with NO byRef
    stamp (unlike :=) and no content copy (unlike =). This is exactly the
    pointer-set aCTionScopeXP uses (local.group = node), wired to a runtime
    RHS instead of a name lookup -- giving a fresh stampable handle each
    loop pass:  cell <- argument :+ new(nm);
***************************************************************************/
extern "C" GroupItem *opRebind(GroupItem *argument, GroupItem *target)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	/*  THE STORE RULING: an armed statement stores nothing.
	Instruct.opRebind.storeRuling  */
	if ( ruler->refused )
		return 0;
	if ( argument )
		target->setGroup(argument);
	return target;
}

/***************************************************************************
	Rule action for the % integer div operator
***************************************************************************/
extern "C" GroupItem *opRem(GroupItem *argument, GroupItem *target)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	/*  THE FALLBACK COLUMN'S FIRST REAL CUSTOMER. Rather than reimplementing
	remainder in IR, emit a CALL to this very function and unbox its result
	-- the shape every non-scalar op will use. The gate returns before the
	interpreted body, exactly like the arithmetic gates.  */
	if ( ruler->jitting )
		{
		 return jitEmitRem(argument, target, ruler->tempField); 
		}
	if ( (isCOUNT(target->groupBody->flags.data) || isNUMBER(target->groupBody->flags.data)) && (isCOUNT(argument->groupBody->flags.data) || isNUMBER(argument->groupBody->flags.data)) )
		ruler->tempField->setCount(target->getCount() % argument->getCount());
	/*  ⚠ PROMOTED 2026-09-05 FROM SENTINEL-AS-DATA. This announced the failure
	and then returned `tempField` -- which at this point HAS NO DATA, so the
	caller received a field that looks like an answer and reads back as its
	own tag. The failure reached a human and was concealed from the program.
	Instruct.opRem.storeRuling  */
	if ( !ruler->tempField->groupBody->flags.data )
		return ::refuse(target,"Operator % -- cannot apply to these operands");
	return ruler->tempField;
}

/***************************************************************************
	Rule action for the :% replace operator.
***************************************************************************/
extern "C" GroupItem *opReplaceAttribute(GroupItem *argument, GroupItem *target)
{
GroupItem 	*grup = 0;
GroupItem 	*added = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	/*  THE STORE RULING: an armed statement stores nothing.
	Instruct.opReplaceAttribute.storeRuling  */
	if ( ruler->refused )
		return 0;
	if ( isLIST(argument->groupBody->flags.binType) )
		while ( grup = argument->prior(grup) )
			{
			added = target->replace(grup);
			added->options.affiliation = 1;
			}
	else {
		added = target->replace(argument);
		added->options.affiliation = 1;
		}
	return target;
}

/***************************************************************************
	Rule action for the :+ replace operator.
***************************************************************************/
extern "C" GroupItem *opReplaceMember(GroupItem *argument, GroupItem *target)
{
GroupItem 	*grup = 0;
GroupItem 	*added = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	/*  THE STORE RULING: an armed statement stores nothing.
	Instruct.opReplaceMember.storeRuling  */
	if ( ruler->refused )
		return 0;
	if ( isLIST(argument->groupBody->flags.binType) )
		while ( grup = argument->prior(grup) )
			{
			added = target->replace(grup);
			added->options.affiliation = 2;
			}
	else {
		added = target->replace(argument);
		added->options.affiliation = 2;
		}
	return target;
}

/***************************************************************************
	Rule action for the :. operator — the inverse of opDot. Where opDot reads
    a groupField property off target, opSetFlag toggles the flag named by the
    groupField argument ON the target. Explicit operands (target . argument)
    sidestep the processFlags item.tag command-detection problem.
        cellA :. mergeON    toggles mergeOn on cellA
    Extend by adding the relevant gCount case (see groupFields in setup).
***************************************************************************/
extern "C" GroupItem *opSetFlag(GroupItem *argument, GroupItem *target)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*flagDef = 0;
	/*  THE STORE RULING: an armed statement stores nothing.
	Instruct.opSetFlag.storeRuling  */
	if ( ruler->refused )
		return 0;
	if ( !argument )
		if ( ruler->lastREF )
			{
			argument = target;
			target = ruler->lastREF->getGroup();
			}
		else	::fprintf(stderr,"opSetFlag: lastREF not set\n");
	if ( !argument || !target )
		{
		::fprintf(stderr,"opSetFlag: missing operand\n");
		return target;
		}
	flagDef = ruler->groupFields->get(argument->groupBody->tag);
	if ( !flagDef )
		{
		::fprintf(stderr,"opSetFlag: argument %s is NOT a groupField\n",argument->groupBody->tag);
		return target;
		}
	/*  ⚠⚠ `:.` SETS. IT DOES NOT TOGGLE. Tony's ruling, 2026-08-17.
	A toggle makes "make sure this flag is on" UNWRITABLE -- there is no
	idempotent spelling, so every site is a bet about the current state and
	the odds depend on whatever C++ hygiene ran first. Measured the
	expensive way: a defensive `CodE :. noPrinT` in genParseTest was
	CLEARING a flag that was already set, which let the walk descend into
	the generated attribute, which masked a printTO leak, which made the run
	appear to terminate. ONE TOGGLE, THREE SYMPTOMS, mutually masking.
	Census before the ruling, 12 executable sites: ZERO relied on
	clear-by-second-toggle, and FIVE were actively BROKEN by it -- the
	isPercenT sites in incant/utilities target reused locals inside loops,
	so every other cell silently lost its percent sizing. Set fixes five and
	breaks none. If a toggle is ever wanted, it gets its own spelling then.
	
	⚠ THE ENUM-VALUED FLAGS ARE PASSTHROUGH WITH LITERAL VALUES AND HAVE TO
	BE. binType and actionType are ENUMS, not bitfields -- isBIN 1,
	isCLASS 2, isLIST 3, isREGISTRY 4; isAction 1, isCoded 2
	(GroupBody.h:65-78). Writing `target.isLIST = true` generates
	`binType = !isLIST(binType)`, because tok renders the accessor as its
	TEST MACRO on the left of an assignment too -- so it assigns 0 or 1 and
	can NEVER assign 3. Measured: `x :. isCodeD` was assigning actionType 1,
	which is isACTION. That is why compile refused every generated rule
	while the actionTypE gate still closed -- the gate was reading a flag
	the wrong write had set. One bad spelling, two false readings.
	Setting an enum CLOBBERS whatever it was, which is inherent to an enum
	and is the intended meaning of "set this kind".  */
	if ( argument && target )
		switch (flagDef->groupBody->gCount)
			{
			case 12:
				target->groupBody->flags.fLAG = 1;
				break;
			case 21:
				target->groupBody->flags.isPercent = 1;
				break;
			case 25:
				target->groupBody->flags.isVirtual = 1;
				break;
			case 26:
				target->groupBody->flags.mergeOn = 1;
				break;
			case 29:
				target->groupBody->flags.noPrint = 1;
				break;
			case 31:
				target->groupBody->flags.byRef = 1;
				/*  hasNewParse -- THE ARTIFACT GATE, 2026-08-24. Ruled on
				architectural grounds: a generated parse body's address must be
				FACE-PROOF BY CONSTRUCTION, so it parks as a noPrint member on
				the shared child list (processCode's proven pattern) and this
				flag is the cheap test that says one is there. The rStuff field
				spelling for parseMethod/actionMethod retires behind it.  */
				break;
			case 41:
				target->groupBody->flags.hasNewParse = 1;
				break;
			case 32:
				 target->groupBody->flags.binType = 3; 
				break;
			case 33:
				 target->groupBody->flags.binType = 1; 
				break;
			case 40:
				 target->groupBody->flags.actionType = 2; 
				/*  isActioN -- THE WRITE HALF. The read half (opDot case 408) has
				existed since incant/enumT; only the write was missing, so
				`x :. isActioN` printed "no case yet -- gCount 408" and did
				NOTHING. incant/frontier station 6 hit it: the station reported
				PASS while the flag it was setting never took.
				
				⚠ PASSTHROUGH WITH A LITERAL, per the enum paragraph above, and
				for exactly the reason it gives -- `target.isAction = true`
				would generate `actionType = !isAction(actionType)`, which can
				only ever write 0 or 1 by accident of isAction being 1. Here 1
				happens to be right, and that is precisely why it must NOT be
				spelled that way: the next enum case to be added would inherit
				a spelling that is wrong everywhere except by coincidence.
				
				ONE CHANNEL: actionType = 1 is what isAction(button) tests
				(GroupBody.h:74) and what processCode writes when it commissions
				a parsed body (GroupRules.mm:11685). Flag and artifact are
				constitutionally unable to disagree because they are the same
				integer, which is isCodeD's discipline applied to its sibling.  */
				break;
			case 408:
				 target->groupBody->flags.actionType = 1; 
				break;
			default:
				::fprintf(stderr,"opSetFlag WARNING: groupField %s has no case yet -- guessing from gCount %s ; the value stands\n",argument->groupBody->tag,::toStringFromInt(flagDef->groupBody->gCount));
			}
	else	::fprintf(stderr,"opSetFlag: missing operand\n");
	return target;
}

/***************************************************************************
	Rule action for the := set group operator. It stashes argument as isGROUP
    in target without changing its parent or affiliation.

    ⚠ THROUGH setGroup, NOT BY HAND -- ONE SPELLING (R2, Tony 2026-09-03).
    Do not re-inline the gGroup write; and note `x := null` now CLEARS x.
    Instruct.opSetGroup.oneSpelling
***************************************************************************/
extern "C" GroupItem *opSetGroup(GroupItem *argument, GroupItem *target)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	/*  THE STORE RULING: an armed statement stores nothing.
	Instruct.opSetGroup.storeRuling  */
	if ( ruler->refused )
		return 0;
	if ( target )
		target->setGroup(argument);
	return target;
}

/***************************************************************************
	Rule action for the <: set tag operator.
***************************************************************************/
extern "C" GroupItem *opSetTag(GroupItem *argument, GroupItem *target)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	/*  THE STORE RULING: an armed statement stores nothing.
	Instruct.opSetTag.storeRuling  */
	if ( ruler->refused )
		return 0;
	if ( argument )
		target->groupBody->tag = argument->getText();
	return target;
}

/***************************************************************************
	operator method for the string rule.
***************************************************************************/
extern "C" GroupItem *opString(GroupItem *target, Buffer *buffer)
{
	target->setText(buffer->toString());
	buffer->reset();
	GroupControl::groupController->groupRules->bufferSTAK->push(buffer);
	GroupControl::groupController->groupRules->useDefaultSpace = 1;
	return target;
}

/*  opDerefAll RETIRED 2026-09-01 (SEQ 111), with the `**` operator it served.
    Tony's star law: `*x` reads ONE level, `**x` is `*` applied TWICE, and a `*`
    past the leaf refuses. A FIXPOINT IS NOT A SPELLING -- it is a named call or
    nothing. So `**` leaves the operator table AND the UnaryOPS bin,
    longest-match stops merging two stars, and `**x` tokenizes as two unaries
    that COMPOSE.
    Censused before removal: ZERO call sites. The only `**` operator uses in the
    whole corpus were FOUR, all inside fixtures -- derefAllT x2, spacingT x2 --
    and the other 39 textual hits are markdown bold in prose or stale comments
    about the debug marker, which was renamed `**` -> `$$` earlier the same day.
    The certificate that it is gone is incant/starT: `**x` on a ONE-deep pointer
    must REFUSE. If it ever reads, the fixpoint has crept back in.  */
/***************************************************************************
	Rule action for the prefix unary minus (negate). Value-producing like
	opMinus, NOT in-place like opMinusMinus: 0 - operand into tempField; the
	operand is left untouched. Routed here from handleUnary via the named
	"negate" op (ruleMethod=opUnaryMinus), distinct from the binary - slot.
***************************************************************************/
extern "C" GroupItem *opUnaryMinus(GroupItem *result)
{
	if ( GroupControl::groupController->groupRules->jitting )
		{
		 return jitEmitUnary(result, jitNeg); 
		}
	if ( isCOUNT(result->groupBody->flags.data) )
		GroupControl::groupController->groupRules->tempField->setCount(0 - result->groupBody->gCount);
	else
	if ( isNUMBER(result->groupBody->flags.data) )
		GroupControl::groupController->groupRules->tempField->setNumber((double)0 - result->groupBody->gNumber);
	if ( !GroupControl::groupController->groupRules->tempField->groupBody->flags.data )
		{
		return ::refuse(result,"Operator unary - -- cannot apply");
		}
	return GroupControl::groupController->groupRules->tempField;
}

/*******************************************************************************
    ⚠ A BROKEN FRAME IS NOT AN ABSENT OPTIONAL, and the return values say so.
    No `into`, no `term` -> return NULL, which fails the chain loudly. Only the
    real "the optional did not match" leg answers success. One channel, one
    meaning: trueResult out of here means THE CHAIN MAY PROCEED, and a missing
    frame is not that.

    // optContract  optRK is parseRK with ONE leg's answer flipped: attempt term N, on success proceed, on FAILURE restore the cursor and still answer success -- same cursor discipline, only the verdict changes
    // oneShimPerKind  a shim per inner kind rather than one optK deciding LIT-vs-CALL at run time, because planTerm already made that decision and two implementers drift silently
*******************************************************************************/
extern "C" GroupItem *optRK(GroupItem *idx)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*got = 0;
GroupItem 	*into = 0;
GroupItem 	*term = 0;
char 		*from = ruler->atRuleMark;
int 		n = 0;
	if ( !idx )
		return 0;
	n = ::atoi(idx->getText());
	/*  Passthrough for parseRK's reason — tok cannot see a hand-declared
	global. Both locals are referenced OUTSIDE the block as well, which is
	what keeps bear-trap #13 from pruning them.  */
	
	into = gKantLabel;
	term = gKantRule ? gKantRule->get(n) : 0;
	
	if ( !into )
		{
		::fprintf(stderr,"optRK: called outside a kant parse frame -- no label to attach under\n");
		return 0;
		}
	if ( !term )
		{
		::fprintf(stderr,"optRK: no term %s in the current kant parse frame\n",idx->getText());
		return 0;
		}
	got = ::parseR(term,into);
	if ( got )
		return ruler->trueResult;
	ruler->atRuleMark = from;
	if ( ruler->parseTrace )
		::fprintf(stderr,"  optRK term= %s  ABSENT -- cursor restored\n",term->groupBody->tag);
	return ruler->trueResult;
}

/*******************************************************************************
    parkOnMaster -- park the action on the DEFINING rule's rStuff.

    Tony/Clay, 2026-08-29. rStuff is PER NODE and groupBody is SHARED, so
    parking on whatever FACE setParse was handed put the eviction's verified
    copy and the slot it must null on DIFFERENT NODES: the generation walk
    calls setParse on member TERMS, the eviction sweep reaches the MASTER, and
    the master's rStuff had never been parked. evictAction refused nine of ten
    Xpress-cohort rules on exactly that, correctly. Resolving definingRule()
    and parking there too means guard and write interrogate one node.

    ⚠ IT IS A SEPARATE FUNCTION FOR A MEASURED REASON, not for tidiness, and
    the reason is worth more than the function. Written inline in setParse it
    needs two locals -- a GroupItem for the definer and a RuleStuff for its
    stuff -- and tok resolves a bare field name against whichever DECLARED
    field owns that member, later declaration winning. Adding them silently
    re-pointed every bare `parseMethod`, `actionMethod`, `upTo` and `data` in
    the REST of setParse onto the definer and its stuff, including the lines
    ABOVE the insertion: the rStuff refusal began testing the wrong node and
    the whole classification switch began writing the master's slot. It
    compiled clean. Read in the generated .mm it is unmistakable, which is the
    only reason it was caught -- project memory's "verify in the regen .mm".
    A call introduces no declaration, so the caller's resolution cannot move.

    ⚠ ADDITIVE, NOT A MOVE. setParse still parks on the face as well, because
    the actor gate below reads actionMethod off THIS face; park only on the
    master and that read goes null and builtinActoR stops being hung at all.
    Writing both is what makes "the actor gate is untouched" a true sentence.
    The face copy costs nothing -- arm two of the isGroupActorPoison probe
    measured a persisted actionMethod harmless, on its own rebuild.

    ⚠ NO MIGRATION IS OWED: parking happens fresh inside every parser run, so
    re-running the driver IS the migration and no stale face copy survives
    into a new process.
*******************************************************************************/
extern "C" GroupItem *parkOnMaster(GroupItem *field)
{
GroupItem 	*definer = field->definingRule();
RuleStuff 	*defStuff = definer->getRStuff();
	if ( defStuff )
		defStuff->actionMethod = field->groupBody->gMethod;
	return field;
}

/***************************************************************************
    parkParse / fireNewParse -- THE FACE-PROOF ARTIFACT ADDRESS.

    Ruled 2026-08-24 on ARCHITECTURAL grounds, not evidentiary ones: a
    generated parse body's address must be face-proof BY CONSTRUCTION. A rule
    has many faces -- measured, three distinct reference nodes for one ScafKB,
    each with its own RuleStuff -- and rStuff is PER NODE, so an address in it
    is an address in one face. The shared child list is not.

    So the artifact parks as a noPrint ATTRIBUTE tagged `ParsE`, which is
    processCode's proven pattern for exactly this job (GroupActions.rtn:951 --
    `result.noPrint = true; field +% result; field.isAction = true`), and the
    `hasNewParse` flag is the cheap gate that says one is there.

    ⚠ WHY THE MEMBER CARRIES A NAME AND NOT A POINTER. A dlsym'd C++ parse
    method is a function pointer and there is no node to park; a GroupItem can
    hold its NAME. So the artifact stores the name and the fire site resolves
    it, which also means the address survives anything that copies structure
    without copying rStuff -- which is the whole point of the move.
***************************************************************************/
extern "C" int parkParse(GroupItem *rule, char *name)
{
GroupItem 	*artifact = 0;
	if ( !rule )
		return 0;
	artifact = new GroupItem("ParsE");
	artifact->setText(name);
	artifact->groupBody->flags.noPrint = 1;
	rule->addAttribute(artifact);
	rule->groupBody->flags.hasNewParse = 1;
	return 1;
}

/*******************************************************************************
	Process a parseAction
*******************************************************************************/
extern "C" GroupItem *parseAction(GroupItem *field)
{
	if ( parseACTION(field->groupBody->flags.methodType) || !field->getRStuff()->label )
		{
		if ( field->groupBody->gMethod(field) )
			return GroupControl::groupController->groupRules->trueResult;
		}
	else
	if ( field->getRStuff()->label && field->groupBody->gMethod(field->getRStuff()->label) )
		return parseSetLabel(field);
	if ( field->getRStuff()->label )
		field->getRStuff()->label->clear();
	GroupControl::groupController->groupRules->atRuleMark = field->getRStuff()->hereAt;
	return 0;
}

/*******************************************************************************
	Run a wild card test on this group against current input
*******************************************************************************/
extern "C" GroupItem *parseAny(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = field->getRStuff();
int 		counter = 0;
int 		more = 0;
	if ( ruleStuff->checkInput() )
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
			::reportMaxLimit(field);
		else
		if ( counter && counter >= ruleStuff->min )
			{
			if ( ruleStuff->label )
				ruleStuff->label->setToken(ruleStuff->hereAt,counter);
			return parseSetLabel(field);
			}
		}
	if ( ruleStuff->label )
		ruleStuff->label->clear();
	ruler->atRuleMark = ruleStuff->hereAt;
	return 0;
}

/*******************************************************************************
    // bracedControlOrigin  GENERATED by genParse('Braced') and pasted verbatim -- the emitter's own output, byte-identical to the recorded emission, standing as the oracle-bearing control for the bind-read seam
*******************************************************************************/
extern "C" GroupItem *parseBraced(GroupItem *rule)
{
GroupItem 	*into = rule->getRStuff()->parentLabel;
GroupItem 	*label = new GroupItem("Braced");
GroupItem 	*t1 = rule->get(1);
GroupItem 	*t2 = rule->get(2);
GroupItem 	*t3 = rule->get(3);
char 		*from = GroupControl::groupController->groupRules->atRuleMark;
	return ::leaveRule(rule,into,label,from,::lit(t1,"[") && ::parseR(t2,label) && ::lit(t3,"]"));
}

/*******************************************************************************
	Run a character test on this group against current input
*******************************************************************************/
extern "C" GroupItem *parseCharacter(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = field->getRStuff();
int 		counter = 0;
int 		more = 0;
	if ( ruleStuff->checkInput() )
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
			::reportMaxLimit(field);
		else
		if ( counter && counter >= ruleStuff->min )
			{
			if ( ruleStuff->label )
				ruleStuff->label->setToken(ruleStuff->hereAt,counter);
			return parseSetLabel(field);
			}
		}
	if ( ruleStuff->label )
		ruleStuff->label->clear();
	ruler->atRuleMark = ruleStuff->hereAt;
	return 0;
}

/*******************************************************************************
	Process a condition
*******************************************************************************/
extern "C" GroupItem *parseCondition(GroupItem *field)
{
RuleStuff 	*ruleStuff = field->getRStuff();
	if ( ruleStuff->min )
		return GroupControl::groupController->groupRules->trueResult;
	return 0;
}

/*******************************************************************************
    Registry and Container test looks for a field entry that matches the input stream.
*******************************************************************************/
extern "C" GroupItem *parseContainer(GroupItem *field)
{
GroupItem 	*grup = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = field->getRStuff();
PLGset 		*inSet = field->getCharacterSet();
char 		*atInput = ruler->atRuleMark;
int 		advance = 0;
Buffer 		*buffer = ruler->stringBUFFER;
	if ( ruleStuff->checkInput() )
		{
		buffer->reset();
		atInput = ruler->atRuleMark;
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
				return parseSetLabel(field);
				}
			buffer->shorten(1);
			}
		}
	if ( ruleStuff->label )
		ruleStuff->label->clear();
	ruler->atRuleMark = ruleStuff->hereAt;
	return 0;
}

extern "C" GroupItem *parseRK(GroupItem *idx)
{
GroupItem 	*got = 0;
GroupItem 	*into = 0;
GroupItem 	*term = 0;
int 		n = 0;
	if ( !idx )
		return 0;
	n = ::atoi(idx->getText());
	/*  Passthrough for the same reason as the frame above -- tok cannot see a
	hand-declared global. Both locals are referenced OUTSIDE the block as
	well, which is what keeps bear-trap #13 from pruning them.  */
	
	into = gKantLabel;
	term = gKantRule ? gKantRule->get(n) : 0;
	
	if ( !into )
		{
		::fprintf(stderr,"parseRK: called outside a kant parse frame -- no label to attach under\n");
		return 0;
		}
	if ( !term )
		{
		::fprintf(stderr,"parseRK: no term %s in the current kant parse frame\n",idx->getText());
		return 0;
		}
	got = ::parseR(term,into);
	if ( got )
		return GroupControl::groupController->groupRules->trueResult;
	return 0;
}

/*****************************************************************************
     Parse a rule.
*****************************************************************************/
extern "C" GroupItem *parseRule(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*pMethod = field->get("builtinParsE");
GroupItem 	*code = field->get("CodE");
GroupItem 	*result = 0;
GroupItem 	*grup = 0;
RuleStuff 	*ruleStuff = pMethod->getRStuff();
	// assumes processCode was run on field already
	/*  MEASUREMENT 1, setParentLabel brief. TEMPORARY, parseTrace gated.
	Which parent can a parseMethod see from the field handed in: the
	structural one, or the per-invocation parse-time one? Prints both with
	POINTERS, because the discriminator is recursion -- one structural node
	in flight at two depths prints the same address twice.
	No percent-dash in the format string; that token closes passthrough.  */
	
	if ( GroupControl::groupController->groupRules->parseTrace )
	::fprintf(stderr,"PARENTPROBE %s self=%p parent=%p parentTag=%s stuff=%p parentLabel=%p parentLabelTag=%s\n",
	field->groupBody->tag,
	(void*)field,
	(void*)field->parent,
	field->parent ? field->parent->groupBody->tag : "(none)",
	(void*)field->rStuff,
	field->rStuff ? (void*)field->rStuff->parentLabel : (void*)0,
	(field->rStuff && field->rStuff->parentLabel) ? field->rStuff->parentLabel->groupBody->tag : "(none)");
	
	if ( ruleStuff->checkInput() )
		{
		if ( isAction(field->groupBody->flags.actionType) )
			{
			while ( grup = code->nextAttribute(grup) )
				if ( grup->groupBody->flags.isLocal && !grup->groupBody->flags.isRule && !grup->groupBody->flags.noPrint && grup->groupBody != field->groupBody )
					grup->clear();
			// here the parse action in method gets run
			if ( result = field->get("BlocK") )
				{
				result = result->groupBody->gMethod(result);
				if ( result )
					result->groupBody->flags.isBranch = 0;
				}
			else	::reportNoBody(field);
			}
		if ( result )
			{
			ruleStuff->label = result;
			return parseSetLabel(field);
			}
		}
	if ( ruleStuff->label )
		ruleStuff->label->clear();
	ruler->atRuleMark = ruleStuff->hereAt;
	return 0;
}

/*******************************************************************************
    // parseRuleMethod  binds a compiled parse to rStuff.parseMethod. ⚠ definingRule(), NOT parent -- a cross-file re-definition binds a satellite the reader never looks at
*******************************************************************************/
extern "C" GroupItem *parseRuleMethod(GroupItem *input)
{
char 		*name = input->getText();
RuleStuff 	*stuff = 0;
int 		live = 0;
	if ( input->groupBody->flags.fLAG )
		if ( name )
			{
			GroupItem 	*grup = input->parent;
			if ( grup )
				{
				GroupItem 	*ruleNode = grup->definingRule();
				stuff = ruleNode->ensureRStuff();
				live = ::countRuleTerms(ruleNode);
				if ( !stuff->termCount )
					::fprintf(stderr,"parseMethod: WARNING binding %s to %s with no parseTerms -- indices unguarded\n",name,grup->groupBody->tag);
				else
				if ( stuff->termCount != live )
					{
					::fprintf(stderr,"parseMethod: REFUSING to bind %s to %s\n",name,grup->groupBody->tag);
					::fprintf(stderr,"             emitted against %s terms, rule now has %s\n",::toStringFromInt(stuff->termCount),::toStringFromInt(live));
					return ruleNode->getGroup();
					}
				setParseMethod(stuff,name);
				/*  CHANGE 4, 2026-08-24 -- THE SWEEP IS ONE SITE. Every
				`parseMethod=` writer in the tree routes through here:
				incant/kantParse1, bindSeamB, bracedK, treeScratch,
				genScratch, termScratch and parseCode all use the define-
				attribute spelling, so migrating this line migrates them
				all and NO WRITER IS LEFT WRITING AN ADDRESS NOTHING READS.
				⚠ THE rStuff WRITE ABOVE IS DELIBERATELY KEPT FOR NOW: the
				old address still has live readers (parse()'s descent path
				among them), and removing it in the same commit that adds
				the new one would make a regression indistinguishable from
				a migration defect. Retiring the field spelling is its own
				step, taken once the gate is proven.  */
				::parkParse(ruleNode,name);
				
				if ( GroupControl::groupController->groupRules->parseTrace )
				{
				GroupItem *bDefiner = grup->definingRule();
				RuleStuff *bDefStuff = bDefiner ? bDefiner->rStuff : 0;
				::fprintf(stderr,"SEAM bind  %s  boundNode=%p boundStuff=%p ownRStuffField=%p\n",
				grup->groupBody->tag,(void*)grup,(void*)stuff,(void*)grup->rStuff);
				::fprintf(stderr,"SEAM read  %s  definer=%p defStuff=%p defParseMethod=%p  boundParseMethod=%p\n",
				grup->groupBody->tag,(void*)bDefiner,(void*)bDefStuff,
				bDefStuff ? (void*)bDefStuff->parseMethod : (void*)0,
				(void*)stuff->parseMethod);
				}
				
				}
			else	::fprintf(stderr,"parseMethod: no rule to bind to\n");
			}
		else	::fprintf(stderr,"parseMethod: expected a method name in text\n");
	else	::fprintf(stderr,"parseMethod: should be invoked as a definition attribute\n");
	return input->getGroup();
}

/*  === GENERATED by genParse('Scaf'), pasted verbatim (rung-1 emission) === */
extern "C" GroupItem *parseScaf(GroupItem *rule)
{
GroupItem 	*into = rule->getRStuff()->parentLabel;
GroupItem 	*label = new GroupItem("Scaf");
GroupItem 	*t1 = rule->get(1);
char 		*from = GroupControl::groupController->groupRules->atRuleMark;
	return ::leaveRule(rule,into,label,from,::lit(t1,"x"));
}

/*  === GENERATED by genParse('Scaf2'), pasted verbatim (rung-2 emission) === */
extern "C" GroupItem *parseScaf2(GroupItem *rule)
{
GroupItem 	*into = rule->getRStuff()->parentLabel;
GroupItem 	*label = new GroupItem("Scaf2");
GroupItem 	*t1 = rule->get(1);
GroupItem 	*t2 = rule->get(2);
char 		*from = GroupControl::groupController->groupRules->atRuleMark;
	return ::leaveRule(rule,into,label,from,::lit(t1,"{") && ::lit(t2,"}"));
}

/*  === GENERATED by genParse('ScafA'), pasted verbatim (rung-4 callee) === */
extern "C" GroupItem *parseScafA(GroupItem *rule)
{
GroupItem 	*into = rule->getRStuff()->parentLabel;
GroupItem 	*label = new GroupItem("ScafA");
GroupItem 	*t1 = rule->get(1);
char 		*from = GroupControl::groupController->groupRules->atRuleMark;
	return ::leaveRule(rule,into,label,from,::lit(t1,"a"));
}

extern "C" GroupItem *parseScafALT(GroupItem *rule)
{
GroupItem 	*into = rule->getRStuff()->parentLabel;
GroupItem 	*t1 = rule->get(1);
GroupItem 	*t2 = rule->get(2);
char 		*from = GroupControl::groupController->groupRules->atRuleMark;
	return ::leaveAlt(rule,from,::parseR(t1,into) || ::parseR(t2,into));
}

/*  === GENERATED by genParse('ScafB'), pasted verbatim (rung-4 caller) ===
    ScafB's first term is a REFERENCE to ScafA, so the leaf is parseR, not lit.
    This is the rung the whole ladder above 4 depends on: parseR hands the term
    to parse(), parse() resolves parseMethod from the DEFINING rule, and
    parseScafA runs -- reached through a reference term that was never bound
    and has its own rStuff.  */
extern "C" GroupItem *parseScafB(GroupItem *rule)
{
GroupItem 	*into = rule->getRStuff()->parentLabel;
GroupItem 	*label = new GroupItem("ScafB");
GroupItem 	*t1 = rule->get(1);
GroupItem 	*t2 = rule->get(2);
char 		*from = GroupControl::groupController->groupRules->atRuleMark;
	return ::leaveRule(rule,into,label,from,::parseR(t1,label) && ::lit(t2,"b"));
}

extern "C" GroupItem *parseScafC(GroupItem *rule)
{
GroupItem 	*into = rule->getRStuff()->parentLabel;
GroupItem 	*label = new GroupItem("ScafC");
GroupItem 	*t1 = rule->get(1);
GroupItem 	*t2 = rule->get(2);
char 		*from = GroupControl::groupController->groupRules->atRuleMark;
	return ::leaveRule(rule,into,label,from,::manyScafC1(label,t1) && ::lit(t2,"c"));
}

/*  === GENERATED by genParse('ScafE'/'ScafF'), pasted verbatim (rung-6) ===
    ScafE isRule "e"- ScafA? "f"-;   — optional REFERENCE
    ScafF isRule "f"- ","?- "g"-;    — optional noLabel LITERAL
    The two shapes the census actually contains. The optional sits between two
    MANDATORY terms deliberately: an optional that swallows a following failure
    is the same defect as optional-as-mandatory, inverted, and only a mandatory
    neighbour can catch it.  */
extern "C" GroupItem *parseScafE(GroupItem *rule)
{
GroupItem 	*into = rule->getRStuff()->parentLabel;
GroupItem 	*label = new GroupItem("ScafE");
GroupItem 	*t1 = rule->get(1);
GroupItem 	*t2 = rule->get(2);
GroupItem 	*t3 = rule->get(3);
char 		*from = GroupControl::groupController->groupRules->atRuleMark;
	return ::leaveRule(rule,into,label,from,::lit(t1,"e") && (::parseR(t2,label) || 1) && ::lit(t3,"f"));
}

extern "C" GroupItem *parseScafF(GroupItem *rule)
{
GroupItem 	*into = rule->getRStuff()->parentLabel;
GroupItem 	*label = new GroupItem("ScafF");
GroupItem 	*t1 = rule->get(1);
GroupItem 	*t2 = rule->get(2);
GroupItem 	*t3 = rule->get(3);
char 		*from = GroupControl::groupController->groupRules->atRuleMark;
	return ::leaveRule(rule,into,label,from,::lit(t1,"f") && (::lit(t2,",") || 1) && ::lit(t3,"g"));
}

/*  === GENERATED by genParse, pasted verbatim (rung-7, ALT emission) ===
    ScafALT  ScafA; ScafI;                    — the alternation
    ScafOUT  isRule "("- ScafALT ")"-;        — reaches it as a term
    Note what the ALT frame does NOT have: a `label` local. §2.4 — an
    alternation builds no label of its own and passes `into` straight through,
    so the winning option attaches to the ENCLOSING rule's label. ScafOUT hands
    its own `label` down as that `into`.  */
extern "C" GroupItem *parseScafI(GroupItem *rule)
{
GroupItem 	*into = rule->getRStuff()->parentLabel;
GroupItem 	*label = new GroupItem("ScafI");
GroupItem 	*t1 = rule->get(1);
char 		*from = GroupControl::groupController->groupRules->atRuleMark;
	return ::leaveRule(rule,into,label,from,::lit(t1,"i"));
}

extern "C" GroupItem *parseScafOUT(GroupItem *rule)
{
GroupItem 	*into = rule->getRStuff()->parentLabel;
GroupItem 	*label = new GroupItem("ScafOUT");
GroupItem 	*t1 = rule->get(1);
GroupItem 	*t2 = rule->get(2);
GroupItem 	*t3 = rule->get(3);
char 		*from = GroupControl::groupController->groupRules->atRuleMark;
	return ::leaveRule(rule,into,label,from,::lit(t1,"(") && ::parseR(t2,label) && ::lit(t3,")"));
}

/*******************************************************************************
	Run a character set test on this group against current input
*******************************************************************************/
extern "C" GroupItem *parseSet(GroupItem *field)
{
PLGset 		*set = field->getCharacterSet();
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = field->getRStuff();
int 		counter = 0;
int 		more = 0;
	if ( ruleStuff->checkInput() )
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
			::reportMaxLimit(field);
		else
		if ( counter && counter >= ruleStuff->min )
			{
			if ( ruleStuff->label )
				ruleStuff->label->setToken(ruleStuff->hereAt,counter);
			return parseSetLabel(field);
			}
		}
	if ( ruleStuff->label )
		ruleStuff->label->clear();
	ruler->atRuleMark = ruleStuff->hereAt;
	return 0;
}

/*******************************************************************************
	On rule success deal w/label setting and return true
*******************************************************************************/
extern "C" GroupItem *parseSetLabel(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = field->getRStuff();
	if ( ruleStuff->noAdvance )
		ruler->atRuleMark = ruleStuff->hereAt;
	if ( ruleStuff->label )
		{
		if ( ruleStuff->parentLabel )
			if ( isGROUP(ruleStuff->label->groupBody->flags.data) && ruleStuff->max > 1 )
				{
				ruleStuff->parentLabel->addAttribute(ruleStuff->label->getGroup());
				ruleStuff->label->clear();
				}
			else {
				ruleStuff->parentLabel->addAttribute(ruleStuff->label);
				ruleStuff->label = new GroupItem(field->groupBody->tag);
				}
		return ruleStuff->label;
		}
	return ruler->trueResult;
}

/***************************************************************************
	Parse method for a field w/data = isSTRING or isTOKEN
***************************************************************************/
extern "C" GroupItem *parseString(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = field->getRStuff();
	if ( ruleStuff->checkInput() )
		{
		char 	*matchedString = ruleStuff->rule->matches(ruler->atRuleMark);
		if ( matchedString )
			{
			if ( ruleStuff->label )
				ruleStuff->label->setText(matchedString);
			return ::parseSetLabel(field);
			}
		}
	if ( ruleStuff->label )
		ruleStuff->label->clear();
	ruler->atRuleMark = ruleStuff->hereAt;
	return 0;
}

/*  ⚠ parseTermCount AND parseRuleMethod ARE ONE DECISION AND MOVE TOGETHER --
    this one writes termCount, the other's refusal guard reads it. Leaving one
    on a satellite compares a count nobody wrote against a rule's live terms
    and silently downgrades the refusal to a warning, which still binds.  */
extern "C" GroupItem *parseTermCount(GroupItem *input)
{
char 		*name = input->getText();
RuleStuff 	*stuff = 0;
	if ( input->groupBody->flags.fLAG )
		if ( name )
			{
			GroupItem 	*grup = input->parent;
			if ( grup )
				{
				GroupItem 	*ruleNode = grup->definingRule();
				stuff = ruleNode->ensureRStuff();
				stuff->termCount = ::atoi(name);
				}
			else	::fprintf(stderr,"parseTerms: no rule to record against\n");
			}
		else	::fprintf(stderr,"parseTerms: expected a count in text\n");
	else	::fprintf(stderr,"parseTerms: should be invoked as a definition attribute\n");
	return input->getGroup();
}

/*******************************************************************************
	Process an up to match
*******************************************************************************/
extern "C" GroupItem *parseUpTo(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = field->getRStuff();
	if ( ruleStuff->checkInput() )
		if ( ::testUpTo(field) )
			return ::parseSetLabel(field);
	if ( ruleStuff->label )
		ruleStuff->label->clear();
	ruler->atRuleMark = ruleStuff->hereAt;
	return 0;
}

/*******************************************************************************
    ⚠ IT REFUSES RATHER THAN FALLING THROUGH. A missing or uncoded action
    returns null, which parse() reads as "this rule did not match" -- the
    honest answer -- and says so on stderr once. Falling back quietly to the
    interpretive arm would make an unregistered action indistinguishable from a
    rule that legitimately failed.
    ⚠ ONE CHANNEL, ONE MEANING: this returns what processAction returns and
    invents nothing, so parse()'s caller cannot tell the arms apart by shape.

    // trampolineSeam  rStuff.parseMethod is a C++ function POINTER and a kant method is a GroupItem, so this stands in the slot with the existing signature and forwards -- no layout change, no groups.ext edit
    // kpConvention  rule `Foo` is served by the kant action named `kpFoo`; v1 scaffolding, not load-bearing on the design
*******************************************************************************/
extern "C" GroupItem *parseViaKant(GroupItem *rule)
{
GroupItem 	*action = 0;
GroupItem 	*label = 0;
GroupItem 	*result = 0;
char 		*want = 0;
char 		*from = 0;
char 		*at = 0;
	want = ::concat(2,"kp",rule->groupBody->tag);
	action = GroupControl::groupController->locate(want);
	if ( !action )
		{
		::fprintf(stderr,"parseViaKant: no kant parse action named %s for rule %s\n",want,rule->groupBody->tag);
		return 0;
		}
	/*  ⚠ THE GUARD IS NOT `isCoded`, AND THE FIRST CUT'S WAS. isCoded is
	CONSUMED BY RUNNING -- processAction compiles the body to a cached
	BlocK and clears it -- so an isCoded test passes on fire 1 and REFUSES
	every fire after, which is exactly what the first run of
	incant/kantParse1 measured (row 1 dispatched, rows 2 and 4 reported
	"carries no code"). Bear-trap #25 records the same fact from the
	testing() side. A rule parses many times, so the guard has to hold
	across fires: an action is runnable if it still carries source OR
	already carries the compiled BlocK.  */
	if ( !isCoded(action->groupBody->flags.actionType) && !action->getAttribute("BlocK") )
		{
		::fprintf(stderr,"parseViaKant: %s carries neither code nor a compiled BlocK\n",want);
		return 0;
		}
	if ( GroupControl::groupController->groupRules->parseTrace )
		::fprintf(stderr,"    parseViaKant %s -> %s\n",rule->groupBody->tag,want);
	/*  THE FRAME. Ruled 2026-08-11 (SEQ 54, door (a)): THE MARK NEVER CROSSES.
	A position is not a value, so it cannot travel as kant data at all; and
	keeping it here keeps Invariant R with one writer, which RuleStuff.twk
	says lives in leaveRule/leaveAlt and nowhere else. The kant body says
	WHAT to match; this frame owns WHERE the input is and WHERE results go.
	
	SAVE-AND-RESTORE IN LOCALS, NOT A GLOBAL ASSIGNMENT, because this is
	re-entrant BY CONSTRUCTION: a kant body calls parseRK, which calls
	parse(), which can fork straight back into this function for a nested
	rule. The C++ call stack is the frame stack; nothing else needs to be.  */
	from = GroupControl::groupController->groupRules->atRuleMark;
	label = new GroupItem(rule->groupBody->tag);
	/*  ⚠ THE SAVE/RESTORE IS PASSTHROUGH AND IT HAS TO BE. A hand-declared C++
	global in jitContext.h is invisible to tok's field resolution -- it
	emits `ERROR FieldBody: could not find gKantLabel` straight into the
	.mm, which fails at the C++ compile and names the identifier but not
	the reason. gParseRecordArmed is the precedent and every one of ITS
	uses is inside a passthrough too. Measured 2026-08-11.
	The prior* locals are declared HERE in raw C++ rather than as tok
	locals, because a tok local referenced ONLY inside passthrough is
	pruned as unused (bear-trap #13) and the block would then reference
	an undeclared identifier.  */
	
	GroupItem  *priorLabel = gKantLabel;
	char       *priorFrom  = gKantFrom;
	GroupItem  *priorRule  = gKantRule;
	gKantLabel = label;
	gKantFrom  = from;
	gKantRule  = rule;
	
	result = ::runAction(rule,action);
	
	gKantLabel = priorLabel;
	gKantFrom  = priorFrom;
	gKantRule  = priorRule;
	
	/*  leaveRule's job, done here because this IS the generated arm's exit for
	a kant body. On success return the label and let parse() attach it
	(PC-4: attach-under happens there, once, for every emitted method). On
	failure rewind and return null -- and NO attach, exactly as the C++
	twin. The trace line mirrors leaveRule's word for word so one grep
	reads both arms.  */
	if ( ::truthOf(result) )
		{
		if ( GroupControl::groupController->groupRules->parseTrace )
			::fprintf(stderr,"  WIN  %s  (kant)\n",rule->groupBody->tag);
		return label;
		}
	/*  ⚠ THE R LINE DISCRIMINATES, AND THE FIRST CUT'S DID NOT. It printed
	"mark rewound" unconditionally, which is an absence-shaped assertion
	wearing a value's clothes: it says R OK whether or not the rewind had
	anything to give back, so the one thing a cursor fixture wants to know
	is exactly what it cannot report. leaveRule's own line compares the
	mark at exit against the entry mark and this mirrors it word for word,
	so the kant arm and the C++ arm are diffable rather than merely
	similar. Caught by writing the fixture that depends on it (H4).  */
	at = GroupControl::groupController->groupRules->atRuleMark;
	GroupControl::groupController->groupRules->atRuleMark = from;
	if ( GroupControl::groupController->groupRules->parseTrace )
		{
		::fprintf(stderr,"  FAIL %s  (kant)\n",rule->groupBody->tag);
		if ( at == from )
			::fprintf(stderr,"       R OK   mark unmoved\n");
		else	::fprintf(stderr,"       R OK   mark rewound\n");
		}
	return 0;
}

/*******************************************************************************
    planRule — the §4.1 fold, then one plan node per real term. NULL means the
    whole rule is refused: a plan that is missing a term is worse than no plan.
*******************************************************************************/
extern "C" GroupItem *planRule(GroupItem *rule)
{
RuleStuff 	*rs = rule->getRStuff();
GroupItem 	*plan = 0;
GroupItem 	*term = 0;
GroupItem 	*node = 0;
GroupItem 	*lab = 0;
GroupItem 	*site = 0;
GroupItem 	*at = 0;
GroupItem 	*slot = 0;
int 		literal = 0;
int 		i = 1;
	if ( ::unresolvedTerms(rule) )
		{
		::fprintf(stderr,"  REFUSE rule %s -- %s unmaterialised terms\n",rule->groupBody->tag,::toStringFromInt(::unresolvedTerms(rule)));
		return 0;
		}
	// ruleLevelLiteral  a rule whose OWN data is a quoted literal reuses LIT/LITTO with no new plan kind, split on the rule's own rStuff.noLabel exactly as planTerm splits
	// containerDataDerived  a container is exempt: addGroup builds its character set at add-member time, so its data is a cache of its membership and never an authored alternative
	if ( rule->groupBody->flags.data && !rule->groupBody->flags.binType )
		{
		if ( !isSTRING(rule->groupBody->flags.data) )
			{
			::fprintf(stderr,"  REFUSE rule %s -- rule-level data %s (§4.1 rule-as-data, rung 5)\n",rule->groupBody->tag,::dataName(rule->groupBody->flags.data));
			return 0;
			}
		if ( !rs )
			{
			::fprintf(stderr,"  REFUSE rule %s -- rule-level literal but no rStuff, so LIT vs LITTO is undecidable\n",rule->groupBody->tag);
			return 0;
			}
		literal = 1;
		}
	// tagAsDataFallback  a literal-valued rule legitimately has no terms, and a rule with neither terms nor data is not degenerate -- only `text` answers, carrying its own TAG, which IS the token to match
	/*  ⚠ THE NO-TERMS REFUSAL BELOW STAYS REACHABLE ON PURPOSE. It still fires
	for a no-terms rule with no rStuff, because LIT vs LITTO is undecidable
	without it. A rule whose tag-fallback also comes up empty must refuse
	LOUD rather than emit a match on nothing.  */
	if ( !literal && !::countRuleTerms(rule) && rs )
		literal = 1;
	if ( !literal && !::countRuleTerms(rule) )
		{
		::fprintf(stderr,"  REFUSE rule %s -- no terms at all\n",rule->groupBody->tag);
		return 0;
		}
	if ( rule->groupBody->flags.isRule && rule->groupBody->flags.hasMembers && !rule->groupBody->flags.binType )
		plan = new GroupItem("ALT");
	else {
		plan = new GroupItem("SEQ");
		lab = new GroupItem("label");
		lab->setText(rule->groupBody->tag);
		plan->addAttribute(lab);
		}
	plan->setText(rule->groupBody->tag);
	/*  THE RULE'S OWN LITERAL PLANS FIRST, ahead of any terms, because it is
	what the rule consumes before them. Family B's three rules have no terms
	at all, so the ordering is invisible today and is written for the shape
	rather than for the specimens.
	
	⚠ `at` IS 0 AND THAT IS A MARKER, NOT AN INDEX. Everywhere else `at` is a
	baked rule[] index and term indices are 1-based, so 0 cannot collide with
	one; it reads as "the rule's own data, not a term slot".
	⚠ THE EMIT-SIDE QUESTION THIS PARAGRAPH PARKED IS ANSWERED: ZERO MEANS
	SELF -- marker 0 binds its local to the rule node itself. Ruled and
	landed 2026-08-24, rule-ladder rung two; the convention is stated at the
	emit site in emitPlan. The out-of-scope note below is retired and kept
	only as the trail. Emit was OUT OF
	SCOPE for this charter (§4) and belongs to genKantParse v1 -- this is
	flagged HERE so the emit side inherits the question stated rather than
	discovering an index that indexes nothing.  */
	if ( literal )
		{
		if ( rs->noLabel )
			node = new GroupItem("LIT");
		else {
			node = new GroupItem("LITTO");
			slot = new GroupItem("slot");
			slot->setText(rule->groupBody->tag);
			}
		node->setText(rule->getText());
		at = new GroupItem("at");
		at->setText("0");
		node->addAttribute(at);
		if ( slot )
			node->addAttribute(slot);
		plan->addMember(node);
		}
	while ( term = rule->get(i) )
		{
		if ( !term->groupBody->flags.noPrint )
			{
			node = ::planTerm(term,i);
			if ( !node )
				{
				/*  planTerm has already printed its own refusal line; this
				counts THAT line. planRule's own line below is counted by
				dumpRulePlans, at the call site. See planTally's header.  */
				planTally(1);
				::fprintf(stderr,"  REFUSE rule %s -- term %s unclassified\n",rule->groupBody->tag,term->groupBody->tag);
				return 0;
				}
			if ( ::compare(node->groupBody->tag,"MANY") == 0 )
				{
				site = new GroupItem("site");
				site->setText(::concat(2,rule->groupBody->tag,::toStringFromInt(i)));
				node->addAttribute(site);
				}
			plan->addMember(node);
			}
		i++;
		}
	return plan;
}

/*******************************************************************************
    // tallyAtThreeSites  the charter's two numbers PRINTED rather than grepped, counted at three sites because every refusal is immediately followed by a `return null` -- a measured invariant, and gapB.sh cross-checks the scalar against the grep every run
*******************************************************************************/
extern "C" int planTally(int mode)
{
	
	static int refusals = 0;
	static int planned  = 0;
	if ( mode == 1 )    return ++refusals;
	if ( mode == 2 )    return ++planned;
	if ( mode == 3 )    return refusals;
	if ( mode == 4 )    return planned;
	return -1;
	
}

/*******************************************************************************
    // planVocabulary  the plan is a tree of GroupItems -- resolved decisions, baked literals, NO target syntax -- in five kinds (SEQ ALT LIT LITTO CALL) that grow one at a time as a rung demands one
    // planNotVisitor  a plan and not a visitor because a plan diff is TARGET-INDEPENDENT, refusals validate once for every emitter, and a plan is printable where visitor state is not
    // positiveTestOnly  planTerm turns one term into one plan node or REFUSES -- every node comes from a POSITIVE test, because inheriting setTestMatch's fall-through would make every unclassified term a silent bogus CALL
    // dataBeforeReference  `data` is tested BEFORE the reference test, so a term that is both refuses instead of silently becoming a CALL
*******************************************************************************/
extern "C" GroupItem *planTerm(GroupItem *term, int index)
{
RuleStuff 	*rs = term->getRStuff();
GroupItem 	*definer = term->definingRule();
GroupItem 	*node = 0;
GroupItem 	*at = 0;
GroupItem 	*slot = 0;
GroupItem 	*many = 0;
GroupItem 	*low = 0;
GroupItem 	*opt = 0;
int 		labelled = 0;
	if ( !rs )
		{
		::fprintf(stderr,"  REFUSE %s -- unmaterialised, no rStuff yet\n",term->groupBody->tag);
		return 0;
		}
	if ( upTo(rs->overTo) || upToOver(rs->overTo) )
		{
		::fprintf(stderr,"  REFUSE %s -- upTo/upToOver (not on the ladder yet)\n",term->groupBody->tag);
		return 0;
		}
	/*  CONTAINER (CT, 2026-08-07). isREGISTRY keeps refusing -- a registry is
	not a bin and its consumption was not measured. isBIN is classified in
	the chain below, BEFORE the reference test, because a bin term is also
	a reference and would otherwise plan as a CALL.  */
	if ( isREGISTRY(term->groupBody->flags.binType) )
		{
		::fprintf(stderr,"  REFUSE %s -- registry container (not on the ladder yet)\n",term->groupBody->tag);
		return 0;
		}
	if ( term->groupBody->flags.isMacro )
		{
		::fprintf(stderr,"  REFUSE %s -- macro (not on the ladder yet)\n",term->groupBody->tag);
		return 0;
		}
	if ( term->groupBody->flags.isCondition )
		{
		::fprintf(stderr,"  REFUSE %s -- condition (not on the ladder yet)\n",term->groupBody->tag);
		return 0;
		}
	if ( parseACTION(term->groupBody->flags.methodType) )
		{
		::fprintf(stderr,"  REFUSE %s -- parseAction (tail position only, §2.8)\n",term->groupBody->tag);
		return 0;
		}
	/*  THE REFERENCE TEST COMES BEFORE THE DATA TEST (Clay SEQ 29 item 1).
	
	Content-is-a-group and is-a-reference are ORTHOGONAL -- measured, two
	terms are both (JSONtoken[5] and DatA[2], both NumbeR). Until now `data`
	was tested first, so the overlap refused. That was the right call while
	the precedence was unsettled: refusing a case nobody had reasoned about
	beats guessing at it. It is settled now, and REFERENCE WINS -- a term
	that names another rule is a call, whatever its content happens to be.
	
	What is left over is isGROUP WITHOUT a reference, which is a genuinely
	different construct: a group inlined at the term rather than named. That
	is a NAMED FUTURE KIND -- "inline group" -- and it keeps refusing. It is
	not the same thing as a call and must not quietly become one.
	
	Note what this does NOT change: a term that is both a reference and
	parseACTION still refuses above, on parseACTION. Only the data overlap
	moved.  */
	// containerFirst  a bin term is ALSO a reference, so testing the reference first would plan it as a CALL and emit parseR against something that is not a rule -- container first IS the classification
	// labelledLiteralRepr  a literal term carries its spelling as character DATA, not in its tag, and noLabel is the only discriminator between LIT and LITTO -- keyed to the representation, never to isLiteral, which lies at the read sites that matter
	/*  ⚠ PLACEMENT IS LOAD-BEARING: THIS COMMENT MUST STAY ABOVE THE CHAIN. A
	block comment wedged BETWEEN two arms, immediately before an `or`, wipes
	the whole extern block to zero. Measured three ways 2026-08-16 -- above
	the chain OK, inside an arm body OK, between arms FATAL. Bear-trap #29.  */
	if ( isBIN(term->groupBody->flags.binType) )
		{
		if ( rs->noLabel )
			{
			::fprintf(stderr,"  REFUSE %s -- noLabel container (no spelling yet; the measured specimen is labelled)\n",term->groupBody->tag);
			return 0;
			}
		node = new GroupItem("CONTAINER");
		node->setText(term->groupBody->tag);
		labelled = 1;
		}
	else
	if ( definer != term )
		{
		node = new GroupItem("CALL");
		node->setText(definer->groupBody->tag);
		}
	else
	if ( term->groupBody->flags.data && isSTRING(term->groupBody->flags.data) )
		{
		if ( rs->noLabel )
			node = new GroupItem("LIT");
		else {
			node = new GroupItem("LITTO");
			labelled = 1;
			}
		node->setText(term->getText());
		}
	else
	if ( term->groupBody->flags.data )
		{
		::fprintf(stderr,"  REFUSE %s -- inline group / structural data %s (named future kind)\n",term->groupBody->tag,::dataName(term->groupBody->flags.data));
		return 0;
		}
	else
	if ( !term->contents() )
		{
		if ( rs->noLabel )
			node = new GroupItem("LIT");
		else {
			node = new GroupItem("LITTO");
			labelled = 1;
			}
		node->setText(term->groupBody->tag);
		}
	else {
		::fprintf(stderr,"  REFUSE %s -- no positive classification\n",term->groupBody->tag);
		return 0;
		}
	at = new GroupItem("at");
	at->setText(::toStringFromInt(index));
	node->addAttribute(at);
	if ( labelled )
		{
		slot = new GroupItem("slot");
		slot->setText(term->groupBody->tag);
		node->addAttribute(slot);
		}
	/*  REPETITION (rung 5). Measured min/max shapes across the census: 40 terms
	are plain (1,1); 12 are optional (0,1); 4 are `*` (0,unbounded); 5 are
	`+` (1,unbounded). The unbounded sentinel is 268435457.
	
	OPTIONAL IS REFUSED, and that is a correction, not a gap. Until now an
	optional term planned as a PLAIN CONJUNCT, so it would have emitted as
	MANDATORY -- `lit(t4,",")` where the hand-written model wrote
	`(lit(rule,",") || true)`. A parser that accepts too little is exactly
	the silent-wrongness this rung is supposed to stop producing, so it
	refuses until optionality gets its own kind. One kind per rung.
	
	MANY WRAPS A CALL AND ONLY A CALL. §2.5 is explicit that star and plus
	mean different things for character-level terms than for references, and
	conflating them yields a parser that accepts correctly and builds
	wrongly. Accumulators already refused above on `data`; a repeated
	LITERAL refuses here.  */
	if ( rs->min == 1 && rs->max == 1 )
		return node;
	/*  OPTIONAL (rung 6), the inline form: ((term) || 1).
	
	THE LABEL QUESTION, SETTLED FROM parse() BEFORE EMITTING ANYTHING.
	A non-matching optional takes the min-0 rescue: matchFailed sets
	`sukcess = true` on `kount >= min` BEFORE the debugHere block, so
	debugHere is skipped -- the label is not zeroed and the mark is not
	rewound -- and control reaches generatedExit, which returns the label
	checkInput built. But the ATTACH lives in the loop-s success block
	(`pStuff.label +% label`), which a non-match never reaches. So the
	interpretive path ATTACHES NOTHING for a non-matching optional, and the
	inline form agrees exactly: on failure the callee-s leaveRule attaches
	nothing, on success it attaches. Non-match and match-with-nothing stay
	distinguishable in the tree -- nothing vs an empty child -- which is
	what the code={} actions read.
	
	One divergence, and generated is the tighter of the two: the
	interpretive non-match skips the rewind, so it can leave the mark
	advanced by checkInput-s skip pass, while the generated callee rewinds
	to its own `from`. Both then re-skip before the next term, so it is not
	observable -- recorded rather than relied on.
	
	MEASURED SHAPES, all 12 optionals in the census: 4 are character-level
	(data set) and already refuse above on `data`, alongside the
	accumulators -- so the S2.5 conflation cannot occur here BY
	CONSTRUCTION, and this is one rung rather than two. 6 are references
	and 2 are noLabel literals; those are the two shapes OPT wraps. A
	LABELLED literal optional does not occur, so it refuses rather than
	being designed for.  */
	if ( rs->min == 0 && rs->max == 1 )
		{
		if ( ::compare(node->groupBody->tag,"LITTO") == 0 )
			{
			::fprintf(stderr,"  REFUSE %s -- optional labelled literal (no census shape, not designed for)\n",term->groupBody->tag);
			return 0;
			}
		opt = new GroupItem("OPT");
		opt->setText(node->getText());
		at = new GroupItem("at");
		at->setText(::toStringFromInt(index));
		opt->addAttribute(at);
		opt->addMember(node);
		return opt;
		}
	if ( rs->max > 1 )
		{
		if ( ::compare(node->groupBody->tag,"CALL") != 0 )
			{
			::fprintf(stderr,"  REFUSE %s -- repetition of a non-reference term (rung 5 is iteration only)\n",term->groupBody->tag);
			return 0;
			}
		many = new GroupItem("MANY");
		many->setText(node->getText());
		low = new GroupItem("min");
		low->setText(::toStringFromInt(rs->min));
		many->addAttribute(low);
		at = new GroupItem("at");
		at->setText(::toStringFromInt(index));
		many->addAttribute(at);
		many->addMember(node);
		return many;
		}
	::fprintf(stderr,"  REFUSE %s -- repetition shape min %s max %s has no kind\n",term->groupBody->tag,::toStringFromInt(rs->min),::toStringFromInt(rs->max));
	return 0;
}

/*******************************************************************************
	Print the field passed in to the buffer passed in
*******************************************************************************/
extern "C" void printField(GroupItem *field, char *format, Buffer *buffer)
{
	if ( isMethod(field->groupBody->flags.instructType) )
		field = field->groupBody->gMethod(field);
	if ( !field )
		field = GroupControl::groupController->groupRules->falseResult;
	else
	if ( isGROUP(field->groupBody->flags.data) )
		field = field->getGroup();
	switch (field->groupBody->flags.data)
		{
		case 5:
			if ( !format )
				format = "%d";
			buffer->appendInt(field->groupBody->gCount,0,0);
			break;
		case 9:
			if ( !format )
				format = "%.1f";
			buffer->appendString(::toStringFromDouble(field->groupBody->gNumber),0,0);
			break;
		case 13:
		case 14:
			if ( !format )
				format = "%s";
			buffer->appendString(field->getText(),0,0);
			break;
		case 0:
		default:
			if ( !format )
				format = "%s";
			buffer->appendString(field->getText(),0,0);
		}
	if ( GroupControl::groupController->groupRules->useDefaultSpace )
		buffer->appendChar(' ',0,0);
}

/*******************************************************************************
    printPlan — the plan made visible. This is the mitigation for the plan's own
    cost: a wrong plan is READABLE, an intermediate visitor state is not.
*******************************************************************************/
extern "C" int printPlan(GroupItem *plan, char *pad)
{
GroupItem 	*kid = 0;
GroupItem 	*meta = 0;
char 		*deeper = 0;
	if ( !plan )
		return 0;
	deeper = ::concat(2,pad,"  ");
	::fprintf(stderr,"%s%s %s\n",pad,plan->groupBody->tag,plan->getText());
	meta = plan->getAttribute("label");
	if ( meta )
		::fprintf(stderr,"%s  label=%s\n",pad,meta->getText());
	meta = plan->getAttribute("at");
	if ( meta )
		::fprintf(stderr,"%s  at=%s\n",pad,meta->getText());
	meta = plan->getAttribute("slot");
	if ( meta )
		::fprintf(stderr,"%s  slot=%s\n",pad,meta->getText());
	meta = plan->getAttribute("min");
	if ( meta )
		::fprintf(stderr,"%s  min=%s\n",pad,meta->getText());
	meta = plan->getAttribute("site");
	if ( meta )
		::fprintf(stderr,"%s  site=%s\n",pad,meta->getText());
	while ( kid = plan->nextMember(kid) )
		::printPlan(kid,deeper);
	return 1;
}

/***************************************************************************
	The incant printTO command runs this to set toBUFFER to the buffer in
    bufferField. toBUFFER gets reset. If there is no bufferField toBUFFER
    is set to null. If toBUFFER is not null, opPrint(), invoked by the
    print command via the PrinT rule, writes in toBUFFER instead of stdout
***************************************************************************/
extern "C" GroupItem *printToBuffer(GroupItem *bufferField)
{
	if ( bufferField && isBUFFER(bufferField->groupBody->flags.data) )
		{
		GroupControl::groupController->groupRules->toBUFFER = bufferField->getBuffer();
		GroupControl::groupController->groupRules->toBUFFER->reset();
		}
	else
	if ( GroupControl::groupController->groupRules->toBUFFER )
		{
debugHere:
		GroupControl::groupController->groupRules->toBUFFER = 0;
		}
	else	::fprintf(stderr,"printToBuffer: ignored\n");
	return GroupControl::groupController->groupRules->trueResult;
}

/*  ⚠ THE ARGUMENT IS EXEMPT, and it is what lets the declaration go.
                runAction binds the argument slot BEFORE calling here, so an
                entry clear that includes it wipes the bind. The DECLARED
                attribute escaped this for free -- aCTionDefinE flagged it
                isArgument and never isLocal. A MINTED one does not: with no
                declaration, aCTionNamE creates the name as an action LOCAL
                (ruleActions.rtn, isLocal = true), which lands it squarely in
                this walk. MEASURED 2026-09-05: without this clause the
                declaration sweep took the fleet 185 -> 147, every argument
                reading back as its own tag (bear-trap #26).
                GroupActions.processAction.argumentExempt  */
extern "C" GroupItem *processAction(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = ruler->ruleSTUFF;
GroupItem 	*label = field;
GroupItem 	*code = 0;
GroupItem 	*grup = 0;
GroupItem 	*result = 0;
GroupItem 	*priorMETHOD = ruler->currentMETHOD;
GroupItem 	*priorTempField = ruler->tempField;
GroupItem 	*action = field;
	if ( action->groupBody->flags.isLabel )
		action = ruleStuff->rule;
	ruler->currentMETHOD = action;
	if ( isCoded(action->groupBody->flags.actionType) && !::processCode(action) )
		return 0;
	/*************************************************************************
	if action is a rule, update local fields from label contents.
	*************************************************************************/
	if ( action->groupBody->flags.isRule )
		{
		code = action->get("CodE");
		while ( result = code->nextAttribute(result) )
			{
			if ( result->groupBody->flags.noPrint )
				continue;
			if ( grup = label->get(result->groupBody->tag) )
				{
				result->setGroup(grup);
				result->groupBody->flags.isLabel = 1;
				}
			else	result->clear();
			}
		}
	if ( result = action->get("BlocK") )
		{
		/*********************************************************************
		The following clears local fields before action runs (note isLabel
		fields are not cleared; they were set above).
		*********************************************************************/
		if ( action->groupBody->flags.isRule )
			action = code;
		while ( grup = action->nextAttribute(grup) )
			if ( grup->groupBody->flags.isLocal && !grup->groupBody->flags.isLabel && !grup->groupBody->flags.noPrint && !grup->groupBody->flags.isArgument && grup->groupBody != action->groupBody )
				grup->clear();
		if ( result = result->groupBody->gMethod(result) )
			result->groupBody->flags.isBranch = 0;
		}
	ruler->currentMETHOD = priorMETHOD;
	ruler->tempField = priorTempField;
	return result;
}

extern "C" int processCode(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*blockRULE = ruler->grokking->getMember("BlocK");
GroupItem 	*code = 0;
GroupItem 	*result = 0;
GroupItem 	*priorMETHOD = ruler->currentMETHOD;
GroupItem 	*action = field;
int 		indenter = ruler->lastIndent;
int 		processing = ruler->processingCode;
	/*  ⚠ THE D2 TRIPWIRE. NOT a tolerance guard -- a refuse-loud trap, and
	the difference is the whole ruling. Tony, 2026-08-22.
	
	D1 says an isRule-class groupBody flag means RULE-SHAPED and that
	rStuff-less is LAWFUL, because that is what a specimen is. D2 says
	isLabel is different in kind: a label exists ONLY as the result of a
	live parse, and its rStuff.rule link is part of that birth. So
	isLabel IMPLIES live rStuff, always. An rStuff-less label is not a
	specimen -- it is WRECKAGE: something upstream broke, copied, or
	hand-built what only a parse may mint.
	
	SO THIS SPEAKS RATHER THAN SHRUGS, and it speaks HERE even though the
	defect happened somewhere else. This is where it became visible, and
	silence here would let wreckage travel down the specimen path --
	compile calls processCode, which is station 5's road.
	
	The guard it replaces asked isLabel (groupBody, COPIED) before
	dereferencing rStuff (never copied): a question posed to the wrong
	oracle, and one flag away from firing.  */
	if ( field->groupBody->flags.isLabel && !field->getRStuff() )
		{
		::fprintf(stderr,"processCode: REFUSING %s -- isLabel with no rStuff. Only a live parse mints a label (Ruling D2), so this node is wreckage, not a specimen; look upstream at whatever copied or hand-built it.\n",field->groupBody->tag);
		return 0;
		}
	if ( field->groupBody->flags.isLabel )
		field = field->getRStuff()->rule;
	/*  PJ-8, THE INTERPRETING HALF OF THE LIFECYCLE. An action's IR record is
	cleared whenever the action is COMPILED, and this is the compile for
	interpreting: the lines below re-parse CodE and attach a fresh BlocK,
	so any IR emitted against the previous one is invalid from here.
	THIS FIRES EXACTLY ONCE PER ACTION, which is why it cannot erase a
	record it should keep: the `field.isAction = true` below overwrites
	actionType, consuming isCoded, and processAction's call site is
	`if isCoded && !processCode(action)`. So a later interpreted call --
	including a ladder fixture's oracle call after a jit compile -- does
	NOT re-enter here. Verified at GroupActions.rtn:549 and :603; the same
	consumption is what bear-trap #25 documents from the testing() side.
	setText("") rather than clear(): a field with no data returns its TAG
	from getText(), so a clear()ed record reads back as "JiT".  */
	
	GroupItem   *staleIR = field->get("JiT");
	if (staleIR)    staleIR->setText(::strdup(""));
	
	code = field->get("CodE");
	if ( field->groupBody->flags.isRule )
		action = code;
	ruler->currentMETHOD = action;
	ruler->divertToRule = 1;
	ruler->pushInput(code);
	ruler->lastIndent = 0;
	ruler->processingCode = 1;
	if ( result = blockRULE->parse(0) )
		{
		result->groupBody->flags.noPrint = 1;
		field->addAttribute(result);
		field->groupBody->flags.actionType = 1;
		}
	else	reportCodeFail(field);
	if ( !processing )
		ruler->processingCode = 0;
	ruler->lastIndent = indenter;
	ruler->popInput();
	ruler->currentMETHOD = priorMETHOD;
	if ( result )
		return 1;
	return 0;
}

/***************************************************************************
	The processFlags method is invoked by multiple incant noPrint fire and
    forget commands run at field definition). The item passed in as argument
    is used to figure out what flag to set/reset; the exception is the exit
    command that is not fire and forget; it is fire and exit.

    BEAR COUNTRY: case 'v' (the `virtual` command) sets isVirtual. This is the
    only sanctioned way a field becomes virtual, and it runs at field
    definition. Do not virtualize a field outside a define. Virtual is a
    define-time property; the forks that consume it (aCTionNamE, runOP) assume
    nothing virtual was created elsewhere. See the wakeup bear-trap log.
***************************************************************************/
extern "C" GroupItem *processFlags(GroupItem *item)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
char 		*command = item->groupBody->tag;
GroupItem 	*target = item->groupBody->flags.fLAG ? item->parent : item;
	if ( item )
		switch (*command)
			{
			case 'a':
				if ( ::compare(command,"assign") == 0 )
					target->groupBody->flags.isAssign = 1;
				break;
			case 'b':
				target->groupBody->flags.binType = 1;
				if ( !target->groupBody->guardSet )
					{
					target->groupBody->guardSet = new PLGset();
					target->groupBody->flags.guarding = 1;
					}
				break;
			case 'c':
				target->groupBody->flags.isCondition = 1;
				// condition on by default, off if entered as condition?
				break;
			case 'd':
				target->groupBody->flags.deferred = 1;
				break;
			case 'D':
				ruler->defining = !ruler->defining;
				if ( !ruler->defining )
					ruler->lastIndent = 0;
				break;
			case 'e':
				::printf("Exiting parse\n");
				::exit(0);
				break;
			case 'f':
				if ( target->getRStuff() )
					target->getRStuff()->notifyFail = 1;
				break;
			case 'i':
				if ( ::compare(command,"index") == 0 )
					target->groupBody->flags.isIndexed = 1;
				else
				if ( ::compare(command,"isList") == 0 )
					target->groupBody->flags.binType = 3;
				else
				if ( ::compare(command,"isRule") == 0 )
					{
					target->groupBody->flags.isRule = 1;
					if ( !target->getRStuff() )
						target->setRStuff(new RuleStuff(target));
					}
				break;
			case 'm':
				if ( ::compare(command,"macro") == 0 )
					target->groupBody->flags.isMacro = 1;
				else	target->groupBody->flags.mergeOn = 1;
				break;
			case 'M':
				if ( !ruler->currentRegistry->groupBody->flags.isRule && ruler->currentDefine )
					ruler->currentDefine->groupBody->flags.addingMembers = 1;
				break;
			case 'n':
				target->groupBody->flags.noPrint = 1;
				break;
			case 'P':
				ruler->isPRINTING = 1;
				break;
			case 's':
				// sort
				if ( isSTRING(item->groupBody->flags.data) && *item->groupBody->gText == 'd' )
					target->groupBody->flags.isSorted = 2;
				else	target->groupBody->flags.isSorted = 1;
				break;
			case 't':
				target->groupBody->flags.tokened = 1;
				break;
			case 'T':
				target->groupBody->flags.tokened = 1;
				break;
			case 'u':
				target->groupBody->flags.isUnary = 1;
				break;
			case 'v':
				target->groupBody->flags.isVirtual = 1;
				break;
			default:
				::fprintf(stderr,"processFlag: invalid argument %s\n",command);
			}
	else	::fprintf(stderr,"processFlags: no command provided\n");
	return ruler->trueResult;
}

/*****************************************************************************
	The incant quoted command is usually used in a print statement to output
    its argument text in quotes.
*****************************************************************************/
extern "C" GroupItem *quoted(GroupItem *input)
{
char 		*strung = ::concat(3,"\"",input->getText(),"\"");
GroupItem 	*grup = new GroupItem(strung);
	return grup;
}

/***************************************************************************
	Register the parent block of item in the currentRegistry. This method is
    associated with register and class attributes defined in bootCommands()
    NOTE: the class attribute that makes its parent a registry should preceed any
    attribute to be registered. The index attribute if it exists, should come
    before class.

    Note the argument passed in may be a copy of a registry, hence the use
    of registri below to make sure argument references the original
***************************************************************************/
extern "C" GroupItem *rEGISTER(GroupItem *item)
{
GroupItem 	*registri = 0;
GroupItem 	*argument = item->groupBody->flags.fLAG ? item->parent : item;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
char 		*name = item->groupBody->flags.data ? item->getText() : (char*)0;
	if ( ::compare(item->groupBody->tag,"class") == 0 )
		{
		argument->makeRegistry();
		argument->groupBody->flags.binType = 2;
		}
	else
	if ( ::compare(item->groupBody->tag,"register") == 0 )
		{
		/*******************************************************************
		Add argument to the named registry or the current
		registry if there is no name
		*******************************************************************/
		if ( name )
			registri = ruler->registries->get(name);
		else	registri = ruler->currentRegistry;
		registri->addMember(argument);
		}
	else {
		if ( !isREGISTRY(argument->groupBody->flags.binType) )
			argument->makeRegistry();
		/*******************************************************************
		The argument registry points to the original instance of the
		registry. argument likely points to a copy
		*******************************************************************/
		ruler->currentRegistry = argument->groupBody->registry;
		}
	return ruler->trueResult;
}

/*******************************************************************************
    // armFromFixture  one more door onto the SAME gate as INCANT_PARSE_RECORD, not a second gate -- a file-static rather than a GroupRules field, so a debug affordance never drags in bear-trap #10's apparatus
*******************************************************************************/
extern "C" GroupItem *recordParse(GroupItem *argument)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	
	gParseRecordArmed = 1;
	
	return ruler->trueResult;
}

/*******************************************************************************
    refuse -- THE ONE FUNNEL. Print the line, arm the unwind, hand back null.
    A refusal ENDS THE ACTIVATION THAT RAISED IT (Tony, 2026-09-05, on f31's
    2,808,029 lines). The action returns null to its caller -- the testable
    nothing -- and nothing after the refusing statement runs.
    GroupActions.refuse
*******************************************************************************/
extern "C" GroupItem *refuse(GroupItem *subject, char *why)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
char 		*name = "(none)";
	if ( subject )
		name = subject->groupBody->tag;
	/*  ⚠ THE LINE IS THE PARSER'S AND IT IS APPROXIMATE. sourceLINE is where the
	PARSER is, which for a re-executed cached body is stale: f31 prints the
	same number for all 43 of its refusals.
	⚠⚠ THE STATEMENT'S OWN LINE WAS TRIED AND DOES NOT EXIST IN A USABLE
	FORM (2026-09-05). rStuff.sourceLine is real, stamped per statement by
	aCTionStatemenT -- but its count is NOT the writer's file line: argBindT
	reported 10 for statements at 16 and 17, and f31 reported 11 for an
	iterate at 45. Nor is sourceLINE: tester reads 8, 9, 10 for definitions
	at 9, 19, 29. NEITHER SOURCE GIVES THE LINE A READER WOULD LOOK AT, so
	the stale-but-plausible number stays and this comment says what it is.
	Do not chase it (bear-trap #36's family).   GroupActions.refuse.theLine  */
	::fprintf(stderr,"REFUSED %s -- %s [line %s]\n",name,why,::toStringFromInt(ruler->sourceLINE));
	ruler->refused = 1;
	return 0;
}

/*****************************************************************************
    Parse an action. Note: the coded field is made an action before its
    code is parsed otherwise a recursive call will complain
*****************************************************************************/
/*****************************************************************************
    reportCodeFail -- WHERE THE CODE BODY ACTUALLY FAILED TO PARSE.

    A bare "parse failed" is a diagnostic that costs more than it gives. It sent
    a whole session reverse-engineering six hypotheses about 53 failures, five
    of which died on measurement, because nothing said which token or line.

    ⚠ THIS IS NOT NEW MACHINERY. aCTionFailed already reports rule, position,
    line and last-parsed-statement, and it works -- it is simply gated on the
    rStuff notifyFail flag, which processFlags sets PER RULE, and the BlocK rule
    a code body is parsed with does not carry it. So the report never fires for
    processCode. This reads the same accessors rather than flagging a shared
    grammar rule mid-flight.

    ONE IMPLEMENTER BY INTENT. If parse-error reporting is ever made good --
    and the standing complaint is that it points at the next county rather than
    the error -- this and aCTionFailed should converge here, not diverge.

    cerr, not cout: a code body can be processed with print diverted.
*****************************************************************************/
extern "C" void reportCodeFail(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	::fprintf(stderr,"ERROR processCode: %s parse failed\n",field->groupBody->tag);
	::fprintf(stderr,"    failed at %s\n",::getDebugText(ruler->ruleSTUFF->failedAt,40));
	::fprintf(stderr,"    on line %s\n",::toStringFromInt(ruler->sourceLINE));
}

extern "C" int reportMaxLimit(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = field->getRStuff();
	::fprintf(stderr,"REFUSED match limit: rule %s term %s\n",ruleStuff->ruleName,field->groupBody->tag);
	::fprintf(stderr,"    hit maxLimit %s with input still matching\n",::toStringFromInt(ruleStuff->max));
	::fprintf(stderr,"    at %s\n",::getDebugText(ruler->atRuleMark,40));
	return 0;
}

/*****************************************************************************
    reportNoBody -- the OTHER refusal, and it is a different fact from the one
    above. reportCodeFail says a body was parsed and the parse failed.
    reportNoBody says a rule was reached through a bound parse method and has
    no compiled body to run, so the parse cannot proceed and is refusing.

    A SIBLING RATHER THAN A REUSE, DELIBERATELY. Calling reportCodeFail here
    would print "ERROR processCode: X parse failed" for a rule that processCode
    never touched -- an instrument naming the wrong mechanism, which is the
    failure this project spends most of its time paying for. The convergence
    note above still applies to both: if parse-error reporting is ever made
    good, these two and aCTionFailed converge here.

    cerr for the same reason as its sibling: a code body can be processed with
    print diverted, and a refusal that vanishes into a buffer is not loud.

    ⚠ IT CAN REPEAT, and that is intended rather than overlooked. A refusing
    rule refuses on every attempt, so a walk that binds a parse method without
    compiling will print once per attempt. Nothing reaches this in an ordinary
    run -- no ordinary path binds a parse method at all -- so the only way to
    see a flood is to be doing exactly the work the flood is about.
*****************************************************************************/
extern "C" void reportNoBody(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	::fprintf(stderr,"REFUSED parseRule: %s has a parse method but no compiled body\n",field->groupBody->tag);
	::fprintf(stderr,"    at %s\n",::getDebugText(ruler->atRuleMark,40));
}

/*****************************************************************************
    reportRepeatLimit -- THE FOURTH REFUSAL, and the one that had no voice.

    reportMaxLimit says a MATCH ran into the token ceiling. This says a RULE ran
    into the repetition ceiling: it matched its limit of times and parse() then
    stopped, which until 2026-08-19 happened in total silence. That silence is
    what made the shared-ceiling arrangement dangerous -- a rule cut short here
    simply stops and the statements after the cut are never parsed, at exit 0.

    ⚠ IT REPORTS AND DOES NOT FAIL, and that is deliberate rather than timid.
    The character loop refuses because a truncated TOKEN is wrong content. A
    rule that repeated to its ceiling has matched everything it matched
    correctly; what is wrong is that there may be more. Failing the match would
    discard correct work and change parse outcomes wholesale. So the fact gets
    named and the existing kount >= min semantics are left alone.

    ⚠ THE COUNTS ARE PASSED, NOT RE-DERIVED. rStuff is per node and parse() may
    be running on a REENTRANCY CLONE (docs/rstuff-chokepoint.md), so reading
    rule.rStuff here could report a different frame's numbers than the loop that
    hit the ceiling. The caller has the live frame; it hands over the values.
*****************************************************************************/
extern "C" int reportRepeatLimit(GroupItem *rule, int kounted, int limit)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	::fprintf(stderr,"REFUSED repetition limit: rule %s\n",rule->groupBody->tag);
	::fprintf(stderr,"    repeated %s times, hit repeatLimit %s\n",::toStringFromInt(kounted),::toStringFromInt(limit));
	::fprintf(stderr,"    at %s\n",::getDebugText(ruler->atRuleMark,40));
	return 0;
}

/*****************************************************************************
    reset — incant command (bound as reset immediateAction=resetField in
    setup). Self-describing by argument: for now it knows buffers (resets the
    mark). A fuller incant action dispatching on argument.taG comes later.
*****************************************************************************/
extern "C" GroupItem *resetField(GroupItem *argument)
{
Buffer 	*buff = argument->getBuffer();
	if ( buff )
		buff->reset();
	return 0;
}

/*****************************************************************************
	Restore local fields after a recursive call.
*****************************************************************************/
extern "C" void restoreLocalFields(GroupItem *action)
{
Stak 		*recurseSTAK = 0;
GroupBody 	*body = 0;
GroupItem 	*frame = 0;
GroupItem 	*grup = 0;
	frame = ::frameFind(action);
	if ( frame )
		recurseSTAK = frame->getStak();
	/*  RESTORE PAIRS BY IDENTITY, NEVER BY POSITION -- the loop below walks
	the STACK, not the field list, and applies no filter of its own.
	GroupActions.restoreLocalFields.identityPair  */
	/*  THE NULL ARM IS REAL, not defensive. restore is reached on paths where
	save never ran -- the jit bracket among them -- and before this repair
	`action.stak` answered on any node, so the question could not arise.
	With the stack on a child, "no frame child" is a state, and it means
	exactly what a zero-length stack means: nothing was saved.  */
	if ( !recurseSTAK )
		action->groupBody->flags.recursive = 0;
	else
	if ( !recurseSTAK->length )
		action->groupBody->flags.recursive = 0;
	else
	while ( body = (GroupBody*)recurseSTAK->pop() )
		{
		grup = (GroupItem*)recurseSTAK->pop();
		*grup->groupBody = *body;
		body = 0;
		}
}

/*******************************************************************************
    row42 — which genParseSpec §4.2 row a term falls in, computed by mirroring
    setTestMatch's cascade IN ITS OWN ORDER (upTo -> container -> data ->
    isMacro -> isCondition -> parseACTION -> default). Order matters: `data`
    is tested BEFORE isMacro in the real function, so a classifier that reads
    the §4.2 table top-to-bottom would already disagree with the tree.
*******************************************************************************/
extern "C" char *row42(GroupItem *term)
{
RuleStuff 	*rs = term->getRStuff();
int 		d = term->groupBody->flags.data;
	if ( !rs )
		return "(no rStuff)";
	if ( upTo(rs->overTo) )
		return "upTo";
	else
	if ( upToOver(rs->overTo) )
		return "upToOver";
	else
	if ( isBIN(term->groupBody->flags.binType) )
		return "isBIN/isREGISTRY";
	else
	if ( isREGISTRY(term->groupBody->flags.binType) )
		return "isBIN/isREGISTRY";
	else
	if ( d )
		return ::dataName(d);
	else
	if ( term->groupBody->flags.isMacro )
		return "isMacro";
	else
	if ( term->groupBody->flags.isCondition )
		return "isCondition";
	else
	if ( parseACTION(term->groupBody->flags.methodType) )
		return "parseACTION";
	else
	if ( !term->contents() )
		return "default lit/litTo";
	return "NO ROW MATCHES";
}

/*****************************************************************************
    Uses dsym to look for a matching method in internal symbols. Uses group
    text for the name to match.
*****************************************************************************/
extern "C" GroupItem *ruleMethod(GroupItem *input)
{
char 	*name = input->getText();
	if ( input->groupBody->flags.fLAG )
		if ( name )
			{
			GroupItem 	*grup = input->parent;
			if ( grup )
				{
				if ( *input->groupBody->tag == 'r' )
					{
					grup->setMethod((GroupItem*(*)(GroupItem*))::dlsym(RTLD_SELF,name));
					grup->groupBody->flags.instructType = 1;
					}
				else {
					grup->setOperat(::dlsym(RTLD_SELF,name));
					grup->groupBody->flags.instructType = 2;
					}
				if ( grup->groupBody->flags.instructType )
					grup->groupBody->flags.methodType = 1;
				else	::fprintf(stderr,"ruleMethod: could not find method: %s\n",name);
				}
			}
		else	::fprintf(stderr,"ruleMethod: expected a method name in ruleMethod text\n");
	else	::fprintf(stderr,"ruleMethod: should be invoked as an attribute when its parent is defined\n");
	return input->getGroup();
}

/*******************************************************************************
    // ruleNameForms  three accepted forms -- quoted literal, bare name, field holding the name -- and BOTH surprises are bear-trap #26: a dataless field returns its own tag, which made the bare form work by accident and the field form fail by the same mechanism
*******************************************************************************/
extern "C" char *ruleNameArg(GroupItem *argument)
{
char 		*name = argument->getText();
GroupItem 	*grup = 0;
	if ( ::locateRule(name) )
		return name;
	grup = GroupControl::groupController->locate(name);
	if ( grup && grup->groupBody->flags.data )
		return grup->getText();
	return name;
}

/*******************************************************************************
    ruleOrRefuse — locateRule, with a refusal that says what went wrong. If a
    bare locate() would have found something, name it and name its registry:
    "no rule of that name" and "that name is a keyword" are different problems
    and the caller should not have to guess which.
*******************************************************************************/
extern "C" GroupItem *ruleOrRefuse(char *name, char *who)
{
GroupItem 	*rule = ::locateRule(name);
GroupItem 	*stray = 0;
	if ( rule )
		return rule;
	stray = GroupControl::groupController->locate(name);
	if ( !stray )
		{
		::fprintf(stderr,"%s: no rule named %s\n",who,name);
		return 0;
		}
	if ( stray->groupBody->registry )
		::fprintf(stderr,"%s: REFUSING %s -- not a rule; locate finds a non-rule in registry %s\n",who,name,stray->groupBody->registry->groupBody->tag);
	else	::fprintf(stderr,"%s: REFUSING %s -- not a rule (and it is in no registry)\n",who,name);
	return 0;
}

/*******************************************************************************
	Run an action that may need code processing.
*******************************************************************************/
extern "C" GroupItem *runAction(GroupItem *argument, GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*result = 0;
GroupItem 	*capture = 0;
GroupItem 	*ruleArg = 0;
	if ( isCoded(field->groupBody->flags.actionType) )
		if ( !::processCode(field) )
			goto exitRunAction;
	// runAction.lastREF a no-argument call leaves the action in lastREF
	ruler->lastREF->setGroup(argument ? argument : field);
	// runAction.mint argument is a runtime-minted binding slot, never a declared
	// attribute -- and this sits ABOVE the jitting gate because BOTH ROADS need
	// the slot to exist and to carry the flag. Only the interpreted arm BINDS it
	ruleArg = field->get("argument");
	if ( !ruleArg )
		ruleArg = field->addString("argument");
	ruleArg->groupBody->flags.isArgument = 1;
	if ( ruler->jitting )
		{
		if ( ::jitEmitSelfCall(argument,field) )
			{
			result = field;
			goto exitRunAction;
			}
		// runAction.jitBind THE EMITTED CALL is jitBindArgRT's at RUN time. But an
		// INLINED callee is walked HERE, at emit time, and the walk reads the
		// argument as it goes -- so the emit-time bind is this arm's, and the two
		// are different roads rather than one duplicated line
		ruleArg->setGroup(argument);
		::jitInlinePush(field);
		result = ::processAction(field);
		::jitInlinePop(result);
		goto exitRunAction;
		}
	// runAction.bindOrder save before bind so the outer activation gets its slot back
	::saveLocalFields(field);
	ruleArg->setGroup(argument);
	// runAction.chanCount chanT's daily row reads this pair, and SAME MUST EQUAL
	// BINDS -- a gap is a bind that did not store the field it was handed. In
	// passthrough because the check is pointer identity, which `==` is not
	
	GroupControl::groupController->groupRules->chanBinds++;
	if ( ruleArg->groupBody->gGroup == argument ) GroupControl::groupController->groupRules->chanSame++;
	
	result = ::processAction(field);
	if ( result )
		{
		capture = new GroupItem(result->groupBody->tag);
		capture->setContent(result);
		result = capture;
		}
	::restoreLocalFields(field);
exitRunAction:
	/*  THE ARM IS ACTIVATION-SCOPED. A refusal ends the action that raised it
	and NOT its caller, so the caller gets a testable null and decides.
	Clearing here is what makes "terminal for the action" mean the action
	rather than the process.   GroupActions.runAction.refusalArm  */
	if ( ruler->refused )
		{
		ruler->refused = 0;
		result = 0;
		}
	return result;
}

extern "C" GroupItem *runOP(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*result = 0;
GroupItem 	*op = field->get(1);
GroupItem 	*arg = field->get(3);
GroupItem 	*target = field->get(2);
	/*  ⚠ THE ARGUMENT FOLLOW, and it is what is LEFT of the flip. runOP's two
	legacy auto-unwraps stood here behind one gate; they were dead the day the
	trunk became the flip and were deleted with the switch on 2026-09-05.
	What survives is the rule that replaced them: an isArgument operand
	yields what it holds.   ArgBinding.ArgBindingSites  */
	// argument is a BINDING: an isArgument operand yields what it holds, and a
	// REBIND of it refuses by name -- tested BEFORE the follow, which destroys
	// the evidence. This funnel serves BOTH ROADS   ArgBinding.ArgBindingSites
	
	if ( op && target && target->groupBody->flags.isArgument ) {
	void *gop = (void*)op->groupBody->gOp;
	if ( gop == (void*)&opSetGroup || gop == (void*)&opRebind ) {
	char why[192];
	::snprintf(why,sizeof(why),
	"`%s` on argument -- argument is a BINDING, not a field; rebind is the caller's job",
	op->groupBody->tag);
	return ::refuse(target,why);
	}
	}
	if ( target && target->groupBody->flags.isArgument && isGROUP(target->groupBody->flags.data) )
	target = target->getGroup();
	if ( arg && arg->groupBody->flags.isArgument && isGROUP(arg->groupBody->flags.data) )
	arg = arg->getGroup();
	
	/*  ⚠ THE STORE RULING (Tony, 2026-09-05). AN ARMED STATEMENT DISPATCHES
	NOTHING FURTHER, STORES INCLUDED. Without this, a refusal raised inside
	an expression still lets the enclosing `=` run, and the assignment
	writes the refusal's null -- BLANKING ITS OWN TARGET. Measured as
	sentinelT ST-1: stRead came back as its own tag instead of the 111 it
	went in with, because the store took.
	⚠ INTERPRETED ONLY, and the era split is the same one aCTionBlocK makes
	three lines below its own arm check: at EMIT time the statements after a
	refusal are REACHABLE and must all be emitted, so stopping the walk here
	would delete them from the IR. The emitted road consults the arm in the
	assign helpers instead.   GroupActions.runOP.storeRuling  */
	if ( ruler->refused )
		if ( !ruler->jitting )
			return 0;
	if ( op->groupBody->flags.instructType && isMethod(target->groupBody->flags.instructType) && target->groupBody->flags.invoke )
		target = target->groupBody->gMethod(target);
	if ( arg )
		if ( isMethod(arg->groupBody->flags.instructType) && arg->groupBody->flags.invoke )
			arg = arg->groupBody->gMethod(arg);
	/*  ⚠ A LIST OPERAND IS DELIBERATELY NOT RESOLVED HERE -- doing it would
	hand the list operators a COPY.   GroupActions.runOP.listOperand  */
	if ( target && target->groupBody->flags.isVirtual )
		target = ::copyOf(target);
	/*  The seed gate must cover BOTH dispatch arms below, not just the
	isOperator one. Unary operators are registered `unary ruleMethod=`
	(incant/setup:104-150) -- isUnary and isMethod, NOT isOperator -- so
	they reach `or op.isMethod` at the foot of this method. Gating seeding
	on isOperator alone left every unary operand unseeded, and jitEmitUnary
	dereferences target->jitData unconditionally: SIGSEGV, not a wrong
	answer. Measured 2026-08-03: gJitSeeded.size()==0 at the crash, with
	gJitBuilder/gJitCurrentFn/gJitResultSlot all live -- so the emit context
	was fine and it was only ever the seeding. isUnary is the precise gate:
	widening to isMethod would seed an operand for every rule method.  */
	if ( ruler->jitting && (isOperator(op->groupBody->flags.instructType) || op->groupBody->flags.isUnary) )
		{
		
		if (target && !target->jitData) {
		if (target->groupBody->flags.isLiteral) jitSeedLiteral(target);
		else                                    jitSeedField(target);
		}
		if (arg && !arg->jitData) {
		if (arg->groupBody->flags.isLiteral)    jitSeedLiteral(arg);
		else                                    jitSeedField(arg);
		}
		
		}
	/*  STEP 2, THE PRESENCE-GATED FORK. Inside the seed gate above by design --
	no new gate was added, because the seeding this fork depends on is done
	by that gate and only that gate. Slot installed, the emitter is called
	and runOP is done; slot absent, control falls through to the interpreter
	dispatch below EXACTLY as before, untouched. That is the whole migration
	contract: an op is either migrated or it is not, and an unmigrated op
	cannot tell the difference.
	⚠ THERE IS NO DEFAULT EMITTER AND THERE MUST NEVER BE ONE. A jitCantEmit
	that delegated to operat would make every unmigrated op look migrated, at
	degrade count zero -- a silent identity default, forbidden in every window.
	The null slot IS the refusal, and it refuses by doing nothing.  */
	/*  Passthrough for the same reason setOperat is: tok resolves the CALL
	`op.jitEmitter(...)` through groupBody correctly but renders the bare
	null TEST as `op->jitEmitter`, and GroupItem carries no such member --
	it is a GroupBody slot reached by alias. Written out here so both halves
	name the same thing, and caught by reading the generated .mm rather than
	by the compiler, which is the cheaper end of that lesson.  */
	/*  ⚠ THE SLOT COUNT IS INCREMENTED HERE, AT THE FORK, AND NOT IN THE SHIMS.
	Moved here at op two, deliberately and before there were thirteen of
	them. Every slot dispatch passes through this one line, so a new shim
	author CANNOT forget to count -- counting is not their job. The
	alternative, one ++ per shim, is a discipline that has to be re-applied
	by everyone who ever adds an op, and this project's ledger on
	copy-the-idiom-lose-the-helper is three instances deep. Prefer the
	structure that makes the omission unconstructable.  */
	/*  ⚠ THE UNARY EDGE IS REFUSED, LOUDLY AND COUNTABLY, UNTIL ITS SPECIMEN
	LANDS. This fork accepts any node carrying a slot, and the seed gate
	above spans isOperator AND isUnary -- so a unary op handed a jitEmitter
	would go live down a path nothing has certified, with only convention
	stopping it. Convention is not a gate.
	KE-4 POSTURE: the refusal is COUNTED and SAID. A quiet decline would be
	indistinguishable from a guard that was never reached. Falling through
	to the interpreter arm below is the safe answer and is what happens.
	Retire guard, counter and rung row together when unary opens -- see
	docs/jitSlotMigration.md, parked section.  */
	
	if (GroupControl::groupController->groupRules->jitting && op->groupBody->gJitEmitter) {
	if (op->groupBody->flags.isUnary) {
	++gJitSlotUnaryRefused;
	::fprintf(stderr,
	"=== JIT SLOT REFUSED #%d: unary op '%s' carries a jitEmitter, "
	"but the unary specimen has not landed -- running INTERPRETED ===\n",
	gJitSlotUnaryRefused, op->groupBody->tag ? op->groupBody->tag : "(unnamed)");
	::fflush(stderr);
	}
	else {
	++gJitSlotCount;
	return op->groupBody->gJitEmitter(arg,target);
	}
	}
	
	/*  OPTION B, 2026-08-24 -- THE OP-POSITION RULE ARM. Ruled by Tony,
	scoped to the ARGUMENTED case.
	
	A rule invoked in expression position -- `NamE("maybe a test;")` --
	arrives here as `op`. It never reached the `or isRule` arm below,
	because that arm tests BARE isRule, which under this method's `use`
	resolves to `field`, not to `op`. So a rule in op position had no arm
	at all, and fell to `or op.isMethod` one line down, since 32 of the 60
	rules in Grokking are BOTH rule-shaped and method-bearing.
	
	THE CONSEQUENCE WAS NOT A WRONG ANSWER BUT A MISSING DIVERT. runRule is
	the ONLY thing that pushes an argument as input (`if field && field.data
	{ divertToRule = true; pushInput(field); }`), so without it the rule
	parsed against the CALL SITE TEXT. checkInput stamped hereAt on
	`NamE("maybe a test;");` itself, and captureSpan then had a label with
	nothing in it -- which is how this was found.
	
	⚠ THE FALL-THROUGH BELOW IS DELIBERATE AND SCOPED. A dual-flag rule in
	op position with NO argument still falls to the isMethod arm; only the
	argumented case is ruled, because only the argumented case has anything
	to divert. The bare-case contract is under measurement and is recorded
	rather than assumed -- today a bare invocation parses against the live
	input stream and consumes it.  */
	if ( isOperator(op->groupBody->flags.instructType) )
		result = op->groupBody->gOp(arg,target);
	else
	if ( isMethod(op->groupBody->flags.instructType) )
		result = op->groupBody->gMethod(target);
	else
	if ( target->groupBody->flags.isRule )
		result = ::runRule(arg,target);
	else
	if ( target->groupBody->flags.actionType )
		result = ::runAction(arg,target);
	else
	if ( isMethod(target->groupBody->flags.instructType) )
		{
		if ( !arg )
			arg = target;
		result = target->groupBody->gMethod(arg);
		}
	return result;
}

/***************************************************************************
    Immediate method called from rule expressions and RunRulE. If there is a
    field argument, input is diverted to its content before running the rule.
***************************************************************************/
extern "C" GroupItem *runRule(GroupItem *field, GroupItem *rule)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*result = 0;
GroupItem 	*newParse = 0;
int 		baseStak = 0;
	/*  DOOR TRACE, parseTrace-gated so it cannot move a baseline. It answers
	the one question the gate cannot: WHICH DOOR a rule arrived through.  */
	if ( ruler->parseTrace )
		::fprintf(stderr,"  runRule DOOR on %s  field= %lu  fieldData= %d\n",rule->groupBody->tag,field != 0,field->groupBody->flags.data != 0);
	if ( ruler->inputSTAK )
		baseStak = ruler->inputSTAK->length;
	if ( field && field->groupBody->flags.data )
		{
		ruler->divertToRule = 1;
		ruler->pushInput(field);
		}
	if ( ruler->parseTrace )
		::frameProbe(field,rule);
	if ( rule->groupBody->flags.hasNewParse )
		if ( newParse = rule->get("builtinParsE") )
			{
			rule->establishFrame(rule->frameParent(field));
			result = newParse->groupBody->gMethod(rule);
			}
		else	::fprintf(stderr,"runRule could not find builtinParsE attribute\n");
	else	result = rule->parse(0);
	while ( field && field->groupBody->flags.data && ruler->inputSTAK && ruler->inputSTAK->length > baseStak )
		ruler->popInput();
	return result;
}

/*******************************************************************************
	runRuleAction checks to see if there is a method parked in actionMethod.
    If there is, and there is a rule label, it runs actionMethod.

    THE CAPTURE GATE IS STRUCTURAL NOW, AND THAT IS THE WHOLE POINT.
    It asks pMethod -- does THIS FIELD carry a builtinParsE -- where it used to
    ask gNewParseInFlight, a file scope C++ global raised by parseRule around
    the generated body and read back through a -% pocket.

    Both spellings answer the same question, "are we inside a new parse", but
    they answer it about different subjects. The global answered it about TIME:
    it was true for whatever ran while parseRule's frame was live, so its
    correctness depended on every road that reaches here either being under
    that frame or being excluded by hand. aCTionBrancH and runOP are two roads
    that are not, which is why the global existed at all. pMethod answers it
    about the FIELD, and a field either carries a generated parse or it does
    not, on every road, with nothing to save and nothing to restore.

    So this is the escape pocket doctrine's first payment: a temporal guard,
    unspellable in kant and therefore written in C++ inside this function, is
    replaced by an ordinary read of a node the function already had in a local.
    Tony objected to the -% spelling before anyone noticed the gate could be
    structural; the objection was the better instinct and this is where it led.

    ⚠ AND IT IS NOT A BEHAVIOUR CHANGE TODAY, which is worth saying so nobody
    reads the fleet staying still as the edit not landing. In an ordinary run
    setParse never fires, so no field carries builtinParsE and this arm is dead
    either way -- exactly as it was dead under the global, which nothing raised
    once parseRule's set was removed. The gate becomes live the first time a
    generated parse runs, which is the campaign.
*******************************************************************************/
extern "C" GroupItem *runRuleAction(GroupItem *field)
{
GroupItem 	*pMethod = field->get("builtinParsE");
GroupItem 	*aMethod = field->get("builtinActoR");
RuleStuff 	*ruleStuff = field->getRStuff();
int 		minters = 0;
	if ( pMethod )
		ruleStuff = pMethod->getRStuff();
	if ( !ruleStuff )
		return GroupControl::groupController->groupRules->trueResult;
	if ( pMethod && ruleStuff->label )
		{
		minters = ::labelMinters(field);
		if ( GroupControl::groupController->groupRules->parseTrace )
			::fprintf(stderr,"  CENSUS %s labelMinters=%d\n",field->groupBody->tag,minters);
		if ( minters == 0 )
			field->captureSpan(ruleStuff);
		}
	if ( ruleStuff->label )
		{
		if ( aMethod )
			ruleStuff->label = aMethod->groupBody->gMethod(ruleStuff->label);
		return ruleStuff->label;
		}
	return GroupControl::groupController->groupRules->trueResult;
}

/***************************************************************************
    runOP fires off a field that might be an action, a rule, a method,
    or an operator

    BEAR COUNTRY: the `target.isVirtual -> copyOf(target)` line below is a
    virtual fork that is INTENTIONALLY UNGATED — it is the safety net for
    operating on a virtual prototype (e.g. the bytecode bcOPs: bcPushLit /
    bcPushField are virtual) outside a defining context. Do NOT gate it on
    `defining`: that removes the net and the bytecode emit path would mutate
    the shared prototype instead of a fork. Huge blast radius; runs hot (do
    not add a permanent `ruler` here — use a directive if you need one to
    debug). Break only in emergency. See the wakeup bear-trap log and the
    aCTionNamE companion note.

    THE isIterator EXEMPTION on the target unwrap (2026-07-29, Tony at the Xcode
    seat). An iterator is a HANDLE, and runOP must not dereference a handle --
    the same reason isPointer is already in that test, which is why this is one
    more term there rather than a special case for ++/--.
    The bug it fixes: pass 1 of `while ++grup` worked because a fresh iterator
    has no position, so isGROUP was false and opPlusPlus received the iterator.
    On pass 2 the cursor is set, isGROUP is true, runOP unwrapped to the CURRENT
    ENTRY, and opPlusPlus got a node with no isIterator flag -- so ++ fell
    through to the numeric path and the loop never terminated.
    Gating on the OPERAND rather than on ++/-- also covers `:=`, which is the
    iterator's only reset: unwrap first and := rebinds the current entry while
    the cursor sits untouched, which fails silently.
    The `arg` unwrap one line below is deliberately NOT exempted, and the split
    is the useful part: an iterator in TARGET position stays the handle, in
    ARGUMENT position it derefs to the current entry.
***************************************************************************/
/***************************************************************************
    runShortCircuit -- TIER 3, THE EVALUATION-CONTROLLING ARM.
    Built 2026-08-11 (docs/andOrRung.md sections 1a and 6; ruling SEQ 32).

    ⚠ WHY THIS IS NOT AN OPERATOR HANDLER, which is the whole finding
    behind the rung: runOP resolves BOTH operands before it dispatches, so
    an opAND/opOR entered from there has already paid for the right arm --
    side effects included. Short-circuit is therefore unreachable at the
    handler position AT ALL. It is reachable HERE, because an unresolved
    operand is still an UNFIRED METHOD: the `arg.isMethod && arg.invoke`
    line in runOP is the firing, and this function simply does not run it
    on the arm the ruling says to skip.

    ⚠ WHY THIS IS A SIBLING OF runOP AND NOT A BRANCH INSIDE IT (Tony,
    2026-08-11). The seat was moved here from the top of runOP on his
    ruling, and the reasoning generalises past this rung:

      - The natural first guess is TokenXP, where unaries are handled.
        That works for a UNARY because the grammar production
        `TokenXP  UnaryOPS? ANYorNum^ InvokeArg?` GROUPS a unary with its
        operand -- the pairing is a parse fact, so there is a node to
        intercept. A BINARY has no such node: `ExpressioN  Token+` is a
        FLAT sequence with `Operators` as one Token alternative, so at
        that seat `AND` has no arms and no precedence yet.
      - The binary structure first exists in interpretXP, which builds the
        left-associative tree. So THE CATEGORY DECISION BELONGS AT TREE
        BUILD, where it is paid ONCE per expression, and not on every
        dispatch.
      - And it keeps runOP what section 6 says it is: "the interpreter's
        strict-operator dispatcher AND NOTHING ELSE." A tier-3 test in the
        strict dispatcher's hot path is a category error wearing a
        conditional.

    So AND/OR keep their operator REGISTRATION -- parser, precedence walk
    and Operators table all untouched -- and are promoted out of the
    operator CATEGORY by the method interpretXP binds. The promotion is a
    dispatch-binding change, not a grammar change.

    ⚠ THE OPERAND CONTRACT IS truthOf's AND ONLY truthOf's. Both arms of
    both words go through it, so the interpreted and jitted engines cannot
    drift apart by one of them growing its own idea of truth.

    THE TIER-3 SET IS CLOSED AND NAMED AT ITS BINDING SITE in interpretXP,
    deliberately in one place: section 6 rules "tier 3 stays small -- if,
    AND/OR, iteration -- then the door closes." Widening it is a ruling,
    so widening it should cost an edit to a line that says so.
***************************************************************************/
extern "C" GroupItem *runShortCircuit(GroupItem *field)
{
GroupItem 	*op = field->get(1);
GroupItem 	*target = field->get(2);
GroupItem 	*arg = field->get(3);
int 		leftIsTrue = 0;
	/*  THE PHASE GATE (section 6): emit time never enters a runtime handler
	for its value. Everything BELOW this line is run time.
	
	⚠ AND THE FLOOR IS A REFUSAL, NOT A FALL-THROUGH, because of what
	was measured the moment the interpreted arm landed: promoting
	AND/OR fixed the `AND`-under-jit 139 and REPLACED IT WITH THE
	SILENT WRONG ANSWER -- jitXand2 and jitXor both want 1 on fire 2
	and returned 0, at DEGRADE COUNT 0. That is a trade of a loud
	failure for the exact shape docs/andOrRung.md section 2 calls "the
	dangerous one ... the shape that survives review".
	Refusing here restores the loudness: the degrade counter is
	asserted at zero by every ladder rung, so an un-emitted AND/OR now
	fails a rung instead of quietly folding its value at emit time.  */
	if ( GroupControl::groupController->groupRules->jitting )
		{
		 return jitEmitShortCircuit(field); 
		}
	/*  runShortCircuit's half of the flip. Measured NEVER to fire in this
	corpus -- 31 entries, zero isGROUP arrivals -- and gated anyway, because
	a divergence between `&&` and `+` is exactly the class nothing is aimed
	at, and it becomes real the day someone writes `if a.group && b`.  */
	
	
	if ( op->groupBody->flags.instructType && isMethod(target->groupBody->flags.instructType) && target->groupBody->flags.invoke )
		target = target->groupBody->gMethod(target);
	leftIsTrue = ::truthOf(target);
	/*  THE SKIP ITSELF. The right arm is never touched on these two paths
	-- not resolved, not unwrapped, not fired -- which is the entire
	behavioural claim of the rung and is what part 6's TICK count
	exists to prove. A value assertion cannot prove it: a right arm
	that runs anyway still produces the right ANSWER in most shapes,
	so only COUNTING shows it was skipped.  */
	if ( ::compare(op->groupBody->tag,"AND") == 0 && !leftIsTrue )
		return GroupControl::groupController->groupRules->falseResult;
	if ( ::compare(op->groupBody->tag,"OR") == 0 && leftIsTrue )
		return GroupControl::groupController->groupRules->trueResult;
	
	
	if ( arg && isMethod(arg->groupBody->flags.instructType) && arg->groupBody->flags.invoke )
		arg = arg->groupBody->gMethod(arg);
	if ( ::truthOf(arg) )
		return GroupControl::groupController->groupRules->trueResult;
	return GroupControl::groupController->groupRules->falseResult;
}

/***************************************************************************
    C extern backing the incant `system` command. Named runSystem to avoid
    the extern "C" symbol clash with libc system(3). User-beware: no escaping,
    no stdout capture, no elaborate error handling. Returns trueResult on
    exit code 0, falseResult otherwise.
***************************************************************************/
extern "C" GroupItem *runSystem(GroupItem *command)
{
char 	*cmdText = command->getText();
int 	status = 0;
	if ( !cmdText )
		return GroupControl::groupController->groupRules->falseResult;
	status = ::system(cmdText);
	if ( status == 0 )
		return GroupControl::groupController->groupRules->trueResult;
	return GroupControl::groupController->groupRules->falseResult;
}

/*****************************************************************************
	Save action fields before a recursive call.
*****************************************************************************/
extern "C" void saveLocalFields(GroupItem *action)
{
Stak 		*recurseSTAK = 0;
GroupBody 	*body = 0;
GroupItem 	*frame = 0;
GroupItem 	*grup = 0;
	frame = ::frameStak(action);
	if ( !isSTAK(frame->groupBody->flags.data) )
		{
		recurseSTAK = new Stak();
		frame->setStak(recurseSTAK);
		}
	else	recurseSTAK = frame->getStak();
	/*  THE FRAME FLOOR. One null per activation, pushed before this frame's
	pairs, so restore stops at ITS OWN floor instead of draining the
	activations below it.   GroupActions.saveLocalFields.frameFloor  */
	recurseSTAK->push(0);
	while ( grup = action->next(grup) )
		if ( (grup->groupBody->flags.isArgument || grup->groupBody->flags.isLocal) && !grup->groupBody->flags.noPrint )
			{
			/*  ⚠ THE SCHEMA SPLIT, and it is not optional under bind-by-body.
			save/restore copy body CONTENTS. That is harmless while the
			argument owns its own body. Once the argument SHARES the
			caller's body, copying contents means the saved body is the
			CALLER's and restore writes it back at return -- UNDOING every
			write the action made through the argument, which is the
			reference semantics the flip exists to preserve.
			So: isLocal carries CONTENTS, isArgument carries the BODY
			POINTER, and each activation re-points rather than overwrites.
			K2 -- recursive, returns its ARGUMENT -- is the row that moves
			first if this is wrong. It is pinned at 7.  */
			body = new GroupBody();
			*body = *grup->groupBody;
			/*  DO NOT clear() HERE. `*body = *grup.groupBody` copies the body
			STRUCT, and that includes the groupList POINTER -- so body and
			grup point at the SAME list object. clear() calls clearList(),
			which pops that shared object EMPTY IN PLACE, gutting the copy we
			just saved. Restore then hands back a body whose list is empty.
			The intent here is only "give the new frame a blank local", so
			blank grup's OWN slots and leave the list object alone; the saved
			body keeps it and restore puts the pointer back.
			Found 2026-07-29 via the iterator, whose cursor state lives in a
			`source` CHILD -- but this is general: no local carrying a list
			could survive recursion. Iterators were just the first to notice.  */
			if ( !grup->groupBody->flags.isArgument )
				{
				grup->clearData();
				grup->groupBody->groupList = 0;
				grup->groupBody->flags.hasAttributes = 0;
				grup->groupBody->flags.hasMembers = 0;
				}
			/*  PAIRED PUSH: the field goes on with its body, so restore
			never has to re-derive which body belongs to whom.
			GroupActions.saveLocalFields.identityPair  */
			recurseSTAK->push(grup);
			recurseSTAK->push(body);
			}
}

/***************************************************************************
	Set method for the block passed by passing the block and method name to dlsym
***************************************************************************/
extern "C" int setCompiledMethod(GroupItem *block, char *name)
{
void 	*methodAddress = 0;
	if ( name )
		if ( methodAddress = ::dlsym(RTLD_DEFAULT,name) )
			{
			block->setMethod((GroupItem*(*)(GroupItem*))methodAddress);
			return 1;
			}
		else	::fprintf(stderr,"\n\tsetCompiledMethod: ERROR no method found %s",name);
	::fprintf(stderr,"\n\tsetCompiledMethod: failed for %s\n",block->groupBody->tag);
	return 0;
}

extern "C" void setFile(GroupItem *bufField, char *name)
{
	if ( isBUFFER(bufField->groupBody->flags.data) )
		bufField->getBuffer()->setFile(name);
}

/***************************************************************************
    setFileOp — operator-signature shim over Buffer.setFile, for the modedOP
    writable-operator path: `doc modedOP "path"` points doc's buffer at a
    file. target is the buffer field, argument carries the path text. Same
    (argument, target) shape as opAssign and the other binary op methods.
***************************************************************************/
extern "C" GroupItem *setFileOp(GroupItem *argument, GroupItem *target)
{
	if ( isBUFFER(target->groupBody->flags.data) )
		target->getBuffer()->setFile(argument->getText());
	return target;
}

/***************************************************************************
    A cOMMANDs method associated with commands like hash and buffer that set
    the appropriate value for the grup passed in.
***************************************************************************/
extern "C" GroupItem *setInternalType(GroupItem *grup)
{
	if ( grup )
		{
		GroupItem 	*target = grup->parent;
		if ( target )
			if ( target = ::makeDataType(target,grup) )
				return target;
		}
	if ( grup )
		::fprintf(stderr,"ERROR setInternalType: failed for %s\n",grup->groupBody->tag);
	else	::fprintf(stderr,"ERROR setInternalType: failed because no argument provided\n");
	return 0;
}

/*****************************************************************************
	setLimits() checks field passed in for limits (min and max).
*****************************************************************************/
extern "C" void setLimits(GroupItem *rule, GroupItem *limits)
{
RuleStuff 	*ruleStuff = rule->getRStuff();
GroupItem 	*maximum = limits->getAttribute("max");
GroupItem 	*minimum = limits->getAttribute("min");
	ruleStuff->min = minimum->getCount();
	/*  limitsSet IS THE DISCRIMINATOR reportMaxLimit needs, and it was
	already declared and already mirrored in groups.ext -- it had simply
	never been written by anything. It answers "did the grammar ask for
	this max, or is it the maxLimit ceiling", which is the question that
	separates a truncation worth refusing from a limit doing its job.
	Stamped only where a maximum was actually supplied.  */
	if ( maximum )
		{
		ruleStuff->max = maximum->getCount();
		ruleStuff->maxRepeat = maximum->getCount();
		ruleStuff->limitsSet = 1;
		}
}

/*****************************************************************************
    The argument passed in to getMarkLineAt must have source and markOffset
    attributes. The source must contain a buffer and markOffset must contain
    a valid count. setMark is defined as an incant command in setup.
*****************************************************************************/
extern "C" GroupItem *setMark(GroupItem *argument)
{
GroupItem 	*source = argument->get("source");
GroupItem 	*markOffset = argument->get("markOffset");
int 		offset = markOffset->getCount();
	if ( source )
		{
		Buffer 	*buffer = source->getBuffer();
		if ( buffer->mark && buffer->current >= buffer->mark + offset )
			buffer->mark += offset;
		else
		if ( buffer->current >= buffer->start + offset )
			buffer->mark = buffer->start + offset;
		else	::refuse(source,"setMark: the mark offset exceeds the current buffer length");
		}
	else	::fprintf(stderr,"setMark: ERROR no buffer source provided\n");
	return 0;
}

/*******************************************************************************
	Set parseMethod and label for the field passed in. For now does not handle macros
*******************************************************************************/
extern "C" GroupItem *setParse(GroupItem *field)
{
RuleStuff 	*ruleStuff = field->getRStuff();
	if ( !ruleStuff )
		return ::refuse(field,"setParse: the field passed in has no rStuff");
	if ( !ruleStuff->parseMethod )
		{
		/***********************************************************************
		Set the parseMethod
		***********************************************************************/
		ruleStuff->actionMethod = field->groupBody->gMethod;
		//parkOnMaster(field);
		if ( upTo(ruleStuff->overTo) || upToOver(ruleStuff->overTo) )
			ruleStuff->parseMethod = ::parseUpTo;
		else
		if ( isBIN(field->groupBody->flags.binType) || isREGISTRY(field->groupBody->flags.binType) )
			ruleStuff->parseMethod = ::parseContainer;
		else
		if ( field->groupBody->flags.isCondition )
			ruleStuff->parseMethod = ::parseCondition;
		else
		if ( parseACTION(field->groupBody->flags.methodType) )
			ruleStuff->parseMethod = ::parseAction;
		else
		if ( field->groupBody->groupList )
			ruleStuff->parseMethod = ::parseRule;
		else
		if ( field->groupBody->flags.data )
			switch (field->groupBody->flags.data)
				{
				case 1:
					ruleStuff->parseMethod = ::parseAny;
					break;
				case 2:
					ruleStuff->parseMethod = ::parseCharacter;
					break;
				case 3:
					ruleStuff->parseMethod = ::parseSet;
					break;
				case 6:
					ruleStuff->parseMethod = 0;
					break;
				default:
					ruleStuff->parseMethod = ::parseString;
				}
		else
		if ( field->groupBody->gMethod )
			ruleStuff->parseMethod = ::parseAction;
		else	ruleStuff->parseMethod = ::parseString;
		if ( ruleStuff->parseMethod )
			{
			GroupItem 	*builtinParsE = field->addString("builtinParsE");
			builtinParsE->setRStuff(ruleStuff);
			builtinParsE->groupBody->flags.noPrint = 1;
			builtinParsE->setMethod(ruleStuff->parseMethod);
			}
		if ( ruleStuff->actionMethod && ruleStuff->parseMethod )
			{
			GroupItem 	*builtinActoR = field->addString("builtinActoR");
			builtinActoR->setRStuff(ruleStuff);
			builtinActoR->groupBody->flags.noPrint = 1;
			builtinActoR->setMethod(ruleStuff->actionMethod);
			}
		field->groupBody->flags.hasNewParse = 1;
		field->updateContentFlags();
		}
	return 0;
}

/*******************************************************************************
    // ⚠ AND THE PASSTHROUGH PREMISE IS RECORDED WRONG in setParseCast, verbatim: most of this can be one tok line. NOT acted on by the comment sweep -- that is a code change with its own certificate

    // setParseCast  passthrough because everything it touches must arrive as a PARAMETER -- an incant local referenced only inside passthrough is pruned with its initializing call (bear-trap #13)
*******************************************************************************/
extern "C" int setParseMethod(RuleStuff *stuff, char *name)
{
	
	void    *address = ::dlsym(RTLD_DEFAULT,name);
	if ( !address )
	{
	::fprintf(stderr,"setParseMethod: REFUSING %s -- no method of that name\n",name);
	return 0;
	}
	stuff->parseMethod = (GroupItem *(*)(GroupItem *))address;
	return 1;
	
}

/***************************************************************************
	Link an action referenced by the block passed in and set its method type.
    If the block passed in is a method type attribute and names a rule in its
    text, the action is set on the rule, otherwise it is set on the block.
    Returns the rule upon which the action is set.
***************************************************************************/
extern "C" GroupItem *setRuleAction(GroupItem *block)
{
GroupItem 	*item = block ? block->parent : (GroupItem*)0;
char 		*name = 0;
	if ( item )
		{
		if ( !item->groupBody->gMethod )
			{
			if ( block->groupBody->flags.data )
				{
				name = block->getText();
				block->setText((char*)0);
				}
			else {
				name = item->getText();
				item->setText((char*)0);
				}
			if ( name )
				::setCompiledMethod(item,name);
			}
		if ( item->groupBody->gMethod )
			{
			if ( ::compare(block->groupBody->tag,"immediateAction") == 0 )
				item->groupBody->flags.methodType = 1;
			else
			if ( ::compare(block->groupBody->tag,"parseAction") == 0 )
				item->groupBody->flags.methodType = 2;
			}
		else	::fprintf(stderr,"setRuleAction: could not set action for %s\n",block->groupBody->tag);
		}
	else	::fprintf(stderr,"setRuleAction: could not set action target\n");
	return item;
}

/*******************************************************************************
    // directorsWindow  a COMMAND and not a kant action, because a rule name in expression position INVOKES the rule -- `if Braced;` exits 139, measured -- so the window comes in through the same text-and-locateRule door genParse uses
*******************************************************************************/
extern "C" GroupItem *showParse(GroupItem *argument)
{
GroupItem 	*rule = ::ruleOrRefuse(::ruleNameArg(argument),"showParse");
GroupItem 	*record = 0;
	if ( !rule )
		return 0;
	record = rule->get("ParsE");
	if ( !record )
		{
		::printf("showParse: %s has no ParsE record -- run genParse with INCANT_PARSE_RECORD armed\n",argument->getText());
		return 0;
		}
	if ( !record->getText() )
		{
		::printf("showParse: %s ParsE record is EMPTY\n",argument->getText());
		return 0;
		}
	::printf("%s\n",record->getText());
	return record;
}

/*******************************************************************************
    // treeNotLanguage  §2.4's acceptance test has to be a TREE test: an ALT attaches to the enclosing label, and getting it wrong gives the right LANGUAGE over the WRONG TREE, which every mark-and-win check reads green
*******************************************************************************/
extern "C" int showTree(GroupItem *node, char *pad)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*kid = 0;
char 		*deeper = 0;
	if ( !node )
		return 0;
	if ( node == ruler->labelNO )
		{
		::fprintf(stderr,"%s(labelNO — matched, no tree)\n",pad);
		return 1;
		}
	deeper = ::concat(2,pad,"  ");
	::fprintf(stderr,"%s%s\n",pad,node->groupBody->tag);
	if ( node->groupBody->flags.hasAttributes || node->groupBody->flags.hasMembers )
		while ( kid = node->nextGroup(kid) )
			::showTree(kid,deeper);
	return 1;
}

/*******************************************************************************
    // sinkRidesAsAttribute  one argument because a kant action takes one; `sink` is the fold's decision and rides as an attribute, REUSED not stacked, or getAttribute keeps answering with the stale one
*******************************************************************************/
extern "C" char *spellKant(GroupItem *speller, GroupItem *node, char *sink)
{
GroupItem 	*slot = 0;
GroupItem 	*result = 0;
	slot = node->getAttribute("sink");
	if ( !slot )
		{
		slot = new GroupItem("sink");
		node->addAttribute(slot);
		}
	slot->setText(sink);
	result = ::runAction(node,speller);
	if ( !result )
		return 0;
	return result->getText();
}

/*******************************************************************************
    // whichSpellerLive  which implementation is live, because emitLeaf's fork is silent by design and a round that never registered its action would read green too -- pop.sh pins this line and the pin IS the acceptance test
*******************************************************************************/
extern "C" GroupItem *spellMode(GroupItem *argument)
{
	if ( ::locateSpeller() )
		::fprintf(stderr,"SPELLER kant\n");
	else	::fprintf(stderr,"SPELLER c++\n");
	return GroupControl::groupController->groupRules->trueResult;
}

/***************************************************************************
	Statement equivalence test. v1: top-level GroupItem.matches (tag, data,
	content equality at the root node). v2 candidate: recursive AST walk.
***************************************************************************/
extern "C" int statementMatches(GroupItem *a, GroupItem *b)
{
	return a->matches(b);
}

/***************************************************************************
	Immediate method for the stop command.
***************************************************************************/
extern "C" GroupItem *stopParsingInput(GroupItem *input)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	if ( ruler->inputDiverted )
		{
		ruler->popInput();
		::printf("\nstop: ending input divert\n");
		}
	else {
		*ruler->atRuleMark = 0;
		ruler->endParse = 1;
		::printf("\nstop: end parsing\n");
		}
	/*  ⚠ THE CENSUS FIRES AT COMPLETION, NOT AT THE REFUSAL, and that is the
	whole of Tony's ruling: F-17e's full sweep is preserved -- all 42
	refusals report as 42 -- and only then does the run refuse to call
	itself successful. Exiting at the first refusal would report one.
	
	SILENT WHEN THE ROAD WAS NEVER TRAVELLED. A run that never called
	compile has no compile census, so nothing prints and no baseline
	moves. That is not a gate on the assertion; it is the difference
	between a zero and an absence.  */
	
	::reportCompileCensus();
	
	return input;
}

/*******************************************************************************
    storeBody -- FILE A GENERATED BODY AGAINST ITS RULE, tagged StorE, PENDING.

    ⚠ GENERATION NEVER WRITES THE LIVE SLOT. It refuses by name when there is
    nothing to file.

    // storeBody  the corpus's founding invariant -- generation never writes the live slot
*******************************************************************************/
extern "C" GroupItem *storeBody(GroupItem *rule)
{
GroupItem 	*reg = 0;
GroupItem 	*entry = 0;
GroupItem 	*body = 0;
	if ( !rule )
		{
		::fprintf(stderr,"storeBody: no field\n");
		return 0;
		}
	body = rule->getAttribute("StorE");
	if ( !body )
		{
		::fprintf(stderr,"storeBody: REFUSING %s -- no StorE attribute to file\n",rule->groupBody->tag);
		return 0;
		}
	reg = GroupControl::groupController->getRegistry("GenBodies");
	if ( reg->groupBody->groupList )
		entry = reg->get(rule->groupBody->tag);
	if ( !entry )
		entry = reg->addMember(new GroupItem(rule->groupBody->tag));
	body->parent = 0;
	entry->addAttribute(body);
	/*  ⚠ NO BACK-POINTER. SEQ 79 step 1, ruled: activateAll resolves the rule
	by NAME instead. The entry once carried entry.group = rule so the
	whole-population form could find its rule, and it did not work --
	GroupItem::setGroup (GroupItem.twk:1662) keeps the pointer only for an
	isLocal/isLabel node or a byRef target, and otherwise takes the
	`gGroup = new(g)` arm and stores an EMBEDDED COPY of a parented node.
	Setting isLocal first, which is what kantDoor does, did not rescue it.
	
	THE FIELD IS DELETED RATHER THAN REPAIRED. Audited before removal, as
	instructed: entry.group was written exactly here and read in exactly
	one place, activateAll's loop. It had NO second purpose, so nothing
	else can be relying on it.  */
	entry->setCount(1);
	return entry;
}

/*******************************************************************************
    storedBody -- THE PER-RULE QUERY VERB: the corpus entry for a rule, or null
    when nothing is filed.

    // storedBody  why the fifth verb was a finding rather than a re-pin of the pre-registered four
*******************************************************************************/
extern "C" GroupItem *storedBody(GroupItem *rule)
{
GroupItem 	*reg = 0;
	if ( !rule )
		return 0;
	reg = GroupControl::groupController->getRegistry("GenBodies");
	if ( !reg->groupBody->groupList )
		return 0;
	return reg->get(rule->groupBody->tag);
}

/***************************************************************************
	Immediate method for the testing command — scratch verification harness,
	rewritten per the current need (see CLAUDE.md). Currently drives the JIT
	compile path: testing(<action>) runs jitRunAction on the action, which
	raises the jitting gate, walks the body via processCode (emitting LLVM IR
	through the operators' jit dispatch), then ORC-compiles and fires. Invoke:
		testing(jitAdd);
	A non-coded argument (a plain count field, not an action) routes instead to
	jitRunIfTest — the control-flow branch smoke test — so testing(maximus)
	drives the multi-block CondBr proof without disturbing the action POPs.
	(The earlier bcLIST-priming bytecode harness is in git history; restore it
	here when bytecode-emit verification is the need again.)
	NB: keep this body free of `//` comments — they bleed field-resolution into
	the following extern (unWrap). Doc goes here, in the block.
***************************************************************************/
extern "C" GroupItem *testing(GroupItem *input)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	if ( isCoded(input->groupBody->flags.actionType) )
		return ::jitRunAction(input) ? ruler->trueResult : 0;
	return ::jitRunIfTest(input) ? ruler->trueResult : 0;
}

/*******************************************************************************
    traceParse — the incant-side switch for §1.8's library instrumentation
    (GroupRules.parseTrace). Off by default, so the baselines cannot move.
*******************************************************************************/
extern "C" GroupItem *traceParse(GroupItem *argument)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	ruler->parseTrace = 1;
	return ruler->trueResult;
}

extern "C" GroupItem *treeOf(GroupItem *argument)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*rule = ::locateRule("ScafOUT");
GroupItem 	*result = 0;
int 		baseStak = 0;
	if ( !rule )
		{
		::fprintf(stderr,"treeOf: no ScafOUT on the search list\n");
		return 0;
		}
	if ( ruler->inputSTAK )
		baseStak = ruler->inputSTAK->length;
	ruler->pushInput(argument);
	result = rule->parse(0);
	while ( ruler->inputSTAK && ruler->inputSTAK->length > baseStak )
		ruler->popInput();
	::fprintf(stderr,"TREE %s\n",argument->getText());
	if ( result )
		::showTree(result,"    ");
	else	::fprintf(stderr,"    (parse FAILED)\n");
	return ruler->trueResult;
}

/***************************************************************************
    truthOf -- THE OPERAND TRUTHINESS CONTRACT. Ruled 2026-08-11 by Tony,
    carried by Clay (SEQ 32); spec docs/andOrRung.md section 3 part 1.
    Normative for BOTH engines and BOTH word forms, and it lives in ONE
    place on purpose -- a contract duplicated at three call sites is the
    one-channel-one-meaning failure waiting for its second reader.

    LAYERED: presence decides only when no value exists to decide by.

        1  absent / null                 -> false
        2  node holding a NUMERIC value  -> BY ITS VALUE   (0 false)
        3  node holding no numeric value -> true BY PRESENCE

    Row 2 covers comparison results, ALWAYS, and that is what forces the
    layering rather than merely preferring it: under a flat "any present
    node is true", a comparison returning 0 would be TRUE and every
    conditional over a value-bearing expression would be always-true.
    That is not a semantics, it is the abolition of falsehood. Row 3 is
    the parse-consumer row -- parseR's GroupItem-or-null, structural
    nodes, rule results -- which is the frame the original table was
    written in, where null-vs-node IS the whole discrimination.

    ⚠ ROW 4, TEXT-VALUED OPERANDS, IS DELIBERATELY UNRULED. No measured
    customer needs it, and it borders KE-4's territory. At EMIT a text
    operand is REFUSED (jitEmitShortCircuit calls jitDegrade rather than
    substituting a constant -- a substituted constant is asserted by
    nothing, and the degrade counter is asserted at zero by every rung).
    At RUN it lands on row 3 and answers true-by-presence. The two arms
    therefore AGREE in outcome, because a refused emit falls back to
    interpretation; they are not two answers, they are one answer and a
    refusal to bake it.

    ⚠ MEASURED, 2026-08-11, and recorded because it is NOT what a reader
    expects: `if <field>` and `<field> AND ...` ALREADY DISAGREE in the
    shipping language. A field holding 0 dumps as `aFalse=0 int` -- it
    carries isCOUNT and gCount 0 -- and `if aFalse;` reads TRUE while
    `aFalse AND aTrue` reads false. This contract matches the OPERATOR
    behaviour, which is the one it governs; it does not touch `if`, and
    closing that gap is a separate ruling with its own customer.
    Instrument: incant/andProbe rows 1 and 5.
***************************************************************************/
extern "C" int truthOf(GroupItem *field)
{
	if ( !field )
		return 0;
	if ( isCOUNT(field->groupBody->flags.data) || isNUMBER(field->groupBody->flags.data) )
		return field->groupBody->gCount != 0;
	return 1;
}

extern "C" void unMark(GroupItem *bufField)
{
	if ( isBUFFER(bufField->groupBody->flags.data) )
		bufField->getBuffer()->unMark();
}

/***************************************************************************
	Rule action for unWrap used in the gXpress generator action.
***************************************************************************/
extern "C" GroupItem *unWrap(GroupItem *result)
{
GroupItem 	*grup = result;
	if ( isGROUP(grup->groupBody->flags.data) )
		while ( isGROUP(grup->groupBody->flags.data) )
			grup = grup->getGroup();
	return grup;
}

/*******************************************************************************
    // lazyRStuff  rStuff is materialised LAZILY, so a missing one means NOT YET and not NOT-A-TERM -- conflating it with the noPrint code-tail entries once emitted a rule reduced to `(null)` that the §3 guard would have bound with a warning
*******************************************************************************/
extern "C" int unresolvedTerms(GroupItem *rule)
{
GroupItem 	*term = 0;
int 		i = 1;
int 		n = 0;
	while ( term = rule->get(i) )
		{
		if ( !term->groupBody->flags.noPrint && !term->getRStuff() )
			n++;
		i++;
		}
	return n;
}

/***************************************************************************
	tokenize -- RETIRED 2026-09-01, and this is its obituary rather than a gap.

	It glommed a parent label's components into one token. Its successor is the
	`tokened` BIT: GroupMain builds NamE and NumbeR with `tokened = true` and no
	tokenize term, processFlags sets the same bit for rules the grammar defines,
	and GroupItem.twk:1142 reads it -- `if tokened captureSpan(stuff);`.
	captureSpan writes the span this used to glom.

	Measured before removal: ZERO firings across the fleet, oneTest, parseClass's
	237-row census, a names-and-numbers-heavy fixture, and a fixture defining a
	rule that literally spelled the term -- with an unconditional
	probe-installed marker on every run, so zero was distinguishable from a
	missing instrument. See docs/fixIts.md F-37.
***************************************************************************/
/***************************************************************************
	wrapped is used when printing to supply quotes around output text
***************************************************************************/
extern "C" char *wrapped(GroupItem *input)
{
char 	*junkText = input->getText();
	if ( isTOKEN(input->groupBody->flags.data) || isSTRING(input->groupBody->flags.data) || isFile(input->groupBody->flags.fileType) )
		if ( GroupControl::groupController->groupRules->spaceSet->foundIn(junkText) )
			if ( ::containsCharacter(junkText,'"') )
				junkText = ::concat(3,"'",junkText,"'");
			else	junkText = ::concat(3,"\"",junkText,"\"");
	return junkText;
}

/*******************************************************************************
	GroupRules constructor
*******************************************************************************/
GroupRules::GroupRules()
{
	atRuleMark = 0;
	ruleSTUFF = 0;
	currentDefine = 0;
	currentMETHOD = 0;
	currentRegistry = 0;
	debugJunk = 0;
	baseRegistryList = 0;
	bcOPs = 0;
	commands = 0;
	files = 0;
	grokking = 0;
	groupFields = 0;
	keyWords = 0;
	opFields = 0;
	properties = 0;
	registries = 0;
	divertOutput = 0;
	falseResult = 0;
	inDENT = 0;
	labelNO = 0;
	lastREF = 0;
	lastStatement = 0;
	generator = 0;
	maxLimit = 0;
	printSPACE = 0;
	repeatLimit = 0;
	ruleSkipSet = 0;
	searchList = 0;
	setupFILE = 0;
	sourceFILE = 0;
	trueResult = 0;
	skipSet = 0;
	inputSTAK = 0;
	chanBinds = 0;
	chanSame = 0;
	refused = 0;
	lastIndent = 0;
	rulesParsed = 0;
	sourceLINE = 0;
	beforeSkip = 0;
	lastSkip = 0;
	fieldBUFFER = 0;
	formatBUFFER = 0;
	stringBUFFER = 0;
	toBUFFER = 0;
	debugAllRules = 0;
	debugGuards = 0;
	defining = 0;
	divertToRule = 0;
	endParse = 0;
	generating = 0;
	ignoreThis = 0;
	ignoreNoPrint = 0;
	ignoreNoRoom = 0;
	inputDiverted = 0;
	isPERCENT = 0;
	isPRINTING = 0;
	isRELATIVE = 0;
	isRigorous = 0;
	membering = 0;
	noSkipping = 0;
	parseTrace = 0;
	processingCode = 0;
	showWarnings = 0;
	jitting = 0;
	blockSTAK = new Stak();
	bufferSTAK = new Stak();
	alphaSet = new PLGset("a-zA-Z");
	nameSet = new PLGset("a-zA-Z0-9");
	punctuateSet = new PLGset("]{}[();");
	shortcutSet = new PLGset("-+~`$_:,");
	spaceSet = new PLGset(" \n\r\t");
	tempField = new GroupItem("tempField");
	useDefaultSpace = 1;
}

/*******************************************************************************
	Skip over spaces if skipping and check for comments. If not skipping we do
    not get here. The idea is we skip over spaces and comment and track the
    indent level to be dealt with when tokenizing.
*******************************************************************************/
char *GroupRules::checkSkip(char *atContent)
{
GroupItem 	*stacked = 0;
int 		commenting = 0;
int 		indenting = 0;
int 		lastINDENT = lastIndent;
int 		replaced = 0;
int 		sawNewLine = 0;
char 		lastNotSpace = 0;
char 		*atReplaceNewline = 0;
	if ( atContent && skipSet )
		{
		while ( *atContent && skipSet->contains(*atContent) )
			{
			if ( *atContent == '\n' )
				{
				sawNewLine = 1;
				lastNotSpace = *(atContent - 1);
				indenting = 0;
				sourceLINE++;
				}
			else
			if ( *atContent == ' ' )
				indenting++;
			else
			if ( *atContent == '\t' )
				indenting += 4;
			else
			if ( *atContent == '/' )
				{
				if ( *(atContent + 1) == '/' )
					{
					while ( *atContent && *atContent != '\n' )
						atContent++;
					continue;
					}
				else
				if ( *(atContent + 1) == '*' )
					{
					commenting++;
					atContent += 2;
					}
				else
				if ( *(atContent + 1) == '#' )
					{
					atContent += 2;
					while ( *atContent && *atContent != '#' )
						atContent++;
					}
				else	break;
				}
			while ( commenting )
				{
				if ( !::strncmp(atContent,"/*",2) )
					{
					commenting++;
					atContent += 2;
					}
				else
				if ( !::strncmp(atContent,"*/",2) )
					{
					atContent++;
					commenting--;
					if ( !commenting )
						{
						atRuleMark = atContent + 1;
						sawNewLine = 0;
						lastNotSpace = 0;
						indenting = 0;
						break;
						}
					}
				atContent++;
				}
			atContent++;
			}
		}
	/***************************************************************************
	Check indent status to set block boundaries
	***************************************************************************/
	if ( sawNewLine && !lastINDENT )
		lastINDENT = indenting;
	if ( sawNewLine && indenting != lastINDENT )
		if ( processingCode || defining )
			while ( indenting != lastINDENT )
				{
				atReplaceNewline = atContent - 1;
				if ( indenting > lastINDENT && lastNotSpace )
					{
					if ( defining )
						{
						if ( lastNotSpace != ':' )
							{
							replaced = 1;
							*atReplaceNewline = ':';
							}
						}
					else
					if ( processingCode )
						if ( lastNotSpace != '{' )
							{
							replaced = 1;
							*atReplaceNewline = '{';
							}
					stacked = new GroupItem("stacked");
					stacked->setCount(lastINDENT);
					blockSTAK->push(stacked);
					lastINDENT = indenting;
					}
				else
				if ( indenting < lastINDENT && lastNotSpace )
					{
					if ( lastNotSpace )
						if ( defining )
							{
							if ( lastNotSpace != '>' || (!indenting && lastNotSpace != ';') )
								{
								replaced = 1;
								*atReplaceNewline = '>';
								}
							}
						else
						if ( processingCode )
							{
							if ( lastNotSpace != '}' )
								{
								replaced = 1;
								*atReplaceNewline = '}';
								}
							}
					if ( stacked = (GroupItem*)blockSTAK->pop() )
						lastINDENT = stacked->getCount();
					else	lastINDENT = indenting;
					}
				else
				if ( !lastNotSpace )
					lastNotSpace = 0;
				if ( replaced )
					atContent = atReplaceNewline;
				}
	if ( atContent > atRuleMark )
		{
		beforeSkip = atRuleMark;
		lastSkip = atContent;
		noSkipping = 0;
		lastIndent = lastINDENT;
		}
	else	noSkipping = 1;
	return atContent;
}

/*******************************************************************************
    Reverts input to prior source
*******************************************************************************/
void GroupRules::popInput()
{
	if ( inputSTAK )
		{
		if ( inputDiverted && inputSTAK->length )
			{
			sourceFILE = (GroupItem*)inputSTAK->pop();
			if ( sourceFILE )
				{
				GroupItem 	*atLINE = sourceFILE->getLabelGroup("atLINE");
				GroupItem 	*atMARK = sourceFILE->getLabelGroup("atMARK");
				Buffer 		*buffer = sourceFILE->getBuffer();
				if ( atLINE )
					sourceLINE = atLINE->getCount();
				if ( buffer )
					atRuleMark = buffer->current;
				else
				if ( atMARK )
					atRuleMark = atMARK->getText();
				}
			}
		//cout "popInput:",head(atRuleMark,10):;
		if ( !inputSTAK->length )
			inputDiverted = 0;
		}
	else	inputDiverted = 0;
	return;
}

/*******************************************************************************
    Diverts the parse to the contents of the source passed in
*******************************************************************************/
int GroupRules::pushInput(GroupItem *source)
{
Buffer 	*buffer = 0;
int 	result = 0;
	if ( !source )
		::fprintf(stderr,"pushInput: passed in a null argument\n");
	else {
		if ( sourceFILE )
			{
			buffer = sourceFILE->getBuffer();
			GroupItem *atLINE = sourceFILE->get("atLINE");
			if ( !atLINE )
				atLINE = sourceFILE->addString("atLINE");
			if ( !inputSTAK )
				inputSTAK = new Stak();
			inputSTAK->push((void*)sourceFILE);
			if ( !buffer )
				{
				GroupItem 	*atMARK = sourceFILE->get("atMARK");
				if ( !atMARK )
					atMARK = sourceFILE->addString("atMARK");
				atMARK->setText(atRuleMark);
				}
			else	buffer->current = atRuleMark;
			inputDiverted = 1;
			atLINE->setCount(sourceLINE);
			}
		sourceFILE = source;
		sourceLINE = 0;
		buffer = source->getBuffer();
		if ( !buffer )
			atRuleMark = source->getText();
		else	atRuleMark = buffer->start;
		if ( !atRuleMark )
			::fprintf(stderr,"pushInput: no input text provided in %s\n",source->groupBody->tag);
		}
	if ( atRuleMark )
		result = 1;
	return result;
}
/*	Warning: the following methods were referenced but not declared
	read(int,char*,long)
	floor(double)
*/
