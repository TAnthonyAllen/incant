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
	if ( !GroupControl::groupController->groupRules->compiling && token && token->groupBody->registry == GroupControl::groupController->groupRules->keyWords && !token->groupBody->flags.noPrint )
		return 0;
	return input;
}

/*******************************************************************************
	The BlocK rule action.

    // bareReturnValue A BARE `return;` YIELDS THE PRIOR STATEMENT'S VALUE, not the keyword's tag; the kind stays in the ruler slot, so the substitution carries no signal
*******************************************************************************/
extern "C" GroupItem *aCTionBlocK(GroupItem *input)
{
int 		broke = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*grup = 0;
GroupItem 	*result = 0;
GroupItem 	*prior = 0;
	// stmtUnderEmit under jitting each statement is published as gJitStmt, so an emitter that cannot emit its part hands the whole statement to one run-time call; the enclosing statement is restored at the foot (SEQ 335 R2)
	 GroupItem *outerJitStmt = gJitStmt; bool outerJitStmtRTDone = gJitStmtRTDone; 
	while ( grup = input->next(grup) )
		{
		prior = result;
		ruler->branchKind = 0;
		 if ( GroupControl::groupController->groupRules->jitting ) { gJitStmt = grup; gJitStmtRTDone = false; ::jitStmtBegin(); } 
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
			//  noBuildRun a statement that could not be emitted without running something at build -- or whose emit refused --
			//  is rolled back and emitted as ONE run-time call; an operand already handed over alone counts (SEQ 384, SEQ 372 R2)
			 if ( ruler->refused ) { if ( !gJitStmtRTDone ) gJitHandOver = true; ::clearRefusal(grup); } 
			 ::jitStmtEnd(grup); 
			 jitStoreResult(); 
			//  A3 + the statement-local gate: the check is emitted only for a
			//  statement that can actually refuse at RUN time, and the flag is
			//  cleared here so it cannot leak into the next statement.
			 jitEmitRefusedCheck(); gJitStmtCanRefuse = false; 
			}
		/*  ⚠ A REFUSAL STOPS THE BLOCK, and the jitting arm must NOT stop the
		EMIT walk -- same era split as the branch check below, and the
		same reason: at emit time the statements after a refusal are
		REACHABLE and must all be emitted. The emitted body does its own
		per-statement check at RUN time.   ruleActions.aCTionBlocK.refusalArm  */
		if ( ruler->refused )
			if ( !ruler->jitting )
				broke = 1;
		if ( broke == 1 )
			break;
		if ( result && ruler->branchKind )
			{
			if ( prior && ruler->branchKind == 3 && result->groupBody->registry == ruler->keyWords )
				result = prior;
			// ⚠ DO NOT let this break run under jitting -- it stops the COMPILER'S walk and
			// emitWalkMustNotStop every statement after a branch vanishes from the IR
			if ( ruler->jitting )
				continue;
			broke = 1;
			break;
			}
		}
	 gJitStmt = outerJitStmt; gJitStmtRTDone = outerJitStmtRTDone; 
	// ruleReturnKeepsLabel a return inside a rule's code hands back its value as-is -- the label it returns is the rule's answer, so it is never unwrapped (SEQ 412)
	if ( result && isGROUP(result->groupBody->flags.data) && (ruler->branchKind != 3 || !ruler->currentMETHOD->getGroup() || !ruler->currentMETHOD->getGroup()->groupBody->flags.isRule) )
		result = result->groupBody->gGroup;
	/*  ⚠ A BLOCK THAT RAN TO THE END AND YIELDED NOTHING SUCCEEDED AND HAS NO VALUE --
	which is labelNO, not null. NULL means FAILED (GroupControl.twk:158), and
	aCTionWhilE/DO/FOR all end `if !result result = labelNO;` for exactly this. This
	one did not, so a body whose last statement yielded nothing handed back null and
	aCTionWhilE's `else break;` read it as "stop".
	⚠ IT WAS INVISIBLE WHILE BlocK's CURLIES CARRIED LABELS: the trailing rightCurly
	was the block's value on every iteration, so no block ever handed back null and
	the loop could not stop that way. Honouring the noLabel dash removed the sentinel
	and left the channel -- value and continue-signal on one slot -- exposed.
	⚠ BROKE IS THE SECOND CHANNEL, and it is the whole repair: a block that BROKE on
	a refusal or a branch still hands back what it had, because there null means
	failed and that is true.   ruleActions.aCTionBlocK.ranOutIsLabelNo  */
	if ( !result )
		if ( broke == 0 )
			result = ruler->labelNO;
	// measureBlockResult what the block hands back, and whether it is a value or a signal
	::measureBlockResult(input,result,broke);
	return result;
}

/*******************************************************************************
	Rule action for Braced rule.
        Braced      leftBrace="["- ExpressioN rightBrace="]"-;
*******************************************************************************/
extern "C" GroupItem *aCTionBraced(GroupItem *input)
{
GroupItem 	*ExpressioN = input->getLabelGroup("ExpressioN");
GroupItem 	*held = 0;
	input->clear();
	// carrierHolder the inner expression is HELD in a member, never attached -- a name inside keeps its identity, and the label keeps a member, so it reaches pass 1 as a labelled node (SEQ 361 R1)
	held = new GroupItem("InvokeArg");
	held->setGroup(ExpressioN);
	held->groupBody->flags.fLAG = 1;
	input->addAttribute(held);
	input->groupBody->flags.fLAG = 1;
	return input;
}

/*******************************************************************************
	Rule action for BrancH.
*******************************************************************************/
extern "C" GroupItem *aCTionBrancH(GroupItem *input)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*BrancheS = input->getLabelGroup("BrancheS");
GroupItem 	*ExpressioN = input->getLabelGroup("ExpressioN");
GroupItem 	*arg = ExpressioN;
	// returnOperandFresh nothing may be in flight before the operand emits, or a stale value answers for it
	if ( ruler->jitting && ExpressioN )
		{
		 gJitResult = nullptr; 
		}
	if ( !arg )
		arg = BrancheS;
	else
	if ( isMethod(arg->groupBody->flags.instructType) )
		arg = arg->groupBody->gMethod(arg);
	// ke3NullOperand under jitting that method is an emitter and a null arg means I REFUSED
	// failedOperandIsFalse interpreted, a null operand FAILED -- the signal rides falseResult, never the truthy keyword node (F-114)
	if ( !arg )
		{
		if ( ruler->jitting )
			arg = BrancheS;
		else	arg = ruler->falseResult;
		}
	switch (*BrancheS->groupBody->tag)
		{
			// controlSlot the kind goes to the ruler slot, never onto arg -- arg is the VALUE (P4, Tony SEQ 179)
			break;
		case 'b':
			ruler->branchKind = 1;
			break;
		case 'c':
			ruler->branchKind = 2;
			break;
		case 'r':
			ruler->branchKind = 3;
		}
	// branchesUnderJit break and return DEGRADE LOUDLY here rather than emitting nothing, and the tag
	// returnEmitNow
	if ( ruler->jitting )
		{
		// loopControlMark the open statement carries a continue or a break, for its hand-over (SEQ 410)
		 if ( !gJitStmtMarks.empty() && BrancheS ) { const char *bk = BrancheS->groupBody->tag; gJitStmtMarks.back().branches |= (bk && bk[0] == 'c' ? 2 : bk && bk[0] == 'b' ? 1 : 0); } 
		if ( *BrancheS->groupBody->tag == 'c' )
			::jitEmitContinue();
		else
		if ( *BrancheS->groupBody->tag == 'r' )
			{
			// branchReturnPosition
			if ( ExpressioN && !isMethod(arg->groupBody->flags.instructType) )
				{
				// returnValueInFlight an operand that already emitted its value (a term call-through) is not read again
				 if (!gJitResult) ::jitEmitBareRead(ExpressioN); 
				}
			// returnOperandSilent a return WITH an operand that emitted nothing degrades by name, never stores the slot's 0
			if ( ExpressioN )
				{
				 if (!gJitResult) ::jitDegrade("return operand produced no value", ExpressioN); 
				}
			if ( ::jitEmitReturn() < 0 )
				::jitDegrade("return REFUSED -- no builder, no epilogue block, or  inlining with no frame. A mis-sequenced caller",input);
			}
		else	::jitDegrade("break under jit -- no emitter yet",input);
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
	// degradeByDefault GroupRules.h's extern block to zero
	if ( GroupControl::groupController->groupRules->jitting )
		{
		jitHandOver("cerr under jit -- no emitter, it runs at RUN time on the interpreted road",input);
		if ( buffer )
			GroupControl::groupController->groupRules->bufferSTAK->push(buffer);
		return 0;
		}
	if ( !buffer )
		buffer = new Buffer("cerr buffer");
	appendPrintXP(stuff,buffer);
	return ::opCerr(input,buffer);
}

/*******************************************************************************
	CodE rule action Note: box boundaries defined by its left and right attributes
*******************************************************************************/
extern "C" GroupItem *aCTionCodE(GroupItem *rule)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*lefty = rule->get(1);
GroupItem 	*righty = rule->get(2);
GroupItem 	*label = ruler->gParseActive->label;
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
	// degradeByDefault GroupRules.h's extern block to zero
	if ( GroupControl::groupController->groupRules->jitting )
		{
		jitHandOver("cout under jit -- no emitter, it runs at RUN time on the interpreted road",input);
		if ( buffer )
			GroupControl::groupController->groupRules->bufferSTAK->push(buffer);
		return 0;
		}
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
GroupItem 	*ALLRULES = 0;
GroupItem 	*grup = 0;
	// debugKeywords  GUARD and ALL are TEXT, not grammar -- only this method knows them
	if ( rules )
		{
		while ( grup = rules->next(grup) )
			{
			if ( ::compare(grup->getText(),"GUARD") == 0 )
				{
				GUARD = ruler->trueResult;
				continue;
				}
			if ( ::compare(grup->getText(),"ALL") == 0 )
				{
				ALLRULES = ruler->trueResult;
				continue;
				}
			if ( GUARD )
				grup->groupBody->flags.debugGuard = 1;
			grup->groupBody->flags.debugged = !grup->groupBody->flags.debugged;
			if ( ALLRULES )
				grup->setDebug(GUARD);
			}
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
	// loopRefuseLoudly as aCTionIF -- a loop whose body label never attached refuses by name, never calls a null
	if ( !StatemenT )
		{
		::fprintf(stderr,"aCTionDO: REFUSING -- the loop parsed but its body StatemenT is MISSING from the label\n");
		return GroupControl::groupController->groupRules->falseResult;
		}
	do	{
		GroupControl::groupController->groupRules->branchKind = 0;
		result = StatemenT->groupBody->gMethod(StatemenT);
		if ( GroupControl::groupController->groupRules->branchKind )
			{
			// ⚠ TRAILING-CONTINUE GUARD -- one IDENTICAL body in DO, FOR and WhilE, and NOT
			// extractable: the arms are continue/return/break over THIS loop
			// trailingContinueGuard
			if ( GroupControl::groupController->groupRules->branchKind == 2 )
				{
				GroupControl::groupController->groupRules->branchKind = 0;
				result = GroupControl::groupController->groupRules->trueResult;
				continue;
				}
			else
			if ( GroupControl::groupController->groupRules->branchKind == 3 )
				return result;
			// BREAK IS CONSUMED HERE -- clearing the slot is what stops the enclosing
			// breakIsConsumed block breaking too
			GroupControl::groupController->groupRules->branchKind = 0;
			if ( result && result->groupBody->registry == GroupControl::groupController->groupRules->keyWords )
				result = 0;
			break;
			}
		}
	while ( ::loopCondition(ExpressioN) );
	// labelNO, not falseResult: this construct executed NO statement, so it has no
	// labelNoNotFalse value -- and 0 is a value
	if ( !result )
		result = GroupControl::groupController->groupRules->labelNO;
	// yieldOrValue ONE RETURN, TWO MEANINGS, TOLD APART BY deferred: direct fire = YIELD (own label -- fireLabelMethod adopts it, and a body's value can be a live field); owner-run = VALUE, as before. The clean split waits for the crossover (Tony, 2026-09-24, F-122)
	if ( input->groupBody->flags.deferred )
		return result;
	return input;
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
				// noSatellite a later definition of an entry ALREADY in this registry fills the entry itself -- re-adding a parented node mints a copy that put() never lists, and the terms would be parented to it (F-O32)
				if ( NewGroup->parent != ruler->currentRegistry )
					NewGroup = ruler->currentRegistry->addMember(NewGroup);
				if ( !NewGroup->groupBody->flags.binType )
					NewGroup->groupBody->flags.isRule = 1;
				if ( !NewGroup->getRStuff() )
					NewGroup->setRStuff(new RuleStuff(NewGroup));
				// ⚠ THE PRODUCER OWNS THE INVARIANT: every live rule carries rStuff. Assert here,
				// producerOwnsInvariant loudly -- do not soften this into a consumer-side guard
				if ( !NewGroup->getRStuff() )
					::fprintf(stderr,"REGISTER: INVARIANT BROKEN -- %s promoted to a rule in registry %s but carries no rStuff. Every live rule must carry rStuff (Mark 3); downstream guards will now read this broken rule as a lawful specimen.\n",NewGroup->groupBody->tag,ruler->currentRegistry->groupBody->tag);
				}
			else
			if ( NewGroup->groupBody->registry != ruler->currentRegistry )
				if ( ruler->currentDefine == NewGroup || !ruler->currentDefine || !ruler->currentDefine->groupBody->flags.addingMembers )
					if ( NewGroup->parent != ruler->currentRegistry )
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
				// argument was set here once; no longer, now set in runAction
				if ( ::compare(item->groupBody->tag,"argument") == 0 )
					::refuse(NewGroup,"a declared `argument` attribute is retired -- delete it; runAction mints the binding slot");
				if ( NewGroup->groupBody->flags.isMacro )
					item->groupBody->flags.noPrint = 1;
				item->groupBody->flags.isInitialized = 1;
				// memberIsATerm a propagated COPY takes part as a rule term on its own rStuff, never the shared body (stroke 2)
				if ( NewGroup->groupBody->flags.isRule && !item->groupBody->flags.binType && !item->isRuleTerm() )
					{
					if ( item->ruleOf )
						{
						if ( !item->getRStuff() )
							item->setRStuff(new RuleStuff(item));
						item->getRStuff()->ruleTerm = 1;
						}
					else	item->groupBody->flags.isRule = 1;
					}
				if ( item->isRuleTerm() )
					if ( !item->getRStuff() )
						item->setRStuff(new RuleStuff(item));
					else	item->setRStuff(new RuleStuff(item->getRStuff()));
				// codeIsAProperty an action's CodE is an artifact, so it goes on the property list, never among the terms (stroke 3)
				if ( item == CodE )
					grup = NewGroup->addProperty(item);
				else	grup = NewGroup->addAttribute(item);
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
		// ruleCodeLocals a rule's code locals are minted into its CodE, so `this` (holding that CodE) and tempField go there too (Tony, SEQ 401)
		if ( NewGroup->groupBody->flags.isRule )
			{
			grup = CodE->addString("this");
			grup->groupBody->flags.isLocal = 1;
			grup->groupBody->flags.noPrint = 1;
			grup->setGroup(CodE);
			grup = CodE->addString("tempField");
			grup->groupBody->flags.isLocal = 1;
			grup->groupBody->flags.noPrint = 1;
			// ruleArgument a rule's code reads the label it fired on as argument; processAction binds it per fire (Tony)
			grup = CodE->addString("argument");
			grup->groupBody->flags.isLocal = 1;
			grup->groupBody->flags.noPrint = 1;
			}
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
			if ( newMember->isRuleTerm() && newMember->getRStuff() && (!newMember->groupBody->flags.data || newMember->groupBody->flags.data > 3) )
				if ( newMember->getRStuff()->max != 1 || newMember->getRStuff()->min != 1 )
					{
					RuleStuff 	*fresh = new RuleStuff(newMember);
					newMember->setRStuff(fresh);
					}
			}
	// ruleMethodCheck the arms are ordered, not interchangeable.
	if ( NewGroup->groupBody->flags.isRule && !parseACTION(NewGroup->groupBody->flags.methodType) && !isREGISTRY(NewGroup->groupBody->flags.binType) )
		{
		if ( !NewGroup->getRStuff() )
			NewGroup->setRStuff(new RuleStuff(NewGroup));
		NewGroup->setActions();
		}
	// holderAttribute a completing field whose group carries a LIST takes that rule as an ATTRIBUTE; a data group still goes to embedRule
	NewGroup->embedAttribute(NewGroup->groupBody->gGroup);
	if ( NewGroup->groupBody->flags.isRule && NewGroup->groupBody->groupList )
		while ( item = NewGroup->nextAttribute(item) )
			item->embedAttribute(item->groupBody->gGroup);
	input->clearList();
	NewGroup->groupBody->flags.isInitialized = 1;
	if ( NewGroup->groupBody->registry && !NewGroup->parent )
		NewGroup->parent = ruler->currentRegistry;
	if ( NewGroup->groupBody->flags.addingMembers )
		NewGroup->groupBody->flags.addingMembers = 0;
	if ( ruler->currentDefine && ruler->currentDefine->groupBody == NewGroup->groupBody )
		ruler->currentDefine = 0;
	input->setGroup(NewGroup);
	/*  refusalBoundary  IT NAMES WHAT IT REMOVES, AND IT REPORTS BEFORE IT REMOVES
	refusalBoundary  so the name is read off a field that is still in the registry.
	refusalBoundary  ruleActions.aCTionDefinE.refusalBoundary  */
	if ( ruler->refused )
		{
		reportDefineRemoved(NewGroup,ruler->currentRegistry);
		if ( ruler->currentRegistry )
			ruler->currentRegistry->remove(NewGroup->groupBody->tag);
		clearRefusal(NewGroup);
		}
	return input;
}

/*******************************************************************************
	Immediate method for DelimText rule
*******************************************************************************/
extern "C" GroupItem *aCTionDelimText(GroupItem *input)
{
GroupItem 	*dtext = input->getLabelGroup("dtext");
GroupItem 	*grup = dtext->groupBody->groupList->firstInList;
	input->clear();
	input->setText(grup->getText());
	return input;
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
	// degradeByDefault GroupRules.h's extern block to zero
	if ( ruler->jitting )
		{
		// forWriters the cursor and the body's writes are writers the build must see before the statement goes to run time (SEQ 390)
		 ::jitNoteFor(input); 
		jitHandOver("FOR under jit -- no emitter (iterate's disease, different keyword); it runs at RUN time",input);
		return 0;
		}
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
		ruler->branchKind = 0;
		result = StatemenT->groupBody->gMethod(StatemenT);
		if ( ruler->branchKind )
			{
			// ⚠ TRAILING-CONTINUE GUARD -- one IDENTICAL body in DO, FOR and WhilE, and NOT
			// extractable: the arms are continue/return/break over THIS loop
			// trailingContinueGuard
			if ( ruler->branchKind == 2 )
				{
				ruler->branchKind = 0;
				result = ruler->trueResult;
				continue;
				}
			else
			if ( ruler->branchKind == 3 )
				return result;
			// BREAK IS CONSUMED HERE -- clearing the slot is what stops the enclosing
			// breakIsConsumed block breaking too
			ruler->branchKind = 0;
			if ( result && result->groupBody->registry == ruler->keyWords )
				result = 0;
			break;
			}
		}
	// labelNO, not falseResult: this construct executed NO statement, so it has no
	// labelNoNotFalse value -- and 0 is a value
	if ( !result )
		result = ruler->labelNO;
	if ( LoopRestrict )
		if ( !LoopRestrict->groupBody->flags.byRef )
			{
			ruler->lastREF->groupBody->gGroup = LoopRestrict;
			ruler->lastREF->groupBody->flags.data = 6;
			}
		else	ruler->lastREF->clear();
	// yieldOrValue ONE RETURN, TWO MEANINGS, TOLD APART BY deferred: direct fire = YIELD (own label -- fireLabelMethod adopts it, and a body's value can be a live field); owner-run = VALUE, as before. The clean split waits for the crossover (Tony, 2026-09-24, F-122)
	if ( input->groupBody->flags.deferred )
		return result;
	return input;
}

/*******************************************************************************
	If the parse gets here it failed.
*******************************************************************************/
extern "C" GroupItem *aCTionFailed(GroupItem *input, char *ownPoint)
{
GroupItem 	*lastStatement = GroupControl::groupController->groupRules->lastStatement;
	// lastCodeToCrash
	::printf("Rule %s\n",input->groupBody->tag);
	// ownPointArgument the failing rule's OWN point, handed by parse() at its failure exit -- never the floor's, which is the root's (SEQ 187 R1)
	::printf("\tFailed at:\t%s\n",::getDebugText(ownPoint,40));
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
	// ifRefuseLoudly
	if ( ::truthOf(result) && !StatemenT )
		{
		::fprintf(stderr,"aCTionIF: REFUSING -- the condition parsed but its governed statement is MISSING. Common causes: a // between the condition and the statement (bear-trap #4), an `if <cond>;` with no statement at all, or a rule named in the condition consuming the statement as its input.\n");
		return GroupControl::groupController->groupRules->falseResult;
		}
	GroupControl::groupController->groupRules->branchKind = 0;
	if ( ::truthOf(result) )
		result = StatemenT->groupBody->gMethod(StatemenT);
	else
	if ( ElsE )
		result = ElsE->groupBody->gMethod(ElsE);
	// labelNoNotFalse if this executed NO statement, it has no value, hence labelNO
	if ( !result )
		result = GroupControl::groupController->groupRules->labelNO;
	// yieldOrValue ONE RETURN, TWO MEANINGS, TOLD APART BY deferred: direct fire = YIELD (own label, unless the arm's result carries a branch signal); owner-run = VALUE, as before. The clean split waits for the crossover (Tony, 2026-09-24, F-122)
	if ( input->groupBody->flags.deferred )
		return result;
	if ( result && GroupControl::groupController->groupRules->branchKind )
		return result;
	return input;
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
		// cursorHandOver a refusal at build hands the statement to run time, and its cursor's ++ with it (SEQ 402)
		if ( GroupControl::groupController->groupRules->jitting )
			{
			 ::jitCursorHandOver(iterator); 
			}
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
			if ( GroupControl::groupController->groupRules->jitting )
				{
				 ::jitCursorHandOver(iterator); 
				}
			return ::refuse(source,why);
			}
		}
	if ( GroupControl::groupController->groupRules->jitting )
		{
		// emitThenFallThru -- the only gate in the tree that does not return, and deliberately so.
		 ::jitNoteWriter(0,iterator,0); 
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
		if ( GroupControl::groupController->groupRules->jitting )
			{
			 ::jitCursorHandOver(iterator); 
			}
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
	// compileOwner while compiling the owner is the one the compile's floor carries, never currentMETHOD -- a generated body repoints that to a grammar face (SEQ 213, SEQ 299)
GroupRules *ruler = GroupControl::groupController->groupRules;
GroupItem *result = 0;
GroupItem *owner = ruler->currentMETHOD->getGroup();
char *arg = 0;
	arg = input->getText();
	if ( ruler->inCompile() )
		owner = ruler->floorOwner();
	result = resolveName(input->getText(),owner);
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
		// numericTower mints isNUMBER here, at the literal's birth, and nothing rounds it
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
GroupItem 	*held = 0;
	input->clear();
	// carrierHolder the inner expression is HELD in a member, as Braced's; an empty () holds nothing and still has its member (SEQ 361 R1)
	held = new GroupItem("InvokeArg");
	if ( ExpressioN )
		held->setGroup(ExpressioN);
	input->addAttribute(held);
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
	// ⚠ THE EMIT-TIME WALK MUST BE EFFECT-FREE -- a print that fires at compile time
	// jittedPrint is worse than one that does not print, because it appears to work
	// ⚠ CALLED AT tok LEVEL, NOT FROM PASSTHROUGH -- as passthrough this hit both
	// emittersAtTokLevel bear-trap #13 and the type-alias hazard at once
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
		if ( !rule->isRuleTerm() )
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
extern "C" GroupItem *aCTionScopeXP(GroupItem *input)
{
GroupItem 	*action = GroupControl::groupController->groupRules->currentMETHOD->getGroup();
GroupItem 	*field = 0;
GroupItem 	*listItem = 0;
GroupItem 	*lookin = 0;
GroupItem 	*scopeList = input->getLabelGroup("scopeList");
GroupItem 	*code = 0;
GroupItem 	*grup = 0;
char 		*name = 0;
	if ( GroupControl::groupController->groupRules->jitting )
		{
		jitHandOver("a scope statement -- it binds locals, so it runs at RUN time",input);
		return input;
		}
	// ruleScopeLocals a rule's code locals live in its CodE, never on the rule (SEQ 401)
	if ( action->groupBody->flags.isRule )
		{
		code = action->actionBody();
		if ( code )
			action = code;
		}
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
				grup = action->addAttribute(grup);
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
	// a rule action like every other: it returns its argument, having no result of its own (SEQ 391 R2)
	return input;
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
	// degradeByDefault GroupRules.h's extern block to zero
	if ( GroupControl::groupController->groupRules->jitting )
		{
		jitHandOver("search under jit -- no emitter, it runs at RUN time",input);
		return 0;
		}
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
	// markSeat3 SEQ 166 point 3 -- what text a StatemenT attempt starts on, and whose buffer
	::measureMarkPoint("3-StatemenT-entry");
	if ( !ruler->inCompile() )
		{
		/*  ⚠ outcome IS DECLARED FIRST SO `statement` STAYS LAST-MENTIONED -- the bare
		`isGROUP` and `group` below resolve against whatever was named most recently
		(bear-trap #42), and a declaration inserted after `statement` would silently
		re-aim them.  */
		GroupItem *outcome = input;
		GroupItem *statement = input;
		if ( isGROUP(statement->groupBody->flags.data) )
			statement = statement->getGroup();
		ruler->lastStatement = statement;
		// firedInLabel the statement's action already ran in fireLabelMethod -- running it here would run it twice
		// statementScope  A REFUSAL'S SCOPE IS THE STATEMENT -- it is cleared HERE, on the
		// statementScope  way out, whether or not a method ran, because the refusal may have
		// statementScope  been raised during the MATCH and never reached a method at all
		clearRefusal(statement);
		return outcome;
		}
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
	// degradeByDefault GroupRules.h's extern block to zero
	if ( GroupControl::groupController->groupRules->jitting )
		{
		jitHandOver("string expression under jit -- no emitter, its statement runs at RUN time",input);
		if ( buffer )
			GroupControl::groupController->groupRules->bufferSTAK->push(buffer);
		return 0;
		}
	if ( !buffer )
		buffer = new Buffer("print buffer");
	appendPrintXP(stuff,buffer);
	return ::opString(stuff,buffer);
}

// aCTionTell the tell rule's action, the one door into a field's grammar: drive the target with the message and return a verdict; an unknown target is a verdict, never a refuse()
extern "C" GroupItem *aCTionTell(GroupItem *input)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*target = input->getLabelGroup("target");
GroupItem 	*message = input->getLabelGroup("message");
GroupItem 	*who = 0;
GroupItem 	*said = 0;
GroupItem 	*raw = 0;
GroupItem 	*got = 0;
GroupItem 	*result = 0;
GroupItem 	*replyFrom = 0;
GroupItem 	*reply = 0;
GroupItem 	*verdict = new GroupItem("verdict");
int 		matched = 0;
int 		known = 0;
int 		msgLen = 0;
int 		markAt = -1;
int 		failAt = -1;
int 		consumed = 0;
int 		stoppedAt = 0;
	if ( target )
		who = GroupControl::groupController->locate(target->getText());
	if ( who )
		known = 1;
	if ( who && message )
		{
		said = new GroupItem("message");
		said->setText(message->getText());
		raw = new GroupItem("driveReport");
		result = driveStep(said,who,raw,0);
		if ( got = raw->get("length") )
			msgLen = got->getCount();
		if ( got = raw->get("mark") )
			markAt = got->getCount();
		if ( got = raw->get("failedAt") )
			failAt = got->getCount();
		if ( result && result != ruler->falseResult )
			matched = 1;
		if ( matched && markAt > 0 )
			consumed = markAt;
		if ( matched )
			stoppedAt = consumed;
		else
		if ( failAt > 0 )
			stoppedAt = failAt;
		}
	verdictCount(verdict,"matched",matched);
	verdictCount(verdict,"consumed",consumed);
	verdictCount(verdict,"length",msgLen);
	verdictCount(verdict,"stoppedAt",stoppedAt);
	verdictCount(verdict,"known",known);
	// replyFromFloor driveStep hands back a generated root's label from the drive floor -- the reply reads that, never the root's slot, which the call bracket has restored
	replyFrom = result;
	if ( matched && replyFrom && replyFrom != ruler->labelNO && replyFrom != ruler->trueResult )
		{
		reply = new GroupItem("reply");
		reply->setGroup(::copyOf(replyFrom));
		verdict->addAttribute(reply);
		}
	return verdict;
}

/*******************************************************************************
	Immediate method for the TraiT rule that defines an attribute. It can be
        TraiTdata="="       DatA Modifier?;
        TraiT               NamE@ Modifier? TraiTdata? TraiTlist?;
*******************************************************************************/
extern "C" GroupItem *aCTionTraiT(GroupItem *input)
{
GroupItem 	*upFlags = 0;
GroupItem 	*Modifier = input->getLabelGroup("Modifier");
GroupItem 	*TraiTdata = input->get("TraiTdata");
GroupItem 	*trait = input->get(1);
	/***************************************************************************
	A trait value can be a group or a literal. Modifier is passed
	to trait to be handled in DefinE. Same applies to TraiTdata.
	***************************************************************************/
	input->clearList();
	if ( isGROUP(trait->groupBody->flags.data) )
		trait = trait->getGroup();
	if ( Modifier )
		{
		trait->options.affiliation = 1;
		if ( trait->getRStuff() )
			trait = new GroupItem(trait);
		else	trait->setRuleStuff();
		}
	if ( TraiTdata )
		upFlags = TraiTdata->get("Modifier");
	// packetIsSpent the flags are READ here and the node is TAKEN OFF -- nothing downstream reads a
	// packetIsSpent Modifier on a trait, and leaving it makes four rules enter testAttributes on every match
	if ( upFlags )
		upFlags->remove();
	// traitSubjectExplicit trait, NOT bare -- a bare setContent below the upFlags read re-points
	// traitSubjectExplicit to upFlags (bear-trap #42)
	if ( TraiTdata )
		trait->setContent(TraiTdata);
	// traitTakesOwnFlags BOTH modifier classes apply AFTER this line -- setContent discards flags
	if ( Modifier )
		::modify(trait,Modifier->getText());
	if ( upFlags )
		::modifyClass(trait,upFlags->getText(),0);
	// wideValueRepeats a repeated value wider than a character lost its max in setContent, so the repetition lands on the trait
	if ( upFlags && TraiTdata->groupBody->flags.data > 3 && !isGROUP(TraiTdata->groupBody->flags.data) )
		::modifyClass(trait,upFlags->getText(),1);
	input->setGroup(trait);
	return input;
}

/*******************************************************************************
    Immediate method for the TraiTdata rule.
*******************************************************************************/
extern "C" GroupItem *aCTionTraiTdata(GroupItem *input)
{
int 		repeated = 0;
GroupItem 	*upMark = 0;
GroupItem 	*Modifier = input->getLabelGroup("Modifier");
GroupItem 	*DatA = input->getLabelGroup("DatA");
	input->clear();
	if ( Modifier )
		{
		DatA->options.affiliation = 1;
		if ( DatA->getRStuff() )
			DatA = new GroupItem(DatA);
		else	DatA->setRuleStuff();
		// modifierRidesUp repetition lands on the DATA only; applying it to the trait as well repeats TWICE
		if ( Modifier )
			::modifyClass(DatA,Modifier->getText(),1);
		if ( DatA->ruleOf )
			DatA->getRStuff()->ruleTerm = 1;
		else	DatA->groupBody->flags.isRule = 1;
		}
	// valueRepeats a value may carry + or *; a character or set repeats in its scanner, anything wider repeats on the trait
	repeated = 0;
	if ( Modifier )
		repeated = ::hasRepeatClass(Modifier->getText());
	// modifierRidesUp the flags ride up as a noPrint ARTIFACT, never as a term
	if ( Modifier )
		input->addAttribute(Modifier);
	if ( Modifier )
		upMark = input->get("Modifier");
	if ( upMark )
		upMark->groupBody->flags.noPrint = 1;
	// upMarkNoRstuff THIS LINE hides the packet from the AUDIT; noPrint alone only hides it from the PARSE
	if ( upMark )
		upMark->setRStuff((RuleStuff*)0);
	// scannerKeepsDatA a repeated character or set stays a group so DatA's rStuff -- its max -- survives
	if ( (DatA->isRuleTerm() && (!DatA->groupBody->flags.isLiteral || (repeated == 1 && DatA->groupBody->flags.data <= 3))) || DatA->groupBody->registry == GroupControl::groupController->groupRules->opFields )
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
	// loopRefuseLoudly as aCTionIF -- a loop whose body label never attached refuses by name, never calls a null
	if ( !StatemenT )
		{
		::fprintf(stderr,"aCTionWhilE: REFUSING -- the loop parsed but its body StatemenT is MISSING from the label\n");
		return GroupControl::groupController->groupRules->falseResult;
		}
	while ( looper = ::loopCondition(ExpressioN) )
		{
		if ( looper->groupBody->flags.isIterator )
			looper = looper->getGroup();
		GroupControl::groupController->groupRules->branchKind = 0;
		if ( result = StatemenT->groupBody->gMethod(StatemenT) )
			{
			if ( GroupControl::groupController->groupRules->branchKind )
				{
				// ⚠ TRAILING-CONTINUE GUARD -- one IDENTICAL body in DO, FOR and WhilE, and NOT
				// extractable: the arms are continue/return/break over THIS loop
				// trailingContinueGuard
				if ( GroupControl::groupController->groupRules->branchKind == 2 )
					{
					GroupControl::groupController->groupRules->branchKind = 0;
					result = GroupControl::groupController->groupRules->trueResult;
					continue;
					}
				else
				if ( GroupControl::groupController->groupRules->branchKind == 3 )
					return result;
				// BREAK IS CONSUMED HERE -- clearing the slot is what stops the
				// breakIsConsumed enclosing block breaking too
				GroupControl::groupController->groupRules->branchKind = 0;
				if ( result->groupBody->registry == GroupControl::groupController->groupRules->keyWords )
					result = 0;
				break;
				}
			}
		else	break;
		}
	// labelNO, not falseResult: this construct executed NO statement, so it has no
	// labelNoNotFalse value -- and 0 is a value
	if ( !result )
		result = GroupControl::groupController->groupRules->labelNO;
	// yieldOrValue ONE RETURN, TWO MEANINGS, TOLD APART BY deferred: direct fire = YIELD (own label -- fireLabelMethod adopts it, and a body's value can be a live field); owner-run = VALUE, as before. The clean split waits for the crossover (Tony, 2026-09-24, F-122)
	if ( input->groupBody->flags.deferred )
		return result;
	return input;
}

/*******************************************************************************
	Xpress rule method.
*******************************************************************************/
extern "C" GroupItem *aCTionXpress(GroupItem *input)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*ExpressioN = input->getLabelGroup("ExpressioN");
	if ( !ruler->inCompile() && ExpressioN->groupBody->gMethod )
		{
		ExpressioN = ExpressioN->groupBody->gMethod(ExpressioN);
		// deferredValue run by its owner (bound under a deferred ancestor -- Xpress is `defer` since F-122), a statement's value is the expression's; a null keeps the label so a loop never dereferences nothing
		 if ( input->groupBody->flags.deferred && ExpressioN ) return ExpressioN; 
		}
	else
	if ( ExpressioN )
		{
		input->clear();
		input->setGroup(ExpressioN);
		}
	return input;
}

// accBare a GroupFields name standing alone -- no postfix after it -- reads through lastREF: the dot with no left operand, which is what trunk's dot-LEADING arm builds (SEQ 328 D1)
extern "C" GroupItem *accBare(GroupItem *term, GroupItem *next)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*node = 0;
	if ( term->groupBody->registry != ruler->groupFields )
		return term;
	if ( next )
		{
		if ( ::compare(next->groupBody->tag,"acPostCall") == 0 || ::compare(next->groupBody->tag,"acPostSub") == 0 )
			return term;
		if ( next->groupBody->registry == ruler->opFields )
			if ( ::compare(next->groupBody->tag,".") == 0 )
				return term;
		}
	node = new GroupItem("acDot");
	node->addAttribute(ruler->opFields->get("."));
	node->addAttribute(term);
	node->setMethod(::runOP);
	node->groupBody->flags.invoke = 1;
	return node;
}

// accBuild the loosest tier: an assignment head parks its target and takes the rest as its right side
extern "C" GroupItem *accBuild(GroupItem *flat)
{
GroupItem 	*node = 0;
GroupItem 	*right = 0;
	if ( !::opIsAssignTier(flat->get(2)) )
		return accLogic(flat);
	node = new GroupItem("acA");
	node->addAttribute(::accPop(flat));
	node->addAttribute(::accPop(flat));
	right = accLogic(flat);
	if ( right )
		node->addAttribute(right);
	node->setMethod(::runAccAssign);
	node->groupBody->flags.invoke = 1;
	return node;
}

// accBuilt THE BREAKPOINT SYMBOL (SEQ 320): called with the finished tier tree, before anything runs; it prints the tree
extern "C" void accBuilt(GroupItem *node)
{
	::accTraceTree(node,0);
}

// accCompare one comparison between two folds; a second comparison in the same part makes the chain, refused by name
extern "C" GroupItem *accCompare(GroupItem *flat)
{
GroupItem 	*left = 0;
GroupItem 	*op = 0;
GroupItem 	*right = 0;
GroupItem 	*node = 0;
	left = accFold(flat);
	if ( !::opIsCompareTier(::accNextOp(flat)) )
		return left;
	op = ::accPop(flat);
	right = accFold(flat);
	if ( ::opIsCompareTier(::accNextOp(flat)) )
		{
		node = new GroupItem("acKchain");
		node->addAttribute(left);
		node->addAttribute(op);
		if ( right )
			node->addAttribute(right);
		while ( ::opIsCompareTier(::accNextOp(flat)) )
			{
			node->addAttribute(::accPop(flat));
			right = accFold(flat);
			if ( right )
				node->addAttribute(right);
			}
		node->setMethod(::runAccChain);
		node->groupBody->flags.invoke = 1;
		return node;
		}
	node = new GroupItem("acK");
	node->addAttribute(left);
	node->addAttribute(op);
	if ( right )
		node->addAttribute(right);
	node->setMethod(::runAccCompare);
	node->groupBody->flags.invoke = 1;
	return node;
}

// accFold an operand, then (op, operand) for as long as the operator is arithmetic -- one operand alone is itself
extern "C" GroupItem *accFold(GroupItem *flat)
{
GroupItem 	*first = 0;
GroupItem 	*op = 0;
GroupItem 	*node = 0;
	first = ::accPop(flat);
	op = ::accNextOp(flat);
	if ( !op )
		return first;
	if ( ::opIsShortCircuit(op) )
		return first;
	if ( ::opIsCompareTier(op) )
		return first;
	node = new GroupItem("acX");
	node->addAttribute(first);
	while ( op )
		{
		if ( ::opIsShortCircuit(op) )
			break;
		if ( ::opIsCompareTier(op) )
			break;
		node->addAttribute(::accPop(flat));
		if ( ::accNextOp(flat) )
			node->addAttribute(::accPop(flat));
		op = ::accNextOp(flat);
		}
	node->setMethod(::runAccFold);
	node->groupBody->flags.invoke = 1;
	return node;
}

// accGroupTerm 1 for a Parens / Braced term: tagged Token, and its first member is the InvokeArg holder aCTionParens / aCTionBraced mint (SEQ 361 R1)
extern "C" int accGroupTerm(GroupItem *term)
{
	
	if ( !term || ::strcmp(term->groupBody->tag,"Token") || !term->groupBody->groupList ) return 0;
	GroupItem *m = term->groupBody->groupList->firstInList;
	return m && !::strcmp(m->groupBody->tag,"InvokeArg");
	
}

// accLogic && and ||, nested to the left: each connective takes what is built so far and the next comparison part
extern "C" GroupItem *accLogic(GroupItem *flat)
{
GroupItem 	*left = 0;
GroupItem 	*op = 0;
GroupItem 	*right = 0;
GroupItem 	*node = 0;
	left = accCompare(flat);
	while ( ::opIsShortCircuit(::accNextOp(flat)) )
		{
		op = ::accPop(flat);
		right = accCompare(flat);
		if ( ::opIsOR(op) )
			{
			node = new GroupItem("acOr");
			node->setMethod(::runAccOr);
			}
		else {
			node = new GroupItem("acAnd");
			node->setMethod(::runAccAnd);
			}
		node->addAttribute(left);
		node->addAttribute(op);
		if ( right )
			node->addAttribute(right);
		node->groupBody->flags.invoke = 1;
		left = node;
		}
	return left;
}

// accNextOp the operator at the head of the list, or null -- these lists alternate, so a peek after an operand is an operator
extern "C" GroupItem *accNextOp(GroupItem *flat)
{
	if ( !flat->groupBody->groupList )
		return 0;
	if ( !flat->groupBody->groupList->listLength )
		return 0;
	return flat->get(1);
}

// accOperandBefore 1 when seq's last piece is an OPERAND, so a group after it is a call or a subscript; 0 for nothing or an operator entry -- a word-named entry is a name (SEQ 330 A1) (SEQ 361 R2)
extern "C" int accOperandBefore(GroupItem *seq)
{
	
	GroupRules *ruler = GroupControl::groupController->groupRules;
	if ( !seq || !seq->groupBody->groupList || !seq->groupBody->groupList->listLength ) return 0;
	GroupItem *last = seq->groupBody->groupList->lastInList;
	if ( last->groupBody->registry != ruler->opFields || isREGISTRY(last->groupBody->flags.binType) ) return 1;
	return ::isalpha((unsigned char)last->groupBody->tag[0]) ? 1 : 0;
	
}

/*  THE TIER SPLIT (SEQ 319, c3; D3 and D5). The flat list -- operand, then (op, operand) pairs --
    is consumed LEFT TO RIGHT and rebuilt as one node per tier, loosest first: an assignment head
    (acA), then && / || (acAnd / acOr, nested to the left, so a && b || c is (a && b) || c), then
    one comparison (acK; a second one makes acKchain, refused by name at run time), then the
    arithmetic fold (acX). Each node gets its executor as its method HERE, so nothing at run time
    asks an operator for its tier. The tier marks are setup data: assignTier, shortCircuit,
    compareTier; anything else folds.
    ⚠ EVERY ITEM IS DETACHED BEFORE IT IS RE-ATTACHED (accPop). addGroup COPIES a node that
    already has a parent, and a copy is what hid holderT's re-invocation in c1 -- so nothing here
    attaches an item that still belongs to the flat list.  */
// accPop take the flat list's first item off it, parent cleared, so the next +% attaches IT and not a copy
extern "C" GroupItem *accPop(GroupItem *flat)
{
GroupItem 	*item = 0;
	if ( !flat->groupBody->groupList )
		return 0;
	if ( !flat->groupBody->groupList->listLength )
		return 0;
	item = flat->get(1);
	if ( !item )
		return 0;
	item->remove();
	item->parent = 0;
	return item;
}

// accTraceFlat the flat list from interpretXPaccum's second pass, on one line, before the split
extern "C" void accTraceFlat(GroupItem *flat)
{
	
	::fprintf(stderr,"ACCUM FLAT  ");
	for ( int k = 1; flat && flat->groupBody->groupList && k <= flat->groupBody->groupList->listLength; k++ )
	::accTraceItem(flat->get(k));
	::fprintf(stderr,"\n");
	
}

// accTraceItem one item: its tag, (op) for an operator entry, =value where it carries data
extern "C" void accTraceItem(GroupItem *item)
{
	
	if ( !item ) { ::fprintf(stderr," (null)"); return; }
	::fprintf(stderr," %s",item->groupBody->tag);
	if ( item->groupBody->registry == GroupControl::groupController->groupRules->opFields ) ::fprintf(stderr,"(op)");
	else if ( item->groupBody->flags.data ) ::fprintf(stderr,"=%s",item->getText());
	
}

// accTraceSeq the sequence from interpretXPaccum's FIRST pass, on one line -- the pieces pass 2 reads by position (SEQ 361 R3)
extern "C" void accTraceSeq(GroupItem *seq)
{
	
	::fprintf(stderr,"ACCUM SEQ   ");
	for ( int k = 1; seq && seq->groupBody->groupList && k <= seq->groupBody->groupList->listLength; k++ )
	::accTraceItem(seq->get(k));
	::fprintf(stderr,"\n");
	
}

// accTraceTree one node per line, two spaces of indent per level; descends into the candidate's own nodes (ac..., xl1) only
extern "C" void accTraceTree(GroupItem *node, int depth)
{
	
	::fprintf(stderr,"ACCUM TREE  ");
	for ( int k = 0; k < depth; k++ ) ::fprintf(stderr,"  ");
	::accTraceItem(node);
	::fprintf(stderr,"\n");
	if ( !node || depth > 20 || !node->groupBody->groupList ) return;
	const char *t = node->groupBody->tag;
	if ( ::strncmp(t,"ac",2) && ::strcmp(t,"xl1") ) return;
	for ( int k = 1; k <= node->groupBody->groupList->listLength; k++ )
	::accTraceTree(node->get(k),depth + 1);
	
}

/*  THE C1 TRACE (SEQ 320). INCANT_ACCUM_TRACE is read by VALUE: unset, empty or 0 is off; 1
    traces every expression; any other value traces the expressions whose FIRST item carries that
    tag (INCANT_ACCUM_TRACE=r for `r = ...`). accTraceFlat prints the flat list before the split
    consumes it; accBuilt prints the tier tree and is the breakpoint symbol -- the tree is finished
    there and nothing has run. Output is stderr, one item per token, ops marked (op), a value
    after = where the item carries data.  */
extern "C" int accTraceWanted(GroupItem *flat)
{
	
	const char *v = ::getenv("INCANT_ACCUM_TRACE");
	if ( !v || !*v || !::strcmp(v,"0") )    return 0;
	if ( !::strcmp(v,"1") )                 return 1;
	if ( !flat || !flat->groupBody->groupList || !flat->groupBody->groupList->listLength ) return 0;
	GroupItem *first = flat->get(1);
	return first && !::strcmp(first->groupBody->tag,v);
	
}

// accessorWrite x.name = v: opDot handed opAssign its isAccessorProduct copy of x's groupField, parented to x; write the field on x through setGroupField, or say by name that it has no write case
extern "C" int accessorWrite(GroupItem *argument, GroupItem *product)
{
int 	value = 0;
	// methodWrite `x.methoD = "name"` binds a METHOD, which no integer can carry -- it leaves before the value is read
	if ( ::compare(product->groupBody->tag,"methoD") == 0 )
		return accessorWriteMethod(argument,product);
	if ( argument )
		value = argument->getCount();
	return accessorWriteValue(value,product);
}

// accessorWriteMethod x.methoD = "name": find the named method with dlsym, as ruleMethod does, and bind it as x's method; a name dlsym cannot find is refused and x is unchanged
extern "C" int accessorWriteMethod(GroupItem *argument, GroupItem *product)
{
GroupItem 	*holder = 0;
char 		*name = 0;
	holder = product->parent;
	if ( !holder || !argument )
		{
		::fprintf(stderr,"opAssign: `.methoD` needs a field on its left and a method name on its right -- nothing bound\n");
		return 1;
		}
	name = argument->getText();
	if ( !::dlsym(RTLD_SELF,name) )
		{
		::refuse(holder,"`.methoD`: no method named by the right-hand text -- nothing bound");
		return 1;
		}
	holder->setMethod((GroupItem*(*)(GroupItem*))::dlsym(RTLD_SELF,name));
	holder->groupBody->flags.instructType = 1;
	return 1;
}

// accessorWriteValue accessorWrite's body, handed the value rather than its node so the jitted = can call it with a scalar (jitAccessorWriteRT, SEQ 297 R0) -- one writer for both roads
extern "C" int accessorWriteValue(int value, GroupItem *product)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*flagDef = 0;
	flagDef = ruler->groupFields->get(product->groupBody->tag);
	if ( flagDef )
		if ( setGroupField(product->parent,flagDef->groupBody->gCount,value) )
			return 1;
	::fprintf(stderr,"opAssign: `.%s` has no write case -- the field is unchanged\n",product->groupBody->tag);
	return 0;
}

// appendGroup print the field passed in to the buffer passed in, or run its print shortcuts
extern "C" GroupItem *appendGroup(GroupItem *input, GroupItem *FormaT, Buffer *buffer)
{
char 		*atText = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
char 		*format = 0;
int 		indenting = 0;
GroupItem 	*grup = 0;
GroupItem 	*field = 0;
	field = input;
	// nullIsRefusal a refusing operator hands this a NULL and its error is already named -- skip the item quietly, never dereference it (F-36)
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
				while ( grup = field->prior(grup) )
					::printField(grup,format,buffer);
			else
			while ( grup = field->next(grup) )
				::printField(grup,format,buffer);
		else	::printField(field,format,buffer);
	else {
		// shortcuts the field text is a string of print shortcuts, each processed in turn
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
		// refusedPrintsNothing a refusal raised while the items were parsed silences the print: a primary never reaches runOP, where operators already stop (F-117)
		 if ( GroupControl::groupController->groupRules->refused ) break; 
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
/*******************************************************************************
	The incant clear command invokes this. It clears its argument.
    If data is a buffer, it is reset. If data is a stak, it is cleared.
    Otherwise input is cleared wiping data and list.
*******************************************************************************/
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

// callIsRule M3's DOOR, in one place: interpreted, a rule term; jitting, a rule term OR anything with an installed parse (F-123)
extern "C" int callIsRule(GroupItem *target)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	if ( !target )
		return 0;
	if ( target->isRuleTerm() )
		return 1;
	if ( ruler->jitting && target->groupBody->flags.hasNewParse )
		return 1;
	return 0;
}

// castStore the cast rule's store (SEQ 347 R0): a count, NUMBER or STRING target that has a kind keeps it and the argument is cast in; answers 1 when it took the store
extern "C" int castStore(GroupItem *argument, GroupItem *target)
{
	if ( !target->groupBody->flags.data || !argument->groupBody->flags.data )
		return 0;
	if ( target->groupBody->flags.data == argument->groupBody->flags.data )
		return 0;
	// castExempt an accessor product is a write THROUGH a field, and those are exempt (R1); a holder carries its group across and lists keep setContent (SEQ 346 R4)
	if ( target->groupBody->flags.isAccessorProduct )
		return 0;
	if ( isGROUP(argument->groupBody->flags.data) )
		return 0;
	if ( !isCOUNT(target->groupBody->flags.data) && !isNUMBER(target->groupBody->flags.data) && !isSTRING(target->groupBody->flags.data) )
		return 0;
	if ( isCOUNT(argument->groupBody->flags.data) || isNUMBER(argument->groupBody->flags.data) || isSTRING(argument->groupBody->flags.data) || isTOKEN(argument->groupBody->flags.data) )
		{
		// castCount .count is getCount: a NUMBER rounds half up toward +inf, a STRING or TOKEN reads its text length
		if ( isCOUNT(target->groupBody->flags.data) )
			target->setCount(argument->getCount());
		else
		if ( isNUMBER(target->groupBody->flags.data) )
			{
			if ( isNUMBER(argument->groupBody->flags.data) )
				target->setNumber(argument->getNumber());
			else	target->setNumber((double)argument->getCount());
			}
		else
		if ( isSTRING(target->groupBody->flags.data) )
			target->setText(argument->getText());
		return 1;
		}
	::refuse(target,"Operator = -- the argument has no count and no text to cast into this kind (SEQ 347 R0)");
	return 1;
}

/*  clearRefusal -- A REFUSAL'S SCOPE IS THE STATEMENT. Tony, ruled 2026-09-17.
    THE SINGLE WRITER of `ruler.refused = 0`, as refuse() is the single writer of the 1.
    docs/refusalScope.md carries the argument and the three measurements behind it.  */
extern "C" int clearRefusal(GroupItem *where)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	if ( !ruler->refused )
		return 0;
	ruler->refused = 0;
	return 1;
}

// clearWalked clear the per-walk mark over a subtree -- it descends only into a node it just unmarked, so the cyclic grammar terminates
extern "C" void clearWalked(GroupItem *field)
{
GroupItem 	*grup = 0;
	if ( !field )
		return;
	if ( !field->groupBody->flags.parseWalked )
		return;
	field->groupBody->flags.parseWalked = 0;
	if ( field->groupBody->flags.hasTraits || field->groupBody->flags.hasMembers )
		while ( grup = field->next(grup) )
			::clearWalked(grup);
}

// closeFile close the buffer's file; with no file set, the field's tag is the filename
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
GroupItem 	*pending = 0;
GroupItem 	*holder = 0;
	// stagedCompile a regenerated body arrives as a PENDING carrier: compile it, and install it only when green -- the rule keeps its current body and isAction until then (SEQ 215, F-31's store-compile-verify-bind)
	pending = field->get("pendingParseR");
	if ( !pending && !isCoded(field->groupBody->flags.actionType) )
		return 0;
	// any rule without parseRule as its method will exit here
	if ( pending )
		holder = pending;
	else	holder = field->parseHolder();
	code = holder->getProperty("CodE");
	// secondRefuseInCompile
	if ( !code )
		return ::refuse(field,"compile: isCoded is set but there is no CodE attribute; the flag and the artifact disagree");
	grup = 0;
	while ( grup = field->next(grup) )
		if ( grup->groupBody->flags.noPrint )
			continue;
		else
		if ( grup->isRuleTerm() )
			code->addAttribute(grup);
	// compileAddTempFields this and tempField -- named on grup, not bare: a declaration above re-points bare names (bear-trap #42)
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
	// refusedRuleDoesNotEndRun has to continue to processCode below
	GroupControl::groupController->groupRules->compiling = 1;
	// so ANYtoken allows key fields
	if ( !::processCode(field,holder) )
		{
		// BOTH arms clear it -- this arm RETURNS, so the tail below never runs and compiling would stay set for the rest of the process
		GroupControl::groupController->groupRules->compiling = 0;
		::printf("\t%s\n",code->getText());
		// failedPendingNamesCarrier a pending carrier that will not compile is DETACHED: the rule keeps its old body, and the refusal names the carrier and the rule
		if ( pending )
			{
			pending->remove();
			 { char zWhy[224]; ::snprintf(zWhy,sizeof zWhy,"compile: the pending carrier for %s would not parse -- %s keeps its current body; the message above names the position",field->groupBody->tag,field->groupBody->tag); return ::refuse(pending,zWhy); } 
			}
		return ::refuse(field,"compile: processCode would not parse the generated body; its message above names the position");
		}
	else	::printf("compile succeeded for %s\n",field->groupBody->tag);
	// installInOneStep the green pending carrier replaces builtinParseR in one step: detached, retagged, and swapped in by replace()
	if ( pending )
		{
		pending->remove();
		 pending->groupBody->tag = ::strdup("builtinParseR"); 
		// installAsProperty the old carrier leaves and the green one arrives, both on the property list (stroke 3)
		grup = field->getProperty("builtinParseR");
		if ( grup )
			grup->remove();
		field->addProperty(pending);
		}
	GroupControl::groupController->groupRules->compiling = 0;
endCompile:
	grup = 0;
	if ( field->groupBody->flags.hasTraits || field->groupBody->flags.hasMembers )
		while ( grup = field->next(grup) )
			{
			if ( grup->groupBody->flags.noPrint )
				continue;
			else	::compile(grup);
			}
	return field;
}

// compileIn THE KANT COMPILE: drive `source` as a compile for `owner` on its own floor, and pop -- the pop is the restore, so nothing is left set (SEQ 299); answers true or false, the BlocK goes on the request's `result` (SEQ 300)
extern "C" GroupItem *compileIn(GroupItem *input)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*spec = input;
GroupItem 	*blockRULE = ruler->grokking->getMember("BlocK");
GroupItem 	*ciReport = new GroupItem("driveReport");
GroupItem 	*ciOwner = 0;
GroupItem 	*ciSource = 0;
GroupItem 	*ciSlot = 0;
GroupItem 	*got = 0;
GroupItem 	*result = 0;
char 		*failText = 0;
	if ( spec && isGROUP(spec->groupBody->flags.data) )
		spec = spec->groupBody->gGroup;
	if ( spec )
		{
		ciOwner = spec->get("owner");
		ciSource = spec->get("source");
		}
	// namedOperands owner and source are attributes of the one argument; each may be a holder of a holder (a local bound with :=), so unwrap to the node
	while ( ciOwner && isGROUP(ciOwner->groupBody->flags.data) && ciOwner->groupBody->gGroup )
		ciOwner = ciOwner->groupBody->gGroup;
	while ( ciSource && isGROUP(ciSource->groupBody->flags.data) && ciSource->groupBody->gGroup )
		ciSource = ciSource->groupBody->gGroup;
	if ( !ciOwner || !ciSource )
		return ::refuse(input,"compileIn: the argument needs an `owner` and a `source` attribute -- the action to compile for, and the code to drive");
	if ( !ciSource->groupBody->flags.data )
		return ::refuse(ciOwner,"compileIn: `source` carries no code");
	// resultSlot the BlocK goes back on the request's `result`, never as the answer -- truth-testing a label FIRES it (#34); emptied first, so a failure leaves it empty, never stale (SEQ 300)
	ciSlot = spec->get("result");
	if ( !ciSlot )
		ciSlot = spec->addAttribute(new GroupItem("result"));
	ciSlot->setGroup(0);
	result = driveStep(ciSource,blockRULE,ciReport,ciOwner);
	if ( result && result != ruler->falseResult )
		{
		ciSlot->setGroup(result);
		return ruler->trueResult;
		}
	if ( got = ciReport->get("failedAt") )
		if ( got->getCount() >= 0 )
			failText = ciSource->getText() + got->getCount();
	reportCodeFail(ciOwner,failText);
	return ruler->falseResult;
}

// concatText a fresh text: left followed by right (SEQ 347 R3)
extern "C" char *concatText(char *left, char *right)
{
	
	if ( !left )    left = (char*)"";
	if ( !right )   right = (char*)"";
	size_t n = strlen(left) + strlen(right) + 1;
	char *t = (char*)malloc(n);
	snprintf(t,n,"%s%s",left,right);
	return t;
	
}

/*******************************************************************************
	copyOf() makes a copy of the field passed in. The copy groupBody is a copy.
    if the source isVirtual the copy will share the same list as grup (the source).
    If source is not isVirtual the copy list will be distinct but will have
    the same elements as the source. Difference is adding anything to the
    copy's list will not add anything to the source list.
*******************************************************************************/
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
    genParse.rtn -- WHAT IS LEFT OF THE C++ PARSE-METHOD EMITTER, retired by mapping 2026-09-26
    (SEQ 191): dataName, locateRule, showTree/treeOf, traceParse, dupTermRefusal (dupCensus cut 2026-09-30).

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
       (definingRule() was retired 2026-09-30, stroke 4.4a; the parse fact stands.)
*******************************************************************************/
// dataName the data-kind NAME for a data-kind number -- one table, read by getDataType and measureKindArm
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

// definersOf every occurrence of a rule -- the registry entry and each term carrying its tag -- and whether instanceRule() answers the REGISTRY's entry, as the shared-children invariant says it must (SEQ 216); prints the counts unconditionally; and whether every child of the shared list is parented to its owner
extern "C" GroupItem *definersOf(GroupItem *input)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	
	const char *want = input ? input->groupBody->tag : 0;
	int seen = 0, toRegistry = 0;
	GroupItem *reg = GroupControl::groupController->getRegistry((char*)"Grokking");
	GroupItem *regEntry = (want && reg) ? reg->get((char*)want) : 0;
	GroupItem *r = 0;
	while ( want && regEntry && (r = reg->next(r)) ) {
	GroupItem *t = 0;
	if ( ::strcmp(r->groupBody->tag,want) == 0 ) { seen++; if ( r->instanceRule() == regEntry ) toRegistry++;
	else ::fprintf(stderr,"  DEFINER %s registry entry answers %p, not itself\n",want,r->instanceRule()); }
	while ( (t = r->next(t)) )
	if ( ::strcmp(t->groupBody->tag,want) == 0 ) {
	seen++;
	GroupItem *d = t->instanceRule();
	if ( d == regEntry ) toRegistry++;
	else ::fprintf(stderr,"  DEFINER %s term of rule %s answers %s@%p (parent %s), not the registry's\n",want,r->groupBody->tag,
	d ? d->groupBody->tag : "-",d,(d && d->parent) ? d->parent->groupBody->tag : "-"); }
	}
	::fprintf(stderr,"DEFINERS %s occurrences=%d registry=%d others=%d\n",want ? want : "(none)",seen,toRegistry,seen - toRegistry);
	// childParents the shared list's children are parented to the node that OWNS the list -- the invariant definingRule() used to police, now read directly (2026-09-30)
	int kids = 0, owned = 0;
	GroupList *shared = regEntry ? regEntry->groupBody->groupList : 0;
	for ( GroupItem *c = shared ? shared->firstInList : 0; c; c = c->nextInParent ) {
	kids++;
	if ( c->parent == regEntry ) owned++;
	else ::fprintf(stderr,"  CHILDPARENT %s child %s parented to %s@%p, not the list's owner\n",want,c->groupBody->tag,c->parent ? c->parent->groupBody->tag : "-",(void*)c->parent); }
	::fprintf(stderr,"CHILDPARENTS %s children=%d owner=%d strays=%d\n",want ? want : "(none)",kids,owned,kids - owned);
	
	return ruler->trueResult;
}

// dispatcher run a listener, disguised as a void*, against its notifier -- a stub that says it needs rewriting
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

// driveFloorLabel a generated DRIVE ROOT's label is parked on the drive's floor, the activation just below the root's own -- one writer (checkInput), one reader (driveStep); returns 1 when it took the label (Tony, 2026-09-26, SEQ 185 (i))
extern "C" int driveFloorLabel(RuleStuff *stuff, GroupItem *label)
{
GroupRules 			*ruler = GroupControl::groupController->groupRules;
ParseActivation 	*below = 0;
ParseActivation 	*top = ruler->gParseActive;
	if ( !stuff || !top || ruler->stuffOf(top) != stuff )
		return 0;
	below = top->prev;
	if ( !below || !below->isFloor )
		return 0;
	below->label = label;
	return 1;
}

// driveStep runRule's body and the one drive runRule and tell share: divert input to the field's content, run the rule, and report OFFSETS into the message, never addresses (H3)
extern "C" GroupItem *driveStep(GroupItem *field, GroupItem *rule, GroupItem *report, GroupItem *forOwner)
{
GroupRules 			*ruler = GroupControl::groupController->groupRules;
GroupItem 			*result = 0;
GroupItem 			*intoField = 0;
int 				baseStak = 0;
int 				branchSave = 0;
int 				floorPushed = 0;
int 				priorDefining = 0;
int 				priorFloor = 0;
int 				priorIndent = 0;
ParseActivation 	driveFloor;
char 				*driveBase = 0;
	// unwrapTheHolder THE SINGLE DEREFERENCE OF THE CARRIER, before anything reads the field: a holder drives what it holds, never its name (SEQ 325 (h))
	if ( field && isGROUP(field->groupBody->flags.data) )
		field = field->groupBody->gGroup;
	// ruleDoorSeat WHICH DOOR a rule arrived through -- the one question the dispatch fork above cannot answer
	::measureRuleDoor(field,rule);
	// branchFrame a drive is its own execution root: the control slot is saved, cleared and restored, so a branch fired inside it cannot leak to the caller (SEQ 264)
	branchSave = ruler->branchKind;
	ruler->branchKind = 0;
	if ( ruler->inputSTAK )
		baseStak = ruler->inputSTAK->length;
	// driveFloor a drive pushes a FLOOR on the new road's activation list; deferredAbove stops there (Tony, 2026-09-24)
	driveFloor.instance = 0;
	driveFloor.isFloor = 1;
	// compileMark a compile's drive passes its owner: the floor answers inCompile() and floorOwner(), and its pop is the restore (SEQ 297, SEQ 299)
	driveFloor.compileOwner = forOwner;
	driveFloor.label = 0;
	driveFloor.prev = ruler->gParseActive;
	driveFloor.failPoint = 0;
	priorDefining = ruler->defining;
	priorIndent = ruler->lastIndent;
	if ( field && field->groupBody->flags.data )
		{
		ruler->gParseActive = &driveFloor;
		floorPushed = 1;
		}
	if ( field && field->groupBody->flags.data )
		{
		ruler->divertToRule = 1;
		ruler->pushInput(field);
		driveBase = ruler->atRuleMark;
		// inputFloor the message is the floor for the whole drive; a nested drive raises it and restores it
		priorFloor = ruler->inputFloor;
		ruler->inputFloor = ruler->inputSTAK->length;
		// markSeat SEQ 166 -- record the drive string's extent so every later point can ask
		// markSeat whether the mark is still inside it
		::measureMarkArm(field);
		::measureMarkPoint("2a-after-push");
		}
	// frameSeat the rule, the field, and the stuff/label chain the fork below is about to read
	::measureFrameProbe(field,rule);
	// heldField the carrier was dereferenced at entry (unwrapTheHolder) -- never add a second one here or below the fork
	intoField = field;
	// gateOnlyNeverGenerate runRule GATES on hasNewParse and NEVER installs a parse -- generation is explicit, through parser
	if ( rule->groupBody->flags.hasNewParse )
		{
		// noSilentFallthrough NEVER fall through to the old parse here -- it trades a loud crash for a quiet wrong answer
		// instanceFirst the reference's own { } before the rule's method -- the same read as runLeafParse's (F-O23)
		if ( !rule->groupBody->gMethod )
			result = ::refuse(rule,"runRule: hasNewParse is set but no method is installed to fire");
		else
		if ( rule->getRStuff() && rule->getRStuff()->overTo )
			result = ::parseUpTo(rule);
		else	result = rule->groupBody->gMethod(rule);
		}
	else {
		// noDataMeansLabel a non-null field with NO DATA is the label to attach into, never an input to divert
		if ( intoField && !intoField->groupBody->flags.data )
			result = ::parseR(rule,intoField);
		else {
			// oldRoadAttach an old-road rule called from INSIDE a new-road activation attaches into that activation -- with parse(0) attachLabel dropped its label, and every print shortcut vanished (F-120, F-116); a real drive has pushed its floor, so it still passes 0
			if ( ruler->gParseActive && !ruler->gParseActive->isFloor )
				result = rule->parse(ruler->stuffOf(ruler->gParseActive),0,0);
			else	result = rule->parse(0,0,0);
			}
		}
	// floorLabel a generated root that SUCCEEDED hands back the label its floor holds (trueResult when it parked none); a failure hands back what the fire did
	if ( floorPushed && rule->groupBody->flags.hasNewParse && result && result != ruler->falseResult && driveFloor.label )
		result = driveFloor.label;
	// markSeat2 SEQ 166 point 2 -- THE KEY PAIR, either side of the pop
	if ( field && field->groupBody->flags.data )
		::measureMarkPoint("2b-before-pop");
	// reportSeat the ONE moment consumed is readable -- after the parse, before the pop below puts the mark back in the sender
	if ( report && driveBase )
		reportDrive(report,driveFloor.failPoint,driveBase);
	if ( field && field->groupBody->flags.data )
		ruler->inputFloor = priorFloor;
	// driveOwnsIndent a drive's message is its own input: its indentation and an unterminated define end with it -- restore the caller's lastIndent and defining (F-125; each alone leaked)
	if ( field && field->groupBody->flags.data )
		{
		ruler->defining = priorDefining;
		ruler->lastIndent = priorIndent;
		}
	while ( field && field->groupBody->flags.data && ruler->inputSTAK && ruler->inputSTAK->length > baseStak )
		ruler->popInput();
	if ( field && field->groupBody->flags.data )
		::measureMarkPoint("2c-after-pop");
	// driveFloor pop the floor before the single return
	if ( floorPushed )
		ruler->gParseActive = driveFloor.prev;
	ruler->branchKind = branchSave;
	return result;
}

/*******************************************************************************
	The incant dumpContents command runs this. It is used mostly for debugging.
    It lists out the componenst of the argument passed in.
*******************************************************************************/
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
    dupTermRefusal -- F-110, shape B (Tony, 2026-09-23). A generated body calls
    each term BY NAME, and parseRule re-resolves the name with
    currentMETHOD.get(tag), which finds the FIRST face carrying that tag -- so a
    rule holding two faces with one tag hands the second call the first one's
    modifiers (wR+ s wR consumed 9 where the old road reads 7). generateParse asks
    here first and emits nothing for such a rule. Returns trueResult when it
    refused, null otherwise. The walk is raw sibling pointers: a nested next()
    would share its cursor with the outer one.
*******************************************************************************/
extern "C" GroupItem *dupTermRefusal(GroupItem *rule)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
int 		refused = 0;
	
	GroupList *terms = rule ? rule->groupBody->groupList : 0;
	for ( GroupItem *a = terms ? terms->firstInList : 0; a && !refused; a = a->nextInParent ) {
	if ( a->groupBody->flags.noPrint ) continue;
	for ( GroupItem *b = a->nextInParent; b; b = b->nextInParent ) {
	if ( b->groupBody->flags.noPrint ) continue;
	if ( ::strcmp(a->groupBody->tag,b->groupBody->tag) == 0 ) {
	::fprintf(stderr,"REFUSED %s -- generateParse: two terms are both %s, and a call by name reaches only the first; label one (again=%s)\n",
	rule->groupBody->tag,a->groupBody->tag,a->groupBody->tag);
	refused = 1;
	break;
	}
	}
	}
	
	if ( refused )
		return ruler->trueResult;
	return 0;
}

// enclosingInstance the instance of this term in the ENCLOSING RULE BODY, through the enclosing parse activation -- a drive floors it, so a drive root has none; never through currentMETHOD, which inside an action is the action and finds its own compiled BlocK (SEQ 212)
extern "C" GroupItem *enclosingInstance(GroupItem *field)
{
GroupRules 			*ruler = GroupControl::groupController->groupRules;
ParseActivation 	*top = ruler->gParseActive;
	// instanceNotOwner the activation's instance, never stuff.owner -- equal on every read measured (stroke 5.3 tap); the stuff test stays so the null cases match
	if ( !field || !top || top->isFloor || !ruler->stuffOf(top) || !top->instance )
		return 0;
	return top->instance->get(field->groupBody->tag);
}

// enclosingStuff the nearest enclosing activation's stuff, or null at a floor or an empty list -- every parentStuff reader asks here and none walks the list (stroke 5.8, SEQ 254 R3)
extern "C" RuleStuff *enclosingStuff(GroupItem *askField, RuleStuff *askStuff)
{
GroupRules 			*ruler = GroupControl::groupController->groupRules;
ParseActivation 	*top = ruler->gParseActive;
	// ownActivation a parseRule has pushed itself and a leaf has pushed nothing -- when the top is the asker's own, the enclosing one is below it (SEQ 254 R4)
	if ( top && top->instance == askField && ruler->stuffOf(top) == askStuff )
		top = top->prev;
	if ( !top || top->isFloor )
		return 0;
	return ruler->stuffOf(top);
}

// handBack STROKE 1.1a -- a term hands its per-call values back and leaves none on rStuff: sukcess, hereAt and a handed-up label are cleared at the ONE exit; a recycled label (fLAG, emptied by the repeat attach and in no tree) stays for reuse. Inline stores, no lookup, no slot (SEQ 283 R2). For parseRule the call bracket restores all three right after
// handedIn STROKE 1.2c -- the verdict, start mark and label come in as ARGUMENTS: a new-road leaf keeps them in locals and writes none on rStuff; parseRule hands in its stuff's (SEQ 301)
// exitFromParse the common exit every parse method returns through: sync, fire the label method, attach; a min-zero miss owes a success
extern "C" GroupItem *exitFromParse(GroupItem *field, int exitOK, char *exitAt, GroupItem *exitLab)
{
ParseActivation 	*cTop = 0;
ParseActivation 	*cRec = 0;
RuleStuff 			*cParent = 0;
char 				*failMark = 0;
GroupItem 			*cInstance = 0;
GroupItem 			*cLab = 0;
GroupItem 			*result = 0;
	// activeNotSubject cTop takes GroupRules' scope and the extra GroupItems take field's, so they are declared FIRST and ruler, field, ruleStuff re-mentioned after them and after every cTop use (bear-traps #42, #58)
GroupRules 			*ruler = GroupControl::groupController->groupRules;
RuleStuff 			*ruleStuff = field->getRStuff();
	if ( exitOK )
		{
		if ( ruleStuff->noAdvance )
			ruler->atRuleMark = exitAt;
		// firedFails a null back from a non-null label is the action failing
		cLab = field->fireLabelMethod(ruleStuff,exitLab,exitAt);
		if ( exitLab && !cLab )
			exitOK = 0;
		exitLab = cLab;
		if ( exitOK )
			{
			// oneAttach ONE ATTACH, through attachLabel, and the promote value is 1 -- promote=0 cannot RETAG here, and the retag is the half a members rule needs
			// containerYields CURE (c), F-138: a member CONTAINER (not a bin) with no label of its own takes its member's label whatever isTarget says -- the new road's attach only; the old road's attachLabel is untouched (SEQ 283 R3)
			if ( exitLab && !ruleStuff->noLabel )
				{
				cLab = exitLab;
				cTop = ruler->gParseActive;
				if ( cTop && cTop->instance == field && ruler->stuffOf(cTop) == ruleStuff )
					cTop = cTop->prev;
				if ( cTop && !cTop->isFloor )
					{
					cRec = cTop;
					cParent = ruler->stuffOf(cTop);
					cInstance = cTop->instance;
					}
				// parentRecord the parent's label lives in its RECORD, the enclosing activation (1.2f, SEQ 306)
				if ( cRec && !cRec->label && cInstance && cInstance->groupBody->flags.hasMembers && !cInstance->groupBody->flags.binType && cLab != ruler->labelNO )
					{
					cRec->label = cLab;
					// askTheRule the retag name is the parent instance's tag, never ruleName (ruleName stroke)
					if ( cLab->labelOf || (!cLab->groupBody->registry && !cLab->parent) )
						cLab->groupBody->tag = cInstance->groupBody->tag;
					}
				else	field->attachLabel(ruleStuff,cParent,1,0,cLab);
				}
			// oneBitReturn a successful term returns its TRUTH, never its label -- the label is already attached above, and a label carrying a matched 0 read as a failed alternative in a || chain (Tony, 2026-09-23, restoring ruling c')
			result = ruler->trueResult;
			}
		}
	if ( !result )
		{
		failMark = ruler->atRuleMark;
		ruler->atRuleMark = exitAt;
		// minZeroIsSatisfied a term whose MINIMUM IS ZERO is satisfied by not matching, so it owes the chain a success and not a null -- parseLoop owns what repeats inside it; this owns the max=1 optional and a max>1 LEAF (nameSet*, Modifier*), which never enters it (SEQ 208)
		if ( !ruleStuff->min && !field->groupBody->flags.isCondition && (ruleStuff->max <= 1 || !repeatsInLoop(field)) )
			result = ruler->trueResult;
		// rootFailPoint the ROOT's own failure point goes on the floor below it -- a term whose enclosing activation is a floor is the root (SEQ 292, SEQ 186 R2)
		if ( !result )
			{
			cTop = ruler->gParseActive;
			if ( cTop && cTop->instance == field && ruler->stuffOf(cTop) == ruleStuff )
				cTop = cTop->prev;
			if ( cTop && cTop->isFloor )
				cTop->failPoint = failMark;
			}
		}
	return result;
}

// fAIL bind the fail method named in the FAIL attribute's text
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

// followArgument argument is a BINDING, not a field: an isArgument operand holding a group yields what it holds
extern "C" GroupItem *followArgument(GroupItem *operand)
{
	
	// argSlot under jitting, a separately built function's own argument is its frame slot, not the emit-time node (SEQ 380)
	if ( GroupControl::groupController->groupRules->jitting ) {
	GroupItem *slotRead = ::jitArgSlotRead(operand);
	if ( slotRead ) return slotRead;
	//  argFollowRT a rule-holding argument has no slot: its RUN-TIME binding is published beside the build-time node this
	//  returns -- the function's own argument is %field, an inlined callee's is a run-time follow -- for jitEmitArgBind (SEQ 409)
	llvm::IRBuilder<> *b = gJitBuilder;
	if ( operand && operand->groupBody->flags.isArgument && isGROUP(operand->groupBody->flags.data)
	&& b && b->GetInsertBlock() && !b->GetInsertBlock()->getTerminator() ) {
	GroupItem *own = gJitCurrentAction ? gJitCurrentAction->get((char*)"argument") : nullptr;
	llvm::Value *v = nullptr;
	if ( operand == own && gJitCurrentFn ) v = gJitCurrentFn->getArg(0);
	else {
	llvm::LLVMContext &ctx = b->getContext();
	llvm::Type *ptr = llvm::PointerType::getUnqual(ctx); llvm::Type *i64 = llvm::Type::getInt64Ty(ctx);
	v = b->CreateCall(llvm::FunctionType::get(ptr, {ptr}, false),
	b->CreateIntToPtr(llvm::ConstantInt::get(i64, (uint64_t)(void*)&jitArgFollowRT), ptr, "argFollowFn"),
	{b->CreateIntToPtr(llvm::ConstantInt::get(i64, (uint64_t)(void*)operand), ptr, "argField")}, "argNow"); }
	gJitArgFollowNode = operand->getGroup();
	gJitArgFollowVal  = v; } }
	if ( operand && operand->groupBody->flags.isArgument && isGROUP(operand->groupBody->flags.data) )
	return operand->getGroup();
	return operand;
	
}

// frameFind read-only twin of frameStak -- null when no frame child exists, so restore can tell never saved from saved nothing without minting one
extern "C" GroupItem *frameFind(GroupItem *action)
{
	return action->getProperty("frameSTAK");
}

// frameStak the frame bracket's save-stack lives on a noPrint CHILD, never in the action's own data slot, which may hold the field's VALUE
extern "C" GroupItem *frameStak(GroupItem *action)
{
GroupItem 	*frame = action->getProperty("frameSTAK");
	if ( frame )
		return frame;
	// frameIsAProperty the frame stack is an artifact, so it goes on the property list (stroke 3)
	frame = new GroupItem("frameSTAK");
	frame->groupBody->flags.noPrint = 1;
	frame = action->addProperty(frame);
	return frame;
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

/*******************************************************************************
    getFile reads the field passed in as a file spec and loads the field buffer
    (creating it if necessary) with text read in from the file. Returns the
    loaded field.
*******************************************************************************/
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

// getMarkLineAt the getLine command: find the line holding fromThis's text in the source buffer, hand it back as a token field into the buffer (valid only while the buffer holds it in place), and leave the mark at the line's start; a mark already set is where the search starts
extern "C" GroupItem *getMarkLineAt(GroupItem *argument)
{
GroupItem 	*source = argument->get("source");
GroupItem 	*fromThis = argument->get("fromThis");
GroupItem 	*result = 0;
	// notASentinel both refusal arms already return the testable nothing; prose for this chain goes above it, never between its arms (bear-trap #29)
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
					// headLineStep  step over the \n the walk STOPPED at, never into line one
					while ( lineStart != buffer->start && *lineStart != '\n' )
						lineStart--;
					if ( *lineStart == '\n' )
						lineStart++;
					buffer->mark = lineStart + matchLength;
					while ( buffer->mark < buffer->current && *buffer->mark != '\n' )
						buffer->mark++;
					buffer->mark++;
					result = new GroupItem("markLine");
					result->setToken(lineStart,(int)(buffer->mark - lineStart));
					buffer->mark = lineStart;
					}
				else	::refuse(fromThis,"getLine: no line in the buffer contains the match text");
			}
		else	::refuse(fromThis,"getLine: no match field provided");
	else	::refuse(source,"getLine: no source, or the source is not a buffer");
	return result;
}

/*******************************************************************************
	Returns a type field (from types: defined in the Generating registry)
    based on the data of the field passed in.
*******************************************************************************/
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

// grammarHolds report every grammar rule, and every term of one, holding a child tagged like the argument -- an action body's name must never land there (SEQ 214, ownerT); prints the count unconditionally
extern "C" GroupItem *grammarHolds(GroupItem *input)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	
	const char *want = input ? input->groupBody->tag : 0;
	int held = 0;
	GroupItem *reg = GroupControl::groupController->getRegistry((char*)"Grokking");
	GroupItem *r = 0;
	while ( want && reg && (r = reg->next(r)) ) {
	if ( r->get((char*)want) ) { held++; ::fprintf(stderr,"  GRAMMARHOLDS %s under rule %s\n",want,r->groupBody->tag); }
	GroupItem *t = 0;
	while ( (t = r->next(t)) )
	if ( t->get((char*)want) ) { held++; ::fprintf(stderr,"  GRAMMARHOLDS %s under term %s of rule %s\n",want,t->groupBody->tag,r->groupBody->tag); }
	}
	::fprintf(stderr,"GRAMMARHOLDS %s = %d\n",want ? want : "(none)",held);
	
	return ruler->trueResult;
}

/*******************************************************************************
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
*******************************************************************************/
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

/*  handleCall -- the `(` arm. No operator: the falsy op is what tells runOP this is
    an invocation rather than an operation. ⚠ THE RECURSION STAMP LIVES HERE and
    nowhere else -- a body naming itself is how currentMETHOD learns it recurses.
    */
extern "C" GroupItem *handleCall(GroupItem *xpress, GroupItem *ANYtoken, GroupItem *InvokeArg)
{
GroupItem 	*op = 0;
GroupItem 	*arg = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	op = ruler->falseResult;
	if ( isGROUP(InvokeArg->groupBody->flags.data) )
		arg = InvokeArg->getGroup();
	// emptyParens an EMPTY () carries nothing and is NOT an argument -- hand on no third operand
	if ( !arg )
		if ( InvokeArg->groupBody->groupList || InvokeArg->groupBody->flags.data )
			arg = InvokeArg;
	xpress->addAttribute(op);
	xpress->addAttribute(ANYtoken);
	if ( arg )
		xpress->addAttribute(arg);
	return 0;
}

/*  THE STAR ROTATION, SUBSCRIPT HALF -- gated on `=[` so an INVOCATION
            `*fn(x)` is left alone   ruleActions.aCTionTokenXP.starDotRotation  */
extern "C" GroupItem *handleSubscript(GroupItem *xpress, GroupItem *unary, GroupItem *ANYtoken, GroupItem *InvokeArg)
{
GroupItem 	*op = 0;
GroupItem 	*arg = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	op = ruler->opFields->get("=[");
	if ( isGROUP(InvokeArg->groupBody->flags.data) )
		arg = InvokeArg->getGroup();
	if ( !arg )
		arg = InvokeArg;
	if ( unary )
		if ( ::unaryIsAccess(unary) )
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
			return xpress;
			}
	xpress->addAttribute(op);
	xpress->addAttribute(ANYtoken);
	xpress->addAttribute(arg);
	return 0;
}

// hasRepeatClass 1 when any character of the modifier is in the repetition class
extern "C" int hasRepeatClass(char *modifier)
{
	
	char one[2];
	one[1] = 0;
	for ( char *p = modifier; p && *p; p++ ) {
	one[0] = *p;
	if ( ::modifierIsRepeat(one) ) return 1;
	}
	
	return 0;
}

/*  interpretXPaccum -- ExpressioN's actor, the one expression road (SEQ 311; the old road
    retired 2026-10-13). The grammar hands it a FLAT list of Token terms (TokenXP and UnaryXP
    left the grammar, SEQ 361): a name, a literal, an operator entry, or a GROUP -- a Parens /
    Braced label, retagged Token, whose member holds its inner expression. Pass 1 reads each
    group by position: after an operand it is a call or a subscript; with no operand before
    it, kant has no parenthetical expressions and it refuses. Pass 2 decides by POSITION: an
    op where an operand is expected is a prefix; an op after an operand is binary; `.`, a call, a subscript after an operand
    are postfixes on it. An ACCESS prefix (`*`, a leading `.`) binds to the name before the
    postfixes, any other prefix to the finished operand: *block(code) is (*block)(code),
    !f(x) is !(f(x)). The result is ONE FLAT list -- operand, then (op, operand) pairs --
    whose method is runOPaccum.  */
extern "C" GroupItem *interpretXPaccum(GroupItem *xpList)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
int 		i = 0;
int 		j = 0;
int 		n = 0;
int 		expectOperand = 1;
int 		traced = 0;
int 		opTerm = 0;
GroupItem 	*seq = 0;
GroupItem 	*flat = 0;
GroupItem 	*term = 0;
GroupItem 	*name = 0;
GroupItem 	*unary = 0;
GroupItem 	*invoke = 0;
GroupItem 	*piece = 0;
GroupItem 	*cur = 0;
GroupItem 	*pend = 0;
GroupItem 	*rest = 0;
GroupItem 	*node = 0;
GroupItem 	*jux = 0;
GroupItem 	*right = 0;
	seq = new GroupItem("acSeq");
	i = 1;
	n = 0;
	if ( xpList->groupBody->groupList )
		n = xpList->groupBody->groupList->listLength;
	while ( i <= n )
		{
		term = xpList->get(i);
		i = i + 1;
		// groupTerm a Parens / Braced reaches here as a LABELLED node -- retagged Token, its first member the InvokeArg holder its actor minted; asked of the member, because a quote can also arrive as a data-less Token (SEQ 361 R1)
		if ( ::accGroupTerm(term) )
			{
			invoke = term->get(1);
			// noParenthetical a group with no operand directly before it is a parenthetical expression, and kant has none: refused by name, and the build GOES ON with its inner value as a harmless primary -- the armed statement dispatches nothing, the next one runs (standing, 2026-09-29; SEQ 361 R2)
			if ( !::accOperandBefore(seq) )
				{
				::refuse(term,"kant has no parenthetical expressions");
				if ( isGROUP(invoke->groupBody->flags.data) )
					seq->addAttribute(invoke->getGroup());
				else	seq->addAttribute(ruler->falseResult);
				continue;
				}
			if ( invoke->groupBody->flags.fLAG )
				piece = new GroupItem("acPostSub");
			else	piece = new GroupItem("acPostCall");
			piece->addAttribute(invoke);
			seq->addAttribute(piece);
			continue;
			}
		seq->addAttribute(term);
		}
	flat = new GroupItem("acX");
	cur = 0;
	jux = 0;
	pend = new GroupItem("acPend");
	rest = 0;
	expectOperand = 1;
	i = 1;
	n = 0;
	if ( seq->groupBody->groupList )
		n = seq->groupBody->groupList->listLength;
	while ( i <= n )
		{
		term = seq->get(i);
		i = i + 1;
		// operatorEntry an operator is an ENTRY of the Operators registry, never the registry itself, and a name followed by a call is the call's target (SEQ 330 A1)
		opTerm = 0;
		if ( term->groupBody->registry == ruler->opFields )
			opTerm = 1;
		if ( isREGISTRY(term->groupBody->flags.binType) )
			opTerm = 0;
		right = 0;
		if ( i <= n )
			right = seq->get(i);
		if ( right )
			if ( ::compare(right->groupBody->tag,"acPostCall") == 0 )
				opTerm = 0;
		if ( opTerm )
			{
			if ( expectOperand )
				{
				pend->addAttribute(term);
				continue;
				}
			if ( ::compare(term->groupBody->tag,".") == 0 )
				{
				if ( i > n )
					return ::refuse(term,"a dot with nothing after it (the accumulator candidate, SEQ 311)");
				right = seq->get(i);
				i = i + 1;
				// dotOpScope a.*b refuses with trunk's words and the build GOES ON: the armed statement dispatches nothing, and the refusal ends the statement, never the parse (SEQ 327 D2; scope ruled 2026-09-17)
				if ( right->groupBody->registry == ruler->opFields )
					{
					unary = right;
					if ( ::compare(right->groupBody->tag,"*") == 0 )
						unary = ruler->opFields->get("deref");
					refuseDotUnaryOp(term,unary);
					right = new GroupItem(right->groupBody->tag);
					}
				if ( right->groupBody->registry != ruler->groupFields )
					right = new GroupItem(right->groupBody->tag);
				node = new GroupItem("acDot");
				node->addAttribute(term);
				node->addAttribute(cur);
				node->addAttribute(right);
				node->setMethod(::runOP);
				node->groupBody->flags.invoke = 1;
				cur = node;
				continue;
				}
			cur = interpretXPaccumWrap(cur,rest);
			rest = 0;
			if ( jux )
				{
				jux->addAttribute(cur);
				cur = interpretXPaccumWrap(jux,0);
				jux = 0;
				}
			flat->addAttribute(cur);
			cur = 0;
			flat->addAttribute(term);
			expectOperand = 1;
			continue;
			}
		if ( ::compare(term->groupBody->tag,"acPostCall") == 0 )
			{
			if ( expectOperand )
				return ::refuse(term,"a call with nothing to call (the accumulator candidate, SEQ 311)");
			node = new GroupItem("acC");
			::handleCall(node,cur,term->get(1));
			node->setMethod(::runOPaccum);
			node->groupBody->flags.invoke = 1;
			cur = node;
			continue;
			}
		if ( ::compare(term->groupBody->tag,"acPostSub") == 0 )
			{
			if ( expectOperand )
				return ::refuse(term,"a subscript with nothing to subscript (the accumulator candidate, SEQ 311)");
			node = new GroupItem("acSub");
			::handleSubscript(node,0,cur,term->get(1));
			node->setMethod(::runOP);
			node->groupBody->flags.invoke = 1;
			cur = node;
			continue;
			}
		// ruleArgument a bare rule name is passed, never fired; only name(...) fires it (SEQ 330 A2)
		if ( term->groupBody->flags.actionType || term->groupBody->flags.instructType )
			if ( !term->groupBody->flags.isRule )
				term->groupBody->flags.invoke = 1;
		if ( expectOperand )
			{
			cur = term;
			// bareAccessor a GroupFields name with no prefix and no postfix reads through lastREF (accBare; SEQ 328 D1)
			right = 0;
			if ( i <= n )
				right = seq->get(i);
			if ( !pend->groupBody->groupList )
				cur = accBare(term,right);
			j = 0;
			if ( pend->groupBody->groupList )
				j = pend->groupBody->groupList->listLength;
			while ( j > 0 )
				{
				piece = pend->get(j);
				// leadingDotNumber `.5` is refused by name with trunk's F-117 hand and the dot dropped, so the number stays a harmless primary -- moved here from pass 1 (SEQ 361; SEQ 327 D4)
				if ( ::compare(piece->groupBody->tag,".") == 0 )
					if ( !right || (::compare(right->groupBody->tag,"acPostCall") != 0 && ::compare(right->groupBody->tag,"acPostSub") != 0) )
						if ( ::refuseLeadingDotNumber(piece,term) )
							{
							j = j - 1;
							continue;
							}
				if ( ::compare(piece->groupBody->tag,".") == 0 )
					{
					node = new GroupItem("acDot");
					node->addAttribute(piece);
					node->addAttribute(cur);
					node->setMethod(::runOP);
					node->groupBody->flags.invoke = 1;
					cur = node;
					}
				else
				if ( ::unaryIsAccess(piece) )
					cur = interpretXPaccumU(piece,cur);
				else	break;
				j = j - 1;
				}
			rest = new GroupItem("acRest");
			while ( j > 0 )
				{
				rest->addAttribute(pend->get(j));
				j = j - 1;
				}
			pend = new GroupItem("acPend");
			expectOperand = 0;
			continue;
			}
		// juxtaposed  an operand after an operand with no op between: the finished one joins the list, the new one is current
		cur = interpretXPaccumWrap(cur,rest);
		rest = 0;
		if ( !jux )
			jux = new GroupItem("acJux");
		jux->addAttribute(cur);
		// bareAccessor a juxtaposed operand takes the same road -- a print item's `"x" taG` (SEQ 328 D1)
		right = 0;
		if ( i <= n )
			right = seq->get(i);
		cur = accBare(term,right);
		}
	if ( pend->groupBody->groupList )
		return ::refuse(pend->get(1),"a prefix operator with no operand after it (the accumulator candidate, SEQ 311)");
	if ( cur )
		{
		cur = interpretXPaccumWrap(cur,rest);
		if ( jux )
			{
			jux->addAttribute(cur);
			cur = interpretXPaccumWrap(jux,0);
			}
		flat->addAttribute(cur);
		}
	// accTrace INCANT_ACCUM_TRACE=1 traces every expression, =<name> those whose first item is <name>; the flat list prints before the split consumes it
	traced = accTraceWanted(flat);
	// accTraceSeq pass 1's own sequence, which pass 2 only reads -- stroke 4's certificate compares it (SEQ 361 R3)
	if ( traced )
		accTraceSeq(seq);
	if ( traced )
		accTraceFlat(flat);
	// tierSplit the flat list becomes one node per tier, loosest first, each with its executor (SEQ 319 c3)
	if ( !flat->groupBody->groupList )
		node = 0;
	else
	if ( flat->groupBody->groupList->listLength == 1 )
		node = flat->get(1);
	else	node = accBuild(flat);
	// accBuilt THE BREAKPOINT: the tier tree is finished and not yet run (SEQ 320)
	if ( traced )
		accBuilt(node);
	xpList->clear();
	xpList->setGroup(node);
	return xpList;
}

/*  interpretXPaccumU -- one prefix over one operand: an acU, run by runOPaccum.  */
extern "C" GroupItem *interpretXPaccumU(GroupItem *op, GroupItem *operand)
{
GroupItem 	*node = new GroupItem("acU");
	node->addAttribute(op);
	node->addAttribute(operand);
	node->setMethod(::runOPaccum);
	node->groupBody->flags.invoke = 1;
	return node;
}

/*  interpretXPaccumWrap -- the prefixes that did NOT bind to the name (rest, nearest the
    name first) wrap the finished operand: !f(x) is !(f(x)).  */
extern "C" GroupItem *interpretXPaccumWrap(GroupItem *operand, GroupItem *rest)
{
int 		i = 1;
GroupItem 	*done = operand;
	// juxtaposed  operands with no op between them are a list, held in SOURCE order as xl1 now is (c4)
	if ( ::compare(done->groupBody->tag,"acJux") == 0 )
		{
		done = new GroupItem("xl1");
		done->groupBody->flags.binType = 3;
		while ( i <= operand->groupBody->groupList->listLength )
			{
			done->addAttribute(operand->get(i));
			i = i + 1;
			}
		i = 1;
		}
	if ( !rest )
		return done;
	if ( !rest->groupBody->groupList )
		return done;
	while ( i <= rest->groupBody->groupList->listLength )
		{
		done = ::interpretXPaccumU(rest->get(i),done);
		i = i + 1;
		}
	return done;
}

// isCallable a call has something to call: a rule (callIsRule), an action, or a method
extern "C" int isCallable(GroupItem *target)
{
	if ( !target )
		return 0;
	if ( ::callIsRule(target) )
		return 1;
	if ( target->groupBody->flags.actionType )
		return 1;
	if ( isMethod(target->groupBody->flags.instructType) )
		return 1;
	return 0;
}

extern "C" GroupItem *jitAccessorNodeRT(GroupItem *source, GroupItem *product)
{
	
	if ( GroupControl::groupController->groupRules->refused ) return 0;
	if ( !product ) return 0;
	if ( product->groupBody->flags.isAccessorProduct ) accessorWrite(source, product);
	if ( source )   product->setContent(source);
	else            product->clearData();
	return product;
	
}

/*  the emitted `x.name = v`: what opAssign's accessorWrite line does, at run time,
    on the product opDot minted (SEQ 297 R0). The mark is tested HERE because the
    product exists only at run time; an unmarked product (a dot that returned a
    node, not a groupField copy) stores nothing, as interpreted opAssign writes
    only the copy. jitAccessorNodeRT is the same with a node on the right.
    jitEmitters.jitEmitAssign.dotTarget  */
extern "C" GroupItem *jitAccessorWriteRT(int value, GroupItem *product)
{
	
	if ( GroupControl::groupController->groupRules->refused ) return 0;
	if ( !product || !product->groupBody->flags.isAccessorProduct ) return product;
	accessorWriteValue(value, product);
	return product;
	
}

/*  jitArgCountRT -- run time, a built function's entry: the value of the node it was handed (%field), following a
    binding one level as followArgument does; 0 for nothing (SEQ 380).  */
extern "C" int jitArgCountRT(GroupItem *field)
{
	
	GroupItem *node = field;
	if ( node && node->groupBody->flags.isArgument && isGROUP(node->groupBody->flags.data) )
	node = node->getGroup();
	return node ? node->getCount() : 0;
	
}

/*  jitArgFollowRT -- run time, an inlined callee's rule-holding argument: what its binding holds NOW (SEQ 409).  */
extern "C" GroupItem *jitArgFollowRT(GroupItem *field)
{
	 return ( field && isGROUP(field->groupBody->flags.data) ) ? field->getGroup() : nullptr; 
}

/*  jitArgSlotRead -- an own-argument read in a separately built function: a fresh node whose value is a load of the
    argument slot at THIS point, or null when the operand is not that function's argument (SEQ 380). A node per read,
    so no result rides on a shared operand (SEQ 376). An inlined callee handed this node binds to it: the chain rule.  */
extern "C" GroupItem *jitArgSlotRead(GroupItem *operand)
{
	
	if (!gJitArgSlot || !gJitBuilder || !operand) return 0;
	if (!operand->groupBody->flags.isArgument || operand->groupBody != gJitArgBody) return 0;
	GroupItem *slotRead = new GroupItem((char*)"argSlot");
	slotRead->jitData = new JitData();
	slotRead->jitData->jitSlot = gJitArgSlot;
	slotRead->jitData->jitType = llvm::Type::getInt32Ty(gJitBuilder->getContext());
	slotRead->jitData->setJitter(gJitBuilder->CreateLoad(slotRead->jitData->jitType, gJitArgSlot, "arg"));
	slotRead->jitData->computed = true;
	gJitSeeded.push_back(slotRead);
	return slotRead;
	
}

/*  jitArgSyncRT -- run time, after a write to a built function's OWN argument: the argSlot node holds the new value; copy it
    to the field the argument is bound to (%field, followed one level as jitArgCountRT reads it) and return it for the slot,
    so slot, node and bound field agree -- the interpreted write is immediate (SEQ 421).  */
extern "C" int jitArgSyncRT(GroupItem *node, GroupItem *field)
{
	
	if ( !node ) return 0;
	GroupItem *bound = field;
	if ( bound && bound->groupBody->flags.isArgument && isGROUP(bound->groupBody->flags.data) ) bound = bound->getGroup();
	if ( bound && bound != node ) {
	if ( isNUMBER(node->groupBody->flags.data) ) bound->setNumber(node->getNumber());
	else                                         bound->setCount(node->getCount()); }
	return node->getCount();
	
}

/*  the emitted `=` with a node on the right does what opAssign does: setContent,
    or clearData on a null -- a holder on the right carries its group across (Tony,
    2026-10-04; SEQ 295 R2). Edit the two together; incant/pop/assignRoadT pins them.
    jitEmitters.jitAssignNodeRT  */
extern "C" GroupItem *jitAssignNodeRT(GroupItem *source, GroupItem *target)
{
	
	/*  THE STORE RULING on the emitted road (Tony, 2026-09-05): an armed
	statement stores nothing. The interpreted twin is runOP's check before
	dispatch; this is the same rule where the emitted road actually does its
	storing.   jitEmitters.jitAssignNodeRT.storeRuling  */
	if ( GroupControl::groupController->groupRules->refused ) return 0;
	if ( !target )  return 0;
	//  castRule opAssign's twin casts as opAssign does (SEQ 347 R0)
	if ( source )   { if ( !::castStore(source,target) ) target->setContent(source); }
	else            target->clearData();
	return target;
	
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

/*  jitBodyField -- THE FIELD A JITTED BODY RUNS ON (i32(ptr), ruled 2026-09-23):
    what the action's `argument` binding holds right now, or null. No emitter reads
    the parameter yet; station 4's door passes a parse carrier's frame through it.  */
extern "C" GroupItem *jitBodyField(GroupItem *action)
{
	
	if (!action) return nullptr;
	GroupItem *a = action->get((char*)"argument");
	return a ? a->getGroup() : nullptr;
	
}

/*  jitBoxCountRT -- run time, a self-call site: a fresh node holding the call's computed value, one per call, so
    the callee's slot and its run-time binding both read THIS call's argument (SEQ 380).  */
extern "C" GroupItem *jitBoxCountRT(int value)
{
	
	GroupItem *box = new GroupItem((char*)"argument");
	box->setCount(value);
	return box;
	
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
	// computedVal a computed value belongs to one function's build; a freed Value's address must not match the next (SEQ 365)
	gJitComputedVal = nullptr;
	// cursorRecord a handed-over cursor belongs to one function's build: the next function built in the same compile must not read it (SEQ 403)
	gJitRTCursors.clear();
	// holderRecord a holder written at run time belongs to one function's build, as the cursor record does (SEQ 405)
	gJitRTHolders.clear();
	gJitStmtHolderWrites.clear();
	gJitArgFollowNode = nullptr; gJitArgFollowVal = nullptr;
	
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
	//  ⚠ A CARRIER IS NAMED FROM ITS HOLDER. Every generated parse body lives in
	//  a noPrint carrier tagged builtinParseR, so naming from the action's own
	//  tag gave all of them jit_builtinParseR -- and the SECOND compile in a
	//  process failed addIRModule with "duplicate definition of symbol
	//  '_jit_builtinParseR'" (measured 2026-09-23). The holder's tag is the rule's
	//  name, stable across incarnations, so the persistence premise above holds:
	//  jit_ExpressioN_builtinParseR. An ordinary action is not noPrint and keeps
	//  jit_<tag> exactly as before.
	char fnName[128];
	{
	const char *tag = action->groupBody->tag;
	if (!tag || !*tag) tag = "anon";
	const char *holder = 0;
	if (action->groupBody->flags.noPrint && action->parent)
	holder = action->parent->groupBody->tag;
	size_t n = 0;
	fnName[n++] = 'j'; fnName[n++] = 'i'; fnName[n++] = 't'; fnName[n++] = '_';
	for (int part = 0; part < 2; part++) {
	const char *src = part ? tag : holder;
	if (!src || !*src) continue;
	if (part && holder && *holder && n < sizeof(fnName) - 1) fnName[n++] = '_';
	for (const char *p = src; *p && n < sizeof(fnName) - 1; p++)
	fnName[n++] = ((*p >= 'A' && *p <= 'Z') || (*p >= 'a' && *p <= 'z') ||
	(*p >= '0' && *p <= '9') || *p == '_') ? *p : '_'; }
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
	//  ⚠ UNIFORM i32(ptr), RULED 2026-09-23 (Tony): the pointer is the field the
	//  body runs on -- an action's argument, a parse carrier's frame. One layout
	//  change for every jitted body; an ordinary action simply does not read it.
	//  The named seam in RuleStuff.twk's jitMethod header, paid.
	llvm::Function *fn = llvm::Function::Create(
	llvm::FunctionType::get(i32, {llvm::PointerType::getUnqual(C)}, false),
	llvm::Function::ExternalLinkage, fnName, gJitModule);
	fn->getArg(0)->setName("field");
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
	// Unified JIT emit-on-walk (pivot, 2026-06-30): jitting ONLY (the bytecode road's
	// generating mode retired, deepClean S4). Parsing builds the runOP trees; EXECUTING the
	// BlocK runs them, and each opMethod's jitting gate emits LLVM in place (the
	// runOP seeding gate seeds leaves first). The interpret walk owns its traversal
	// and never re-parents live nodes — the structural cure for the by-reference
	// operand-stack corruption the deferred jitXpress path hit.
	//  THE EMIT WALK IS A FRAME FOR THE CONTROL SLOT (P4): an emit-time break, continue or
	//  return writes the slot and aCTionBlocK walks on past it, so the slot is saved here
	//  and restored after the walk -- the compile cannot leave a signal for the caller.
	int emitBranchSave = ruler->branchKind;
	ruler->branchKind = 0;
	ruler->jitting = 1;
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
	::processCode(action,action->actionHolder());
	
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
	//  argSlotNotCount the argument is a BINDING: its count shares storage with gGroup, so it gets the slot below, never this one (SEQ 380)
	if (fb->flags.isArgument) continue;
	if (fb->flags.noPrint) continue;
	if (fld->jitData) continue;          // already seeded this compile
	//  nonScalarNoSlot a local whose writer makes it a holder or a non-scalar kind gets no scalar slot (SEQ 388 R1)
	if (::jitLocalNonScalar(fb)) continue;
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
	//  argSlot THE ARGUMENT SLOT (SEQ 380): filled at entry from %field, the per-call node the caller passed; every own-argument read loads it
	{
	GroupItem *af = action->get((char*)"argument");
	GroupItem *bound = (af && af->groupBody->flags.isArgument && isGROUP(af->groupBody->flags.data)) ? af->getGroup() : nullptr;
	int bd = bound ? bound->groupBody->flags.data : 0;
	if (bound && !bound->groupBody->groupList && !isNUMBER(bd) && !isSTRING(bd)
	&& (isCOUNT(bd) || bound->groupBody->flags.isLiteral || bound->jitData)) {
	llvm::Type *ptrT = llvm::PointerType::getUnqual(C);
	llvm::Value *slot = B.CreateAlloca(i32, nullptr, "argSlot");
	llvm::Value *readFn = B.CreateIntToPtr(
	llvm::ConstantInt::get(llvm::Type::getInt64Ty(C), (uint64_t)(void*)&jitArgCountRT), ptrT, "argReadFn");
	llvm::FunctionType *readTy = llvm::FunctionType::get(i32, {ptrT}, false);
	B.CreateStore(B.CreateCall(readTy, readFn, {fn->getArg(0)}, "argIn"), slot);
	gJitArgBody   = af->groupBody;
	gJitArgSlot   = slot;
	gJitArgOrigin = bound; }
	}
	// =========================== end frame prologue ===========================
	// Execute the parsed BlocK under jitting: runOP/op-gates emit straight-line IR;
	// control flow lands via aCTionIF's jitting gate -> jitEmitGIF.
	//  walkScope the emit walk begins clean (a parse's refusal ended with the parse) and is the only stretch where refuse() is silent (SEQ 372 R0, R1)
	{
	::clearRefusal(action);
	bool walkSave = gJitEmitWalk;
	gJitEmitWalk = true;
	jitExecBlock(action);
	gJitEmitWalk = walkSave;
	}
	ruler->jitting = 0;
	ruler->branchKind = emitBranchSave;
	//  kindlessNet a slotted local still kindless with no writer the build saw is NOT JITTABLE (SEQ 388 R2, Tony)
	if (!gJitRestartNeeded) for (JitFrameSlot &f : gJitFrame) {
	GroupBody *lb = f.ty->isDoubleTy() ? (GroupBody*)((char*)f.home - offsetof(GroupBody, gNumber))
	: (GroupBody*)((char*)f.home - offsetof(GroupBody, gCount));
	if (lb->flags.data || gJitLocalKind.count(lb)) continue;
	fprintf(stderr, "=== jitRunAction: NOT JITTABLE -- %s's local %s is kindless and has no writer the build can see ===\n",
	action->groupBody->tag, lb->tag ? lb->tag : "?");
	fflush(stderr);
	gJitBuilder = nullptr;
	gJitResult  = nullptr;
	gJitResultSlot = nullptr;
	return -8; }
	
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

// jitCarryCopy a copy-out keeps the compiled value: a FRESH JitData holding the source's, never the shared pointer -- a later dot re-seeds tempField's (docket item 1)
extern "C" void jitCarryCopy(GroupItem *keep, GroupItem *source)
{
	
	if ( !GroupControl::groupController->groupRules->jitting || !keep || !source || !source->jitData ) return;
	keep->jitData = new JitData();
	keep->jitData->setJitter(source->jitData->getJitter());
	gJitSeeded.push_back(keep);
	
}

// jitCastCountTextRT a jitted store of a count into a STRING target takes it as text (SEQ 347 R0)
extern "C" void jitCastCountTextRT(GroupItem *field, int value)
{
	 if (field) { char *t = (char*)malloc(24); snprintf(t,24,"%d",value); field->setText(t); } 
}

// jitCastNumberTextRT a jitted store of a NUMBER into a STRING target takes it as text (SEQ 347 R0)
extern "C" void jitCastNumberTextRT(GroupItem *field, double value)
{
	 if (field) { char *t = (char*)malloc(32); snprintf(t,32,"%g",value); field->setText(t); } 
}

extern "C" void jitChanPopRT()
{
	
	if ( gChanStkTop > 0 ) {
	gChanStkTop--;
	if ( gChanStkBody[gChanStkTop] ) {
	gChanStkBody[gChanStkTop]->gGroup     = gChanStkGroup[gChanStkTop];
	gChanStkBody[gChanStkTop]->flags.data = gChanStkData[gChanStkTop];
	}
	}
	
}

/*  jitChanPushRT / jitChanPopRT -- the argument channel's two halves: push the pending entry (or an empty one) and clear
    it; pop, and write a non-empty entry's binding back. jitSaveFrameRT / jitRestoreFrameRT call them around a self-call;
    an inlined region with a run-time bind calls them alone, at its entry and its join -- the binding only, no locals
    (SEQ 396 R0). gChanStk is the stack, so regions nest (R2).  */
extern "C" void jitChanPushRT()
{
	
	if ( gChanStkTop < GCHAN_DEPTH ) {
	gChanStkBody[gChanStkTop]  = gChanPendBody;
	gChanStkGroup[gChanStkTop] = gChanPendGroup;
	gChanStkData[gChanStkTop]  = gChanPendData;
	gChanStkTop++;
	}
	gChanPendBody = 0; gChanPendGroup = 0; gChanPendData = 0;
	
}

/*  jitCursorHandOver / jitHandedCursor -- an iterate refused at build is handed over to run time (its statement becomes one
    jitStmtRT call), so its cursor is not flagged isIterator until the run, and opPlusPlus's build-time read would emit a count
    increment that never ends. aCTionIterate's poison arms record the cursor; opPlusPlus asks, and emits the iterator step,
    called at run time (SEQ 402). The record is per function build: jitBuildFunction clears it at its head (SEQ 403).  */
extern "C" void jitCursorHandOver(GroupItem *iterator)
{
	 if ( iterator ) gJitRTCursors.insert((void*)iterator->groupBody); 
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
	
	//  foldedIntoHandOver a degrade inside a statement already handed to run time is the same fallback, counted once (SEQ 384)
	if ( gJitHandOver ) return gJitDegradeCount;
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
	// concatJit a STRING or TOKEN left is a run-time concatenation, as opPlus's own jitting gate does (SEQ 347 R3)
	if ( isSTRING(target->groupBody->flags.data) || isTOKEN(target->groupBody->flags.data) )
		{
		 return jitEmitConcat(argument, target); 
		}
	 return jitEmitBinary(argument, target, jitAdd); 
}

/*  jitEmitArgBind -- THE ONE BIND, emitted at run time for a call's argument: the published run-time node, a boxed count,
    or the baked operand, through jitBindArgRT. jitEmitSelfCall's argument block, lifted verbatim, so the self-call and
    runAction's inline arm bind alike (SEQ 393 R2, SEQ 396 R0). Returns 1 and leaves the bound argument in gJitBoundArg
    when it emitted a bind; 0 for a call with no argument. Its header and the run-time-argument note are jitEmitSelfCall's.  */
extern "C" int jitEmitArgBind(GroupItem *argument, GroupItem *action)
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	gJitBoundArg = nullptr;
	if (!b || !action) return 0;
	llvm::Value *argVal = nullptr;
	//  argFollowRT a rule-holding argument followed at build binds its RUN-TIME binding, never the build-time node (SEQ 409)
	if (argument && gJitArgFollowVal && argument == gJitArgFollowNode) {
	argVal = gJitArgFollowVal;
	gJitArgFollowNode = nullptr; gJitArgFollowVal = nullptr; }
	if (!argVal && !argument && gJitLastIsNode && gJitResultNode) {
	argVal = gJitResultNode;
	gJitLastIsNode = false; }
	if (argument || argVal) {
	llvm::LLVMContext &ctx = b->getContext();
	llvm::Type *ptr = llvm::PointerType::getUnqual(ctx);
	llvm::Type *i64 = llvm::Type::getInt64Ty(ctx);
	llvm::Type *i32 = llvm::Type::getInt32Ty(ctx);
	//  boxedArgument THE CALL PASSES ITS COMPUTED VALUE (SEQ 380): a fresh node per call, made at run time from the
	//  i32 in hand, so the callee's slot reads THIS call's value. A non-scalar argument still passes its node.
	llvm::Value *boxed = nullptr;
	if (!argVal && !argument->groupBody->groupList) {
	int ad = argument->groupBody->flags.data;
	if (!argument->jitData && !isNUMBER(ad) && !isSTRING(ad) && !isGROUP(ad) && argument->groupBody->flags.isLiteral)
	jitSeedLiteral(argument);
	//  boxComputedOnly a value the build computed is boxed; a named field binds as ITSELF -- its name and its run-time
	//  value, never a box of a build-time load (SEQ 407, Tony: by identity, not by name or data)
	llvm::Value *av = (argument->jitData && argument->jitData->computed) ? argument->jitData->getJitter() : nullptr;
	if (av && av->getType()->isIntegerTy(1)) av = b->CreateZExt(av, i32, "argWide");
	if (av && av->getType() == i32) {
	llvm::Value *boxFn = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)&jitBoxCountRT), ptr, "boxFn");
	llvm::FunctionType *boxTy = llvm::FunctionType::get(ptr, {i32}, false);
	boxed = b->CreateCall(boxTy, boxFn, {av}, "argBox"); } }
	llvm::Value *argAddr = argVal ? argVal : boxed ? boxed : b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)argument), ptr, "callArg");
	llvm::Value *fldAddr = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)action), ptr, "callee");
	llvm::Value *bindFn = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)&jitBindArgRT), ptr, "bindFn");
	llvm::FunctionType *bindTy = llvm::FunctionType::get(ptr, {ptr, ptr}, false);
	b->CreateCall(bindTy, bindFn, {argAddr, fldAddr}, "bindArg");
	gJitBoundArg = argAddr;
	return 1; }
	return 0;
	
}

/*******************************************************************************
    jitEmitAssign -- the store-back emitter. SKELETON: not wired, no gate, no
    fixtures.

    // storeOnlyByDesign  what the store destination resolves to, and why a literal target correctly has no slot
    // compoundIsComposed  why += and friends are composed at the gate rather than branched here
*******************************************************************************/
extern "C" GroupItem *jitEmitAssign(GroupItem *argument, GroupItem *target)
{
	
	// ⚠ `x.name = v` -- THE TARGET IS THE NODE A DOT JUST SEEDED (SEQ 297 R0). The
	// store goes to the field through the accessor setter at RUN time, as opAssign's
	// accessorWrite does; the product is minted by opDot at run time, so the test of
	// its mark is in the helper. Checked BEFORE the node branch: on `x.name = 1`
	// gJitLastIsNode is the LEFT operand's, and taking that branch stored the dot's
	// copy into its own node and dropped the 1.   jitEmitters.jitEmitAssign.dotTarget
	if (target && target == gJitDotSeeded && gJitDotProduct && target->jitData
	&& target->jitData->jitValue == gJitDotSeededVal) {
	llvm::Value *product = gJitDotProduct;
	gJitDotSeeded = nullptr; gJitDotSeededVal = nullptr; gJitDotProduct = nullptr;
	if (argument == target) {
	// two dots publish into the one shared node, so the left's product is lost
	gJitLastIsNode = false;
	jitDegrade("`x.a = y.b` -- both dots share one result node", target);
	return target; }
	llvm::IRBuilder<> *db = gJitBuilder;
	llvm::LLVMContext &dctx = db->getContext();
	llvm::Type *dptr = llvm::PointerType::getUnqual(dctx);
	llvm::Type *di32 = llvm::Type::getInt32Ty(dctx);
	llvm::Type *di64 = llvm::Type::getInt64Ty(dctx);
	//  byOwner the shared slot is this assignment's only when its argument is the producer's node (SEQ 423)
	llvm::Value *srcNode = (argument && argument->jitData && argument->jitData->jitNode) ? argument->jitData->jitNode
	: (gJitLastIsNode && gJitResultNode && gJitResultNode != product && argument == gJitNodeOwner) ? gJitResultNode : nullptr;
	if (srcNode) {
	gJitLastIsNode = false;
	llvm::Value *fn = db->CreateIntToPtr(
	llvm::ConstantInt::get(di64, (uint64_t)(void*)&jitAccessorNodeRT), dptr, "accNodeFn");
	llvm::FunctionType *ty = llvm::FunctionType::get(dptr, {dptr, dptr}, false);
	db->CreateCall(ty, fn, {srcNode, product}, "accNode");
	return target; }
	gJitLastIsNode = false;
	if (!argument || !argument->jitData || !argument->jitData->jitValue) {
	jitDegrade("`x.name = v` with an unseeded right operand", target);
	return target; }
	llvm::Value *v = argument->jitData->jitValue;
	if (v->getType() != di32) {
	jitDegrade("`x.name = v` with a non-count right operand", target);
	return target; }
	llvm::Value *fn = db->CreateIntToPtr(
	llvm::ConstantInt::get(di64, (uint64_t)(void*)&jitAccessorWriteRT), dptr, "accWriteFn");
	llvm::FunctionType *ty = llvm::FunctionType::get(dptr, {di32, dptr}, false);
	db->CreateCall(ty, fn, {v, product}, "accWrite");
	gJitResult = v;
	return target;
	}
	// ⚠ A NODE ON THE RIGHT GOES THROUGH THE RUN-TIME HELPER (SEQ 138). A star
	// publishes a NODE, not a scalar, and storing its SSA value put the node's
	// ADDRESS into the target's slot -- which is how starT's jitted road read
	// 5560000 where the interpreted road read LEAF. jitAssignNodeRT does what
	// opAssign does -- setContent, so a holder carries its group across (SEQ 295).
	// The flag is cleared here because this is the consumer.
	//  derefTarget `*h = v` writes INTO what h points at -- its run-time node -- through opAssign's own cast store (SEQ 423)
	if (target && target->jitData && target->jitData->jitNode) {
	llvm::IRBuilder<> *tb = gJitBuilder;
	llvm::LLVMContext &tctx = tb->getContext();
	llvm::Type *tptr = llvm::PointerType::getUnqual(tctx);
	llvm::Type *ti32 = llvm::Type::getInt32Ty(tctx);
	llvm::Type *ti64 = llvm::Type::getInt64Ty(tctx);
	auto tbake = [&](void *p, const char *nm) { return tb->CreateIntToPtr(llvm::ConstantInt::get(ti64, (uint64_t)p), tptr, nm); };
	llvm::Value *src = (argument && argument->jitData && argument->jitData->jitNode) ? argument->jitData->jitNode
	: (gJitLastIsNode && gJitResultNode && argument && argument == gJitNodeOwner && argument != target) ? gJitResultNode : nullptr;
	if (!src) {
	llvm::Value *v = (argument && argument->jitData) ? argument->jitData->jitValue : nullptr;
	if (v && v->getType()->isIntegerTy(1)) v = tb->CreateZExt(v, ti32, "derefTgtWide");
	if (!v || v->getType() != ti32) {
	jitDegrade("`*h = v` with a right operand that is not a count or a node", target);
	gJitHandOver = true;
	gJitResult = nullptr;
	return target; }
	src = tb->CreateCall(llvm::FunctionType::get(tptr, {ti32}, false), tbake((void*)&jitBoxCountRT, "derefTgtBoxFn"), {v}, "derefTgtBox"); }
	gJitLastIsNode = false;
	tb->CreateCall(llvm::FunctionType::get(tptr, {tptr, tptr}, false), tbake((void*)&jitAssignNodeRT, "derefTgtFn"),
	{src, target->jitData->jitNode}, "derefTgtWrite");
	return target;
	}
	//  byOwner a node source is the argument's own run-time node, or the shared slot only when the argument IS its producer's node (SEQ 423)
	llvm::Value *nodeSrc = (argument && argument->jitData && argument->jitData->jitNode) ? argument->jitData->jitNode
	: (gJitLastIsNode && gJitResultNode && argument && argument == gJitNodeOwner) ? gJitResultNode : nullptr;
	if (nodeSrc && target) {
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
	nb->CreateCall(ty, fn, {nodeSrc, tgtAddr}, "assignNode");
	gJitFieldResident.insert((void*)target->groupBody);
	//  ⚠ A FRAME LOCAL'S READS LOAD ITS SLOT, NOT ITS FIELD. The helper wrote
	//  the FIELD; the slot still held the prologue's value, so every later
	//  read saw the stale one and the epilogue wrote it back OVER the
	//  assignment. Reload the home into the slot, so the frame agrees with
	//  the field from here on. Keyed on either home, because the data type
	//  the prologue saw may not be the one the helper just wrote.
	//  Measured on rung JC 2026-09-23: `length = listLengtH;` then
	//  `if length > 0` compared the prologue's %prolog, and the walk stopped
	//  at the root.   jitEmitters.jitEmitAssign.frameSlotReload
	{
	GroupBody    *tb = target->groupBody;
	JitFrameSlot *fs = jitFrameFind((void*)&(tb->gCount));
	if (!fs)      fs = jitFrameFind((void*)&(tb->gNumber));
	if (fs) {
	llvm::Value *home = nb->CreateIntToPtr(
	llvm::ConstantInt::get(ni64, (uint64_t)fs->home), nptr, "assignHome");
	nb->CreateStore(nb->CreateLoad(fs->ty, home, "assignReload"), fs->slot); }
	}
	return target;
	}
	// ⚠ THE SEED GATE (F-47, Tony SEQ 134) -- jitEmitUnary's own guard, copied.
	// BOTH operands were dereferenced unguarded here, so an unseeded one was a
	// bad pointer dereference at 0x28 rather than a named degrade. The sibling
	// has had this gate all along and its comment argues the case: a quiet
	// null-check returning target would be worse than the crash it replaces --
	// exit 0 with wrong IR. So this DEGRADES, countably, and gJitDegradeCount is
	// asserted 0 by every rung, which is what stops it passing silently.
	// stmtRT an unseeded operand never leaves its statement emitting nothing: the WHOLE statement becomes one run-time call on the interpreted road, once per statement (SEQ 335 R2, jitIfRT's pattern)
	if (!argument || !argument->jitData || !target || !target->jitData) {
	jitDegrade("assign operand reached jitEmitAssign unseeded", target);
	gJitHandOver = true;
	gJitResult = nullptr;
	return target;
	}
	llvm::IRBuilder<> *b = gJitBuilder;
	// Plain `=`: pure store-back of the source operand's SSA value into the
	// target's slot. No arithmetic.
	//  castRule a store CASTS into the target's kind and never writes a raw value of the other type (SEQ 347 R0) -- a target
	//  with no kind takes the argument's at run time; a STRING target takes the value as text
	{
	llvm::LLVMContext &cctx = b->getContext();
	llvm::Type *dT = llvm::Type::getDoubleTy(cctx), *iT = llvm::Type::getInt32Ty(cctx), *pT = llvm::PointerType::getUnqual(cctx);
	llvm::Value *v = argument->jitData->jitValue;
	GroupBody *tbk = target->groupBody;
	JitFrameSlot *tfs = jitFrameFind((void*)&(tbk->gCount));
	if (!tfs) tfs = jitFrameFind((void*)&(tbk->gNumber));
	bool vNum = v->getType()->isDoubleTy();
	auto bake64 = [&](void *p, const char *nm) { return b->CreateIntToPtr(llvm::ConstantInt::get(llvm::Type::getInt64Ty(cctx), (uint64_t)p), pT, nm); };
	if (!tfs && (!tbk->flags.data || isSTRING(tbk->flags.data))) {
	void *fn = !tbk->flags.data ? (vNum ? (void*)&jitFlushNumberRT : (void*)&jitFlushCountRT)
	: (vNum ? (void*)&jitCastNumberTextRT : (void*)&jitCastCountTextRT);
	llvm::FunctionType *fty = llvm::FunctionType::get(llvm::Type::getVoidTy(cctx), {pT, v->getType()}, false);
	b->CreateCall(fty, bake64(fn, "castFn"), {bake64((void*)target, "castField"), v});
	//  argWriteThrough a write to the function's OWN argument: slot, node and bound field agree (SEQ 421)
	if (gJitArgSlot && gJitCurrentFn && target->jitData->jitSlot == gJitArgSlot) {
	llvm::FunctionType *sty = llvm::FunctionType::get(iT, {pT, pT}, false);
	b->CreateStore(b->CreateCall(sty, bake64((void*)&jitArgSyncRT, "argSyncFn"),
	{bake64((void*)target, "argNode"), gJitCurrentFn->getArg(0)}, "argSync"), gJitArgSlot); }
	} else {
	llvm::Type *slotT = tfs ? tfs->ty : (isNUMBER(tbk->flags.data) ? dT : iT);
	if (slotT->isDoubleTy() && !vNum)       v = b->CreateSIToFP(v, dT, "castNum");
	else if (!slotT->isDoubleTy() && vNum)  v = b->CreateFPToSI(b->CreateUnaryIntrinsic(llvm::Intrinsic::floor,
	b->CreateFAdd(v, llvm::ConstantFP::get(dT, 0.5), "castHalf")), iT, "castCount");
	b->CreateStore(v, target->jitData->jitSlot);
	}
	}
	//  frameKind a scalar = into a FRAME slot is recorded, so the op-fire flush can stamp the kind the interpreted = would have given
	{
	GroupBody *tb = target->groupBody;
	if (JitFrameSlot *fs = jitFrameFind((void*)&(tb->gCount))) gJitFrameAssigned.insert(fs->home);
	else if (JitFrameSlot *fs2 = jitFrameFind((void*)&(tb->gNumber))) gJitFrameAssigned.insert(fs2->home);
	}
	// Compound (+= *= ...) is NOT a second branch here — it is the composition
	// done by the opMethod gate: jitEmitBinary(argument,target,<jitOp>) first,
	// which returns the result on its OWN node (SEQ 377 R1), then a store-back
	// of that node's value into target. Left to the gate by design.
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
	{
	GroupItem *slotRead = jitArgSlotRead(token);
	if (slotRead)   token = slotRead;
	else if ( token->groupBody->flags.isArgument && isGROUP(token->groupBody->flags.data) )
	token = token->getGroup();
	}
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
	//  listHandsOver a read of a field carrying a list hands its statement to run time, as a value the jit cannot carry does (SEQ 392 R2)
	if (token->groupBody->groupList) {
	::jitHandOver((char*)"a bare read of a field carrying a list -- its statement runs at RUN time", token);
	return 0; }
	if (::jitKindUncarried(token)) {
	::jitHandOver((char*)"a read of a value whose kind is not a count or a number -- its statement runs at RUN time", token);
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
	// divNumber `/` always yields a NUMBER, as opDiv does -- two counts are promoted and divided as doubles (SEQ 347)
	bool fp = l->getType()->isDoubleTy() || r->getType()->isDoubleTy() || op == jitSDiv;
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
	//  ⚠ THE RESULT IS ITS OWN NODE, NEVER THE OPERAND'S jitData (Tony, SEQ 376 R2 / SEQ 377 R1) -- an inlined callee's
	//  `argument - 1` left its sub on the caller's operand node, and the next read of argument read it (jitArithOperandT)
	GroupItem *binResult = new GroupItem((char*)"binResult");
	binResult->jitData = new JitData();
	binResult->jitData->setJitter(res);
	binResult->jitData->computed = true;
	gJitSeeded.push_back(binResult);
	gJitResult = res;
	// computedVal the result node carries a computed value, not a field's -- an assigning operator on it refuses (SEQ 365 R0)
	gJitComputedVal = res;
	return binResult;
	
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
	//  ⚠ THE RESULT IS ITS OWN NODE, NEVER THE OPERAND'S jitData (Tony, SEQ 376 R2). An inlined callee's every `argument`
	//  read follows to ONE node; a result left there was read by the next compare as its operand -- icmp i1 vs i32, the
	//  build aborted (jitCmpOperandAT). A compare's value is computed, not the field, so it rides on a fresh node.
	GroupItem *cmpResult = new GroupItem((char*)"cmpResult");
	cmpResult->jitData = new JitData();
	cmpResult->jitData->setJitter(res);
	cmpResult->jitData->computed = true;
	gJitSeeded.push_back(cmpResult);
	gJitResult = res;
	return cmpResult;
	
}

// jitEmitConcat a STRING or TOKEN left of `+`: a run-time call to opPlus itself, its node published as the value (SEQ 347 R3)
extern "C" GroupItem *jitEmitConcat(GroupItem *argument, GroupItem *target)
{
	
	if (!gJitBuilder || !target) return target;
	llvm::IRBuilder<> *b = gJitBuilder;
	llvm::LLVMContext &ctx = b->getContext();
	llvm::Type *ptr = llvm::PointerType::getUnqual(ctx);
	llvm::Type *i64 = llvm::Type::getInt64Ty(ctx);
	auto bake = [&](void *p, const char *nm) { return b->CreateIntToPtr(llvm::ConstantInt::get(i64, (uint64_t)p), ptr, nm); };
	llvm::FunctionType *opTy = llvm::FunctionType::get(ptr, {ptr, ptr}, false);
	llvm::Value *res = b->CreateCall(opTy, bake((void*)&opPlus, "concatFn"), {bake((void*)argument, "concatArg"), bake((void*)target, "concatTgt")}, "concatRes");
	gJitResultNode = res;
	gJitLastIsNode = true;
	gJitNodeOwner  = target;
	gJitEmitted    = true;
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
	
	gJitDerefNode = nullptr;
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
	//  ownNode the run-time node rides on a FRESH node, handed back to the consumer (SEQ 423, SEQ 377's rule)
	llvm::Value *unboxFn = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)&jitUnboxCount), ptr, "derefUnboxFn");
	llvm::Value *val = b->CreateCall(llvm::FunctionType::get(llvm::Type::getInt32Ty(ctx), {ptr}, false), unboxFn, {res}, "derefVal");
	GroupItem *derefNode = new GroupItem((char*)"derefResult");
	derefNode->jitData = new JitData();
	derefNode->jitData->jitNode = res;
	derefNode->jitData->jitType = llvm::Type::getInt32Ty(ctx);
	derefNode->jitData->setJitter(val);
	derefNode->jitData->computed = true;
	gJitSeeded.push_back(derefNode);
	//  print takes the node through the shared slot, cleared per item; an assignment only by owner
	gJitResultNode = res;
	gJitLastIsNode = true;
	gJitNodeOwner  = derefNode;
	//  bindByFollow a call handed this node binds its run-time node through SEQ 409's pair -- jitEmitArgBind is untouched
	gJitArgFollowNode = derefNode; gJitArgFollowVal = res;
	gJitEmitted    = true;
	gJitDerefNode  = derefNode;
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
	
	//  derefOperand a dereference's operand is its run-time node (SEQ 423)
	llvm::Value *argAddr = (argument && argument->jitData && argument->jitData->jitNode) ? argument->jitData->jitNode
	: b->CreateIntToPtr(llvm::ConstantInt::get(i64, (uint64_t)(void*)argument), ptr, "dotArg");
	llvm::Value *tgtAddr = (target && target->jitData && target->jitData->jitNode) ? target->jitData->jitNode
	: b->CreateIntToPtr(llvm::ConstantInt::get(i64, (uint64_t)(void*)target), ptr, "dotTgt");
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
	gJitNodeOwner  = resultNode;
	
	if (resultNode) {
	if (!resultNode->jitData) resultNode->jitData = new JitData();
	resultNode->jitData->setJitter(val);
	resultNode->jitData->computed = true;
	gJitSeeded.push_back(resultNode); }
	//  dotSeeded which node this dot seeded and with what, so a `=` onto it writes the field (SEQ 297)
	gJitDotSeeded    = resultNode;
	gJitDotSeededVal = val;
	gJitDotProduct   = res;
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

extern "C" GroupItem *jitEmitGIF(GroupItem *input)
{
GroupItem 	*ExpressioN = input->getLabelGroup("ExpressioN");
GroupItem 	*StatemenT = input->getLabelGroup("StatemenT");
GroupItem 	*ElsE = input->getLabelGroup("ElsE");
GroupItem 	*result = ExpressioN;
	// freshCondition nothing may be in flight before the condition emits, so a refused condition reads as NO value, never as the last statement's (SEQ 331)
	 gJitResult = nullptr; 
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
	// conditionHandedOver a condition that handed its statement to run time ends the emit here: the arms would be rolled back
	 if ( gJitHandOver ) return new GroupItem((char*)"jitIfRT"); 
	// wholeIfInterpreted a condition with no value degrades the WHOLE if to the interpreted road: one run-time call runs it through aCTionIF, and no arm is ever emitted without its condition (SEQ 331, Tony)
	
	if (!gJitResult) {
	::jitHandOver((char*)"IF condition produced no value -- the whole IF runs INTERPRETED", ExpressioN);
	return new GroupItem((char*)"jitIfRT");
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

extern "C" void jitEmitIfRT(GroupItem *input)
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	if (!b || !input) return;
	llvm::LLVMContext &ctx = b->getContext();
	llvm::Type *ptr = llvm::PointerType::getUnqual(ctx);
	llvm::Type *i32 = llvm::Type::getInt32Ty(ctx);
	llvm::Type *i64 = llvm::Type::getInt64Ty(ctx);
	llvm::Value *ifAddr = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)input), ptr, "ifNode");
	llvm::Value *fn = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)&jitIfRT), ptr, "ifFn");
	llvm::FunctionType *ty = llvm::FunctionType::get(i32, {ptr}, false);
	b->CreateCall(ty, fn, {ifAddr}, "ifRT");
	gJitEmitted    = true;
	gJitLastIsNode = false;
	
}

/*  jitEmitInlineEnter -- runAction's inline arm, after jitInlinePush: bind the callee's argument at RUN time (the emit-time
    bind stays, the walk needs it) and push the channel, so the inlined body's run-time statements read THIS call's
    argument and the region's join (jitInlinePop) un-binds it on every exit (SEQ 396). A call with no argument emits
    nothing, so its IR is unchanged.  */
extern "C" void jitEmitInlineEnter(GroupItem *argument, GroupItem *action)
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	if (!b || !b->GetInsertBlock() || b->GetInsertBlock()->getTerminator() || gJitInlineFrames.empty()) return;
	if (!::jitEmitArgBind(argument, action)) return;
	llvm::LLVMContext &ctx = b->getContext();
	llvm::Type *ptr = llvm::PointerType::getUnqual(ctx);
	llvm::Type *i64 = llvm::Type::getInt64Ty(ctx);
	llvm::FunctionType *vTy = llvm::FunctionType::get(llvm::Type::getVoidTy(ctx), {}, false);
	b->CreateCall(vTy, b->CreateIntToPtr(llvm::ConstantInt::get(i64, (uint64_t)(void*)&jitChanPushRT), ptr, "chanPushFn"), {});
	gJitInlineFrames.back().chanPushed = true;
	
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

extern "C" GroupItem *jitEmitOpFire(GroupItem *op, GroupItem *arg, GroupItem *target)
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	if (!b || !op) return nullptr;
	llvm::LLVMContext &ctx = b->getContext();
	llvm::Type *ptr = llvm::PointerType::getUnqual(ctx);
	llvm::Type *i32 = llvm::Type::getInt32Ty(ctx);
	llvm::Type *i64 = llvm::Type::getInt64Ty(ctx);
	auto bake = [&](void *p, const char *nm) {
	return b->CreateIntToPtr(llvm::ConstantInt::get(i64, (uint64_t)p), ptr, nm); };
	//  flush a frame slot to its field before the call. A slot a scalar `=` wrote
	//  this compile gets its KIND too (gJitFrameAssigned); any other stays as it is.
	auto flush = [&](GroupItem *g, JitFrameSlot *fs, const char *nm) {
	llvm::Value *v = b->CreateLoad(fs->ty, fs->slot, nm);
	if (gJitFrameAssigned.count(fs->home)) {
	bool num = fs->ty->isDoubleTy();
	llvm::FunctionType *fty = llvm::FunctionType::get(llvm::Type::getVoidTy(ctx), {ptr, fs->ty}, false);
	b->CreateCall(fty, bake(num ? (void*)&jitFlushNumberRT : (void*)&jitFlushCountRT, "opFireFlushFn"),
	{bake((void*)g, "opFireFlushField"), v}); }
	//  kindChecked a raw store would overwrite a local that holds a GROUP at run time -- gCount shares gGroup's storage (SEQ 384)
	else {
	llvm::FunctionType *fty = llvm::FunctionType::get(llvm::Type::getVoidTy(ctx), {ptr, fs->ty}, false);
	b->CreateCall(fty, bake(fs->ty->isDoubleTy() ? (void*)&jitFlushNumberSlotRT : (void*)&jitFlushCountSlotRT, "opFireFlushFn"),
	{bake((char*)fs->home - offsetof(GroupBody, gCount), "opFireBody"), v}); } };
	auto frameOf = [&](GroupItem *g) -> JitFrameSlot* {
	JitFrameSlot *fs = jitFrameFind((void*)&(g->groupBody->gCount));
	if (!fs)      fs = jitFrameFind((void*)&(g->groupBody->gNumber));
	return fs; };
	bool nodeTaken = false;
	llvm::Value *tgtV = nullptr, *argV = nullptr;
	//  TARGET -- identity is the point: the fire writes INTO it.
	if (!target) {
	if (gJitLastIsNode && gJitResultNode) { tgtV = gJitResultNode; nodeTaken = true; }
	}
	else {
	if (JitFrameSlot *fs = frameOf(target)) flush(target, fs, "opFireFlushT");
	//  derefOperand a dereference's operand is its run-time node (SEQ 423)
	tgtV = (target->jitData && target->jitData->jitNode) ? target->jitData->jitNode : bake((void*)target, "opFireTgt");
	//  argWriteThrough the function's OWN argument: the node takes the slot's value before the operator reads it (SEQ 421)
	if (gJitArgSlot && target->jitData && target->jitData->jitSlot == gJitArgSlot)
	b->CreateCall(llvm::FunctionType::get(llvm::Type::getVoidTy(ctx), {ptr, i32}, false), bake((void*)&jitFlushCountRT, "argNodeFn"),
	{tgtV, b->CreateLoad(i32, gJitArgSlot, "argPrime")});
	}
	//  ARGUMENT -- its VALUE is the point.
	if (!arg) {
	if (!nodeTaken && gJitLastIsNode && gJitResultNode) { argV = gJitResultNode; nodeTaken = true; }
	}
	else if (arg->jitData && arg->jitData->jitNode) argV = arg->jitData->jitNode;
	else if (arg->groupBody->flags.isLiteral || !arg->jitData || !arg->jitData->jitValue) {
	if (JitFrameSlot *fs = frameOf(arg)) flush(arg, fs, "opFireFlushA");
	argV = bake((void*)arg, "opFireArg");
	}
	else {
	llvm::Value *v = arg->jitData->jitValue;
	GroupItem *box = new GroupItem((char*)"jitOpFireBox");
	if (v->getType()->isDoubleTy()) {
	box->setNumber(0.0);
	b->CreateStore(v, bake((void*)&(box->groupBody->gNumber), "opFireBoxN")); }
	else if (v->getType()->isIntegerTy()) {
	if (!v->getType()->isIntegerTy(32)) v = b->CreateZExtOrTrunc(v, i32, "opFireBoxW");
	box->setCount(0);
	b->CreateStore(v, bake((void*)&(box->groupBody->gCount), "opFireBoxC")); }
	else box = nullptr;
	if (box) argV = bake((void*)box, "opFireArgBox");
	}
	if (!tgtV || !argV) {
	::jitDegrade((char*)(!tgtV ? "operator-with-members: TARGET has no run-time producer -- REFUSED"
	: "operator-with-members: ARGUMENT has no run-time producer -- REFUSED"), target);
	return nullptr; }
	if (nodeTaken) gJitLastIsNode = false;
	llvm::FunctionType *ty = llvm::FunctionType::get(ptr, {ptr, ptr, ptr}, false);
	llvm::Value *res = b->CreateCall(ty, bake((void*)&jitOpFireRT, "opFireFn"),
	{bake((void*)op, "opFireOp"), argV, tgtV}, "opFire");
	//  argWriteThrough after the fire, slot, node and bound field agree (SEQ 421)
	if (target && gJitArgSlot && gJitCurrentFn && target->jitData && target->jitData->jitSlot == gJitArgSlot)
	b->CreateStore(b->CreateCall(llvm::FunctionType::get(i32, {ptr, ptr}, false), bake((void*)&jitArgSyncRT, "argSyncFn"),
	{tgtV, gJitCurrentFn->getArg(0)}, "argSync"), gJitArgSlot);
	gJitStmtCanRefuse = true;
	//  the fire wrote the FIELD: a frame target's slot is reloaded from it, and
	//  prints read the field (gJitFieldResident), as jitEmitAssign's node arm does.
	if (target) {
	if (JitFrameSlot *fs = frameOf(target)) {
	llvm::FunctionType *rty = llvm::FunctionType::get(fs->ty, {ptr, fs->ty}, false);
	llvm::Value *nv = b->CreateCall(rty, bake(fs->ty->isDoubleTy() ? (void*)&jitReloadNumberSlotRT : (void*)&jitReloadCountSlotRT, "opFireReloadFn"),
	{bake((char*)fs->home - offsetof(GroupBody, gCount), "opFireBodyR"), b->CreateLoad(fs->ty, fs->slot, "opFireOld")}, "opFireReload");
	b->CreateStore(nv, fs->slot); }
	gJitFieldResident.insert((void*)target->groupBody);
	}
	gJitResultNode = res;
	gJitResult     = nullptr;
	gJitEmitted    = true;
	return new GroupItem((char*)"jitOpFire");
	
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
	resultNode->jitData->computed = true;
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

extern "C" void jitEmitScOperandRT(GroupItem *operand)
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	if (!b || !operand) return;
	llvm::LLVMContext &ctx = b->getContext();
	llvm::Type *ptr = llvm::PointerType::getUnqual(ctx);
	llvm::Type *i32 = llvm::Type::getInt32Ty(ctx);
	llvm::Type *i64 = llvm::Type::getInt64Ty(ctx);
	llvm::Value *opAddr = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)operand), ptr, "scOpNode");
	llvm::Value *fn = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)&jitScOperandRT), ptr, "scOpFn");
	llvm::FunctionType *ty = llvm::FunctionType::get(i32, {ptr}, false);
	gJitResult     = b->CreateCall(ty, fn, {opAddr}, "scOpRT");
	gJitEmitted    = true;
	gJitLastIsNode = false;
	//  handedOnce the operand's run-time call is its statement's hand-over: the boundary must not hand the whole statement to jitStmtRT as well (SEQ 372 R2)
	if (gJitStmt)   gJitStmtRTDone = true;
	
}

/*******************************************************************************
    jitEmitSelfCall -- THE RECURSIVE CALL, emitted rather than inlined. Returns
    the call's VALUE NODE when it emitted -- a fresh node carrying %selfcall (SEQ
    378 R0) -- and null when it did not, which is the common, CORRECT answer,
    because an ordinary call still inlines.

    // inliningStopsHere  why a self-call cannot be inlined, and why the cached SSA state fires before non-termination does
    // selfCallSignature  what a no-argument self-call proves and what it does not
*******************************************************************************/
extern "C" GroupItem *jitEmitSelfCall(GroupItem *argument, GroupItem *action)
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
	//  ⚠ A RUN-TIME ARGUMENT IS BOUND TOO. `callee(*cursor)` -- the class (e)
	//  spelling since 2026-09-04 -- has no node at emit time: the star emits a
	//  run-time deref and publishes its SSA node on gJitResultNode, so runAction
	//  hands this function a null argument. The old `if (argument)` then bound
	//  NOTHING, silently, and every depth walked the caller's argument again --
	//  rung JC recursed until the stack died. Bind the published node instead;
	//  jitBindArgRT does the same bind with it at run time. The flag is cleared
	//  because this is the consumer.   jitEmitters.jitEmitSelfCall.runtimeArg
	//  oneBindHelper the argument block lives in jitEmitArgBind, shared with runAction's inline arm (SEQ 396 R0)
	llvm::Value *selfArg = nullptr;
	if (::jitEmitArgBind(argument, action))
	selfArg = gJitBoundArg;
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
	//  i32(ptr): the callee runs on the argument it was just bound to, or on
	//  nothing when the call carries none.
	llvm::Value *callField = selfArg ? selfArg
	: (llvm::Value*)llvm::ConstantPointerNull::get(llvm::PointerType::getUnqual(ctx));
	llvm::Value *v = b->CreateCall(target, {callField}, "selfcall");
	llvm::Value *restoreFn = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)&jitRestoreFrameRT), ptr, "restoreFn");
	b->CreateCall(frameTy, restoreFn, {calleeAddr});
	gJitResult  = v;
	gJitEmitted = true;
	//  ⚠ THE CALL'S VALUE IS %selfcall, ON ITS OWN NODE (Tony, SEQ 378 R0). runAction used to hand back the ACTION,
	//  so the caller seeded the action node and loaded its own count -- a value nobody wrote (jitSelfCallValT).
	GroupItem *callResult = new GroupItem((char*)"callResult");
	callResult->jitData = new JitData();
	callResult->jitData->setJitter(v);
	callResult->jitData->computed = true;
	gJitSeeded.push_back(callResult);
	return callResult; }
	
}

// jitEmitShortCircuitSlots the emit on the connective's SLOTS -- the tree shape is [op, left, right] and the candidate's is [left, op, right], so each unpacks into this, as runOP does into runOPslots (SEQ 335 J4a); `field` is the node the result rides on
extern "C" GroupItem *jitEmitShortCircuitSlots(GroupItem *op, GroupItem *target, GroupItem *arg, GroupItem *field)
{
int 	isAND = 0;
	// skipByRegistration the direction is the operator's isOR registration, never its spelling -- `op.tag eq "AND"` stood here until 2026-09-23 and read `&&` as OR
	if ( !::opIsOR(op) )
		isAND = 1;
	// freshOperand nothing may be in flight before an operand emits, so an operand that emits nothing reads as NO value, never as the last thing emitted (SEQ 335 R2)
	 gJitResult = nullptr; 
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
	// operandRT an operand with no value is ONE run-time call that evaluates it interpreted and hands back its truth -- the connective is never omitted, and the right side stays inside its own branch (SEQ 335 R2, jitIfRT's pattern)
	
	if (!gJitResult) {
	jitDegrade("AND/OR LEFT operand produced no value -- it runs INTERPRETED", target);
	jitEmitScOperandRT(target);
	}
	
	jitScBegin(isAND);
	 gJitResult = nullptr; 
	if ( isMethod(arg->groupBody->flags.instructType) && arg->groupBody->flags.invoke )
		arg->groupBody->gMethod(arg);
	else	::jitEmitBareRead(arg);
	
	if (!gJitResult) {
	jitDegrade("AND/OR RIGHT operand produced no value -- it runs INTERPRETED", arg);
	jitEmitScOperandRT(arg);
	}
	
	jitScEnd(field);
	return field;
}

extern "C" void jitEmitStmtRT(GroupItem *statement)
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	if (!b || !statement) return;
	llvm::LLVMContext &ctx = b->getContext();
	llvm::Type *ptr = llvm::PointerType::getUnqual(ctx);
	llvm::Type *i32 = llvm::Type::getInt32Ty(ctx);
	llvm::Type *i64 = llvm::Type::getInt64Ty(ctx);
	llvm::Value *stAddr = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)statement), ptr, "stmtNode");
	llvm::Value *fn = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)&jitStmtRT), ptr, "stmtFn");
	llvm::FunctionType *ty = llvm::FunctionType::get(i32, {ptr, ptr}, false);
	//  the statement's owner: an inlined callee's is the activation processAction made current; the function's own is its action
	GroupItem *owner = gJitInlining.empty() ? gJitCurrentAction
	: (GroupItem*)GroupControl::groupController->groupRules->currentMETHOD->groupBody->gGroup;
	llvm::Value *ownAddr = b->CreateIntToPtr(llvm::ConstantInt::get(i64, (uint64_t)(void*)owner), ptr, "stmtOwner");
	//  currentValues the interpreted run reads and writes FIELDS: every frame slot goes to its field before the call and
	//  comes back after it -- the reload BEFORE the refusal branch, so the epilogue cannot write a stale slot over what the
	//  statement wrote (SEQ 384, seal 163's hazard)
	//  ⚠ THROUGH A KIND CHECK, NEVER A RAW STORE: the slot is homed on gCount / gNumber, which share storage with gGroup,
	//  so a raw flush of a local that holds a GROUP at run time overwrites the pointer (measured: kindJ1T's iterator,
	//  under the forced-jit census). A slot this compile wrote with a scalar `=` is flushed WITH its kind, as opFire's is.
	auto bodyOf = [&](JitFrameSlot &f) {
	return b->CreateIntToPtr(llvm::ConstantInt::get(i64, (uint64_t)((char*)f.home - offsetof(GroupBody, gCount))), ptr, "rtBody"); };
	for ( JitFrameSlot &f : gJitFrame ) {
	bool num = f.ty->isDoubleTy();
	void *helper = gJitFrameAssigned.count(f.home)
	? (num ? (void*)&jitFlushNumberSlotKindRT : (void*)&jitFlushCountSlotKindRT)
	: (num ? (void*)&jitFlushNumberSlotRT     : (void*)&jitFlushCountSlotRT);
	llvm::FunctionType *fty = llvm::FunctionType::get(llvm::Type::getVoidTy(ctx), {ptr, f.ty}, false);
	b->CreateCall(fty, b->CreateIntToPtr(llvm::ConstantInt::get(i64, (uint64_t)helper), ptr, "rtFlushFn"),
	{bodyOf(f), b->CreateLoad(f.ty, f.slot, "rtFlush")}); }
	llvm::Value *rv = b->CreateCall(ty, fn, {stAddr, ownAddr}, "stmtRT");
	for ( JitFrameSlot &f : gJitFrame ) {
	bool num = f.ty->isDoubleTy();
	llvm::FunctionType *fty = llvm::FunctionType::get(f.ty, {ptr, f.ty}, false);
	void *helper = num ? (void*)&jitReloadNumberSlotRT : (void*)&jitReloadCountSlotRT;
	llvm::Value *nv = b->CreateCall(fty, b->CreateIntToPtr(llvm::ConstantInt::get(i64, (uint64_t)helper), ptr, "rtReloadFn"),
	{bodyOf(f), b->CreateLoad(f.ty, f.slot, "rtOld")}, "rtReload");
	b->CreateStore(nv, f.slot); }
	gJitEmitted    = true;
	gJitLastIsNode = false;
	// refusalExit the interpreted run refused: leave the function as runAction's exit leaves the action -- an inlined
	// callee through its own exit block, else the epilogue, which clears the arm (SEQ 370 R1)
	llvm::Function   *rfn  = b->GetInsertBlock()->getParent();
	llvm::BasicBlock *exit = nullptr;
	if (!gJitInlining.empty()) {
	if (!gJitInlineFrames.empty() && gJitInlineFrames.back().exitBB) {
	JitInlineFrame &f = gJitInlineFrames.back();
	if (!f.used) { rfn->insert(rfn->end(), f.exitBB); f.used = true; }
	exit = f.exitBB; } }
	else exit = gJitEpilogueBB;
	if (!exit) return;
	//  returnedExit the interpreted run RETURNED (2): its value goes to the result slot and the function leaves through the
	//  same exit -- an inlined callee's own, else the epilogue -- as jitEmitReturn's store-then-branch (SEQ 393 A)
	llvm::BasicBlock *ret  = llvm::BasicBlock::Create(ctx, "stmtReturned", rfn);
	llvm::BasicBlock *chk  = llvm::BasicBlock::Create(ctx, "stmtNotReturned", rfn);
	llvm::BasicBlock *cont = llvm::BasicBlock::Create(ctx, "stmtNotRefused", rfn);
	b->CreateCondBr(b->CreateICmpEQ(rv, llvm::ConstantInt::get(i32, 2), "stmtReturn"), ret, chk);
	b->SetInsertPoint(ret);
	if (gJitResultSlot) {
	llvm::FunctionType *vty = llvm::FunctionType::get(i32, {i32}, false);
	llvm::Value *old = b->CreateLoad(i32, gJitResultSlot, "rtRetOld");
	llvm::Value *nv  = b->CreateCall(vty, b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)&jitStmtRTValueRT), ptr, "rtRetFn"), {old}, "rtRet");
	b->CreateStore(nv, gJitResultSlot); }
	b->CreateBr(exit);
	b->SetInsertPoint(chk);
	//  loopTargets a statement carrying a continue / break (and ONLY one) switches: 3 -> the innermost loop's condition,
	//  4 -> its exit -- the loop of THIS function or inlined region; a region with no loop of its own ends there, as the
	//  interpreter ends a loopless action (SEQ 410)
	if (gJitStmtRTBranches) {
	size_t floor = (!gJitInlining.empty() && !gJitInlineFrames.empty()) ? gJitInlineFrames.back().loopDepth : 0;
	llvm::BasicBlock *contBB = exit, *brkBB = exit;
	if (gLoopCondBlocks.size() > floor && !gLoopExitBlocks.empty()) { contBB = gLoopCondBlocks.back(); brkBB = gLoopExitBlocks.back(); }
	llvm::IntegerType *it32 = llvm::Type::getInt32Ty(ctx);
	llvm::SwitchInst *sw = b->CreateSwitch(rv, exit, 3);
	sw->addCase(llvm::ConstantInt::get(it32, 0), cont);
	if (gJitStmtRTBranches & 2) sw->addCase(llvm::ConstantInt::get(it32, 3), contBB);
	if (gJitStmtRTBranches & 1) sw->addCase(llvm::ConstantInt::get(it32, 4), brkBB); }
	else b->CreateCondBr(b->CreateICmpNE(rv, llvm::ConstantInt::get(i32, 0), "stmtRefused"), exit, cont);
	b->SetInsertPoint(cont);
	
}

extern "C" GroupItem *jitEmitSub(GroupItem *argument, GroupItem *target)
{
	 return jitEmitBinary(argument, target, jitSub); 
}

extern "C" GroupItem *jitEmitTermCall(GroupItem *op, GroupItem *target, GroupItem *arg)
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	if (!b || !op) return nullptr;
	llvm::LLVMContext &ctx = b->getContext();
	llvm::Type *ptr = llvm::PointerType::getUnqual(ctx);
	llvm::Type *i32 = llvm::Type::getInt32Ty(ctx);
	llvm::Type *i64 = llvm::Type::getInt64Ty(ctx);
	llvm::Value *opAddr = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)op), ptr, "termOp");
	llvm::Value *targetAddr = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)target), ptr, "termTarget");
	llvm::Value *argAddr = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)arg), ptr, "termArg");
	llvm::Value *fn = b->CreateIntToPtr(
	llvm::ConstantInt::get(i64, (uint64_t)(void*)&jitTermCallRT), ptr, "termFn");
	llvm::FunctionType *ty = llvm::FunctionType::get(i32, {ptr, ptr, ptr}, false);
	gJitResult     = b->CreateCall(ty, fn, {opAddr, targetAddr, argAddr}, "termCall");
	gJitEmitted    = true;
	gJitLastIsNode = false;
	return new GroupItem((char*)"jitTerm");
	
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
	//  ⚠ own node, never the operand's jitData (SEQ 377 R1) -- the same defect as jitEmitBinary's
	GroupItem *negResult = new GroupItem((char*)"negResult");
	negResult->jitData = new JitData();
	negResult->jitData->setJitter(res);
	negResult->jitData->computed = true;
	gJitSeeded.push_back(negResult);
	gJitResult = res;
	// computedVal -a is a value, not a field (SEQ 365 R0)
	gJitComputedVal = res;
	return negResult;
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
	//  derefTarget ++ / -- on `*h` writes into what h points at (SEQ 423)
	if (target->jitData->jitNode && res->getType()->isIntegerTy(32)) {
	llvm::LLVMContext &uctx = b->getContext();
	llvm::Type *uP = llvm::PointerType::getUnqual(uctx);
	b->CreateCall(llvm::FunctionType::get(llvm::Type::getVoidTy(uctx), {uP, res->getType()}, false),
	b->CreateIntToPtr(llvm::ConstantInt::get(llvm::Type::getInt64Ty(uctx), (uint64_t)(void*)&jitFlushCountRT), uP, "derefIncFn"),
	{target->jitData->jitNode, res}); }
	//  argWriteThrough ++ / -- on the function's OWN argument: the node and the bound field take the slot's value (SEQ 421)
	if (gJitArgSlot && gJitCurrentFn && target->jitData->jitSlot == gJitArgSlot && res->getType()->isIntegerTy(32)) {
	llvm::LLVMContext &uctx = b->getContext();
	llvm::Type *uP = llvm::PointerType::getUnqual(uctx), *u64 = llvm::Type::getInt64Ty(uctx), *u32 = llvm::Type::getInt32Ty(uctx);
	auto ubake = [&](void *p, const char *nm) { return b->CreateIntToPtr(llvm::ConstantInt::get(u64, (uint64_t)p), uP, nm); };
	b->CreateCall(llvm::FunctionType::get(llvm::Type::getVoidTy(uctx), {uP, u32}, false), ubake((void*)&jitFlushCountRT, "argNodeFn"),
	{ubake((void*)target, "argNode"), res});
	b->CreateCall(llvm::FunctionType::get(u32, {uP, uP}, false), ubake((void*)&jitArgSyncRT, "argSyncFn"),
	{ubake((void*)target, "argNode"), gJitCurrentFn->getArg(0)}, "argSync"); }
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
   in place. Control flow lands through aCTionIF's jitting gate -> jitEmitGIF.
   jitRunAction calls it after processCode has built the BlocK. */
extern "C" GroupItem *jitExecBlock(GroupItem *input)
{
	// artifactNotTag the body is an ARTIFACT, read off the property list -- never a tag search through terms, which finds a bare BlocK the body itself names (SEQ 344)
GroupItem *body = input->actionBlocK();
	if ( body )
		body->groupBody->gMethod(body);
	return input;
}

/*  jitFieldMethod -- set-then-call dispatch for a field's compiled method.
    see DesignDocs: JitFieldMethod
*******************************************************************************/
extern "C" GroupItem *jitFieldMethod(GroupItem *field)
{
	
	GroupRules *ruler   = GroupControl::groupController->groupRules;
	//  THE CANONICAL NODE. Everything below reads and writes THIS, never the
	//  arriving wrapper -- instanceRule() since stroke 4.3; see DesignDocs JitFieldMethod.
	GroupItem  *definer = field->instanceRule();
	RuleStuff  *stuff   = definer->rStuff;
	char       *name    = definer->groupBody->tag;
	
	if (::getenv("INCANT_SLOT_PROBE"))
	fprintf(stderr,
	"=== SLOTPROBE %s: field=%p definer=%p body=%p rStuff=%p jitMethod=%p ===\n",
	name, (void*)field, (void*)definer, (void*)definer->groupBody,
	(void*)stuff, (void*)definer->groupBody->gJitMethod);
	
	/*  PATH 1 -- THE SLOT. This is the only dispatch in the function. */
	if (definer->groupBody->gJitMethod) {
	int r = definer->groupBody->gJitMethod(jitBodyField(definer));
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
	definer->groupBody->gJitMethod = gJitLastFn;
	if (::getenv("INCANT_SLOT_PROBE"))
	fprintf(stderr,
	"=== SLOTPROBE %s STORED: rStuff=%p jitMethod=%p  readback rStuff=%p jitMethod=%p ===\n",
	name, (void*)stuff, (void*)definer->groupBody->gJitMethod,
	(void*)definer->rStuff,
	(void*)definer->groupBody->gJitMethod);
	
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
    jitEmitOpFire / jitOpFireRT -- AN OPERATOR WITH MEMBERS, FIRED AT RUN TIME
    (Tony's ruling 2026-09-25: += answers on the jitted road for every target the
    interpreted road handles, per fire, no degrade, no fallback). The emitted code
    calls jitOpFireRT with the LIVE operands; it runs pickKindOP -- the same pick
    runOP makes -- and fires the chosen method. Nothing about an operand's kind is
    baked, so a cursor over mixed kinds and a target typed by its first fire both
    answer as the interpreted road does.
    OPERANDS ARE PRODUCED AT RUN TIME, one class each:
      a NULL operand with a node in flight -- `*cursor` -- is jitDerefRT's node;
      a literal is baked by address (it carries its value);
      a field is baked by address, its FRAME SLOT flushed to the field first and,
        for the target, reloaded after, so compiled reads agree with the helper;
      an ARGUMENT whose live value is only in SSA (an inner result) is stored into
        a scratch node baked at emit -- a plain store, per fire.
    Anything else REFUSES BY NAME, counted, rather than guessing.
*******************************************************************************/
/*  the op-fire flush for a frame slot a scalar `=` has written: the VALUE and the
    KIND, through the setters, as the interpreted `=` would have left the local.  */
extern "C" void jitFlushCountRT(GroupItem *field, int value)
{
	 if (field) field->setCount(value); 
}

extern "C" void jitFlushCountSlotKindRT(GroupItem *body, int value)
{
	 GroupBody *gb = (GroupBody*)(void*)body; if ( isCOUNT(gb->flags.data) || !gb->flags.data ) { gb->gCount = value; gb->flags.data = 5; } 
}

/*  The run-time flush / reload around a handed-over statement (SEQ 384). Each is handed a frame slot's GroupBody -- typed
    GroupItem here only because a tok extern needs a type; the passthrough treats it as the body -- and moves the value
    ONLY while the field holds a scalar of the slot's kind. A field holding a group, a string or a list keeps it.  */
extern "C" void jitFlushCountSlotRT(GroupItem *body, int value)
{
	 GroupBody *gb = (GroupBody*)(void*)body; if ( isCOUNT(gb->flags.data) ) gb->gCount = value; 
}

extern "C" void jitFlushNumberRT(GroupItem *field, double value)
{
	 if (field) field->setNumber(value); 
}

extern "C" void jitFlushNumberSlotKindRT(GroupItem *body, double value)
{
	 GroupBody *gb = (GroupBody*)(void*)body; if ( isNUMBER(gb->flags.data) || !gb->flags.data ) { gb->gNumber = value; gb->flags.data = 9; } 
}

extern "C" void jitFlushNumberSlotRT(GroupItem *body, double value)
{
	 GroupBody *gb = (GroupBody*)(void*)body; if ( isNUMBER(gb->flags.data) ) gb->gNumber = value; 
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
	gJitFrameAssigned.clear();
	gJitResult     = nullptr;
	gJitResultNode = nullptr;
	gJitPrintBuf   = nullptr;
	gIfEndBlocks.clear();
	gIfElseBlocks.clear();
	gLoopCondBlocks.clear();
	gLoopExitBlocks.clear();
	gLoopBodyBlocks.clear();
	gJitInlining.clear();
	gJitArgBody   = nullptr;
	gJitArgSlot   = nullptr;
	gJitArgOrigin = nullptr;
	gJitStmtMarks.clear();
	gJitHandOver  = false;
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

/*  jitHandOver -- the statement under emission runs at RUN time instead (SEQ 384). Announces through jitDegrade, once
    per statement (a later degrade in the same statement folds into it), and marks the statement for jitStmtEnd.  */
extern "C" int jitHandOver(char *what, GroupItem *node)
{
	if ( !GroupControl::groupController->groupRules->jitting )
		return 0;
	
	if ( !gJitHandOver ) ::jitDegrade(what,node);
	gJitHandOver      = true;
	gJitStmtCanRefuse = false;
	gJitResult        = nullptr;
	return 1;
	
}

extern "C" int jitHandedCursor(GroupItem *field)
{
	 return ( field && gJitRTCursors.count((void*)field->groupBody) ) ? 1 : 0; 
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

/*******************************************************************************
    jitEmitGIF -- THE gIF EMITTER, riding the INTERPRET walk (pivot,
    2026-06-30). Called from aCTionIF's jitting gate with the live if-node.

    // gifRidesTheWalk  the five-step bracket, and why owning the traversal is the structural cure for the deferred path's stack corruption
*******************************************************************************/
/*  jitIfRT -- an IF the jit could not emit, run at RUN time on the interpreted road: aCTionIF on the
    statement node, with jitting off as it always is at run time. Its value is not used.
    A REFUSAL'S SCOPE IS THE STATEMENT: the emit walk's refusals are still raised when the first fire
    runs, so this statement opens with none in force and clears its own on the way out.  */
extern "C" int jitIfRT(GroupItem *input)
{
	
	::clearRefusal(input);
	::aCTionIF(input);
	::clearRefusal(input);
	return 0;
	
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
	//  regionSeeds a value seeded inside the region was made in its blocks, which do not dominate the code after the join
	//  (an early exit skips them) and belong to ONE inlined copy: cleared here, so the next read re-seeds (SEQ 407 (a))
	if (f.seededAt <= gJitSeeded.size()) {
	for (size_t i = f.seededAt; i < gJitSeeded.size(); i++) gJitSeeded[i]->jitData = nullptr;
	gJitSeeded.resize(f.seededAt); }
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
	resultNode->jitData->computed = true;
	gJitSeeded.push_back(resultNode); } } }
	else if (f.exitBB && !f.used)
	delete f.exitBB;
	//  chanPopAtJoin every exit of the region -- the fall-through, a return, a handed-over return, a refusal -- has
	//  reached this one point above (they all target exitBB), so the pop here runs on all of them (SEQ 396 R1)
	if (f.chanPushed && b && b->GetInsertBlock() && !b->GetInsertBlock()->getTerminator()) {
	llvm::LLVMContext &ctx = b->getContext();
	llvm::Type *ptr = llvm::PointerType::getUnqual(ctx);
	llvm::Type *i64 = llvm::Type::getInt64Ty(ctx);
	llvm::FunctionType *vTy = llvm::FunctionType::get(llvm::Type::getVoidTy(ctx), {}, false);
	b->CreateCall(vTy, b->CreateIntToPtr(llvm::ConstantInt::get(i64, (uint64_t)(void*)&jitChanPopRT), ptr, "chanPopFn"), {}); } }
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
	f.seededAt = gJitSeeded.size();
	f.loopDepth = gLoopCondBlocks.size();
	gJitInlineFrames.push_back(f);
	
}

/*  jitKindUncarried -- 1 for an UNSEEDED operand whose kind at build is known and is not a count or a number (a string,
    token, buffer, group, set ...). The jit carries counts and numbers only; such an operand's value is a run-time fact,
    so its statement is handed over (docket item 3). A kindless operand is NOT caught here.  */
extern "C" int jitKindUncarried(GroupItem *x)
{
	
	if ( !x || x->jitData ) return 0;
	int kd = x->groupBody->flags.data;
	if ( !kd && ::jitLocalNonScalar(x->groupBody) ) return 1;     // a kindless local its writer made non-scalar (SEQ 388)
	return ( kd && !isCOUNT(kd) && !isNUMBER(kd) ) ? 1 : 0;
	
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

/*  jitNoteFor -- a for statement's writers, recorded at aCTionFOR's jitting gate before the statement goes to run time
    (SEQ 390 R2, Tony). The cursor (Looper, followed to the local) is a holder, as an iterate cursor is. The body is never
    walked at build, but it is already BUILT, so its writes are read from the tree: an instruction whose children are a
    local, an assign-tier op and a value. `:=` / `<-` make a holder; a value of known kind gives that kind; a value of no
    known kind gives no scalar slot -- the body runs interpreted, so nothing the jit carries makes it a scalar. The scan
    descends into instruction nodes and through an ExpressioN's group, never into a local, a rule or an action.  */
extern "C" int jitNoteFor(GroupItem *input)
{
	
	if ( !input ) return 0;
	GroupItem *lp = input->get((char*)"Looper");
	if ( lp ) ::jitNoteWriter(0, (isGROUP(lp->groupBody->flags.data) && lp->getGroup()) ? lp->getGroup() : lp, 0);
	std::function<void(GroupItem*,int)> scan = [&](GroupItem *n, int d) {
	if ( !n || d > 64 ) return;
	GroupBody *b = n->groupBody;
	if ( b->flags.isLocal || b->flags.isRule || b->flags.actionType ) return;
	if ( n != input && n->get((char*)"Looper") && n->get((char*)"StatemenT") ) { ::jitNoteFor(n); return; }
	if ( !b->flags.instructType ) {
	if ( isGROUP(b->flags.data) && b->gGroup && b->tag && !::strcmp(b->tag, "ExpressioN") ) scan(b->gGroup, d+1);
	return; }
	if ( b->groupList ) {
	GroupItem *t = n->get(1), *op = n->get(2), *v = n->get(3);
	if ( t && op && ::opIsAssignTier(op) && t->groupBody->flags.isLocal && !t->groupBody->flags.isArgument
	&& !t->groupBody->flags.noPrint && !t->groupBody->flags.data ) {
	GroupBody *tb = t->groupBody;
	int kind = 1;
	if ( (void*)op->groupBody->gOp == (void*)&opSetGroup || (void*)op->groupBody->gOp == (void*)&opRebind ) kind = 6;
	else if ( v && v->groupBody->flags.data ) kind = isCOUNT(v->groupBody->flags.data) || isNUMBER(v->groupBody->flags.data) ? 5 : v->groupBody->flags.data;
	auto it = gJitLocalKind.find(tb);
	if ( kind == 5 ) { if ( it == gJitLocalKind.end() ) gJitLocalKind[tb] = 5; }
	else if ( it == gJitLocalKind.end() || it->second == 5 ) {
	gJitLocalKind[tb] = kind;
	if ( ::jitFrameFind((void*)&(tb->gCount)) || ::jitFrameFind((void*)&(tb->gNumber)) ) {
	gJitRestartNeeded = true;
	gJitKindRestarts++; } } }
	for ( GroupItem *c = b->groupList->firstInList; c; c = c->nextInParent ) scan(c, d+1); } };
	scan(input->get((char*)"StatemenT"), 0);
	return 1;
	
}

/*  jitNoteWriter -- a kindless local takes its kind from its build-visible writer (SEQ 388 R1, Tony). Asked at runOPdirect's
    top for every assign-tier op under jitting, and at aCTionIterate's jitting gate for the cursor (op null). `:=`, `<-` and
    a cursor make a holder; `=` or a compound whose argument has a known non-scalar kind (a string literal, a local already
    found non-scalar) gives that kind; any other argument is one the jit seeds or carries, so a scalar. `=` with no
    argument in hand says nothing. A non-scalar outranks a scalar, and one found after the prologue slotted the local
    restarts the build -- a non-scalar never gets a scalar slot.  */
extern "C" int jitNoteWriter(GroupItem *op, GroupItem *target, GroupItem *arg)
{
	
	if ( !target ) return 0;
	GroupBody *tb = target->groupBody;
	if ( !tb->flags.isLocal || tb->flags.isArgument || tb->flags.noPrint || tb->flags.data ) return 0;
	int kind = 5;
	if ( !op ) kind = 6;
	else if ( (void*)op->groupBody->gOp == (void*)&opSetGroup || (void*)op->groupBody->gOp == (void*)&opRebind ) kind = 6;
	else if ( !arg ) return 0;
	else if ( !arg->jitData ) {
	int ad = arg->groupBody->flags.data;
	if ( ad && !isCOUNT(ad) && !isNUMBER(ad) )             kind = ad;
	else if ( !ad && ::jitLocalNonScalar(arg->groupBody) ) kind = gJitLocalKind[arg->groupBody]; }
	auto it = gJitLocalKind.find(tb);
	if ( kind == 5 ) { if ( it == gJitLocalKind.end() ) gJitLocalKind[tb] = 5; return 0; }
	if ( it != gJitLocalKind.end() && it->second != 5 ) return 0;
	gJitLocalKind[tb] = kind;
	if ( ::jitFrameFind((void*)&(tb->gCount)) || ::jitFrameFind((void*)&(tb->gNumber)) ) {
	gJitRestartNeeded = true;
	gJitKindRestarts++; }
	return 1;
	
}

/*  jitOpEmits -- WILL THIS DISPATCH EMIT, OR EXECUTE? (SEQ 384, Tony: compiling has no side effects.) Asked under jitting
    BEFORE runOPdirect dispatches, so a dispatch that would run its interpreted body at build is handed to run time instead.
    An operator emits only if its function carries a jitting gate (the list below); a unary the same; a call emits for a
    rule (the term call) or an action (inlined), and for a command only if the command is jit-aware. Anything not on the
    list is handed over -- a new operator defaults to running at run time, never at build.  */
extern "C" int jitOpEmits(GroupItem *op, GroupItem *target)
{
	
	if ( !op ) return 1;
	GroupBody *ob = op->groupBody;
	if ( isOperator(ob->flags.instructType) ) {
	void *g = (void*)ob->gOp;
	static void *gated[] = { (void*)&opAssign, (void*)&opPlus, (void*)&opRem, (void*)&opMinus, (void*)&opMultiply,
	(void*)&opDiv, (void*)&opEQ, (void*)&opNotEQ, (void*)&opGT, (void*)&opGE, (void*)&opLT, (void*)&opLE,
	(void*)&opDot, (void*)&opPlusEQ, (void*)&opMinusEQ, (void*)&opMultiplyEQ, (void*)&opDivEQ };
	for ( void *p : gated ) if ( p == g ) return 1;
	return 0; }
	if ( isMethod(ob->flags.instructType) ) {
	//  nothingToSee a unary on an operand the build cannot see (null) has nothing to emit from -- its gate would read it
	if ( !target ) return 0;
	void *m = (void*)ob->gMethod;
	static void *gated[] = { (void*)&opPlusPlus, (void*)&opMinusMinus, (void*)&opUnaryMinus, (void*)&opDeref,
	(void*)&opDot, (void*)&jitTrace };
	for ( void *p : gated ) if ( p == m ) return 1;
	return 0; }
	if ( target ) {
	GroupBody *tb = target->groupBody;
	if ( ::callIsRule(target) )                 return 1;
	if ( tb->flags.actionType )                 return 1;
	if ( isMethod(tb->flags.instructType) )     return (void*)tb->gMethod == (void*)&jitTrace;
	}
	return 1;
	
}

extern "C" GroupItem *jitOpFireRT(GroupItem *op, GroupItem *arg, GroupItem *target)
{
	
	GroupRules *ruler = GroupControl::groupController->groupRules;
	if ( ruler->refused || !op ) return 0;
	if ( target && target->groupBody->flags.isVirtual )   target = ::copyOf(target);
	GroupItem *pick = ::pickKindOP(op,target,arg);
	if ( !pick->groupBody->gOp ) return 0;
	return pick->groupBody->gOp(arg,target);
	
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
	//  jitAssignNodeRT into the FIELD, not into a jitSlot, so the scalar arm
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
    // priorNotNext  the walk is next() -- appendGroup's own order; the list is built in source order since c4
*******************************************************************************/
extern "C" void jitPrintList(GroupItem *ExpressioN, GroupItem *FormaT)
{
	
	if (!gJitBuilder || !ExpressioN) return;
	GroupItem *part = 0;
	while ((part = ExpressioN->next(part))) {
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
    jitProbeDrive -- THE STATION CERTIFICATE'S DRIVE, jitted against interpreted.
    driveStep's own lines (push the message, raise the floor, fire, read the mark
    as an OFFSET, pop). BOTH roads drive `rule` through parseRule and WATCH
    `armed` (default: rule) at the door, counting its fires and successes; jitted=1
    compiles armed's carrier first (compile only, outside the push) and has the
    door fire that compiled body in place of its BlocK -- nothing else changes.
    ⚠ `rule` is a ROOT, not the rule under test: a top-level drive of a member
    rule (DO, IF, PrinT ...) REFUSES "no enclosing activation to take the label"
    on the interpreted road, so they are reached nested, as the door will reach
    them. `refused` is cleared either side of the drive and reported. (Station 1 fired the body BARE, which skipped parseRule's
    frame, faces and exit -- a harness difference that would read as a body one.)
    Prints one PROBE line with the term-call count; the reading is also left in
    gProbe* for an lldb driver.
    ⚠ Driven from lldb until the door exists (station 4): a carrier is not
    isCoded, so testing() cannot reach it.
*******************************************************************************/
extern "C" int jitProbeDrive(GroupItem *rule, GroupItem *armed, char *msg, int jitted)
{
	
	GroupRules *ruler = GroupControl::groupController->groupRules;
	gProbeVerdict = gProbeConsumed = gProbeLength = gProbeTerms = gProbeFires = gProbeTrue = -9;
	if (!rule || !msg) return -1;
	if (!armed) armed = rule;
	GroupItem *carrier = armed->get((char*)"builtinParseR");
	if (!carrier) { printf("PROBE REFUSED: %s has no carrier\n", armed->groupBody->tag); fflush(stdout); return -8; }
	//  COMPILE OUTSIDE THE PUSH AND WITHOUT FIRING -- the fire belongs to the door.
	//  ONE COMPILE PER CARRIER PER PROCESS (2026-09-24): a carrier's symbol can be defined only once, so switching the
	//  armed carrier away and back used to recompile and fail with a duplicate definition. The door remembers each
	//  carrier's compiled function and reuses it.
	static GroupItem *pcCarrier[256];
	static int (*pcFn[256])(GroupItem*);
	static int pcN = 0;
	int (*probeFn)(GroupItem*) = nullptr;
	if (jitted) {
	for (int i = 0; i < pcN; i++) if (pcCarrier[i] == carrier) { probeFn = pcFn[i]; break; }
	if (!probeFn) {
	gJitCompileOnly = 1;
	int c = ::jitRunAction(carrier);
	gJitCompileOnly = 0;
	if (c < 0 || gJitLastAction != carrier) { printf("PROBE REFUSED: compile of %s returned %d\n", armed->groupBody->tag, c); fflush(stdout); return -7; }
	probeFn = gJitLastFn;
	if (pcN < 256) { pcCarrier[pcN] = carrier; pcFn[pcN] = probeFn; pcN++; } } }
	GroupItem *m = new GroupItem((char*)"probeMsg");
	m->setText(::strdup(msg));
	if (!m->groupBody->flags.data) { printf("PROBE REFUSED: message carries no data\n"); fflush(stdout); return -1; }
	int baseStak = ruler->inputSTAK ? ruler->inputSTAK->length : 0;
	ruler->divertToRule = 1;
	//  probeFloor A DRIVE HIDES ITS CALLER: the floor goes on before the push and comes off before the single return (stroke 5.5f, SEQ 241)
	ParseActivation probeFloor;
	probeFloor.instance = 0; probeFloor.isFloor = 1; probeFloor.compileOwner = 0; probeFloor.label = 0; probeFloor.prev = ruler->gParseActive;
	ruler->gParseActive = &probeFloor;
	//  branchFrame a drive door is a frame for the control slot until D-22 unifies the doors (SEQ 264 R2)
	int probeBranchSave = ruler->branchKind;
	ruler->branchKind = 0;
	ruler->pushInput(m);
	char *driveBase  = ruler->atRuleMark;
	int   priorFloor = ruler->inputFloor;
	ruler->inputFloor = ruler->inputSTAK->length;
	int priorIndent = ruler->lastIndent, priorDefining = ruler->defining;
	//  BOTH ROADS FIRE `rule` THROUGH parseRule and WATCH `armed` at the door; the
	//  jitted road also fires armed's COMPILED body there. Every other rule runs the
	//  interpreted road either way.
	gJitProbeCarrier = carrier;
	gJitProbeFn      = jitted ? probeFn : nullptr;
	gProbeRuleFires = gProbeRuleTrue = 0;
	gTermCallCount = 0;
	ruler->refused = 0;
	GroupItem *r = rule->groupBody->gMethod ? rule->groupBody->gMethod(rule) : 0;
	int terms = gTermCallCount, fires = gProbeRuleFires, trues = gProbeRuleTrue, refused = ruler->refused;
	gJitProbeCarrier = nullptr; gJitProbeFn = nullptr;
	ruler->refused = 0;
	int verdict = ::truthOf(r);
	int len = (int)::strlen(driveBase), consumed = -1;
	if (ruler->atRuleMark >= driveBase && ruler->atRuleMark <= driveBase + len)
	consumed = (int)(ruler->atRuleMark - driveBase);
	ruler->inputFloor = priorFloor;
	ruler->lastIndent = priorIndent; ruler->defining = priorDefining;     //  driveStep's own restore (F-125)
	while (ruler->inputSTAK && ruler->inputSTAK->length > baseStak) ruler->popInput();
	gProbeVerdict = verdict; gProbeConsumed = consumed; gProbeLength = len; gProbeTerms = terms;
	gProbeFires = fires; gProbeTrue = trues;
	printf("PROBE %s via %s %s msg=\"%s\" verdict=%d consumed=%d length=%d terms=%d fires=%d true=%d refused=%d\n",
	armed->groupBody->tag, rule->groupBody->tag, jitted ? "JITTED" : "INTERP", msg,
	verdict, consumed, len, terms, fires, trues, refused);
	fflush(stdout);
	ruler->gParseActive = probeFloor.prev;
	ruler->branchKind = probeBranchSave;
	return verdict;
	
}

extern "C" GroupItem *jitRefire(GroupItem *input)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	
	if (!gJitLastFn) {
	printf("=== jitRefire: NOTHING COMPILED YET (call testing() first) ===\n");
	fflush(stdout);
	return 0; }
	int r = gJitLastFn(jitBodyField(gJitLastAction));
	printf("=== jitRefire result = %d ===\n", r); fflush(stdout);
	
	return ruler->trueResult;
}

extern "C" int jitReloadCountSlotRT(GroupItem *body, int old)
{
	 GroupBody *gb = (GroupBody*)(void*)body; return isCOUNT(gb->flags.data) ? gb->gCount : old; 
}

extern "C" double jitReloadNumberSlotRT(GroupItem *body, double old)
{
	 GroupBody *gb = (GroupBody*)(void*)body; return isNUMBER(gb->flags.data) ? gb->gNumber : old; 
}

/*  pairs with jitSaveFrameRT's unconditional push.   jitEmitters.jitSaveFrameRT  */
extern "C" void jitRestoreFrameRT(GroupItem *field)
{
	::restoreLocalFields(field);
	/*  Pop, and restore only a non-empty entry -- an argument-less jitted call
	pushed an empty one and has nothing to give back.   jitContext.gChan  */
	::jitChanPopRT();
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
	//  compileOnce a compiled body is REUSED, never rebuilt -- its JiT record and the JIT's symbol stay as built (SEQ 385 R1)
	if (JitCacheSlot *cached = action ? jitCacheFind(action->groupBody) : nullptr) {
	printf("=== jitRunAction: %s REUSED as %s ===\n", action->groupBody->tag, cached->name.c_str());
	gJitLastFn     = cached->fn;
	gJitLastAction = action;
	int r = gJitCompileOnly ? 0 : cached->fn(jitBodyField(action));
	printf("=== jitRunAction result = %d ===\n", r);
	printf("=== jitDegrade count = %d ===\n", gJitDegradeCount);
	printf("=== jitCompile count = %d ===\n", gJitCompileCount);
	printf("=== jitSlot count = %d ===\n", gJitSlotCount);
	printf("=== jitSlotUnaryRefused = %d ===\n", gJitSlotUnaryRefused); fflush(stdout);
	return r; }
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
	gJitLocalKind.clear();
	gJitKindRestarts = 0;
	int  restarts = 0;
	int  built    = 0;
	for (;;) {
	//  R2's BOUND, CHECKED BEFORE THE WORK RATHER THAN AFTER. Each restart
	//  is caused by at least one NOVEL callee entering gJitNeedOwnFn, which
	//  never shrinks -- so restarts can never exceed its size. A violation
	//  means the monotone growth argument is false, and it is reported as a
	//  RED (-7) rather than allowed to spin: a hang is not a wrong answer,
	//  it is the absence of a run, and nobody parked that (rule H5).
	if (restarts > (int)gJitNeedOwnFn.size() + gJitKindRestarts) {
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
	//  compileOnce a callee the JIT already holds is DECLARED here, not rebuilt; the JIT links the call to it
	if (JitCacheSlot *cached = jitCacheFind(pb)) {
	llvm::Function *decl = llvm::Function::Create(
	llvm::FunctionType::get(llvm::Type::getInt32Ty(*gJitCtx), {llvm::PointerType::getUnqual(*gJitCtx)}, false),
	llvm::Function::ExternalLinkage, cached->name, gJitModule);
	JitFnSlot s; s.body = pb; s.action = pa; s.fn = decl;
	gJitFnMap.push_back(s);
	printf("=== jitRunAction: callee %s REUSED as %s ===\n", pb->tag, cached->name.c_str());
	fflush(stdout);
	continue; }
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
	//  compileOnce what this module DEFINES, named now -- the Functions die with the move below
	std::vector<std::pair<GroupBody*,std::string>> defined;
	for (JitFnSlot &s : gJitFnMap)
	if (!s.fn->isDeclaration()) defined.push_back({s.body, s.fn->getName().str()});
	defined.push_back({action->groupBody, driverName});
	
	if (auto err = jit->addIRModule(
	llvm::orc::ThreadSafeModule(std::move(mod), std::move(ctx)))) {
	//  LLVM'S OWN TEXT, NOT A SWALLOWED ERROR. A bare -3 said only that the
	//  add failed; the text says WHY -- a duplicate symbol reads differently
	//  from a malformed module, and the recon had to guess between them.
	std::string why = llvm::toString(std::move(err));
	gJitCtx = nullptr; gJitModule = nullptr;
	printf("=== JIT addIRModule failed: %s ===\n", why.c_str()); fflush(stdout); return -3; }
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
	//  noDanglingBuilder the builder was jitBuildFunction's local and is gone; run-time code must not see it (seal 163, SEQ 384)
	gJitBuilder = nullptr;
	auto sym = jit->lookup(fnName);
	if (!sym) { llvm::consumeError(sym.takeError());
	printf("=== JIT lookup failed ===\n"); fflush(stdout); return -4; }
	int (*fp)(GroupItem*) = sym->toPtr<int(*)(GroupItem*)>();
	gJitLastFn     = fp;      // keep it: the ladder fires it again, uncompiled
	gJitLastAction = action;  // and what it runs on is re-read at each refire
	for (auto &d : defined) {
	if (jitCacheFind(d.first)) continue;
	auto ds = jit->lookup(d.second);
	if (!ds) { llvm::consumeError(ds.takeError()); continue; }
	gJitCache.push_back({d.first, d.second, ds->toPtr<int(*)(GroupItem*)>()}); }
	int r = gJitCompileOnly ? 0 : fp(jitBodyField(action));
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
	::jitChanPushRT();
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
	resultNode->jitData->computed = true;
	gJitSeeded.push_back(resultNode);
	}
	gJitResult = out;
	gJitEmitted = true;
	
}

/*  jitScOperandRT -- one AND/OR operand the jit could not emit, evaluated at RUN time on the interpreted road, as
    runShortCircuit evaluates it; its truth comes back as an i32. A refusal's scope is the operand: it opens with none
    in force and clears its own on the way out, as jitIfRT does.  */
extern "C" int jitScOperandRT(GroupItem *operand)
{
GroupItem 	*value = operand;
int 		truth = 0;
	::clearRefusal(operand);
	if ( value )
		if ( isMethod(value->groupBody->flags.instructType) && value->groupBody->flags.invoke )
			value = value->groupBody->gMethod(value);
	truth = ::truthOf(value);
	::clearRefusal(operand);
	return truth;
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
	//  literalComputed the build makes a literal's value itself -- a constant -- so it counts as computed (SEQ 407)
	d->computed = true;
	token->jitData = d;
	gJitSeeded.push_back(token);
	return token;
	
}

// jitSeedOperands seed both operands for the emitter -- a literal as a constant, anything else as a field
extern "C" void jitSeedOperands(GroupItem *target, GroupItem *arg)
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
	GroupItem  *definer = field->instanceRule();
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
	/*  THE PROPERTY LIST IS HALF THE RECORD SINCE OBJECT-MODEL STROKE 3: CodE and
	BlocK moved there, JiT did not, and coresidence asks about all three.  */
	att = 0;
	while ((att = definer->nextProperty(att))) {
	char *t = att->groupBody->tag;
	char *x = att->getText();
	printf("  %s  noPrint=%d  %zu bytes\n",
	t ? t : "(untagged)",
	att->groupBody->flags.noPrint ? 1 : 0,
	x ? ::strlen(x) : (size_t)0);
	kount++; }
	printf("=== RECORD %s: %d attributes ===\n", definer->groupBody->tag, kount);
	fflush(stdout);
	return ruler->trueResult;
	
}

// jitSlotTaken 1 when a jitting op carries an emitter slot to fire -- counted HERE so no shim can forget; a unary slot refuses out loud and runs interpreted
extern "C" int jitSlotTaken(GroupItem *op)
{
	
	if ( !GroupControl::groupController->groupRules->jitting || !op->groupBody->gJitEmitter ) return 0;
	if ( op->groupBody->flags.isUnary ) {
	++gJitSlotUnaryRefused;
	::fprintf(stderr,
	"=== JIT SLOT REFUSED #%d: unary op '%s' carries a jitEmitter, "
	"but the unary specimen has not landed -- running INTERPRETED ===\n",
	gJitSlotUnaryRefused, op->groupBody->tag ? op->groupBody->tag : "(unnamed)");
	::fflush(stderr);
	return 0;
	}
	++gJitSlotCount;
	return 1;
	
}

/*  jitStmtBegin -- mark where a statement's emission starts: the insert block, its last instruction, and how many blocks
    the function has. Saves the enclosing statement's hand-over flag and starts this one clear.  */
extern "C" void jitStmtBegin()
{
	
	JitStmtMark m;
	llvm::IRBuilder<> *b = gJitBuilder;
	if ( b && b->GetInsertBlock() && b->GetInsertBlock()->getParent() && b->GetInsertPoint() == b->GetInsertBlock()->end() ) {
	m.bb      = b->GetInsertBlock();
	m.last    = m.bb->empty() ? nullptr : &m.bb->back();
	m.nBlocks = m.bb->getParent()->size(); }
	m.outer = gJitHandOver;
	gJitHandOver = false;
	gJitArgFollowNode = nullptr; gJitArgFollowVal = nullptr;
	gJitStmtMarks.push_back(m);
	
}

/*  jitStmtEnd -- a handed-over statement: ROLL BACK every instruction and block it emitted, so no emitted half runs and
    then runs again inside the interpreted whole, then emit ONE run-time call for it (jitEmitStmtRT, which flushes the
    frame before the call and reloads it after). Blocks an enclosing construct still holds -- if / loop / short-circuit
    stacks, inline exits, the epilogue -- are kept. Restores the enclosing statement's flag.  */
extern "C" void jitStmtEnd(GroupItem *statement)
{
	
	gJitArgFollowNode = nullptr; gJitArgFollowVal = nullptr;
	if ( gJitStmtMarks.empty() ) return;
	size_t depth = gJitStmtMarks.size();
	JitStmtMark m = gJitStmtMarks.back();
	gJitStmtMarks.pop_back();
	bool handed = gJitHandOver;
	//  holderWrites a handed-over statement's holder writes are recorded; a statement that runs compiled passes them to its
	//  enclosing statement, which may still be handed over whole (SEQ 405)
	for ( auto it = gJitStmtHolderWrites.begin(); it != gJitStmtHolderWrites.end(); ) {
	if ( it->first >= depth ) {
	if ( handed ) { gJitRTHolders.insert(it->second); it = gJitStmtHolderWrites.erase(it); continue; }
	it->first = depth - 1;
	if ( it->first == 0 ) { it = gJitStmtHolderWrites.erase(it); continue; } }
	++it; }
	gJitHandOver = m.outer;
	//  loopControlUp a compiled statement's continue / break marks belong to the statement enclosing it (SEQ 410)
	if ( !handed ) { if ( !gJitStmtMarks.empty() ) gJitStmtMarks.back().branches |= m.branches; return; }
	llvm::IRBuilder<> *b = gJitBuilder;
	if ( !b ) return;
	if ( m.bb ) {
	llvm::Function *fn = m.bb->getParent();
	std::set<llvm::BasicBlock*> keep;
	for ( auto *x : gIfEndBlocks )    keep.insert(x);
	for ( auto *x : gIfElseBlocks )   keep.insert(x);
	for ( auto *x : gLoopCondBlocks ) keep.insert(x);
	for ( auto *x : gLoopExitBlocks ) keep.insert(x);
	for ( auto *x : gLoopBodyBlocks ) keep.insert(x);
	for ( auto *x : gScEndBlocks )    keep.insert(x);
	for ( auto &f : gJitInlineFrames ) if ( f.exitBB ) keep.insert(f.exitBB);
	if ( gJitEpilogueBB ) keep.insert(gJitEpilogueBB);
	std::vector<llvm::BasicBlock*> dead;
	size_t i = 0;
	for ( auto &bbx : *fn ) { if ( i++ >= m.nBlocks && !keep.count(&bbx) ) dead.push_back(&bbx); }
	std::vector<llvm::Instruction*> tail;
	for ( auto it = m.last ? std::next(m.last->getIterator()) : m.bb->begin(); it != m.bb->end(); ++it ) tail.push_back(&*it);
	std::set<llvm::Value*> gone;
	for ( auto *ins : tail ) gone.insert(ins);
	for ( auto *d : dead ) for ( auto &ins : *d ) gone.insert(&ins);
	for ( GroupItem *g : gJitSeeded )
	if ( g->jitData && (gone.count(g->jitData->jitValue) || gone.count(g->jitData->jitSlot)) ) g->jitData = nullptr;
	auto clearIf = [&](llvm::Value *&v) { if ( v && gone.count(v) ) v = nullptr; };
	clearIf(gJitResult); clearIf(gJitResultNode); clearIf(gJitPrintBuf);
	clearIf(gJitDotSeededVal); clearIf(gJitDotProduct); clearIf(gJitComputedVal);
	for ( auto *ins : tail ) ins->dropAllReferences();
	for ( auto *d : dead ) d->dropAllReferences();
	for ( auto *v : gone ) if ( !v->use_empty() ) v->replaceAllUsesWith(llvm::PoisonValue::get(v->getType()));
	for ( auto it = tail.rbegin(); it != tail.rend(); ++it ) (*it)->eraseFromParent();
	for ( auto *d : dead ) d->eraseFromParent();
	b->SetInsertPoint(m.bb); }
	gJitResult        = nullptr;
	gJitLastIsNode    = false;
	gJitStmtCanRefuse = false;
	//  loopControlScan the build does not walk the arm of a statement it hands over, so its continue / break is found in the
	//  statement's own tree: a keyword node tagged continue or break, through labels (SEQ 410)
	{
	GroupRules *rl = GroupControl::groupController->groupRules;
	std::set<GroupItem*> seen;
	std::function<int(GroupItem*,int)> scan = [&](GroupItem *g, int d) -> int {
	if ( !g || d > 64 || !seen.insert(g).second ) return 0;
	int r = 0;
	const char *t = g->groupBody->tag;
	if ( t && g->groupBody->registry == rl->keyWords ) {
	if ( !strcmp(t, "continue") ) r |= 2;
	else if ( !strcmp(t, "break") ) r |= 1; }
	if ( g->groupBody->flags.isLabel && isGROUP(g->groupBody->flags.data) ) r |= scan(g->getGroup(), d + 1);
	for ( GroupItem *c = g->groupBody->groupList ? g->groupBody->groupList->firstInList : nullptr; c; c = c->nextInParent )
	r |= scan(c, d + 1);
	return r; };
	m.branches |= scan(statement, 0);
	}
	gJitStmtRTBranches = m.branches;
	::jitEmitStmtRT(statement);
	gJitStmtRTBranches = 0;
	
}

/*  jitStmtRT -- a statement the jit could not emit, run at RUN time on the interpreted road: its own method on its own
    node, with jitting off as it always is at run time. A refusal's scope is the statement, as in jitIfRT. Returns 0 ran,
    1 refused, 2 RETURNED -- its value then waits in gJitStmtRTValue for the emitted code (SEQ 393 A).  */
extern "C" int jitStmtRT(GroupItem *statement, GroupItem *owner)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*priorMETHOD = ruler->currentMETHOD->getGroup();
GroupItem 	*stmtValue = 0;
int 		refusedHere = 0;
	// ownerIsCurrent the statement runs as its action's, so a local it mints or a scope it binds lands there (SEQ 384: dirT's scope statement read a null currentMETHOD)
	if ( owner )
		ruler->currentMETHOD->setGroup(owner);
	::clearRefusal(statement);
	if ( isMethod(statement->groupBody->flags.instructType) )
		stmtValue = statement->groupBody->gMethod(statement);
	ruler->currentMETHOD->setGroup(priorMETHOD);
	// endsTheAction a refusal raised by the interpreted run ends the action: the emitted call leaves the function on a 1 (SEQ 370 R1)
	if ( ruler->refused )
		refusedHere = 1;
	::clearRefusal(statement);
	// returnEndsTheFunction a return run here ends the COMPILED function, which is its action's frame: the slot is consumed, never left set for the caller's block (SEQ 393 A)
	if ( !refusedHere && ruler->branchKind == 3 )
		{
		ruler->branchKind = 0;
		if ( stmtValue && stmtValue->groupBody->registry == ruler->keyWords )
			stmtValue = 0;
		 gJitStmtRTValue = stmtValue; 
		refusedHere = 2;
		}
	// loopControl a continue or a break run here leaves the statement for its loop: 3 continue, 4 break (SEQ 410)
	if ( !refusedHere && ruler->branchKind == 2 )
		{
		ruler->branchKind = 0;
		refusedHere = 3;
		}
	if ( !refusedHere && ruler->branchKind == 1 )
		{
		ruler->branchKind = 0;
		refusedHere = 4;
		}
	return refusedHere;
}

/*  jitStmtRTValueRT -- run time, after a handed-over statement RETURNED: the value it returned, as a count, followed
    through a holder as aCTionBlocK follows it; `old` (the result slot) for a bare `return;` (SEQ 393 A).  */
extern "C" int jitStmtRTValueRT(int old)
{
	
	GroupItem *v = gJitStmtRTValue;
	gJitStmtRTValue = nullptr;
	if ( !v ) return old;
	if ( isGROUP(v->groupBody->flags.data) && v->getGroup() ) v = v->getGroup();
	return v->getCount();
	
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

/*******************************************************************************
    jitEmitTermCall / jitTermCallRT -- THE TERM CALL-THROUGH (jitter station 1,
    2026-09-23). A rule invoked as a term -- `Token()` in a generated body --
    used to be PARSED AT EMIT TIME by runOP's isRule arm, against whatever input
    was live, and emit nothing. Now runOP's arm emits a call to jitTermCallRT,
    which at RUN time runs runOP on the same node the interpreted way and returns
    truthOf the result. One spelling on both roads: the run-time helper IS the
    interpreted dispatch. Inline comes later and is diffed against this.
    ⚠ It returns a FRESH node, never the xpress node or a sentinel: a write on the
    parse tree or on trueResult would outlive the compile (bear-trap #22). (Before
    P4, aCTionBrancH stamped isBranch on whatever came back; the kind now rides the
    ruler slot.)
    SEQ 318 c1: it bakes the dispatch's three RAW slots -- op, target, argument as
    they arrived, before following -- and replays runOPslots on them, which is
    exactly what runOP on the instruction node did (runOP is now that unpacker).
*******************************************************************************/
extern "C" int jitTermCallRT(GroupItem *op, GroupItem *target, GroupItem *arg)
{
	
	return ::truthOf(::runOPslots(op,target,arg));
	
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
    jitter -- THE jitter; COMMAND (SEQ 386). From this point in the run every
    action is compiled at its first call and answers from the cache after.
    Actions only; no off switch. It is gJitter's one writer. The exit report is
    the witness: one line per body the jitter met.
*******************************************************************************/
extern "C" GroupItem *jitter(GroupItem *input)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	
	if ( !gJitter )
	::atexit([]{
	for ( JitterTally &t : gJitterTally ) {
	if ( t.notJittable ) ::fprintf(stderr,"=== jitter: %s not jittable, called %d interpreted ===\n", t.tag.c_str(), t.called);
	else                 ::fprintf(stderr,"=== jitter: %s built %d called %d ===\n", t.tag.c_str(), t.built, t.called); }
	::fflush(stderr); });
	gJitter = 1;
	
	return ruler->trueResult;
}

/*  jitterReady -- runAction's intercept asks it at every interpreted call once the jitter is on. 1: gJitterFn is the
    action's compiled function, fire it. 0: run it interpreted. A first call compiles through jitRunAction, silenced --
    the run's output is the program's, not the compiler's -- and is never retried once refused.   jitter.firstCall  */
extern "C" int jitterReady(GroupItem *field)
{
	
	GroupBody   *fb = field->groupBody;
	JitterTally *t  = ::jitterTallyFind(fb);
	if ( !t ) { gJitterTally.push_back({fb, std::string(fb->tag ? fb->tag : "anon"), 0, 0, false}); t = &gJitterTally.back(); }
	if ( t->notJittable ) { t->called++; return 0; }
	JitCacheSlot *c = ::jitCacheFind(fb);
	if ( !c ) {
	GroupRules *ruler = GroupControl::groupController->groupRules;
	int (*saveFn)(GroupItem*) = gJitLastFn; GroupItem *saveAct = gJitLastAction;
	fflush(stdout); fflush(stderr);
	int so = dup(1), se = dup(2), dn = open("/dev/null", O_WRONLY);
	const char *keep = ::getenv("INCANT_JITTER_ERR");
	int de = keep ? open(keep, O_WRONLY | O_CREAT | O_APPEND, 0644) : dup(dn);
	dup2(dn,1); dup2(de,2); close(de);
	gJitCompileOnly = 1;
	int rc = ::jitRunAction(field);
	gJitCompileOnly = 0;
	fflush(stdout); fflush(stderr);
	dup2(so,1); dup2(se,2); close(so); close(se); close(dn);
	gJitLastFn = saveFn; gJitLastAction = saveAct;
	ruler->refused = 0;
	c = ::jitCacheFind(fb);
	if ( rc < 0 || !c ) {
	t->notJittable = true; t->called++;
	::fprintf(stderr,"=== jitter: %s NOT JITTABLE (compile returned %d) -- it runs interpreted from now on ===\n", t->tag.c_str(), rc);
	::fflush(stderr);
	return 0; }
	t->built++; }
	t->called++;
	gJitterFn = c->fn;
	return 1;
	
}

// limitWriteCheck after the write: a bad maxLimit or repeatLimit is refused and the prior count put back (F-27)
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

// limitWriteGuard before the write: the prior count when the target is maxLimit or repeatLimit, else 0 -- one int test on every other assignment
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

/*******************************************************************************
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
*******************************************************************************/
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
	The incant load command, a noPrint command designed used as an
    attribute invokes loadDirectory to read in a directory and for every file
    in the directory creates an entry in the input parent group.
    DOES NOT HANDLE FILE MASKS??? It used to I think.
*******************************************************************************/
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

/*******************************************************************************
	The incant include command call this method to read in file to be processed.
    It does not specify what rule to run on the new input.
*******************************************************************************/
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
    A loop's condition, for DO and WhilE. A method-bearing condition is called
    exactly as before; a bare value -- `while 0;` -- has no method and is tested
    by truthOf, as aCTionIF already does.
*******************************************************************************/
extern "C" GroupItem *loopCondition(GroupItem *cond)
{
	if ( !cond )
		return 0;
	if ( cond->groupBody->gMethod )
		return cond->groupBody->gMethod(cond);
	if ( ::truthOf(cond) )
		return cond;
	return 0;
}

// makeDataType set target to the data type the argument names -- called from setInternalType
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

/*******************************************************************************
	Command to make a new field w/tag set from input text. The GroupItem(String)
	constructor seeds BOTH tag and text from the string; we clear the text so a
	freshly-made field starts empty — the tag carries the name, the value does
	not. (Without this, new("x") yields text "x", which rides along through <:
	retags as a stale "=x" content artifact. Igor minion absorb, 2026-06-29.)
*******************************************************************************/
extern "C" GroupItem *makeNew(GroupItem *input)
{
char 		*strung = input->getText();
GroupItem 	*grup = new GroupItem(strung);
	grup->setText((char*)0);
	grup->groupBody->flags.isInitialized = 1;
	return grup;
}

/*******************************************************************************
	window attribute handler. A form field carries `window` as an attribute;
    this fires at parent-define time (fLAG set) and marks the parent form
    field as a window (isWindow). Define-then-show: it does NOT open the
    window -- openWindow(form) is the separate explicit raise trigger,
    called by name when the window should appear.
*******************************************************************************/
extern "C" GroupItem *markWindow(GroupItem *input)
{
GroupItem 	*form = input->parent;
	if ( input->groupBody->flags.fLAG )
		form->groupBody->flags.isWindow = 1;
	else	::fprintf(stderr,"window: should be invoked as an attribute when its parent is defined\n");
	return GroupControl::groupController->groupRules->trueResult;
}

// materialiseTerms rStuff at DEFINE TIME, for the rule and each term -- it closes the gap the bootstrapper's hand-built rules leave
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

// modifierIsRepeat THE MODIFIER CLASS PREDICATE: a presence test for repeatClass in the Modifiers registry, default flag -- a hand, not a witness
extern "C" int modifierIsRepeat(char *modifier)
{
	
	char one[2];
	if ( !modifier || !*modifier ) return 0;
	one[0] = *modifier; one[1] = 0;
	GroupItem *reg = GroupControl::groupController->getRegistry("Modifiers");
	if ( !reg ) return 0;
	GroupItem *entry = reg->get(one);
	if ( !entry ) return 0;
	return entry->get("repeatClass") ? 1 : 0;
	
	return 0;
}

// modify process the modifiers for the field passed in, updating its RuleStuff
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
			case '<':
				field->getRStuff()->noAdvance = 1;
				break;
			case '%':
				field->getRStuff()->modPercent = 1;
				break;
			case '&':
				field->getRStuff()->modPointer = 1;
				break;
			case '@':
				field->getRStuff()->isTarget = 1;
				break;
			case '-':
				field->getRStuff()->noLabel = 1;
				break;
			case '_':
				field->getRStuff()->modUnGuarded = 1;
				break;
			case '^':
				field->getRStuff()->noSkip = 1;
				break;
			case '{':
				field->getRStuff()->overTo = 1;
				field->getRStuff()->modUnGuarded = 1;
				break;
			case '}':
				field->getRStuff()->overTo = 2;
				field->getRStuff()->modUnGuarded = 1;
				break;
			case '$':
				field->groupBody->flags.isMacro = 1;
			}
}

// modifyClass modify(), filtered to ONE class -- one place knows what a modifier DOES, one place knows what CLASS it is
extern "C" void modifyClass(GroupItem *field, char *modifier, int wantRepeat)
{
	
	char one[2];
	one[1] = 0;
	for ( char *p = modifier; p && *p; p++ ) {
	one[0] = *p;
	if ( ::modifierIsRepeat(one) == wantRepeat ) ::modify(field,one);
	}
	
}

// opAND the AND operator's STRICT fallback: both operands have already run, so the short-circuit is runShortCircuit's, never this; answers 1 or 0 through truthOf
extern "C" GroupItem *opAND(GroupItem *argument, GroupItem *target)
{
	if ( ::truthOf(target) && ::truthOf(argument) )
		return GroupControl::groupController->groupRules->trueResult;
	return GroupControl::groupController->groupRules->falseResult;
}

// opAddAttribute the +% operator: add the argument, or each item of a list argument, as an attribute of target
extern "C" GroupItem *opAddAttribute(GroupItem *argument, GroupItem *target)
{
GroupItem 	*grup = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	// storeRuling an armed statement stores nothing
	if ( ruler->refused )
		return 0;
	// listHolderUnwraps a list entry that is a holder attaches its CONTENT, one level -- a dated exception to the star law (Tony, 2026-10-22, SEQ 399); the list arm only
	if ( isLIST(argument->groupBody->flags.binType) )
		while ( grup = argument->next(grup) )
			if ( isGROUP(grup->groupBody->flags.data) && grup->getGroup() )
				target->addAttribute(grup->getGroup());
			else	target->addAttribute(grup);
	else	target->addAttribute(argument);
	return target;
}

// opAddMember the +/ operator: add the argument, or each item of a list, as a member of target -- share-body, as +% is
extern "C" GroupItem *opAddMember(GroupItem *argument, GroupItem *target)
{
GroupItem 	*grup = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	// storeRuling an armed statement stores nothing
	if ( ruler->refused )
		return 0;
	// literalRightSideRefuses membership attaches a NODE; a literal is a value, refused by presence (isLiteral), never by a classifier
	if ( argument->groupBody->flags.isLiteral )
		return ::refuse(target,"Operator +/ -- the right side is a literal; membership attaches a field to a list, and a literal is a value with no node to attach");
	if ( isLIST(argument->groupBody->flags.binType) )
		while ( grup = argument->next(grup) )
			target->addMember(grup);
	else	target->addMember(argument);
	return target;
}

// opAddPointer the +* operator: add an attribute that POINTS AT the argument (+% adds a copy); read it back with *
extern "C" GroupItem *opAddPointer(GroupItem *argument, GroupItem *target)
{
GroupItem 	*ptr = 0;
	// pointerLifetime nothing checks the pointee's lifetime, deliberately -- point at a tempField and it changes underneath you
	if ( !argument )
		{
		// f43 name TARGET explicitly (bare tag resolved to ptr, still null here), and refuse -- never hand target back as if it were an answer
		return ::refuse(target,"Operator +* -- an operand that is nothing");
		}
	ptr = new GroupItem(argument->groupBody->tag);
	ptr->groupBody->gGroup = argument;
	ptr->groupBody->flags.data = 6;
	ptr->groupBody->flags.isInitialized = 1;
	target->addAttribute(ptr);
	return target;
}

// opAddProperty the +< operator: file the argument on target's property list, never among its terms (SEQ 224)
extern "C" GroupItem *opAddProperty(GroupItem *argument, GroupItem *target)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	// storeRuling an armed statement stores nothing, as for +%
	if ( ruler->refused )
		return 0;
	target->addProperty(argument);
	return target;
}

// opAssign the = operator: setContent -- target takes the argument's data, a holder carries its group across, a null clears; it never aliases, whatever byRef says; jitAssignNodeRT is its jitted twin, so edit the two together (assignRoadT pins both)
extern "C" GroupItem *opAssign(GroupItem *argument, GroupItem *target)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
int 		priorLimit = ::limitWriteGuard(target);
	if ( ruler->jitting )
		{
		 return jitEmitAssign(argument, target); 
		}
	// storeRulingHere an armed statement stores nothing -- asked HERE, not at runOP's entry, because an assignment dispatches before its own right-hand side
	if ( ruler->refused )
		return 0;
	// accessorWrite `x.name = v` writes the FIELD x through setGroupField, not only the copy opDot handed back (SEQ 295 R3)
	if ( target->groupBody->flags.isAccessorProduct )
		::accessorWrite(argument,target);
	// castRule a target that has a kind keeps it and the argument is cast in (SEQ 347 R0); one with no kind takes the argument's, as setContent does
	if ( argument )
		{
		if ( !::castStore(argument,target) )
			target->setContent(argument);
		}
	else	target->clearData();
	// limitGuard F-27: a non-zero priorLimit means target IS maxLimit; the guard call sits above the jitting arm on purpose
	if ( priorLimit )
		::limitWriteCheck(target,priorLimit);
	return target;
}

// opCall THE CALL EXECUTOR, A(B) and field(): rule, action, method, in runOP's old order; operands arrive finished (SEQ 318 c2)
extern "C" GroupItem *opCall(GroupItem *target, GroupItem *arg)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	// storeRuling an armed statement dispatches nothing further -- interpreted only
	if ( ruler->refused )
		if ( !ruler->jitting )
			return 0;
	// termCallIsRunOPs jitting, the term call is emitted by runOPslots, which holds the raw slots; reaching it here is a defect, said by name
	if ( ::callIsRule(target) )
		{
		
		if ( ruler->jitting )   return ::refuse(target,"opCall reached a term call under jitting -- runOPslots owns that emit, with the raw slots (SEQ 318 c2)");
		++gTermCallCount;
		return ::runRule(arg,target);
		
		}
	if ( target->groupBody->flags.actionType )
		return ::runAction(arg,target);
	if ( isMethod(target->groupBody->flags.instructType) )
		{
		if ( !arg )
			arg = target;
		return target->groupBody->gMethod(arg);
		}
	return ::refuse(target,"opCall: nothing to call -- not a rule, an action or a method (SEQ 318 c2)");
}

// opCallTest test of the call op: run target's action, or its method, on the argument
extern "C" GroupItem *opCallTest(GroupItem *argument, GroupItem *target)
{
GroupItem 	*result = 0;
	if ( target->groupBody->flags.actionType )
		result = ::runAction(argument,target);
	else
	if ( target->groupBody->gMethod )
		if ( argument )
			result = target->groupBody->gMethod(argument);
		else	result = target->groupBody->gMethod(target);
	else	::fprintf(stderr,"opCallTest: %shas no method\n",target->groupBody->tag);
	return result;
}

// opCerr the cerr rule's operator method, the stderr sink: a SIBLING of opPrint rather than a third arm, and it does not honour the print diversion, on purpose
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

// opCout the cout rule's operator method, the explicit stdout sink: it never consults toBUFFER, and that missing test IS the feature (KANT-23)
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

// opDebug the $$ debug marker: an Xcode inspection point that unwraps a group and hands it back
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

// opDeref the prefix unary *: hand back the group a field holds, or null -- its own op, so the binary * slot (opMultiply) stays isolated; under jit, jitEmitDeref or a degrade by name
extern "C" GroupItem *opDeref(GroupItem *result)
{
	if ( GroupControl::groupController->groupRules->jitting )
		{
		// holderHandOver a holder written by a handed-over statement is known only at run time: its dereference is handed over too, never followed at build (SEQ 405)
		 if ( result && gJitRTHolders.count((void*)result->groupBody) ) { ::jitHandOver((char*)"a dereference of a holder written at run time -- its statement runs at RUN time", result); return 0; } 
		// ownNode the compiled dereference hands back its own fresh node, never the build-time follow (SEQ 423)
		 if (::jitEmitDeref(result) && gJitDerefNode) return gJitDerefNode;
		::jitDegrade("unary * under jit -- emitter refused",result); 
		}
	// starRuling *x on a field holding no group yields NULL and does not refuse; the consumer of the null refuses, in its own name (Tony, 2026-09-05)
	if ( isGROUP(result->groupBody->flags.data) )
		return result->getGroup();
	return 0;
}

// opDiv the / operator: always a DOUBLE, even when exact -- 10 / 4 is 2.5
extern "C" GroupItem *opDiv(GroupItem *argument, GroupItem *target)
{
	if ( GroupControl::groupController->groupRules->jitting )
		{
		 return jitEmitBinary(argument, target, jitSDiv); 
		}
	// alwaysDouble division never changes meaning by operand type, and an exact quotient stays a double so the jit knows the result type at emit time
	if ( isCOUNT(argument->groupBody->flags.data) || isNUMBER(argument->groupBody->flags.data) || isSTRING(argument->groupBody->flags.data) || isTOKEN(argument->groupBody->flags.data) )
		GroupControl::groupController->groupRules->tempField->setNumber(target->getNumber() / argument->getNumber());
	if ( !GroupControl::groupController->groupRules->tempField->groupBody->flags.data )
		{
		return ::refuse(target,"Operator / -- not supported for these operands");
		}
	return GroupControl::groupController->groupRules->tempField;
}

// opDivEQ the /= operator: divide as / does, then narrow into the slot target already is
extern "C" GroupItem *opDivEQ(GroupItem *argument, GroupItem *target)
{
GroupItem 	*result = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	// storeRuling an armed statement stores nothing
	if ( ruler->refused )
		return 0;
	if ( ruler->jitting )
		{
		 return jitEmitAssign(jitEmitBinary(argument, target, jitSDiv), target); 
		}
	if ( (isCOUNT(target->groupBody->flags.data) || isNUMBER(target->groupBody->flags.data)) && (isCOUNT(argument->groupBody->flags.data) || isNUMBER(argument->groupBody->flags.data) || isSTRING(argument->groupBody->flags.data) || isTOKEN(argument->groupBody->flags.data)) )
		{
		// a count target rounds half-up through getCount's floor(x+0.5), so the two cannot drift; a double keeps the fraction
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
		while ( result = argument->next(result) )
			::opDivEQ(result,target);
	return result;
}

// opDot the . operator: the field a dot expression names -- a groupField accessor read off target, or target's component of that tag; local fields are ignored
extern "C" GroupItem *opDot(GroupItem *argument, GroupItem *target)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*product = 0;
	// accessorGate ONE gate for the whole accessor family; remove it and a jitted `if noPrinT` branches on whatever was last in flight
	if ( ruler->jitting )
		{
		 return jitEmitDot(argument, target, ruler->tempField); 
		}
	// leadingOnly !argument means the leading-dot form ONLY -- the right of a dot is a literal tag (ruled 09-16), so a binary null right has no road (F-132)
	if ( !argument )
		if ( ruler->lastREF )
			{
			argument = target;
			target = ruler->lastREF->getGroup();
			}
		else	::fprintf(stderr,"opDot: lastREF not set\n");
	// what arrived on the right, and whether it is a groupField
	::measureDotOperands(argument,target);
	if ( argument )
		{
		// rightIsATag the right operand is a LITERAL NAME, so read its TAG -- never .text, which answers only through bear-trap #26's fall-through
		// nullTarget a star on a field that holds no group yields NULL, and `*x.y` folds the star onto x -- refuse by name, never read through null (starDotNull, SEQ 301)
		if ( argument->groupBody->registry != ruler->groupFields )
			{
			if ( !target )
				return ::refuse(argument,"opDot: the left of this dot holds nothing -- in `*x.y` the star binds to x, so read through a temporary: `t = x.y;` then `*t`");
			product = target->get(argument->groupBody->tag);
			}
		else {
			if ( !target )
				return 0;
			product = new GroupItem(argument->groupBody->tag);
			// accessorMark the ONE meaning of isAccessorProduct: this node is opDot's copy of a groupField, so `=` on it writes the field through setGroupField (SEQ 295 R3); a node-returning case replaces product and the mark goes with it
			product->groupBody->flags.isAccessorProduct = 1;
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
					break;
				case 6:
					product->setCount((int)target->groupBody->flags.data);
					break;
				case 7:
					if ( target->groupBody->flags.hasAttributes )
						product->setCount(1);
					break;
				case 8:
					if ( target->groupBody->flags.hasMembers )
						product->setCount(1);
					// case42hasTraits NOT case 7: setParse makes hasAttributes TRUE for every walked rule, so only this one discriminates
					break;
				case 42:
					if ( target->groupBody->flags.hasTraits )
						product->setCount(1);
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
					if ( target->isRuleTerm() )
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
				case 33:
					if ( isBIN(target->groupBody->flags.binType) )
						product->setCount(1);
					break;
				case 34:
					if ( isAttribute(target->options.affiliation) )
						product->setCount(1);
					break;
				case 35:
					if ( isMember(target->options.affiliation) )
						product->setCount(1);
					// hasActionAsksActor "this rule has an action": its builtinActoR, never a fire-time cache (SEQ 205 R1)
					break;
				case 36:
					if ( target->getProperty("builtinActoR") )
						product->setCount(1);
					break;
				case 40:
					if ( isCoded(target->groupBody->flags.actionType) )
						product->setCount(1);
					// case41hasNewParse the READ half; the write half is setGroupField case 41 -- they ship together or the flag is unassertable
					break;
				case 41:
					if ( target->groupBody->flags.hasNewParse )
						product->setCount(1);
					// isGrouPNoWriteHalf READ-ONLY by design: isGROUP is a data KIND, not a flag, so no write half is owed
					break;
				case 43:
					if ( isGROUP(target->groupBody->flags.data) )
						product->setCount(1);
					// debuggeDNoWriteHalf READ-ONLY by design: the debug rule is the flag's only writer, and a second would let a fixture fake its own reading
					break;
				case 44:
					if ( target->groupBody->flags.debugged )
						product->setCount(1);
					break;
				case 45:
					if ( target->groupBody->flags.isUnary )
						product->setCount(1);
					break;
				case 46:
					if ( target->groupBody->flags.fLAG )
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
					// cases403to404 the `groupList &&` prefix is LOAD-BEARING -- without it the guard dereferences the pointer it guards
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
					// case405firstMember affiliation-FILTERED first, unlike `.firsT`, which returns the attribute on an attribute-first node
					break;
				case 405:
					if ( !target->groupBody->groupList )
						product = 0;
					else	product = target->nextMember(0);
					break;
				case 406:
					product->setCount((int)target->groupBody->flags.actionType);
					// case407binType binType is an ENUM, so nonzero means ANY container kind -- deliberately wider than isBIN||isREGISTRY
					break;
				case 407:
					if ( target->groupBody->flags.binType )
						product->setCount(1);
					// case408isAction 406 cannot witness isCoded -> isAction; this tests isAction SPECIFICALLY, as parseRule does
					break;
				case 408:
					if ( isAction(target->groupBody->flags.actionType) )
						product->setCount(1);
					// unsupportedAccessor a gCount with no case of its own lands on default and SAYS SO, rather than answering with a silent null
					break;
				case 409:
					product->setCount((int)target->groupBody->flags.instructType);
					break;
				case 411:
					product->setCount(ruler->lastIndent);
					break;
				case 412:
					product->setCount(ruler->inCompile());
					break;
				case 413:
					if ( isMethod(target->groupBody->flags.instructType) )
						product->setCount(1);
					break;
				default:
					product->setText(::concat(3,"access to ",argument->groupBody->tag," not supported yet"));
				}
			// nullIsLawful seven accessors answer null for 'nothing there' -- guard the read, as the next line does (nullAccessorDeref, born fb9e4de)
			if ( product && !product->groupBody->flags.data )
				product->setCount(0);
			if ( product && !product->parent )
				product->parent = target;
			}
		}
	return product;
}

// opEQ the == operator: a data-less operand equals a numeric zero; otherwise compareValues decides
extern "C" GroupItem *opEQ(GroupItem *argument, GroupItem *target)
{
	if ( GroupControl::groupController->groupRules->jitting )
		{
		 return jitEmitCompare(argument, target, jitEQ); 
		}
	// f41 a refused operand arrives as null -- refuse it by name (see opPlus)
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

// opGE the >= operator, on opEQ's shape
extern "C" GroupItem *opGE(GroupItem *argument, GroupItem *target)
{
	if ( GroupControl::groupController->groupRules->jitting )
		{
		 return jitEmitCompare(argument, target, jitGE); 
		}
	// f41 a refused operand arrives as null -- refuse it by name (see opPlus)
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

// opGT the > operator, on opEQ's shape
extern "C" GroupItem *opGT(GroupItem *argument, GroupItem *target)
{
	if ( GroupControl::groupController->groupRules->jitting )
		{
		 return jitEmitCompare(argument, target, jitGT); 
		}
	// f41 a refused operand arrives as null -- refuse it by name (see opPlus)
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

// opGet the [] subscript: target's component by count or by name; a group argument names it by its gText
extern "C" GroupItem *opGet(GroupItem *argument, GroupItem *target)
{
GroupItem 	*result = 0;
char 		*txt = 0;
	// nullTarget a null target is a lawful empty answer, as in opDot
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

// opGetAttribute the =% operator: target's attribute named by the argument's text
extern "C" GroupItem *opGetAttribute(GroupItem *argument, GroupItem *target)
{
char 	*strung = argument->getText();
	return target->getAttribute(strung);
}

// opGetMember the =/ operator: target's member named by the argument's text
extern "C" GroupItem *opGetMember(GroupItem *argument, GroupItem *target)
{
char 	*strung = argument->getText();
	return target->getMember(strung);
}

// opGetProperty the =< operator: reads target's property list only, so a term of the same name cannot answer (SEQ 224)
extern "C" GroupItem *opGetProperty(GroupItem *argument, GroupItem *target)
{
char 	*strung = argument->getText();
	return target->getProperty(strung);
}

// opIN the IN operator: a list argument holds target's tag; a set argument holds any of target's characters; a set target holds all of the argument's; a buffer argument contains target's text -- to be rewritten once there are set operators
extern "C" GroupItem *opIN(GroupItem *argument, GroupItem *target)
{
PLGset 		*set = 0;
GroupItem 	*result = 0;
	if ( argument->groupBody->groupList )
		result = argument->firstComponent(target->groupBody->tag);
	else
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
		char 	*searchString = target->getText();
		// findInBuffer leaves the buffer's mark at the match; target goes back so the caller has the match length
		if ( argument->getBuffer()->findInBuffer(searchString) )
			result = target;
		}
	return result;
}

/*  opIsAssignTier, opIsCompareTier -- THE OTHER TWO TIERS, AS DATA (SEQ 316, D3). The
    `assignTier` and `compareTier` flags on the operator in incant/setup; shortCircuit above
    is the logic tier, and an operator with none of the three folds as arithmetic. They
    replaced two spelled lists in the PoC's runOPaccum; since SEQ 319 c3 the split reads them at BUILD.   HANDS, NOT WITNESSES  */
extern "C" int opIsAssignTier(GroupItem *op)
{
	if ( !op )
		return 0;
	if ( op->get("assignTier") )
		return 1;
	return 0;
}

extern "C" int opIsCompareTier(GroupItem *op)
{
	if ( !op )
		return 0;
	if ( op->get("compareTier") )
		return 1;
	return 0;
}

extern "C" int opIsOR(GroupItem *op)
{
	if ( !op )
		return 0;
	if ( op->get("isOR") )
		return 1;
	return 0;
}

/*  opIsShortCircuit -- TIER-3 MEMBERSHIP. opIsOR -- WHICH WAY IT SKIPS. Two questions,
    two attributes on the operator in incant/setup, and NO SPELLING IN EITHER ACTION.
    ⚠ THEY REPLACED TWO LISTS, NOT ONE: interpretXP chose the tier-3 binding by tag AND
    runShortCircuit chose the skip direction by tag. `||` could be seen by neither, on
    the very same operateMethod as `OR`, and fixing only the first made `true || false`
    read FALSE because the second then sent it past both skips.
    ⚠ HANDS, NOT WITNESSES -- no measure prefix.  */
extern "C" int opIsShortCircuit(GroupItem *op)
{
	if ( !op )
		return 0;
	if ( op->get("shortCircuit") )
		return 1;
	return 0;
}

// opLE the <= operator, on opEQ's shape
extern "C" GroupItem *opLE(GroupItem *argument, GroupItem *target)
{
	if ( GroupControl::groupController->groupRules->jitting )
		{
		 return jitEmitCompare(argument, target, jitLE); 
		}
	// f41 a refused operand arrives as null -- refuse it by name (see opPlus)
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

// opLT the < operator, on opEQ's shape
extern "C" GroupItem *opLT(GroupItem *argument, GroupItem *target)
{
	if ( GroupControl::groupController->groupRules->jitting )
		{
		 return jitEmitCompare(argument, target, jitLT); 
		}
	// f41 a refused operand arrives as null -- refuse it by name (see opPlus)
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

// opLastREF the @ operator: point lastREF at the result and hand it back
extern "C" GroupItem *opLastREF(GroupItem *result)
{
	GroupControl::groupController->groupRules->lastREF->groupBody->gGroup = result;
	GroupControl::groupController->groupRules->lastREF->groupBody->flags.data = 6;
	return result;
}

// opMatch the ~= match operator: true when target's text and the argument's compare equal
extern "C" GroupItem *opMatch(GroupItem *argument, GroupItem *target)
{
	if ( !::compare(target->getText(),argument->getText()) )
		return GroupControl::groupController->groupRules->trueResult;
	return 0;
}

// opMinus the - operator: numbers subtract (a double operand promotes the result); a string drops the argument's count of characters from its tail
extern "C" GroupItem *opMinus(GroupItem *argument, GroupItem *target)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	if ( ruler->jitting )
		{
		 return jitEmitBinary(argument, target, jitSub); 
		}
	// f41 a refused operand arrives as null -- refuse it by name (see opPlus)
	if ( !argument )
		{
		return ::refuse(target,"Operator - -- an operand that is nothing");
		}
	if ( (isCOUNT(target->groupBody->flags.data) || isNUMBER(target->groupBody->flags.data)) && (isCOUNT(argument->groupBody->flags.data) || isNUMBER(argument->groupBody->flags.data) || isSTRING(argument->groupBody->flags.data) || isTOKEN(argument->groupBody->flags.data)) )
		{
		// binaryPromotes a double operand promotes the result; count OP count stays a count (see opPlus)
		if ( isNUMBER(target->groupBody->flags.data) || isNUMBER(argument->groupBody->flags.data) )
			ruler->tempField->setNumber(target->getNumber() - argument->getNumber());
		else	ruler->tempField->setCount(target->groupBody->gCount - argument->getCount());
		}
	else
	if ( (isSTRING(target->groupBody->flags.data) || isTOKEN(target->groupBody->flags.data)) && argument->getCount() > 0 )
		if ( target->groupBody->gCount > argument->getCount() )
			ruler->tempField->setText(::headToCount(target->getText(),target->groupBody->gCount - argument->getCount()));
	if ( !ruler->tempField->groupBody->flags.data )
		{
		return ::refuse(target,"Operator - -- cannot apply to these operands");
		}
	return ruler->tempField;
}

// opMinusEQ the -= operator: remove a member by tag from a list, or subtract in place -- computed in doubles, narrowed at the result
extern "C" GroupItem *opMinusEQ(GroupItem *argument, GroupItem *target)
{
GroupItem 	*result = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	// storeRuling an armed statement stores nothing
	if ( ruler->refused )
		return 0;
	if ( ruler->jitting )
		{
		 return jitEmitAssign(jitEmitBinary(argument, target, jitSub), target); 
		}
	if ( target->groupBody->groupList )
		result = target->remove(argument->groupBody->tag);
	else
	if ( target->groupBody->flags.data && argument->groupBody->flags.data )
		{
		result = target;
		switch (target->groupBody->flags.data)
			{
				// narrowAtResult compute in doubles, narrow at the result -- through tempField.count, so getCount stays the ONE half-up implementer
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
		while ( result = argument->next(result) )
			::opMinusEQ(result,target);
	return result;
}

// opMinusMinus the -- operator: an iterator steps BACK one child; a value steps down by one; a field never assigned is absent and refuses
extern "C" GroupItem *opMinusMinus(GroupItem *result)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	// storeRuling an armed statement stores nothing
	if ( ruler->refused )
		return 0;
	// handedCursor a cursor whose iterate was handed over at build is not flagged until run time: its -- is the iterator step back (SEQ 403)
	if ( ruler->jitting )
		{
		 if ( ::jitHandedCursor(result) ) return jitEmitIterStepBack(result); 
		}
	if ( result->groupBody->flags.isIterator )
		{
		// an iterator is not unwrapped in runOP; -- cannot tell members from attributes, as GroupItem has no priorMember() or priorAttribute()
		// iterGate the jitting gate sits INSIDE the iterator arm and ABOVE its return, or the compiled walk has no loop (F-53)
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
	// zeroIsNotAbsent a field never assigned refuses by name; there is no pop arm -- removing a member is remove's job
	if ( !result->groupBody->flags.data )
		return ::refuse(result,"Operator -- -- this field has no value to step; a field assigned 0 is a count and steps to -1, one never assigned is absent");
	else
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
	else	return ::refuse(result,"Operator -- -- not supported for this data type");
	return result;
}

// opMultiply the * multiply operator: a double operand promotes the result
extern "C" GroupItem *opMultiply(GroupItem *argument, GroupItem *target)
{
	if ( GroupControl::groupController->groupRules->jitting )
		{
		 return jitEmitBinary(argument, target, jitMul); 
		}
	// binaryPromotes as for + (see opPlus)
	// f41 a refused operand arrives as null -- refuse it by name (see opPlus); F-36's second crash was here
	if ( !argument )
		{
		return ::refuse(target,"Operator * -- an operand that is nothing");
		}
	if ( isCOUNT(argument->groupBody->flags.data) || isNUMBER(argument->groupBody->flags.data) || isSTRING(argument->groupBody->flags.data) || isTOKEN(argument->groupBody->flags.data) )
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

// opMultiplyEQ the *= operator: multiply in place -- computed in doubles, narrowed at the result
extern "C" GroupItem *opMultiplyEQ(GroupItem *argument, GroupItem *target)
{
GroupItem 	*result = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	// storeRuling an armed statement stores nothing
	if ( ruler->refused )
		return 0;
	if ( ruler->jitting )
		{
		 return jitEmitAssign(jitEmitBinary(argument, target, jitMul), target); 
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
		while ( result = argument->next(result) )
			::opMultiplyEQ(result,target);
	return result;
}

// opNOT the ! operator: answers by truthOf, never by presence -- a node holding zero is false, so !0 is true
extern "C" GroupItem *opNOT(GroupItem *result)
{
	if ( !::truthOf(result) )
		return GroupControl::groupController->groupRules->trueResult;
	return 0;
}

// opNotEQ the != operator, on opEQ's shape
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

// opOR the OR operator's STRICT fallback, as for AND (see opAND)
extern "C" GroupItem *opOR(GroupItem *argument, GroupItem *target)
{
	if ( ::truthOf(target) || ::truthOf(argument) )
		return GroupControl::groupController->groupRules->trueResult;
	return GroupControl::groupController->groupRules->falseResult;
}

// opPlus the + operator: numbers add (a double operand promotes the result); a string advances by the argument's count
extern "C" GroupItem *opPlus(GroupItem *argument, GroupItem *target)
{
	if ( GroupControl::groupController->groupRules->jitting )
		{
		// concatJit a STRING or TOKEN left is a run-time concatenation, published as a node (SEQ 347 R3)
		if ( isSTRING(target->groupBody->flags.data) || isTOKEN(target->groupBody->flags.data) )
			{
			 return jitEmitConcat(argument, target); 
			}
		 return jitEmitBinary(argument, target, jitAdd); 
		}
	// f41 a refused operand arrives as null -- refuse it by name, beside the wrong-type case each operator already names
	if ( !argument )
		{
		return ::refuse(target,"Operator + -- an operand that is nothing");
		}
	// concatLeft a STRING or TOKEN on the left concatenates the right side's text (SEQ 347 R3)
	if ( target->groupBody->flags.data && (isSTRING(target->groupBody->flags.data) || isTOKEN(target->groupBody->flags.data)) && argument->groupBody->flags.data )
		GroupControl::groupController->groupRules->tempField->setText(::concatText(target->getText(),argument->getText()));
	else
	if ( target->groupBody->flags.data && (isCOUNT(argument->groupBody->flags.data) || isNUMBER(argument->groupBody->flags.data) || isSTRING(argument->groupBody->flags.data) || isTOKEN(argument->groupBody->flags.data)) )
		{
		// binaryPromotes a binary op has no count slot to narrow into, so a double operand promotes the result; count OP count stays a count
		if ( isNUMBER(target->groupBody->flags.data) || isNUMBER(argument->groupBody->flags.data) )
			GroupControl::groupController->groupRules->tempField->setNumber(target->getNumber() + argument->getNumber());
		else
		if ( isCOUNT(target->groupBody->flags.data) )
			GroupControl::groupController->groupRules->tempField->setCount(target->groupBody->gCount + argument->getCount());
		}
	if ( !GroupControl::groupController->groupRules->tempField->groupBody->flags.data )
		{
		return ::refuse(target,"Operator + -- cannot apply to these operands");
		}
	return GroupControl::groupController->groupRules->tempField;
}

// opPlusEQ the += operator, now only the named refusal: every kind is a member of '+=' picked by pickKindOP on both roads, and this answers a pick with no member
extern "C" GroupItem *opPlusEQ(GroupItem *argument, GroupItem *target)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	// storeRuling an armed statement stores nothing
	if ( ruler->refused )
		return 0;
	measurePlusEQWrite(target);
	// keptJitLine the one jitting line announces opPlusEQ reached at EMIT time, which happens only if '+=' has no members
	if ( ruler->jitting )
		::jitDegrade("+= on an unhandled datA",target);
	else	::fprintf(stderr,"ERROR Operator += failed on %s and %s\n",target->groupBody->tag,argument->groupBody->tag);
	return target;
}

// opPlusEQisBUFFER the '+=isBUFFER' member: an empty target takes the argument's data; else write the text into the buffer
extern "C" GroupItem *opPlusEQisBUFFER(GroupItem *argument, GroupItem *target)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	if ( ruler->refused )
		return 0;
	measurePlusEQWrite(target);
	measureKindArm("opPlusEQisBUFFER",target);
	if ( !target->groupBody->flags.data )
		{
		target->copyData(argument);
		return target;
		}
	if ( isLIST(argument->groupBody->flags.binType) || !argument->groupBody->flags.data )
		return plusEQshapeRefusal("isBUFFER",argument,target);
	// with a mark set the text goes in at the mark, else at the end; the mark is left as is
	target->getBuffer()->appendString(argument->getText(),0,0);
	return target;
}

// opPlusEQisCOUNT the '+=isCOUNT' member: an empty target takes the argument's data; else add, computed in doubles and narrowed at the result
extern "C" GroupItem *opPlusEQisCOUNT(GroupItem *argument, GroupItem *target)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	// refusedFirst the store ruling is asked BEFORE any gate reads argument -- a refused rhs arrives as null
	if ( ruler->refused )
		return 0;
	measurePlusEQWrite(target);
	measureKindArm("opPlusEQisCOUNT",target);
	if ( !target->groupBody->flags.data )
		{
		target->copyData(argument);
		return target;
		}
	if ( isLIST(argument->groupBody->flags.binType) || !argument->groupBody->flags.data )
		return plusEQshapeRefusal("isCOUNT",argument,target);
	ruler->tempField->setNumber(target->getNumber() + argument->getNumber());
	target->groupBody->gCount = ruler->tempField->getCount();
	return target;
}

// opPlusEQisNUMBER the '+=isNUMBER' member: an empty target takes the argument's data; else add
extern "C" GroupItem *opPlusEQisNUMBER(GroupItem *argument, GroupItem *target)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	if ( ruler->refused )
		return 0;
	measurePlusEQWrite(target);
	measureKindArm("opPlusEQisNUMBER",target);
	if ( !target->groupBody->flags.data )
		{
		target->copyData(argument);
		return target;
		}
	if ( isLIST(argument->groupBody->flags.binType) || !argument->groupBody->flags.data )
		return plusEQshapeRefusal("isNUMBER",argument,target);
	target->groupBody->gNumber += argument->getNumber();
	return target;
}

// opPlusEQisSTAK the '+=isSTAK' member: an empty target takes the argument's data; else push the argument
extern "C" GroupItem *opPlusEQisSTAK(GroupItem *argument, GroupItem *target)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	if ( ruler->refused )
		return 0;
	measurePlusEQWrite(target);
	measureKindArm("opPlusEQisSTAK",target);
	if ( !target->groupBody->flags.data )
		{
		target->copyData(argument);
		return target;
		}
	if ( isLIST(argument->groupBody->flags.binType) || !argument->groupBody->flags.data )
		return plusEQshapeRefusal("isSTAK",argument,target);
	target->groupBody->gStak->push(argument);
	return target;
}

// opPlusEQisSTRING the '+=isSTRING' and '+=isTOKEN' member, one method under two registrations: a list argument concatenates, into an EMPTY target too (pick step 4a); else append the text
extern "C" GroupItem *opPlusEQisSTRING(GroupItem *argument, GroupItem *target)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	if ( ruler->refused )
		return 0;
	measurePlusEQWrite(target);
	measureKindArm("opPlusEQisSTRING",target);
	if ( isLIST(argument->groupBody->flags.binType) )
		{
		Buffer 	*concatBuf = (Buffer*)ruler->bufferSTAK->pop();
		if ( !concatBuf )
			concatBuf = new Buffer("concat buffer");
		if ( target->groupBody->flags.data )
			::appendGroup(target,0,concatBuf);
		::appendGroup(argument,0,concatBuf);
		return ::opString(target,concatBuf);
		}
	if ( !target->groupBody->flags.data )
		{
		target->copyData(argument);
		return target;
		}
	if ( !argument->groupBody->flags.data )
		return plusEQshapeRefusal("isSTRING",argument,target);
	target->setText(::concat(2,target->getText(),argument->getText()));
	return target;
}

// opPlusEQstruct the '+=struct' member: a bin or registry, a field with members (a grammar graft included), or an empty field given a dataless node -- a list argument is copied in (copyListTo), anything else appended
extern "C" GroupItem *opPlusEQstruct(GroupItem *argument, GroupItem *target)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	if ( ruler->refused )
		return 0;
	measurePlusEQWrite(target);
	measureKindArm("opPlusEQstruct",target);
	if ( isLIST(argument->groupBody->flags.binType) )
		{
		argument->copyListTo(target);
		return target;
		}
	target->addMember(argument);
	return target;
}

// opPlusPlus the ++ operator: an iterator steps to the next child; a value steps up by one; a field never assigned is absent and refuses
extern "C" GroupItem *opPlusPlus(GroupItem *result)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	// storeRuling an armed statement stores nothing
	if ( ruler->refused )
		return 0;
	measurePlusPlusWrite(result);
	// handedCursor a cursor whose iterate was handed over at build is not flagged until run time: its ++ is the iterator step (SEQ 402)
	if ( ruler->jitting )
		{
		 if ( ::jitHandedCursor(result) ) return jitEmitIterStep(result); 
		}
	if ( result->groupBody->flags.isIterator )
		{
		// iterGate the jitting gate sits INSIDE the iterator arm, or the compiled walk visits nothing (Tony, 2026-08-04)
		if ( ruler->jitting )
			{
			 return jitEmitIterStep(result); 
			}
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
	measurePlusPlusWrite(result);
	// zeroIsNotAbsent a field assigned 0 is a count and bumps to 1; one never assigned is absent and refuses by name
	if ( !result->groupBody->flags.data )
		return ::refuse(result,"Operator ++ -- this field has no value to bump; a field assigned 0 is a count and bumps to 1, one never assigned is absent");
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

// opPointer the =* unary: mark the operand a pointer -- fired as a noPrint definition attribute (setPointer), fLAG redirects it to the field being defined, a la processFlags
extern "C" GroupItem *opPointer(GroupItem *field)
{
	if ( field->groupBody->flags.fLAG )
		field = field->parent;
	field->groupBody->flags.isPointer = 1;
	return field;
}

// opPrint the print rule's operator method: the text goes to the buffer printTO diverted to, else to stdout
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

// opRebind the <- operator: point the target local's group at the evaluated right side -- no content copy, no byRef stamp; a fresh handle each loop pass: cell <- argument :+ new(nm);
extern "C" GroupItem *opRebind(GroupItem *argument, GroupItem *target)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	// storeRuling an armed statement stores nothing
	if ( ruler->refused )
		return 0;
	if ( argument )
		target->setGroup(argument);
	return target;
}

// opRem the % operator: integer remainder
extern "C" GroupItem *opRem(GroupItem *argument, GroupItem *target)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	// jitEmitRem emits a CALL to this very function and unboxes its result, the shape every non-scalar op uses
	if ( ruler->jitting )
		{
		 return jitEmitRem(argument, target, ruler->tempField); 
		}
	if ( (isCOUNT(target->groupBody->flags.data) || isNUMBER(target->groupBody->flags.data)) && (isCOUNT(argument->groupBody->flags.data) || isNUMBER(argument->groupBody->flags.data) || isSTRING(argument->groupBody->flags.data) || isTOKEN(argument->groupBody->flags.data)) )
		ruler->tempField->setCount(target->getCount() % argument->getCount());
	// a refusal, never a data-less tempField that reads back as its own tag (promoted from sentinel-as-data, 2026-09-05)
	if ( !ruler->tempField->groupBody->flags.data )
		return ::refuse(target,"Operator % -- cannot apply to these operands");
	return ruler->tempField;
}

// opReplaceAttribute the :% operator: replace target's component of the same tag with the argument, or each list item, as an attribute
extern "C" GroupItem *opReplaceAttribute(GroupItem *argument, GroupItem *target)
{
GroupItem 	*grup = 0;
GroupItem 	*added = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	// storeRuling an armed statement stores nothing
	if ( ruler->refused )
		return 0;
	if ( isLIST(argument->groupBody->flags.binType) )
		while ( grup = argument->next(grup) )
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

// opReplaceMember the :+ operator: replace target's component of the same tag with the argument, or each list item, as a member
extern "C" GroupItem *opReplaceMember(GroupItem *argument, GroupItem *target)
{
GroupItem 	*grup = 0;
GroupItem 	*added = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	// storeRuling an armed statement stores nothing
	if ( ruler->refused )
		return 0;
	if ( isLIST(argument->groupBody->flags.binType) )
		while ( grup = argument->next(grup) )
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

// opSetFlag the :. operator, the inverse of opDot: SET the groupField flag the argument names on target -- it never toggles; explicit operands sidestep processFlags' command detection
extern "C" GroupItem *opSetFlag(GroupItem *argument, GroupItem *target)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*flagDef = 0;
	// storeRuling an armed statement stores nothing
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
	// notAFlag a name with no groupFields entry has no flag to set -- refused by name, never a no-op (kant's generic flaG, case 12, retired 2026-10-02)
	if ( !flagDef )
		{
		char 	*why = ::concat(3,"`:. ",argument->groupBody->tag,"` -- not a groupField, so there is no flag to set; for a use-then-toss mark, +% a noPrint marker defined in pROPERTIEs (docs/flagCensus.md)");
		return ::refuse(target,why);
		}
	// setsNeverToggles a toggle makes "make sure it is on" unwritable (Tony, 2026-08-17)
	// enumLiteral an enum KIND (binType, actionType) is written as a literal value, never through its test macro, which can only write 0 or 1
	// oneSetter `:.` is setGroupField with the value 1 -- the cases live there, beside `=`'s (SEQ 295 R3)
	if ( argument && target )
		{
		if ( !setGroupField(target,flagDef->groupBody->gCount,1) )
			::fprintf(stderr,"opSetFlag WARNING: groupField %s has no case yet -- guessing from gCount %s ; the value stands\n",argument->groupBody->tag,::toStringFromInt(flagDef->groupBody->gCount));
		}
	else	::fprintf(stderr,"opSetFlag: missing operand\n");
	return target;
}

// opSetGroup the := operator: hold the argument as target's group, parent and affiliation unchanged -- through setGroup, never by hand, so x := null CLEARS x
extern "C" GroupItem *opSetGroup(GroupItem *argument, GroupItem *target)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	// storeRuling an armed statement stores nothing
	if ( ruler->refused )
		return 0;
	if ( target )
		target->setGroup(argument);
	return target;
}

// opSetTag the <: operator: target takes the argument's text as its tag
extern "C" GroupItem *opSetTag(GroupItem *argument, GroupItem *target)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	// storeRuling an armed statement stores nothing
	if ( ruler->refused )
		return 0;
	if ( argument )
		target->groupBody->tag = argument->getText();
	return target;
}

// opString the string rule's operator method: the print text becomes target's text
extern "C" GroupItem *opString(GroupItem *target, Buffer *buffer)
{
	target->setText(buffer->toString());
	buffer->reset();
	GroupControl::groupController->groupRules->bufferSTAK->push(buffer);
	GroupControl::groupController->groupRules->useDefaultSpace = 1;
	return target;
}

// opUnaryMinus the prefix unary - (negate): 0 - operand into tempField, the operand untouched -- its own op, distinct from the binary - slot
extern "C" GroupItem *opUnaryMinus(GroupItem *result)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	if ( ruler->jitting )
		{
		 return jitEmitUnary(result, jitNeg); 
		}
	if ( isCOUNT(result->groupBody->flags.data) )
		ruler->tempField->setCount(0 - result->groupBody->gCount);
	else
	if ( isNUMBER(result->groupBody->flags.data) )
		ruler->tempField->setNumber((double)0 - result->groupBody->gNumber);
	if ( !ruler->tempField->groupBody->flags.data )
		{
		return ::refuse(result,"Operator unary - -- cannot apply");
		}
	return ruler->tempField;
}

// parkInRecord a label handed up to a parent whose RECORD is live goes there; with no such record it is dropped -- nothing reads it (1.2f, SEQ 306 R1)
extern "C" int parkInRecord(RuleStuff *s, GroupItem *lab)
{
GroupRules 			*ruler = GroupControl::groupController->groupRules;
ParseActivation 	*rec = ruler->gParseActive;
	while ( rec && ruler->stuffOf(rec) != s )
		rec = rec->prev;
	if ( !rec )
		return 0;
	rec->label = lab;
	return 1;
}

// parseAction run the rule's action as its parse -- handed the field for a parseACTION rule or when there is no label, else the label
extern "C" GroupItem *parseAction(GroupItem *field)
{
GroupItem 	*leafLab = 0;
char 		*leafAt = 0;
int 		leafOK = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	// leafStart the term starts where the input stands -- parseAction calls no checkInput, and the stuff's stale hereAt is no longer read (SEQ 301; UNPINNED, no road reaches it)
	leafAt = ruler->atRuleMark;
	// ownSlot read the actor's method, never gMethod -- on a parseACTION node gMethod IS parseAction and the call recurses forever
	// noNullActor the old spelling read gMethod, which setParseWalk always fills; a rule may have no actor, and calling a null would trade the self-recursion for a null call
GroupItem 	*leafActor = field->getProperty("builtinActoR");
	if ( !leafActor || !leafActor->groupBody->gMethod )
		return ::refuse(field,"parseAction: no action is installed for this rule");
	// noLabelOnStuff a leaf finds no label on its stuff, so the action is handed the field -- the `!label` arm, which is the only one the new road ever reached (SEQ 301)
	if ( leafLab = leafActor->groupBody->gMethod(field) )
		leafOK = 1;
	if ( leafLab )
		leafLab->clear();
	return ::exitFromParse(field,leafOK,leafAt,leafLab);
}

// parseCharacter match a run of one character against the current input
extern "C" GroupItem *parseCharacter(GroupItem *field)
{
GroupItem 	*leafLab = 0;
char 		*leafAt = 0;
int 		leafOK = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = field->getRStuff();
int 		counter = 0;
int 		more = 0;
	// leafLocals the verdict, start and label live in locals and go to the exit as arguments -- nothing on rStuff (SEQ 301, 1.2c)
	leafAt = ruleStuff->inputAt();
	if ( leafAt && *leafAt && ruleStuff->checkGuard(field) )
		{
		leafLab = ruleStuff->mintLabel(field);
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
			::reportMaxLimit(field);
		else
		if ( counter && counter >= ruleStuff->min )
			{
			if ( leafLab )
				leafLab->setToken(leafAt,counter);
			leafOK = 1;
			}
		}
	// keepTheMatch clear only on failure, as parseContainer -- a success clearing here handed every action an empty term label (F-114 site 2)
	if ( leafLab && !leafOK )
		leafLab->clear();
	return ::exitFromParse(field,leafOK,leafAt,leafLab);
}

// parseCondition a condition succeeds exactly when min is set
extern "C" GroupItem *parseCondition(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = field->getRStuff();
	// leafStart the term starts where the input stands, so a failure rewinds nowhere -- the stuff's stale hereAt is no longer read (SEQ 301; UNPINNED, no road reaches it)
	if ( ruleStuff->min )
		return ::exitFromParse(field,1,ruler->atRuleMark,0);
	return ::exitFromParse(field,0,ruler->atRuleMark,0);
}

// parseContainer match the longest input prefix that names an entry of this bin or registry
extern "C" GroupItem *parseContainer(GroupItem *field)
{
GroupItem 	*leafLab = 0;
char 		*leafAt = 0;
int 		leafOK = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
PLGset 		*inSet = field->getCharacterSet();
char 		*atInput = ruler->atRuleMark;
int 		advance = 0;
Buffer 		*buffer = ruler->stringBUFFER;
RuleStuff 	*ruleStuff = field->getRStuff();
GroupItem 	*grup = 0;
char 		*entryMark = ruler->atRuleMark;
int 		matched = 0;
	// faceReresolve a bin or registry reached BY NAME is re-resolved to the calling rule's own face, as parseRule does, through the enclosing parse activation -- the face carries the term's rStuff (its modifiers and label slot)
	 { GroupItem *zEnc = ::enclosingInstance(field); if ( zEnc ) field = zEnc; } 
	ruleStuff = field->getRStuff();
	// noStuffLawfulSkip a registry has no rStuff: match with default limits and exit WITHOUT exitFromParse -- never refuse, never mint onto it
	if ( !ruleStuff )
		{
		buffer->reset();
		entryMark = ruler->atRuleMark;
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
				// longestHitOnly the first hit is the longest -- stop, or shorten(1) finds its prefix (= after ==) and advances again (F-124)
				ruler->atRuleMark += advance;
				matched = 1;
				break;
				}
			buffer->shorten(1);
			}
		if ( matched )
			return ruler->trueResult;
		ruler->atRuleMark = entryMark;
		return 0;
		}
	// leafLocals the verdict, start and label live in locals and go to the exit as arguments -- nothing on rStuff (SEQ 301, 1.2c)
	leafAt = ruleStuff->inputAt();
	if ( leafAt && *leafAt && ruleStuff->checkGuard(field) )
		{
		leafLab = ruleStuff->mintLabel(field);
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
				// longestHitOnly the first hit is the longest -- stop, or shorten(1) finds its prefix (= after ==), advances again and relabels (F-124)
				if ( !ruleStuff->noAdvance )
					ruler->atRuleMark += advance;
				if ( leafLab )
					leafLab->setGroup(grup);
				leafOK = 1;
				break;
				}
			buffer->shorten(1);
			}
		}
	// keepTheMatch clear only on failure -- on success the label carries the matched entry to attachLabel, and clearing it first handed TokenXP an empty unary
	if ( leafLab && !leafOK )
		leafLab->clear();
	return ::exitFromParse(field,leafOK,leafAt,leafLab);
}

// parseLoop run a repeating term up to max; the verdict is the COUNT against min, never the success flag
extern "C" GroupItem *parseLoop(GroupItem *field)
{
	// enclosingRule re-resolve to the enclosing rule body's own face, through the ENCLOSING PARSE ACTIVATION -- a drive floors it, so a drive root keeps the rule it was handed (SEQ 212)
	 { GroupItem *zEnc = ::enclosingInstance(field); if ( zEnc ) field = zEnc; } 
RuleStuff *ruleStuff = field->getRStuff();
int timesMatched = 0;
	while ( timesMatched < ruleStuff->max )
		if ( !::runLeafParse(field) )
			break;
		else	timesMatched++;
	// countNotFlag the verdict is the COUNT, never the flag -- the last attempt is the failing one that ends the run, and a stale flag would pass a short run; the flag read is removed (Tony, 2026-09-24; SEQ 195)
	::measureLoopVerdict(field,timesMatched);
	if ( timesMatched >= ruleStuff->min )
		return GroupControl::groupController->groupRules->trueResult;
	return 0;
}

// parseOnFloor the file's top-level parse runs on a FLOOR, as a drive does -- every failure then has a floor below it (SEQ 186 R1, shape (i))
extern "C" GroupItem *parseOnFloor(GroupItem *rule)
{
ParseActivation 	topFloor;
GroupItem 			*result = 0;
GroupRules 			*ruler = GroupControl::groupController->groupRules;
	topFloor.instance = 0;
	topFloor.isFloor = 1;
	topFloor.compileOwner = 0;
	topFloor.label = 0;
	topFloor.prev = ruler->gParseActive;
	topFloor.failPoint = 0;
	ruler->gParseActive = &topFloor;
	// activeNotSubject the record takes GroupRules' scope, so re-mention ruler (bear-trap #58)
	result = rule->parse(0,0,0);
	ruler->gParseActive = topFloor.prev;
	return result;
}

// parseRule run a rule's generated body; a new declaration here re-points every bare field below it (bear-trap #42)
extern "C" GroupItem *parseRule(GroupItem *field)
{
GroupRules 			*ruler = GroupControl::groupController->groupRules;
GroupItem 			*code = field->parseBody();
GroupItem 			*result = 0;
GroupItem 			*grup = 0;
GroupItem 			*myLabel = 0;
GroupItem 			*into = 0;
GroupItem 			*priorMETHOD = 0;
int 				callOK = 0;
char 				*callHere = 0;
ParseActivation 	callActive;
	// enclosingRule re-resolve to the enclosing rule body's own face, through the ENCLOSING PARSE ACTIVATION -- a drive floors it, so a drive root keeps the rule it was handed (SEQ 212)
	 { GroupItem *zEnc = ::enclosingInstance(field); if ( zEnc ) field = zEnc; } 
RuleStuff 			*ruleStuff = field->getRStuff();
	// activePush this call's record goes on the activation list; one pop, after exitFromParse
	callActive.instance = field;
	callActive.isFloor = 0;
	callActive.compileOwner = 0;
	callActive.label = 0;
	callActive.prev = ruler->gParseActive;
	callActive.failPoint = 0;
	ruler->gParseActive = &callActive;
	// activeNotSubject the record inherits GroupRules' scope, so re-mention ruler then ruleStuff or currentMETHOD binds to callActive (bear-trap #57)
	::measureParentProbe(field);
	// intoSnapshot the enclosing activation's label as it stood at entry -- a snapshot, never the live slot, which a child can rewrite before the read (recon 25c)
	// parentRecord the enclosing record is the one below this call's own (1.2f, SEQ 306)
	if ( callActive.prev && !callActive.prev->isFloor )
		into = callActive.prev->label;
	// bareFieldRepoint the use lines below are load bearing -- a new declaration re-points every bare field under it
	// ownVerdict this call's verdict is the local callOK, handed to the exit -- sukcess left RuleStuff (1.2d, SEQ 302)
	// callHereLocal this call's start mark is the local callHere, handed to checkInput and the exit -- hereAt left RuleStuff (1.2e, SEQ 303)
	callHere = ruleStuff->inputAt();
	if ( ruleStuff->checkInput(field,0,callHere) )
		{
		// ownRecord this call's label is minted into its own record (1.2f, SEQ 306)
		callActive.label = ruleStuff->mintLabel(field);
		if ( isAction(field->groupBody->flags.actionType) )
			{
			while ( grup = code->nextAttribute(grup) )
				if ( grup->groupBody->flags.isLocal && !grup->isRuleTerm() && !grup->groupBody->flags.noPrint && grup->groupBody != field->groupBody )
					grup->clear();
			// noArgumentOnARule a rule carries no argument slot (Tony, 2026-09-20; F-94) -- the return carries one bit
			// labelReachesNothing myLabel is minted and goes nowhere until CT-5 gives it a channel
			myLabel = new GroupItem(field->groupBody->tag);
			myLabel->labelOf = field;
			::measureLabelMint(field,myLabel,into);
			::saveLocalFields(field);
			priorMETHOD = ruler->currentMETHOD->getGroup();
			ruler->currentMETHOD->setGroup(field);
			// here the parse action in method gets run
			if ( result = field->parseBlocK() )
				{
				// probeDoor armed only inside jitProbeDrive: fire the COMPILED body in place of this BlocK, nothing else changes
				// branchFrame a fire is a frame for the control slot: saved, cleared, restored, so a body's branch cannot leak to the caller (P4)
				
				int fireBranchSave = ruler->branchKind;
				ruler->branchKind = 0;
				if ( gJitProbeCarrier && field->get((char*)"builtinParseR") == gJitProbeCarrier ) {
				++gProbeRuleFires;
				if ( gJitProbeFn )  result = gJitProbeFn(::jitBodyField(gJitProbeCarrier)) ? ruler->trueResult : ruler->falseResult;
				else                result = result->groupBody->gMethod(result);
				if ( ::truthOf(result) )    ++gProbeRuleTrue; }
				else
				result = result->groupBody->gMethod(result);
				ruler->branchKind = fireBranchSave;
				
				}
			ruler->currentMETHOD->setGroup(priorMETHOD);
			::restoreLocalFields(field);
			}
		else	::reportNoBody(field);
checkSuccess:
		// this is just a marker for directives
		// resultSeat the rule, the returned node and its truthOf -- a standing callout (measure-callout ruling)
		::measureParseResult(field,result);
		// chainTruth the rule succeeds when its chain is TRUE, not when it returned something (F-95, Tony 2026-09-22)
		callOK = ::truthOf(result);
		}
	// markSeat1 SEQ 166 point 1 -- the last seat with visibility before the trace goes silent
	::measureMarkPoint("1-parseRule-exit");
	// stuffHandedIn parseRule hands the exit its own verdict, start mark and record label -- nothing of this call is on its stuff (1.2d-f)
	result = ::exitFromParse(field,callOK,callHere,callActive.label);
	// activeList pop this call's activation -- AFTER exitFromParse, so its own fire saw itself on top and skipped it
	ruler->gParseActive = callActive.prev;
	// callBracketRetired its last slot, label, moved onto the record in 1.2f -- a call's state is its own record's or its own locals' (SEQ 306)
	return result;
}

// parseSet match a run of characters from this rule's character set
extern "C" GroupItem *parseSet(GroupItem *field)
{
GroupItem 	*leafLab = 0;
char 		*leafAt = 0;
int 		leafOK = 0;
PLGset 		*set = field->getCharacterSet();
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = field->getRStuff();
int 		counter = 0;
int 		more = 0;
	// leafLocals the verdict, start and label live in locals and go to the exit as arguments -- nothing on rStuff (SEQ 301, 1.2c)
	leafAt = ruleStuff->inputAt();
	if ( leafAt && *leafAt && ruleStuff->checkGuard(field) )
		{
		leafLab = ruleStuff->mintLabel(field);
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
			::reportMaxLimit(field);
		else
		if ( counter && counter >= ruleStuff->min )
			{
			if ( leafLab )
				leafLab->setToken(leafAt,counter);
			leafOK = 1;
			}
		}
	// keepTheMatch clear only on failure, as parseContainer -- a success clearing here handed every action an empty term label (F-114 site 2)
	if ( leafLab && !leafOK )
		leafLab->clear();
	return ::exitFromParse(field,leafOK,leafAt,leafLab);
}

// parseString match this rule's string or token text at the current input
extern "C" GroupItem *parseString(GroupItem *field)
{
GroupItem 	*leafLab = 0;
char 		*leafAt = 0;
int 		leafOK = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = field->getRStuff();
	// leafLocals the verdict, start and label live in locals and go to the exit as arguments -- nothing on rStuff (SEQ 301, 1.2c)
	leafAt = ruleStuff->inputAt();
	if ( leafAt && *leafAt && ruleStuff->checkGuard(field) )
		{
		leafLab = ruleStuff->mintLabel(field);
		// nodeInHand match through the field itself, never RuleStuff.owner -- equal on every call measured (stroke 5.2)
		char *matchedString = field->matches(ruler->atRuleMark);
		if ( matchedString )
			{
			if ( leafLab )
				leafLab->setText(matchedString);
			leafOK = 1;
			}
		}
	// keepTheMatch clear only on failure, as parseContainer -- a success clearing here handed every action an empty term label (F-114 site 2)
	if ( leafLab && !leafOK )
		leafLab->clear();
	return ::exitFromParse(field,leafOK,leafAt,leafLab);
}

// parseUpTo match everything up to (or over) the rule's terminator, through testUpTo
extern "C" GroupItem *parseUpTo(GroupItem *field)
{
GroupItem 	*leafLab = 0;
char 		*leafAt = 0;
int 		leafOK = 0;
RuleStuff 	*ruleStuff = field->getRStuff();
	// leafLocals as the other leaves -- upToMatch fills the leaf's own label, never the stuff's (SEQ 301, 1.2c)
	leafAt = ruleStuff->inputAt();
	if ( leafAt && *leafAt && ruleStuff->checkGuard(field) )
		{
		leafLab = ruleStuff->mintLabel(field);
		if ( ::upToMatch(field,leafLab) )
			leafOK = 1;
		}
	// keepTheMatch clear only on failure, as parseContainer -- a success clearing here handed every action an empty term label (F-114 site 2)
	if ( leafLab && !leafOK )
		leafLab->clear();
	return ::exitFromParse(field,leafOK,leafAt,leafLab);
}

// pickKindOP THE WHOLE += PICK, ONE PLACE, BOTH ROADS -- members keyed on the TARGET; no member for the pick hands back the op, and opPlusEQ refuses by name
// structuralIsMembers structural is hasMembers, NEVER groupList -- attributes live on the list
// tagsBuiltHere the structural and 4a tags are built here, not through getDataType: an empty field and a structural one both read "none"
extern "C" GroupItem *pickKindOP(GroupItem *op, GroupItem *target, GroupItem *arg)
{
	if ( !op || !target )
		return op;
	if ( !op->groupBody->flags.hasMembers )
		return op;
	
	auto member = [&](const char *suffix) -> GroupItem* {
	char name[128];
	::snprintf(name,sizeof name,"%s%s",op->groupBody->tag,suffix);
	GroupItem *m = op->getMember(name);
	return m ? m : op; };
	GroupBody *tb = target->groupBody;
	if ( tb->flags.binType )                                    return member("struct");
	if ( tb->flags.data )                                       return target->checkOP(op);
	if ( tb->flags.hasMembers )                                 return member("struct");
	if ( !arg )                                                 return op;
	if ( isLIST(arg->groupBody->flags.binType) )                return member("isSTRING");
	if ( arg->groupBody->flags.data )                           return arg->checkOP(op);
	return member("struct");
	
}

// plusEQshapeRefusal a += member's refusal of a list or dataless argument, through refuse(), which prints REFUSED and never ERROR -- pop.sh's ERROR ratchet
extern "C" GroupItem *plusEQshapeRefusal(char *kind, GroupItem *argument, GroupItem *target)
{
	
	char why[160];
	::snprintf(why,sizeof why,"+= of a list or dataless argument onto %s -- no member takes that shape",kind ? kind : "?");
	return ::refuse(target,why);
	
}

// printField print the field passed in to the buffer passed in, in its data type's default format
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
	The incant printTO command runs this to set toBUFFER to the buffer in
    bufferField. toBUFFER gets reset. If there is no bufferField toBUFFER
    is set to null. If toBUFFER is not null, opPrint(), invoked by the
    print command via the PrinT rule, writes in toBUFFER instead of stdout
*******************************************************************************/
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

/*******************************************************************************
    jitRefire -- FIRE THE LAST COMPILED FUNCTION AGAIN, without recompiling.
    Returns trueResult on a fire, null if nothing has been compiled yet -- LOUD,
    because a silent no-op would make a rung green for the wrong reason.

    // rightAnswerWrongUniverse  why a compile-fire-check POP proves nothing on its own, and what a second fire settles
*******************************************************************************/
// probeDrive -- THE NATIVE JITTED DRIVE (Tony, 2026-09-24): jitProbeDrive from incant, so the lldb probe is for debugging only. The argument's attributes name root, armed (default root), msg and jitted; rules are found BY NAME STRING in Grokking, never handed in as rule-shaped values (bear-trap #34: a truth test fires them). Prints one PROBEDRIVE line; returns trueResult (bear-trap #33)
extern "C" GroupItem *probeDrive(GroupItem *input)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	
	GroupItem *spec = input;
	if ( spec && isGROUP(spec->groupBody->flags.data) ) spec = spec->groupBody->gGroup;
	GroupItem *g = GroupControl::groupController->getRegistry((char*)"Grokking");
	GroupItem *rootN = spec ? spec->get((char*)"root")   : 0;
	GroupItem *armN  = spec ? spec->get((char*)"armed")  : 0;
	GroupItem *msgN  = spec ? spec->get((char*)"msg")    : 0;
	GroupItem *jitN  = spec ? spec->get((char*)"jitted") : 0;
	char *rootS = rootN ? rootN->getText() : 0;
	char *armS  = armN  ? armN->getText()  : rootS;
	char *msgS  = msgN  ? msgN->getText()  : 0;
	int jitted  = (jitN && isCOUNT(jitN->groupBody->flags.data)) ? (int)jitN->groupBody->gCount : 0;
	GroupItem *root  = (g && rootS) ? g->get(rootS) : 0;
	GroupItem *armed = (g && armS)  ? g->get(armS)  : 0;
	if ( !root || !armed || !msgS ) {
	::fprintf(stderr,"PROBEDRIVE REFUSED: root=%s armed=%s msg=%s -- a name did not resolve in Grokking, or no msg\n",
	rootS ? rootS : "(none)", armS ? armS : "(none)", msgS ? "given" : "(none)");
	return ruler->trueResult; }
	int r = ::jitProbeDrive(root, armed, msgS, jitted);
	::fprintf(stderr,"PROBEDRIVE root=%s armed=%s %s ret=%d verdict=%d consumed=%d length=%d terms=%d fires=%d true=%d\n",
	rootS, armS, jitted ? "JITTED" : "INTERP", r, gProbeVerdict, gProbeConsumed, gProbeLength, gProbeTerms, gProbeFires, gProbeTrue);
	
	return ruler->trueResult;
}

// probeSweep -- THE STATION-2 SWEEP, NATIVE, IN ONE PROCESS (Tony, 2026-09-24). Every carrier reachable from DO (walked as jitLadder/station2/probe.py walks them), except those whose tag is in `skip` (default: stuff -- its naming key is pending). Per carrier: calibrate INTERPRETED over the `pairs` file, pick up to two accepts and two rejects by pick.py's rule, then certify JITTED against INTERPRETED, two fires each, one compile. Prints SWEEP lines on stderr; returns trueResult
extern "C" GroupItem *probeSweep(GroupItem *input)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	
	GroupItem *spec = input;
	if ( spec && isGROUP(spec->groupBody->flags.data) ) spec = spec->groupBody->gGroup;
	GroupItem *pN = spec ? spec->get((char*)"pairs") : 0, *sN = spec ? spec->get((char*)"skip") : 0;
	const char *pairsPath = pN ? pN->getText() : "jitLadder/station2/pairs";
	const char *skip = sN ? sN->getText() : "stuff";
	GroupItem *g = GroupControl::groupController->getRegistry((char*)"Grokking");
	GroupItem *root0 = g ? g->get((char*)"DO") : 0;
	if ( !root0 ) { ::fprintf(stderr,"SWEEP REFUSED: no DO in Grokking\n"); return ruler->trueResult; }
	// the pairs
	static char *pRoot[512]; static char *pMsg[512]; int np = 0;
	FILE *pf = ::fopen(pairsPath,"r");
	if ( !pf ) { ::fprintf(stderr,"SWEEP REFUSED: cannot open %s\n",pairsPath); return ruler->trueResult; }
	char line[4096];
	while ( np < 512 && ::fgets(line,sizeof line,pf) ) {
	size_t L = ::strlen(line); while ( L && (line[L-1]=='\n' || line[L-1]=='\r') ) line[--L] = 0;
	char *bar = ::strchr(line,'|'); if ( !bar ) continue;
	*bar = 0; pRoot[np] = ::strdup(line);
	char *m = ::strdup(bar+1), *w = m;
	for ( char *r = m; *r; r++ ) { if ( r[0]=='\\' && r[1]=='n' ) { *w++ = '\n'; r++; } else *w++ = *r; }
	*w = 0; pMsg[np++] = m; }
	::fclose(pf);
	// the carriers, walked as probe.py walks them
	static GroupItem *cNode[256]; int nc = 0;
	static GroupItem *seen[4096]; int ns = 0;
	static GroupItem *cSeen[256]; int ncs = 0;
	static GroupItem *stk[4096]; int sp = 0;
	stk[sp++] = root0;
	while ( sp ) {
	GroupItem *n = stk[--sp];
	int dup = 0; for ( int i = 0; i < ns; i++ ) if ( seen[i] == n ) { dup = 1; break; }
	if ( dup || ns >= 4096 ) continue;
	seen[ns++] = n;
	GroupItem *c = n->get((char*)"builtinParseR");
	if ( c ) { int cd = 0; for ( int i = 0; i < ncs; i++ ) if ( cSeen[i] == c ) { cd = 1; break; }
	if ( !cd && nc < 256 ) { cSeen[ncs++] = c; cNode[nc++] = n; } }
	GroupItem *kids[256]; int nk = 0; GroupItem *k = 0;
	while ( (k = n->next(k)) && nk < 256 ) {
	if ( !k->isRuleTerm() ) continue;
	kids[nk++] = k; }
	for ( int i = nk - 1; i >= 0 && sp < 4096; i-- ) stk[sp++] = kids[i]; }
	::fprintf(stderr,"SWEEP BEGIN carriers=%d pairs=%d skip=%s\n",nc,np,skip);
	int certified = 0, agreeAll = 0, diffAll = 0, nopick = 0, skipped = 0;
	for ( int ci = 0; ci < nc; ci++ ) {
	GroupItem *armed = cNode[ci];
	const char *tag = armed->groupBody->tag;
	if ( ::strcmp(tag,skip) == 0 ) { ::fprintf(stderr,"SWEEP SKIP %d %s\n",ci,tag); skipped++; continue; }
	// calibrate, interpreted
	int cv[512], cc[512], ct[512], cfi[512], ctr[512];
	for ( int i = 0; i < np; i++ ) {
	GroupItem *root = g->get(pRoot[i]);
	if ( !root ) { cfi[i] = -1; continue; }
	::jitProbeDrive(root, armed, pMsg[i], 0);
	cv[i] = gProbeVerdict; cc[i] = gProbeConsumed; ct[i] = gProbeTerms; cfi[i] = gProbeFires; ctr[i] = gProbeTrue; }
	// pick: accepts (fired, all succeeded) by consumed desc then terms desc; a second accept with a different consumed; rejects (fired, none) by terms desc
	int acc[512], na = 0, rej[512], nr = 0;
	for ( int i = 0; i < np; i++ ) {
	if ( cfi[i] > 0 && ctr[i] == cfi[i] ) acc[na++] = i;
	else if ( cfi[i] > 0 && ctr[i] == 0 ) rej[nr++] = i; }
	for ( int a = 0; a < na; a++ ) for ( int b = a+1; b < na; b++ )
	if ( cc[acc[b]] > cc[acc[a]] || (cc[acc[b]] == cc[acc[a]] && ct[acc[b]] > ct[acc[a]]) ) { int t = acc[a]; acc[a] = acc[b]; acc[b] = t; }
	for ( int a = 0; a < nr; a++ ) for ( int b = a+1; b < nr; b++ )
	if ( ct[rej[b]] > ct[rej[a]] ) { int t = rej[a]; rej[a] = rej[b]; rej[b] = t; }
	int pick[4], npk = 0;
	if ( na ) { pick[npk++] = acc[0]; int other = -1; for ( int a = 1; a < na; a++ ) if ( cc[acc[a]] != cc[acc[0]] ) other = acc[a]; if ( other >= 0 ) pick[npk++] = other; }
	for ( int r = 0; r < nr && r < 2; r++ ) pick[npk++] = rej[r];
	::fprintf(stderr,"SWEEP CARRIER %d %s accepts=%d rejects=%d picked=%d\n",ci,tag,na,nr,npk);
	if ( !npk ) { nopick++; continue; }
	// certify: jitted first (one compile), then the oracle; two fires each
	int before = gJitDegradeCount;
	int rv[2][4][2], rc[2][4][2], rt[2][4][2], rf[2][4][2], rtr[2][4][2], refused = 0;
	for ( int jt = 1; jt >= 0; jt-- ) for ( int p = 0; p < npk; p++ ) for ( int f = 0; f < 2; f++ ) {
	int i = pick[p];
	int r = ::jitProbeDrive(g->get(pRoot[i]), armed, pMsg[i], jt);
	if ( r == -7 || r == -8 ) refused = 1;
	rv[jt][p][f] = gProbeVerdict; rc[jt][p][f] = gProbeConsumed; rt[jt][p][f] = gProbeTerms; rf[jt][p][f] = gProbeFires; rtr[jt][p][f] = gProbeTrue;
	::fprintf(stderr,"SWEEP ROW %s %s fire%d %s|%s v=%d c=%d t=%d fires=%d true=%d\n",tag,jt?"J":"I",f+1,pRoot[i],pMsg[i],gProbeVerdict,gProbeConsumed,gProbeTerms,gProbeFires,gProbeTrue); }
	int degr = gJitDegradeCount - before;
	int agree = !refused;
	for ( int p = 0; p < npk; p++ ) for ( int f = 0; f < 2; f++ )
	if ( rv[1][p][f]!=rv[0][p][f] || rc[1][p][f]!=rc[0][p][f] || rt[1][p][f]!=rt[0][p][f] || rf[1][p][f]!=rf[0][p][f] || rtr[1][p][f]!=rtr[0][p][f] ) agree = 0;
	::fprintf(stderr,"SWEEP RESULT %s %s degrade=%d%s\n",tag,agree?"AGREE":"DIFF",degr,refused?" REFUSED":"");
	certified++; if ( agree ) agreeAll++; else diffAll++; }
	::fprintf(stderr,"SWEEP END carriers=%d skipped=%d nopick=%d certified=%d agree=%d diff=%d\n",nc,skipped,nopick,certified,agreeAll,diffAll);
	
	return ruler->trueResult;
}

// processAction run a cached BlocK for an action, or for a rule with its label's contents bound to its locals; locals are cleared at entry
extern "C" GroupItem *processAction(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*label = field;
GroupItem 	*code = 0;
GroupItem 	*grup = 0;
GroupItem 	*result = 0;
GroupItem 	*priorMETHOD = ruler->currentMETHOD->getGroup();
GroupItem 	*priorTempField = ruler->tempField;
GroupItem 	*action = field;
	// labelKnowsItsRule a label carries the rule it was minted for -- no singleton, no owner (stroke 5.6b)
	if ( action->groupBody->flags.isLabel )
		action = field->labelOf;
	ruler->currentMETHOD->setGroup(action);
	if ( !action->actionBlocK() && !::processCode(action,action->actionHolder()) )
		return 0;
	// branchFrame an action is a frame for the control slot: a callee's return or break is consumed here, never read by the caller's loop (P4, Tony SEQ 179)
	
	int actionBranchSave = GroupControl::groupController->groupRules->branchKind;
	GroupControl::groupController->groupRules->branchKind = 0;
	
	// labelToLocals a rule's locals take the label's contents; isLabel fields are not cleared below
	if ( action->groupBody->flags.isRule )
		{
		code = action->actionBody();
		// ruleArgument the code's argument is the label this fire was handed, the isLabel node itself (Tony)
		if ( grup = code->get("argument") )
			{
			if ( label->groupBody->flags.isLabel )
				grup->setGroup(label);
			else	grup->clear();
			}
		while ( result = code->nextAttribute(result) )
			{
			if ( result->groupBody->flags.noPrint )
				continue;
			// rulesOwnOnly clear only the rule's own locals and terms -- a global the body reads SHARES its body, so clearing it wiped the global (F-133)
			if ( grup = label->get(result->groupBody->tag) )
				{
				result->setGroup(grup);
				result->groupBody->flags.isLabel = 1;
				}
			else
			if ( result->groupBody->flags.isLocal || action->get(result->groupBody->tag) )
				result->clear();
			}
		}
	if ( result = action->actionBlocK() )
		{
		if ( action->groupBody->flags.isRule )
			action = code;
		// argumentExempt the argument is exempt from the entry clear -- runAction bound it before calling here
		while ( grup = action->nextAttribute(grup) )
			if ( grup->groupBody->flags.isLocal && !grup->groupBody->flags.isLabel && !grup->groupBody->flags.noPrint && !grup->groupBody->flags.isArgument && grup->groupBody != action->groupBody )
				grup->clear();
		result = result->groupBody->gMethod(result);
		}
	 GroupControl::groupController->groupRules->branchKind = actionBranchSave; 
	ruler->currentMETHOD->setGroup(priorMETHOD);
	ruler->tempField = priorTempField;
	return result;
}

// processCode parse an action's CodE into a BlocK and attach it; the field is made an action FIRST, or a recursive call would complain
extern "C" int processCode(GroupItem *field, GroupItem *holder)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*blockRULE = ruler->grokking->getMember("BlocK");
GroupItem 	*codeReport = new GroupItem("driveReport");
GroupItem 	*got = 0;
GroupItem 	*code = 0;
GroupItem 	*result = 0;
GroupItem 	*priorMETHOD = ruler->currentMETHOD->getGroup();
GroupItem 	*action = field;
int 		indenter = ruler->lastIndent;
char 		*failText = 0;
	// d2Tripwire an rStuff-less label is WRECKAGE, not a specimen (Ruling D2) -- refuse loud here, where it became visible
	if ( field->groupBody->flags.isLabel && !field->getRStuff() )
		{
		::fprintf(stderr,"processCode: REFUSING %s -- isLabel with no rStuff. Only a live parse mints a label (Ruling D2), so this node is wreckage, not a specimen; look upstream at whatever copied or hand-built it.\n",field->groupBody->tag);
		return 0;
		}
	// labelArmDead no road hands processCode a label (F-130: 0 calls, SEQ 246 tap) -- refuse by name, never guess the rule
	if ( field->groupBody->flags.isLabel )
		{
		if ( field->labelOf )
			::refuse(field->labelOf,"processCode: the label arm was reached -- a label was handed in where an action belongs (F-130)");
		else	::refuse(field,"processCode: the label arm was reached by a label with no labelOf (F-130)");
		return 0;
		}
	// staleIR re-parsing invalidates the action's IR record -- setText, never clear(), or it reads back as its tag
	
	GroupItem   *staleIR = field->get("JiT");
	if (staleIR)    staleIR->setText(::strdup(""));
	
	code = holder->getProperty("CodE");
	if ( field->groupBody->flags.isRule )
		action = code;
	ruler->currentMETHOD->setGroup(action);
	ruler->lastIndent = 0;
	// compileIsADrive the compile is a DRIVE: BlocK's generated parse when it carries one, the old road otherwise, on a floor either way -- a compile after parser() used to refuse (F-128)
	// compileOwner the drive's floor carries the owner: aCTionNamE mints the body's names into this action, never into the grammar face a generated body makes current (SEQ 214, SEQ 299)
	// parseSpeaks a parse's refusal prints, even mid-walk, and ends with the parse -- never pinned on an emitted statement (SEQ 372 R0, R1)
	// parseNeverEmits a parse RUNS, even inside a compile: on the new road the drive runs BlocK's generated body, and under jitting its terms were emitted into the action's function instead of parsing the code (SEQ 382 R2)
	 bool walkSave = gJitEmitWalk; gJitEmitWalk = false; 
	 int jitSave = GroupControl::groupController->groupRules->jitting; GroupControl::groupController->groupRules->jitting = 0; 
	result = ::driveStep(code,blockRULE,codeReport,action);
	 GroupControl::groupController->groupRules->jitting = jitSave; 
	 gJitEmitWalk = walkSave; if ( walkSave ) ::clearRefusal(field); 
	if ( result )
		{
		result->groupBody->flags.noPrint = 1;
		holder->addProperty(result);
		field->groupBody->flags.actionType = 1;
		}
	else {
		// handedPoint the drive hands back its floor's failure point as an offset into the code it drove (SEQ 292)
		if ( got = codeReport->get("failedAt") )
			if ( got->getCount() >= 0 )
				failText = code->getText() + got->getCount();
		reportCodeFail(field,failText);
		}
	ruler->lastIndent = indenter;
	ruler->currentMETHOD->setGroup(priorMETHOD);
	if ( result )
		return 1;
	return 0;
}

/*******************************************************************************
	The processFlags method is invoked by multiple incant noPrint fire and
    forget commands run at field definition). The item passed in as argument
    is used to figure out what flag to set/reset; the exception is the exit
    command that is not fire and forget; it is fire and exit.

    BEAR COUNTRY: case 'v' (the `virtual` command) sets isVirtual. This is the
    only sanctioned way a field becomes virtual, and it runs at field
    definition. Do not virtualize a field outside a define. Virtual is a
    define-time property; the forks that consume it (aCTionNamE, runOP) assume
    nothing virtual was created elsewhere. See the wakeup bear-trap log.
*******************************************************************************/
extern "C" GroupItem *processFlags(GroupItem *item)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
char 		*command = item->groupBody->tag;
GroupItem 	*target = item->groupBody->flags.fLAG ? item->parent : item;
	if ( item )
		switch (*command)
			{
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

/*******************************************************************************
	The incant quoted command is usually used in a print statement to output
    its argument text in quotes.
*******************************************************************************/
extern "C" GroupItem *quoted(GroupItem *input)
{
char 		*strung = ::concat(3,"\"",input->getText(),"\"");
GroupItem 	*grup = new GroupItem(strung);
	return grup;
}

/*******************************************************************************
	Register the parent block of item in the currentRegistry. This method is
    associated with register and class attributes defined in bootCommands()
    NOTE: the class attribute that makes its parent a registry should preceed any
    attribute to be registered. The index attribute if it exists, should come
    before class.

    Note the argument passed in may be a copy of a registry, hence the use
    of registri below to make sure argument references the original
*******************************************************************************/
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

// recordLabel the label of the nearest live record whose stuff is s -- a child's read of its parent's label (1.2f, SEQ 306)
extern "C" GroupItem *recordLabel(RuleStuff *s)
{
GroupRules 			*ruler = GroupControl::groupController->groupRules;
ParseActivation 	*rec = ruler->gParseActive;
	while ( rec && ruler->stuffOf(rec) != s )
		rec = rec->prev;
	if ( rec )
		return rec->label;
	return 0;
}

// refuse THE ONE FUNNEL: print the line, arm the unwind, hand back null -- a refusal ends the activation that raised it
extern "C" GroupItem *refuse(GroupItem *subject, char *why)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
char 		*name = "(none)";
int 		silent = 0;
	if ( subject )
		name = subject->groupBody->tag;
	// theLine sourceLINE is where the PARSER is, stale for a cached body -- no usable per-statement line exists; do not chase it
	// emitSilent only in the jit EMIT WALK is a refusal not announced: the statement runs on the interpreted road at RUN time, which announces it there (SEQ 370 R1, scoped by SEQ 372 R0)
	 silent = ruler->jitting && gJitEmitWalk; 
	if ( !silent )
		::fprintf(stderr,"REFUSED %s -- %s [line %s]\n",name,why,::toStringFromInt(ruler->sourceLINE));
	ruler->refused = 1;
	return 0;
}

// refuseArgRebind a := or <- on the argument refuses by name, tested BEFORE the follow, which destroys the evidence; 1 when it refused
extern "C" int refuseArgRebind(GroupItem *op, GroupItem *target)
{
	
	if ( !op || !target || !target->groupBody->flags.isArgument ) return 0;
	void *gop = (void*)op->groupBody->gOp;
	if ( gop != (void*)&opSetGroup && gop != (void*)&opRebind ) return 0;
	char why[192];
	::snprintf(why,sizeof(why),
	"`%s` on argument -- argument is a BINDING, not a field; rebind is the caller's job",
	op->groupBody->tag);
	::refuse(target,why);
	return 1;
	
}

// refuseDotUnaryOp the refusal itself, for any road that holds the dot and the unary after it: trunk's uxp, the candidate's flat list (SEQ 327 D2)
extern "C" int refuseDotUnaryOp(GroupItem *op, GroupItem *aop)
{
	/*  derefIsTheTag  NAME THE OPERATOR BY ITS REGISTRY TAG AND DO NOT RECONSTRUCT THE
	SOURCE SPELLING -- the unary star registers as `deref` (incant/setup:115), so
	echoing the tag into a cure produced `a[derefb]` on the first cut of this line.
	The cure is spelled as the SHAPE, with the star as the worked example.
	⚠ THE CONCATENATION IDIOM IS setActions' -- juxtaposition allocates, so it is
	freed after the refusal has printed it.  */
	/*  escalated  refuse() PROPER, NOT A cerr, ON TONY'S RULING OF 2026-09-17. It rides
	escalated  WITH the refusalBoundary report above, because the two are one stroke
	escalated  seen from both ends: this raises ruler.refused, and the boundary is
	escalated  what turns that flag into a named removal instead of a silent one.  */
char *why = ::concat(3,"unary ",aop->groupBody->tag," on the right of a dot is never seen by opDot -- move it inside a subscript: a[*b], not a.*b");
	::refuse(op,why);
	::free(why);
	return 1;
}

/*  refuseLeadingDotNumber -- A NUMBER NEEDS A LEADING DIGIT (Tony, ruled 2026-09-24, F-117 option (a)). `.5` is
    not a number and not an accessor: a leading `.` on a LITERAL number is refused by name, suggesting 0.5. A leading
    `.` on a field (`.x`, the accessor road through lastREF) is untouched. Before this the old road read `.5` as an
    accessor with no target and crashed in opDot; the new road printed nothing.
    ⚠ A HAND, NOT A WITNESS -- no measure prefix.  */
extern "C" int refuseLeadingDotNumber(GroupItem *unary, GroupItem *token)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	if ( !unary )
		return 0;
	if ( unary->groupBody->registry != ruler->opFields )
		return 0;
	if ( ::compare(unary->groupBody->tag,".") != 0 )
		return 0;
	if ( !token )
		return 0;
	if ( token->groupBody->registry == ruler->groupFields )
		return 0;
	if ( !isCOUNT(token->groupBody->flags.data) && !isNUMBER(token->groupBody->flags.data) )
		return 0;
char 		*why = ::concat(4,"`.",token->getText(),"` is not a number -- a number needs a leading digit; write 0.",token->getText());
	::refuse(token,why);
	::free(why);
	return 1;
}

// refuseUnknownOperator an operator registered in Operators with no operateMethod refuses by name; a rule, action or value reaching the foot is untouched
extern "C" GroupItem *refuseUnknownOperator(GroupItem *op, GroupItem *target)
{
	
	if ( !op || op->groupBody->registry != GroupControl::groupController->groupRules->opFields ) return 0;
	char why[224];
	GroupItem *who = target ? target : op;
	::snprintf(why,sizeof(why),
	"operator '%s' has no road -- the token is registered in Operators with no operateMethod, so this statement would change nothing",
	op->groupBody->tag ? op->groupBody->tag : "(unnamed)");
	return ::refuse(who,why);
	
}

// refuseValueTarget an assigning operator whose target is a computed value, never a field, refuses by name; 1 when it refused (Tony, SEQ 360 R1). Interpreted: the target IS tempField. Jitted: tempField is opDot's accessor carrier (R1), so the test is the target's jitValue BEING the last computed value, gJitComputedVal (SEQ 365 R0)
extern "C" int refuseValueTarget(GroupItem *op, GroupItem *target)
{
	
	GroupRules *ruler = GroupControl::groupController->groupRules;
	if ( !op || !target ) return 0;
	if ( ruler->jitting ) {
	if ( !target->jitData || !target->jitData->jitValue || target->jitData->jitValue != gJitComputedVal ) return 0; }
	else if ( target != ruler->tempField ) return 0;
	void *gop = (void*)op->groupBody->gOp, *gm = (void*)op->groupBody->gMethod;
	if ( gop != (void*)&opAssign && gop != (void*)&opPlusEQ && gop != (void*)&opMinusEQ && gop != (void*)&opMultiplyEQ
	&& gop != (void*)&opDivEQ && gm != (void*)&opPlusPlus && gm != (void*)&opMinusMinus ) return 0;
	char why[128];
	::snprintf(why,sizeof(why),"the left of %s is a value, not a field",op->groupBody->tag);
	::refuse(op,why);
	return 1;
	
}

// repeatsInLoop the ONE test for "this term repeats inside parseLoop": every rule body, and max > 1 when not a leaf -- leaves (data 1-3) loop inside their own method. The install site and exitFromParse's zero-width tail both ask it (SEQ 208). Its first clause is ruling A -- every rule body (SEQ 203; reverted SEQ 211, back with the drive-compile merge, SEQ 217)
extern "C" int repeatsInLoop(GroupItem *field)
{
RuleStuff 	*ruleStuff = field->getRStuff();
	if ( !ruleStuff )
		return 0;
	if ( field->groupBody->gParseMethod == ::parseRule || (ruleStuff->max > 1 && (!field->groupBody->flags.data || field->groupBody->flags.data > 3)) )
		return 1;
	return 0;
}

// reportCodeFail WHERE a code body failed to parse -- rule, position and line, on cerr because print may be diverted
extern "C" void reportCodeFail(GroupItem *field, char *failText)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	::fprintf(stderr,"ERROR processCode: %s parse failed\n",field->groupBody->tag);
	::fprintf(stderr,"    failed at %s\n",::getDebugText(failText,40));
	::fprintf(stderr,"    on line %s\n",::toStringFromInt(ruler->sourceLINE));
}

/*  reportDefineRemoved -- THE BOUNDARY'S VOICE. A SIBLING OF reportNoBody, NOT A REUSE
    OF refuse(). Built 2026-09-17 on Tony's ruling: aCTionDefinE's refusalBoundary names
    what it removes WHEN it removes it, so a refusal inside a define block is loud with a
    patient (R-2). Until today the boundary deleted a definition in perfect silence and the
    only symptom was that nothing later could find the field.

    ⚠ IT DELIBERATELY DOES NOT RE-PRINT THE REFUSAL'S REASON, AND THAT IS THE DESIGN AND
    NOT AN OMISSION. Two sites, two facts: refuse() names ITS patient and why it refused;
    this names WHAT WAS REMOVED and from where, which is the fact only the boundary holds.
    A reporter that re-stated another site's reason would be a witness recomputing its
    subject's decision, which is the drift this project has already paid for.

    ⚠ AND THE PAIRING IS GUARANTEED RATHER THAN HOPED FOR: refuse() (GroupActions.rtn:859)
    is the SOLE WRITER of ruler.refused, measured 2026-09-17, so this line cannot print
    without a REFUSED line above it. If a second writer is ever added, that is the moment
    this comment stops being true.   ruleActions.aCTionDefinE.refusalBoundary  */
extern "C" void reportDefineRemoved(GroupItem *field, GroupItem *intoReg)
{
char 	*regName = "(no registry)";
	if ( intoReg )
		regName = intoReg->groupBody->tag;
	::fprintf(stderr,"REMOVED %s from %s -- a refusal fired while it was being defined, so the definition is GONE and nothing later will find it\n",field->groupBody->tag,regName);
}

// reportDrive driveStep's report: three counts, offsets into the message
extern "C" void reportDrive(GroupItem *report, char *failed, char *driveBase)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*num = 0;
int 		driveLen = ::strlen(driveBase);
int 		atOffset = -1;
int 		failOffset = -1;
	if ( ruler->atRuleMark >= driveBase && ruler->atRuleMark <= driveBase + driveLen )
		atOffset = (int)(ruler->atRuleMark - driveBase);
	if ( failed && failed >= driveBase && failed <= driveBase + driveLen )
		failOffset = (int)(failed - driveBase);
	num = new GroupItem("length");
	num->setCount(driveLen);
	report->addAttribute(num);
	num = new GroupItem("mark");
	num->setCount(atOffset);
	report->addAttribute(num);
	num = new GroupItem("failedAt");
	num->setCount(failOffset);
	report->addAttribute(num);
}

// reportMaxLimit a match hit the maxLimit ceiling with input still matching -- REFUSE rather than truncate; callers gate on max > 1
extern "C" int reportMaxLimit(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = field->getRStuff();
	::fprintf(stderr,"REFUSED match limit: rule %s term %s\n",ruleStuff->ruleName,field->groupBody->tag);
	::fprintf(stderr,"    hit maxLimit %s with input still matching\n",::toStringFromInt(ruleStuff->max));
	::fprintf(stderr,"    at %s\n",::getDebugText(ruler->atRuleMark,40));
	return 0;
}

// reportNoBody a rule reached through a bound parse method has no compiled body -- a sibling of reportCodeFail, never a reuse of it
extern "C" void reportNoBody(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	::fprintf(stderr,"REFUSED parseRule: %s has a parse method but no compiled body\n",field->groupBody->tag);
	::fprintf(stderr,"    at %s\n",::getDebugText(ruler->atRuleMark,40));
}

// reportRepeatLimit a rule repeated to its ceiling -- REPORTS and does not fail; the counts are passed in because rStuff may be a reentrancy clone's
extern "C" int reportRepeatLimit(GroupItem *rule, int kounted, int limit)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	::fprintf(stderr,"REFUSED repetition limit: rule %s\n",rule->groupBody->tag);
	::fprintf(stderr,"    repeated %s times, hit repeatLimit %s\n",::toStringFromInt(kounted),::toStringFromInt(limit));
	::fprintf(stderr,"    at %s\n",::getDebugText(ruler->atRuleMark,40));
	return 0;
}

/*  reportRunAbandoned -- THE OUTERMOST BOUNDARY, AND THE ONLY PLACE THAT KNOWS THE RUN IS
    OVER. Built 2026-09-17 for fixIts F-76.

    A refusal is terminal for its action and it BREAKS the enclosing block (aCTionBlocK's
    refusalArm). The break walks outward, and the two things that CLEAR the flag --
    runAction's refusalArm and aCTionDefinE's refusalBoundary -- sit on paths a refusal
    raised from an EXPRESSION during a definition never reaches, because the match fails
    before aCTionDefinE's action ever fires. Measured 2026-09-17 with a probe at that
    action's tail: `arBad` (refused from a rule action) prints `refused=1` there and is
    reported and cleared; `dcBad` (refused from an expression) produces NO tail line at all.

    ⚠ SO THE BOUNDARY IS NOT MISSED ON THAT PATH, IT IS STRUCTURALLY UNREACHABLE -- and
    nothing clears the flag, so the rest of the FILE is abandoned. Silently. At exit 0,
    with no `stop:` line, which is indistinguishable from a short successful run and is
    the failure mode this project has paid for more than any other.

    ⚠ THIS DOES NOT CHANGE THAT BEHAVIOUR AND IS NOT TRYING TO. Whether a define-time
    expression refusal SHOULD be terminal is a ruling nobody has made, and giving that path
    a boundary is a change to parse semantics rather than a line. What this removes is the
    SILENCE: being terminal is defensible, being terminal without saying so is not.
    ruleActions.reportRunAbandoned  */
extern "C" void reportRunAbandoned(char *fileName)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
char 		*whichFile = "(no file)";
	// markSeat4 SEQ 166 point 4 -- what the REPORTER reads, and which input level it belongs to
	::measureMarkPoint("4-reportAbandoned");
	if ( fileName )
		whichFile = fileName;
	/*  unconsumedInput  THE ABANDONMENT THAT ACTUALLY HAPPENS, F-79. `Start` is
	unconsumedInput  `StatemenT+`, so a statement that FAILS TO MATCH ends the
	unconsumedInput  repetition and every byte after it is never parsed -- no error,
	unconsumedInput  no stop: line, exit 0. Measured 2026-09-17: a refusing define and
	unconsumedInput  an unterminated literal both do it, and a `@@@` or a bad operator
	unconsumedInput  do NOT, so the discriminator is MATCH FAILURE and not malformity.
	unconsumedInput  Reading the mark is what names it; the refusal flag cannot, because
	unconsumedInput  half these cases never raise one.   docs/refusalScope.md  */
	if ( *ruler->atRuleMark )
		{
		::fprintf(stderr,"ABANDONED %s -- the parse STOPPED with input left over. A statement failed to match, which ends Start's StatemenT+ repetition, so everything from here on was NEVER PARSED. The exit status is still 0. It resumes at:\n",whichFile);
		::fprintf(stderr,"    %s\n",::getDebugText(ruler->atRuleMark,60));
		return;
		}
	if ( !ruler->refused )
		return;
	/*  wordingCorrected  THE FIRST CUT OF THIS LINE SAID "every statement after the
	wordingCorrected  REFUSED line was SKIPPED, not parsed" AND THAT IS FALSE FOR HALF
	wordingCorrected  THE CASES -- measured 2026-09-17, F-78. A refusal inside a define
	wordingCorrected  breaks the block and later statements ARE skipped; a refusal at
	wordingCorrected  statement level does NOT stop plain statements, it silences ACTION
	wordingCorrected  AND COMMAND DISPATCH -- so stop() is never entered and MORE gets
	wordingCorrected  parsed, not less. The message now claims only what is true of both.  */
	::fprintf(stderr,"ABANDONED %s -- the run ended with a refusal outstanding. Nothing after the REFUSED line above is reliable: action and command dispatch is silenced, so statements can be skipped AND a stop() can be missed, leaving the region below it parsed as source. The exit status is still 0\n",whichFile);
}

// resetField the reset command (reset immediateAction=resetField): for now it knows buffers, and resets the mark
extern "C" GroupItem *resetField(GroupItem *argument)
{
Buffer 	*buff = argument->getBuffer();
	if ( buff )
		buff->reset();
	return 0;
}

// resolveName THE WHOLE RESOLUTION of a name in an action body, against an OWNER: already the owner's, a declared field referenced into the owner, or a new local minted there (SEQ 214). aCTionNamE calls it; the post-compile resolveNames pass will call it with owner = the action (Tony's (ii))
extern "C" GroupItem *resolveName(char *arg, GroupItem *owner)
{
	
	GroupRules *ruler = GroupControl::groupController->groupRules;
	GroupItem *grup = 0, *result = 0;
	int inCode = ruler->inCompile();
	if ( inCode && owner )   result = owner->getAttribute(arg);
	if ( !result )                          result = GroupControl::groupController->locate(arg);
	if ( result && result->parent == owner )    return result;
	if ( ruler->defining && result && result->groupBody->flags.isVirtual )  result = ::copyOf(result);
	grup = new GroupItem(arg);
	if ( ruler->alphaSet->contains(*arg) && inCode && owner )
	if ( !result || (!result->groupBody->flags.isArgument && !result->groupBody->flags.isLocal) )
	if ( !(result && result->groupBody->registry == ruler->opFields) ) {
	if ( result ) {
	if ( owner->isRuleTerm() && result->isRuleTerm() ) {
	result = owner->addAttribute(grup);
	result->groupBody->flags.isLocal = 1; }
	else    result = owner->addAttribute(result); }
	else {
	result = owner->addAttribute(grup);
	result->groupBody->flags.isLocal = 1; } }
	if ( !result )  result = grup;
	return result;
	
}

// restoreLocalFields restore what saveLocalFields banked, at the end of a nested call
extern "C" void restoreLocalFields(GroupItem *action)
{
Stak 		*recurseSTAK = 0;
GroupBody 	*body = 0;
GroupItem 	*frame = 0;
GroupItem 	*grup = 0;
	frame = ::frameFind(action);
	if ( frame )
		recurseSTAK = frame->getStak();
	// identityPair restore pairs by identity, never by position -- walk the STACK, not the field list, with no filter of its own
	// nullArm restore is reached where save never ran (the jit bracket among them); no frame child means nothing was saved
	if ( recurseSTAK && recurseSTAK->length )
		while ( body = (GroupBody*)recurseSTAK->pop() )
			{
			grup = (GroupItem*)recurseSTAK->pop();
			*grup->groupBody = *body;
			body = 0;
			}
}

// ruleMethod bind the method the attribute's text names, found with dlsym -- as the parent's method for ruleMethod, else as its operator
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

// ruleOfCensus the instance -> rule link's invariants over every node reachable from the registries (terms AND properties) and from the argument: ruleOf never aimed at a copy, same body as its original, and ONE root per body (every node sharing a body names the same original -- only the copy constructor shares a body); lists the cross-registry copies with what they wrote into the shared body (stroke 4.1; ruleOf-only since isCopy was deleted, 4.2); prints unconditionally
extern "C" GroupItem *ruleOfCensus(GroupItem *input)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	
	static GroupItem **seen = 0; static void **bodyKey = 0; static GroupItem **bodyRoot = 0; static long cap = 0; long used = 0;
	if ( !seen ) { cap = 1 << 20; seen = (GroupItem**)::calloc(cap,sizeof(GroupItem*)); bodyKey = (void**)::calloc(cap,sizeof(void*)); bodyRoot = (GroupItem**)::calloc(cap,sizeof(GroupItem*)); }
	else { ::memset(seen,0,cap * sizeof(GroupItem*)); ::memset(bodyKey,0,cap * sizeof(void*)); ::memset(bodyRoot,0,cap * sizeof(GroupItem*)); }
	GroupItem **stack = (GroupItem**)::malloc(sizeof(GroupItem*) * cap); long sp = 0;
	long labels = 0, nodes = 0, copies = 0, toCopy = 0, bodyMis = 0, rootConflict = 0;
	GroupItem *regs = ruler->registries;
	if ( regs ) stack[sp++] = regs;
	if ( input ) stack[sp++] = input;
	while ( sp > 0 ) {
	GroupItem *n = stack[--sp];
	if ( !n ) continue;
	unsigned long h = ((unsigned long)n >> 4) & (cap - 1);
	while ( seen[h] && seen[h] != n ) h = (h + 1) & (cap - 1);
	if ( seen[h] == n || used > cap / 2 ) continue;
	seen[h] = n; used++; nodes++;
	if ( n->groupBody->groupList ) for ( GroupItem *c = n->groupBody->groupList->firstInList; c && sp < cap; c = c->nextInParent ) stack[sp++] = c;
	if ( n->groupBody->propertyList ) for ( GroupItem *c = n->groupBody->propertyList->firstInList; c && sp < cap; c = c->nextInParent ) stack[sp++] = c;
	GroupItem *L = n->ruleOf;
	if ( L ) copies++;
	if ( n->groupBody->flags.isLabel ) labels++;
	{   GroupItem *root = L ? L : n; void *b = (void*)n->groupBody;
	unsigned long k = ((unsigned long)b >> 4) & (cap - 1);
	while ( bodyKey[k] && bodyKey[k] != b ) k = (k + 1) & (cap - 1);
	if ( !bodyKey[k] ) { bodyKey[k] = b; bodyRoot[k] = root; }
	else if ( bodyRoot[k] != root ) { rootConflict++; if ( rootConflict <= 5 ) ::fprintf(stderr,"  RULEOF two roots for one body: %s@%p names %p, the body's first reader named %p\n",n->groupBody->tag,n,root,bodyRoot[k]); } }
	if ( L && L->ruleOf ) { toCopy++; if ( toCopy <= 5 ) ::fprintf(stderr,"  RULEOF aims at a copy: %s@%p -> %s@%p\n",n->groupBody->tag,n,L->groupBody->tag,L); }
	if ( L && L->groupBody != n->groupBody ) bodyMis++;
	}
	::free(stack);
	::fprintf(stderr,"RULEOF nodes=%ld labels=%ld copies=%ld aimsAtCopy=%ld bodyMismatch=%ld rootConflict=%ld\n",nodes,labels,copies,toCopy,bodyMis,rootConflict);
	int xr = 0;
	if ( regs && regs->groupBody->groupList ) for ( GroupItem *rg = regs->groupBody->groupList->firstInList; rg; rg = rg->nextInParent )
	if ( rg->groupBody->groupList ) for ( GroupItem *e = rg->groupBody->groupList->firstInList; e; e = e->nextInParent ) {
	GroupItem *L = e->ruleOf;
	if ( !L || !L->parent || L->parent == rg || L->parent->parent != regs ) continue;
	xr++;
	int kids = 0, kidsOfCopy = 0, props = 0, propsOfCopy = 0;
	if ( e->groupBody->groupList ) for ( GroupItem *c = e->groupBody->groupList->firstInList; c; c = c->nextInParent ) { kids++; if ( c->parent == e ) kidsOfCopy++; }
	if ( e->groupBody->propertyList ) for ( GroupItem *c = e->groupBody->propertyList->firstInList; c; c = c->nextInParent ) { props++; if ( c->parent == e ) propsOfCopy++; }
	::fprintf(stderr,"  RULEOF XREG %s/%s <- %s/%s  terms=%d (written through the copy %d)  properties=%d (through the copy %d)  isRule=%d binType=%d instructType=%d actionType=%d\n",
	rg->groupBody->tag,e->groupBody->tag,L->parent->groupBody->tag,L->groupBody->tag,kids,kidsOfCopy,props,propsOfCopy,
	(int)e->groupBody->flags.isRule,(int)e->groupBody->flags.binType,(int)e->groupBody->flags.instructType,(int)e->groupBody->flags.actionType);
	}
	::fprintf(stderr,"RULEOF cross-registry copies=%d\n",xr);
	
	return ruler->trueResult;
}

// runAccAnd the logic tier, &&: evaluate the left side, early-out on false, else the right side decides -- a SENTINEL either way
extern "C" GroupItem *runAccAnd(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*left = 0;
	// jitAnd under jitting the connective's slots go to the tree's own emitter, which owns the short-circuit diamond (SEQ 335 J4a)
	if ( ruler->jitting )
		{
		if ( field->groupBody->groupList->listLength < 3 )
			return ::refuse(field,"a connective with no right side under jitting (SEQ 335 J4a)");
		return jitEmitShortCircuitSlots(field->get(2),field->get(1),field->get(3),field);
		}
	left = runOPaccumOperand(field->get(1));
	if ( !::truthOf(left) )
		return ruler->falseResult;
	if ( field->groupBody->groupList->listLength < 3 )
		return ruler->falseResult;
	if ( ::truthOf(runOPaccumOperand(field->get(3))) )
		return ruler->trueResult;
	return ruler->falseResult;
}

/*  THE TIER EXECUTORS (SEQ 319, c3). interpretXPaccum builds one node per tier, loosest first,
    and gives each node ITS executor as its method at build time (D5): acA assign, acAnd / acOr
    logic, acK compare, acKchain the chained-comparison refusal, acX the arithmetic fold. NOTHING
    here asks an operator for its tier -- the split already did, once. Operands arrive as nodes
    and are finished by runOPaccumOperand; runOPdirect fires on finished operands (c1).
    Interpreted only: under jitting each refuses (SEQ 311 R4).  */
// runAccAssign the assignment tier, a single step: finish the head's target, evaluate the right side, assign
extern "C" GroupItem *runAccAssign(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*op = field->get(2);
GroupItem 	*val = 0;
GroupItem 	*target = 0;
	// jitAssign this body is runOPslots' order, so under jitting it emits as trunk's instruction does; only the stored-refusal stop is interpreted only (SEQ 331 J2)
	if ( field->groupBody->groupList->listLength > 2 )
		val = runOPaccumOperand(field->get(3));
	// finished the head's target is finished here; val is a VALUE and is never invoked again (holderT, SEQ 318 c1)
	target = field->get(1);
	if ( ::refuseArgRebind(op,target) )
		return 0;
	target = ::followArgument(target);
	if ( ruler->refused )
		if ( !ruler->jitting )
			return 0;
	if ( op->groupBody->flags.instructType && isMethod(target->groupBody->flags.instructType) && target->groupBody->flags.invoke )
		target = target->groupBody->gMethod(target);
	// valueTarget a computed target -- tempField -- refuses by name (Tony, SEQ 360 R1)
	if ( ::refuseValueTarget(op,target) )
		return 0;
	if ( target && target->groupBody->flags.isVirtual )
		target = ::copyOf(target);
	return ::runOPdirect(op,target,val);
}

// runAccChain a CHAINED comparison, seen at build: refused by its own name (SEQ 318 R1)
extern "C" GroupItem *runAccChain(GroupItem *field)
{
	return ::refuse(field->get(2),"a chained comparison (a < b < c) -- refused by name (SEQ 318 R1)");
}

// runAccCompare the compare tier, a single step: left side, right side, the comparison
extern "C" GroupItem *runAccCompare(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*left = 0;
GroupItem 	*keep = 0;
GroupItem 	*right = 0;
	// jitCompare under jitting the body emits as it stands: both sides finished, runOPdirect seeds them and the op's gate emits the compare (SEQ 334 J6)
	left = runOPaccumOperand(field->get(1));
	// copyOut a side answering in tempField is copied out before the other side can run
	if ( left == ruler->tempField )
		{
		keep = new GroupItem("acRun");
		keep->setContent(left);
		::jitCarryCopy(keep,left);
		left = keep;
		}
	// refuseNotSubstitute under jitting a side that produced nothing refuses by name -- a falseResult in its place would be seeded as a constant
	if ( !left )
		if ( ruler->jitting )
			return ::refuse(field,"a compare side produced nothing under jitting (SEQ 334 J6)");
	if ( !left )
		left = ruler->falseResult;
	if ( left->groupBody->flags.isVirtual )
		left = ::copyOf(left);
	if ( field->groupBody->groupList->listLength > 2 )
		right = runOPaccumOperand(field->get(3));
	if ( !right )
		if ( ruler->jitting )
			return ::refuse(field,"a compare side produced nothing under jitting (SEQ 334 J6)");
	return ::runOPdirect(field->get(2),left,right);
}

// runAccFold the arithmetic tier, THE FOLD: left to right, no precedence, no tier test -- every operator here is arithmetic by construction
extern "C" GroupItem *runAccFold(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
int 		n = field->groupBody->groupList->listLength;
int 		i = 2;
GroupItem 	*run = 0;
GroupItem 	*keep = 0;
	// jitFold under jitting the fold emits as it stands: each step is runOPdirect, which seeds an unseeded operand and the op's gate emits; a step's result rides on its target (SEQ 334 J6)
	run = runOPaccumOperand(field->get(1));
	while ( i < n )
		{
		// copyOut a step answering in tempField is copied out before the next operand can run
		if ( run == ruler->tempField )
			{
			keep = new GroupItem("acRun");
			keep->setContent(run);
			::jitCarryCopy(keep,run);
			run = keep;
			}
		// refuseNotSubstitute under jitting an operand that produced nothing refuses by name -- a falseResult in its place would be seeded as a constant
		if ( !run )
			if ( ruler->jitting )
				return ::refuse(field,"a fold operand produced nothing under jitting (SEQ 334 J6)");
		if ( !run )
			run = ruler->falseResult;
		// finished both sides are finished: the running value is a value, the right side is evaluated once here
		if ( run->groupBody->flags.isVirtual )
			run = ::copyOf(run);
		// valueTarget a step's target is the running value; jitted, a computed one rides on its LEFT OPERAND, so an assigning step refuses rather than write it (SEQ 365 R0) -- interpreted it is the acRun copy and never refuses
		if ( ::refuseValueTarget(field->get(i),run) )
			return 0;
		run = ::runOPdirect(field->get(i),run,runOPaccumOperand(field->get(i + 1)));
		i = i + 2;
		}
	return run;
}

// runAccOr the logic tier, ||: evaluate the left side, early-out on true, else the right side decides -- a SENTINEL either way
extern "C" GroupItem *runAccOr(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*left = 0;
	// jitOr under jitting the connective's slots go to the tree's own emitter, which owns the short-circuit diamond (SEQ 335 J4a)
	if ( ruler->jitting )
		{
		if ( field->groupBody->groupList->listLength < 3 )
			return ::refuse(field,"a connective with no right side under jitting (SEQ 335 J4a)");
		return jitEmitShortCircuitSlots(field->get(2),field->get(1),field->get(3),field);
		}
	left = runOPaccumOperand(field->get(1));
	if ( ::truthOf(left) )
		return ruler->trueResult;
	if ( field->groupBody->groupList->listLength < 3 )
		return ruler->falseResult;
	if ( ::truthOf(runOPaccumOperand(field->get(3))) )
		return ruler->trueResult;
	return ruler->falseResult;
}

// runAction run an action that may need code processing -- two arms, the jit arm and the interpreted one, each returning through its own exit
extern "C" GroupItem *runAction(GroupItem *argument, GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*result = 0;
GroupItem 	*capture = 0;
GroupItem 	*ruleArg = 0;
	if ( isCoded(field->groupBody->flags.actionType) )
		if ( !::processCode(field,field) )
			goto exitRunAction;
	// lastREF a no-argument call leaves the action in lastREF
	ruler->lastREF->setGroup(argument ? argument : field);
	// mint argument is a runtime-minted binding slot, never a declared attribute -- above the jitting gate because BOTH ROADS need it flagged
	ruleArg = field->get("argument");
	if ( !ruleArg )
		ruleArg = field->addString("argument");
	ruleArg->groupBody->flags.isArgument = 1;
	if ( ruler->jitting )
		{
		// selfCallValue an emitted self-call hands back its value node (%selfcall), never the action (SEQ 378 R0)
		if ( result = ::jitEmitSelfCall(argument,field) )
			goto exitRunAction;
		// jitBind an INLINED callee is walked here at emit time, so the emit-time bind is this arm's; an emitted call binds in jitBindArgRT
		ruleArg->setGroup(argument);
		::jitInlinePush(field);
		// runtimeBind the call's argument is bound again AT RUN TIME, inside a channel push the region's join pops (SEQ 396)
		jitEmitInlineEnter(argument,field);
		result = ::processAction(field);
		::jitInlinePop(result);
		goto exitRunAction;
		}
	// bindOrder save before bind so the outer activation gets its slot back
	::saveLocalFields(field);
	// ownArgument a computed argument answers in ruler.tempField, the ONE scratch node every arithmetic operator writes -- the call that computed it owns a copy (Tony, SEQ 374 R0/R1)
	if ( argument == ruler->tempField )
		{
		capture = new GroupItem(argument->groupBody->tag);
		capture->setContent(argument);
		argument = capture;
		}
	ruleArg->setGroup(argument);
	// chanCount chanT's pair, SAME MUST EQUAL BINDS -- passthrough because the check is pointer identity, which == is not
	
	GroupControl::groupController->groupRules->chanBinds++;
	if ( ruleArg->groupBody->gGroup == argument ) GroupControl::groupController->groupRules->chanSame++;
	
	// jitterIntercept after jitter; a call fires its compiled function, compiled at the first call -- inside the bracket, so the frame is the interpreter's (SEQ 386)
	
	if ( gJitter && ::jitterReady(field) )  result = ::jitBoxCountRT(gJitterFn(::jitBodyField(field)));
	else                                    result = ::processAction(field);
	
	if ( result )
		{
		capture = new GroupItem(result->groupBody->tag);
		capture->setContent(result);
		result = capture;
		}
	::restoreLocalFields(field);
exitRunAction:
	// refusalArm activation-scoped: a refusal ends the action that raised it and NOT its caller, which gets a testable null
	if ( ruler->refused )
		{
		clearRefusal(result);
		result = 0;
		}
	return result;
}

// runLeafParse fire a leaf's parse method through its defining rule; a missing method is a named refusal, never a call
extern "C" GroupItem *runLeafParse(GroupItem *field)
{
	// instanceFirst the reference's own { } before the rule's method -- the same read as driveStep's (F-O23)
	if ( field->getRStuff() && field->getRStuff()->overTo )
		return ::parseUpTo(field);
	// ruleFactsOnBody the rule's method is on the shared body, so the defining rule is not looked up (stroke 1.4)
	if ( field->groupBody->gParseMethod )
		return field->groupBody->gParseMethod(field);
	return ::refuse(field,"parseLoop: no parse method is installed on the defining rule");
}

// runOP the instruction's UNPACKER: its three slots, handed to runOPslots (SEQ 318 c1)
extern "C" GroupItem *runOP(GroupItem *field)
{
	return ::runOPslots(field->get(1),field->get(2),field->get(3));
}

/*  runOPaccum -- THE ACCUMULATOR CANDIDATE'S PREFIX AND CALL (SEQ 311; tiers moved out at SEQ 319 c3).
    Two shapes built by interpretXPaccum: acU (a prefix over an operand) and acC (a call whose
    target is itself built -- (*block)(code)). The tiers have their own executors below.
    Interpreted only: under jitting it refuses (SEQ 311 R4).  */
extern "C" GroupItem *runOPaccum(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*op = 0;
GroupItem 	*val = 0;
GroupItem 	*arg = 0;
	// jitCall an acC is the call instruction's own shape, so under jitting its RAW slots go to runOPslots, which owns the term-call emit (SEQ 331 J1)
	if ( ruler->jitting )
		{
		if ( ::compare(field->groupBody->tag,"acC") == 0 )
			{
			val = field->get(2);
			if ( ::compare(val->groupBody->tag,"acU") == 0 || ::compare(val->groupBody->tag,"acDot") == 0 || ::compare(val->groupBody->tag,"acSub") == 0 || ::compare(val->groupBody->tag,"acC") == 0 )
				return ::refuse(field,"a call whose target is built -- not yet on the jit road (SEQ 331 J1)");
			arg = 0;
			if ( field->groupBody->groupList->listLength > 2 )
				arg = field->get(3);
			return ::runOPslots(field->get(1),val,arg);
			}
		// jitPrefix an acU goes through runOPdirect, which seeds a unary and takes the slot fork; the null-deref refusal is a run-time fact, never taken at emit time (SEQ 332 J3)
		if ( ::compare(field->groupBody->tag,"acU") == 0 )
			{
			op = field->get(1);
			if ( ::compare(op->groupBody->tag,"-") == 0 )
				op = ruler->opFields->get("negate");
			if ( ::compare(op->groupBody->tag,"*") == 0 )
				op = ruler->opFields->get("deref");
			val = runOPaccumOperand(field->get(2));
			// valueTarget ++ or -- on a computed value refuses by name on the jit road too (SEQ 365 R0)
			if ( ::refuseValueTarget(op,val) )
				return 0;
			return ::runOPdirect(op,val,0);
			}
		return ::refuse(field,"the accumulator candidate is interpreted only -- under jitting it refuses (SEQ 311 R4)");
		}
	if ( ::compare(field->groupBody->tag,"acU") == 0 )
		{
		op = field->get(1);
		val = runOPaccumOperand(field->get(2));
		if ( ::compare(op->groupBody->tag,"-") == 0 )
			op = ruler->opFields->get("negate");
		if ( ::compare(op->groupBody->tag,"*") == 0 )
			op = ruler->opFields->get("deref");
		// nullDeref a star handed NOTHING refuses by name before opDeref, which reads its operand's body and crashed on a null (SEQ 327 D3); only the star -- `!` of a false compare is a lawful null
		if ( !val )
			if ( op == ruler->opFields->get("deref") )
				return ::refuse(op,"a star on an operand that is nothing -- the inner read yielded null (the accumulator candidate, SEQ 327 D3)");
		// noTarget an operator that is not a unary has no target in a prefix position -- `x &= y` read as `x & (= y)`; refuse it by name, never call it as one (SEQ 347 R4)
		if ( !op->groupBody->flags.isUnary && ::compare(op->groupBody->tag,".") != 0 )
			return ::refuse(op,"an operator in a prefix position with no target -- it is not a unary (SEQ 347 R4)");
		// valueTarget ++ or -- on a computed value -- tempField -- refuses by name (Tony, SEQ 360 R1)
		if ( ::refuseValueTarget(op,val) )
			return 0;
		return op->groupBody->gMethod(val);
		}
	// noStepList each step goes straight to runOPdirect -- no acStep list is built (SEQ 318 c1)
	if ( ::compare(field->groupBody->tag,"acC") == 0 )
		{
		val = field->get(2);
		if ( ::compare(val->groupBody->tag,"acU") == 0 || ::compare(val->groupBody->tag,"acDot") == 0 || ::compare(val->groupBody->tag,"acSub") == 0 || ::compare(val->groupBody->tag,"acC") == 0 )
			val = val->groupBody->gMethod(val);
		// finished the call's operands are finished HERE, as runOP finishes an instruction's: the target followed, the argument followed and invoked
		val = ::followArgument(val);
		if ( val && val->groupBody->flags.isVirtual )
			val = ::copyOf(val);
		arg = 0;
		if ( field->groupBody->groupList->listLength > 2 )
			arg = runOPaccumOperand(field->get(3));
		// callExecutor the call goes straight to opCall; anything uncallable refuses as runOPdirect's ladder would
		// dispatchSeat the call's witness, as runOPdirect gave it before opCall existed (searchNewParseT SNP-0 reads it)
		::measureRuleDispatch(ruler->falseResult,val,arg);
		if ( ::isCallable(val) )
			return ::opCall(val,arg);
		return ::refuseUnknownOperator(ruler->falseResult,val);
		}
	return ::refuse(field,"runOPaccum runs a prefix or a call only -- tiers have their own executors (SEQ 319 c3)");
}

/*  runOPaccumOperand -- one operand, evaluated if it carries an invocation.  */
extern "C" GroupItem *runOPaccumOperand(GroupItem *operand)
{
GroupItem 	*val = ::followArgument(operand);
	if ( val )
		if ( isMethod(val->groupBody->flags.instructType) && val->groupBody->flags.invoke )
			val = val->groupBody->gMethod(val);
	return val;
}

// runOPdirect the FIRE: operands arrive FINISHED (D4); pick the kind, then fire the op, a rule, an action or a method
extern "C" GroupItem *runOPdirect(GroupItem *op, GroupItem *target, GroupItem *arg)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*result = 0;
	// kindlessWriter a kindless local's writer is recorded before anything else -- one in a handed-over statement counts (SEQ 388)
	 if ( ruler->jitting && target && op && ::opIsAssignTier(op) ) ::jitNoteWriter(op,target,arg); 
	// holderWrite a := or <- notes the holder it writes, for its statement's hand-over to record (SEQ 405)
	 if ( ruler->jitting && target && op && ((void*)op->groupBody->gOp == (void*)&opSetGroup || (void*)op->groupBody->gOp == (void*)&opRebind) ) gJitStmtHolderWrites.push_back({gJitStmtMarks.size(), (void*)target->groupBody}); 
	// handedOverEmitsNothing a statement already handed to run time dispatches nothing more at build -- its emitters would be handed nulls (SEQ 384)
	 if ( ruler->jitting && gJitHandOver ) return 0; 
	// storeRuling an armed statement dispatches nothing further -- interpreted only
	if ( ruler->refused )
		if ( !ruler->jitting )
			return 0;
	// perKindPick one spelling, pickKindOP, on both roads; under jitting the pick is EMITTED as a run-time call-through, never made here
	if ( op->groupBody->flags.hasMembers )
		{
		if ( ruler->jitting )
			return jitEmitOpFire(op,arg,target);
		op = ::pickKindOP(op,target,arg);
		}
	// seedBothArms a unary is isUnary and isMethod, never isOperator -- seed on isOperator alone and jitEmitUnary segfaults
	// kindUncarried a binary operator that would consume a value whose kind the jit cannot carry hands its statement to run time; a dot only bakes its target's address, `=` stores its target through a run-time road, and a node in flight has its own run-time road (docket item 3)
	
	if ( ruler->jitting && !gJitLastIsNode && isOperator(op->groupBody->flags.instructType) && (void*)op->groupBody->gOp != (void*)&opDot
	&& ((op->groupBody->gOp != &opAssign && ::jitKindUncarried(target)) || ::jitKindUncarried(arg)) ) {
	::jitHandOver((char*)"an operand whose kind is not a count or a number -- its statement runs at RUN time", op);
	return 0; }
	
	if ( ruler->jitting && (isOperator(op->groupBody->flags.instructType) || op->groupBody->flags.isUnary) )
		::jitSeedOperands(target,arg);
	// slotNeedsBoth an emitter slot reads both operands: a side the build cannot see goes to run time, never into the emitter (SEQ 384)
	
	if ( ruler->jitting && op->groupBody->gJitEmitter && !op->groupBody->flags.isUnary && (!target || !arg) ) {
	::jitHandOver((char*)"an operator with a side the build cannot see -- its statement runs at RUN time", op);
	return 0; }
	
	// slotFork an op with an emitter slot is migrated, one without cannot tell -- there is no default emitter, ever
	 if ( ::jitSlotTaken(op) ) return op->groupBody->gJitEmitter(arg,target); 
	// noBuildRun a dispatch that would RUN its interpreted body at build goes to run time instead (SEQ 384, Tony: compiling has no side effects)
	if ( ruler->jitting && !jitOpEmits(op,target) )
		{
		if ( isOperator(op->groupBody->flags.instructType) || isMethod(op->groupBody->flags.instructType) )
			jitHandOver("an operator with no emitter -- its statement runs at RUN time",op);
		else	jitHandOver("a command call -- its statement runs at RUN time",target);
		return 0;
		}
	// dispatchSeat which node the name reached, and which arm the fork will take
	::measureRuleDispatch(op,target,arg);
	// callExecutor an operator fires as itself; anything else whose target is callable is a CALL, and opCall is its one executor (SEQ 318 c2)
	if ( isOperator(op->groupBody->flags.instructType) )
		result = op->groupBody->gOp(arg,target);
	else
	if ( isMethod(op->groupBody->flags.instructType) )
		result = op->groupBody->gMethod(target);
	else
	if ( ::isCallable(target) )
		result = ::opCall(target,arg);
	else	result = ::refuseUnknownOperator(op,target);
	return result;
}

// runOPslots the INSTRUCTION's half: FINISH the operands -- follow, refuse a rebound argument, invoke -- then fire (SEQ 318 c1)
extern "C" GroupItem *runOPslots(GroupItem *op, GroupItem *target, GroupItem *arg)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	// rawSlots declared in passthrough: tok prunes a local that only a passthrough reads (bear-trap 13)
	 GroupItem *rawOp = op, *rawTarget = target, *rawArg = arg; 
	// argBinding argument is a BINDING: a rebind of it refuses, then an isArgument operand yields what it holds
	if ( ::refuseArgRebind(op,target) )
		return 0;
	target = ::followArgument(target);
	arg = ::followArgument(arg);
	// storeRuling an armed statement dispatches nothing further, stores included -- interpreted only, emit time must reach every statement
	if ( ruler->refused )
		if ( !ruler->jitting )
			return 0;
	if ( op->groupBody->flags.instructType && isMethod(target->groupBody->flags.instructType) && target->groupBody->flags.invoke )
		target = target->groupBody->gMethod(target);
	if ( arg )
		if ( isMethod(arg->groupBody->flags.instructType) && arg->groupBody->flags.invoke )
			arg = arg->groupBody->gMethod(arg);
	// listOperand a list operand is never resolved here -- that would hand the list operators a copy
	// virtualFork UNGATED ON PURPOSE -- gated on defining, the bytecode emit path would mutate the shared prototype
	if ( target && target->groupBody->flags.isVirtual )
		target = ::copyOf(target);
	// termCallIntercept jitting, the term call REPLAYS this instruction at run time, so it bakes the RAW slots -- the ladder's own conditions, read here (SEQ 318 c1)
	if ( ruler->jitting && !op->groupBody->flags.hasMembers && !isOperator(op->groupBody->flags.instructType) && !isMethod(op->groupBody->flags.instructType) )
		if ( ::callIsRule(target) )
			{
			
			if ( !::jitSlotTaken(op) ) {
			if ( op->groupBody->flags.isUnary )   ::jitSeedOperands(target,arg);
			::measureRuleDispatch(op,target,arg);
			return ::jitEmitTermCall(rawOp,rawTarget,rawArg); }
			
			}
	return ::runOPdirect(op,target,arg);
}

// runRule the drive step with no report; a generated root hands back its label, and the kant caller gets one bit
extern "C" GroupItem *runRule(GroupItem *field, GroupItem *rule)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*result = ::driveStep(field,rule,0,0);
	// oneBit a generated root hands driveStep its LABEL; the kant caller still gets the chain's truth (ruling c')
	if ( rule->groupBody->flags.hasNewParse && result && result != ruler->falseResult )
		return ruler->trueResult;
	return result;
}

// saveLocalFields save an action's argument and locals before a nested call, so each activation starts from its own state
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
	// frameFloor null pushed so restore stops at ITS OWN floor
	recurseSTAK->push(0);
	while ( grup = action->next(grup) )
		if ( (grup->groupBody->flags.isArgument || grup->groupBody->flags.isLocal) && !grup->groupBody->flags.noPrint )
			{
			body = new GroupBody();
			*body = *grup->groupBody;
			if ( !grup->groupBody->flags.isArgument )
				{
				grup->clearData();
				grup->groupBody->groupList = 0;
				grup->groupBody->flags.hasAttributes = 0;
				grup->groupBody->flags.hasMembers = 0;
				}
			// identityPair the field goes on with its body
			recurseSTAK->push(grup);
			recurseSTAK->push(body);
			}
}

// setCompiledMethod set the block's method by passing the method name to dlsym
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

// setFile point the buffer field's buffer at the named file
extern "C" void setFile(GroupItem *bufField, char *name)
{
	if ( isBUFFER(bufField->groupBody->flags.data) )
		bufField->getBuffer()->setFile(name);
}

// setFileOp the modedOP shim over Buffer.setFile: doc modedOP "path" points doc's buffer at a file -- opAssign's (argument, target) shape
extern "C" GroupItem *setFileOp(GroupItem *argument, GroupItem *target)
{
	if ( isBUFFER(target->groupBody->flags.data) )
		target->getBuffer()->setFile(argument->getText());
	return target;
}

// setGroupField THE ONE WRITER OF A groupField BY NUMBER (SEQ 295 R3): x :. name hands it 1, x.name = v hands it v; a flag takes value != 0, an enum kind is set by non-zero and cleared by zero only when it holds that kind; 0 back when the number has no write case; the read-only accessors (43, 44) have none, on purpose
extern "C" int setGroupField(GroupItem *target, int fieldNo, int value)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
int 		on = 0;
	if ( !target )
		return 0;
	if ( value )
		on = 1;
	// invokeWrite  case 11 is the write half of opDot's case 11; without it x.invokE = 1 and x :. invokE fell to default and wrote nothing at exit 0 (2026-10-09)
	switch (fieldNo)
		{
		case 11:
			target->groupBody->flags.invoke = on;
			break;
		case 21:
			target->groupBody->flags.isPercent = on;
			break;
		case 25:
			target->groupBody->flags.isVirtual = on;
			break;
		case 26:
			target->groupBody->flags.mergeOn = on;
			break;
		case 29:
			target->groupBody->flags.noPrint = on;
			break;
		case 31:
			target->groupBody->flags.byRef = on;
			// hasNewParse the artifact gate: a generated parse body parks as a noPrint member on the shared child list, and this flag says one is there (2026-08-24)
			break;
		case 32:
			if ( on )
				target->groupBody->flags.binType = 3;
			else
			if ( target->groupBody->flags.binType == 3 )
				target->groupBody->flags.binType = 0;
			break;
		case 33:
			if ( on )
				target->groupBody->flags.binType = 1;
			else
			if ( target->groupBody->flags.binType == 1 )
				target->groupBody->flags.binType = 0;
			break;
		case 40:
			if ( on )
				target->groupBody->flags.actionType = 2;
			else
			if ( target->groupBody->flags.actionType == 2 )
				target->groupBody->flags.actionType = 0;
			break;
		case 41:
			target->groupBody->flags.hasNewParse = on;
			break;
		case 46:
			target->groupBody->flags.fLAG = on;
			// isActionWrite the write half of opDot case 408, as a LITERAL -- `target.isAction = true` would be right here only by coincidence
			break;
		case 408:
			if ( on )
				target->groupBody->flags.actionType = 1;
			else
			if ( target->groupBody->flags.actionType == 1 )
				target->groupBody->flags.actionType = 0;
			break;
		case 411:
			ruler->lastIndent = value;
			// compileReadOnly processingCodE reads the nearest drive floor; a compile marks its own, so a kant write has no road (SEQ 297 R2)
			break;
		case 412:
			::refuse(target,"processingCodE is read-only -- it reads the nearest drive floor, which processCode marks; there is no kant write (SEQ 297)");
			break;
		default:
			return 0;
		}
	return 1;
}

/*******************************************************************************
    A cOMMANDs method associated with commands like hash and buffer that set
    the appropriate value for the grup passed in.
*******************************************************************************/
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

// setMark the setMark command: advance the source buffer's mark by markOffset, or set it that far from the start; an offset past the current end refuses
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

// setParse the top-level entry, and the only one incant calls: reset the per-walk mark, then walk
extern "C" GroupItem *setParse(GroupItem *field)
{
	// perWalkNotPerProcess the mark breaks the grammar's cycle WITHIN one walk; outliving it refuses a second root over shared nodes
	::clearWalked(field);
	return setParseWalk(field);
}

// setParseWalk classify each face's parse method; recurses into itself, never back through setParse
extern "C" GroupItem *setParseWalk(GroupItem *field)
{
RuleStuff 	*ruleStuff = field->getRStuff();
	// tokenSkip a member with isRule 0 is a token -- matched, never entered; isRule 1 with no rStuff is a wound and refuses
	if ( !ruleStuff )
		{
		if ( !field->isRuleTerm() )
			{
			if ( GroupControl::groupController->groupRules->debugAllRules )
				::fprintf(stderr,"setParseWalk: token %s, not entered\n",field->groupBody->tag);
			return 0;
			}
		return ::refuse(field,"setParse: the field passed in has no rStuff");
		}
	// newRoadTarget every face with rStuff, before the installed and re-entry exits -- isTarget is what promotes and RETAGS a member's label (09-22 retag ruling, SEQ 192)
	setTargetFlag(ruleStuff,field);
	// installedIsDone an rStuff carrying hasNewParse is installed, and the walk leaves it alone
	if ( field->groupBody->flags.hasNewParse )
		{
		if ( GroupControl::groupController->groupRules->debugAllRules )
			::fprintf(stderr,"setParseWalk: already installed %s, leaving it alone\n",field->groupBody->tag);
		return 0;
		}
	// silentReEntry the grammar is a DAG, so re-entry is routine -- return without descending, never refuse
	if ( field->groupBody->flags.parseWalked )
		{
		if ( GroupControl::groupController->groupRules->debugAllRules )
			::fprintf(stderr,"setParseWalk: re-entry on %s, not descending\n",field->groupBody->tag);
		return 0;
		}
	field->groupBody->flags.parseWalked = 1;
	// actionMethodRemoved the walk writes gMethod and parseMethod and NOTHING ELSE -- the action is the builtinActoR setActions publishes at definition
	// realTermNotAList a FIELD with nothing but noPrint artifacts is a DATA rule: hasTraits and hasMembers ignore artifacts, groupList does not. The CONVERSION predicate is NOT this test -- it still asks the group's real groupList.
	// upToIsTheReferences a reference's { } is ITS fact, never the rule's -- only an inline definition (not a copy) classifies from its own overTo (F-O23)
	if ( (upTo(ruleStuff->overTo) || upToOver(ruleStuff->overTo)) && !field->ruleOf )
		field->groupBody->gParseMethod = ::parseUpTo;
	else
	if ( isBIN(field->groupBody->flags.binType) || isREGISTRY(field->groupBody->flags.binType) )
		field->groupBody->gParseMethod = ::parseContainer;
	else
	if ( field->groupBody->flags.isCondition )
		field->groupBody->gParseMethod = ::parseCondition;
	else
	if ( parseACTION(field->groupBody->flags.methodType) )
		field->groupBody->gParseMethod = ::parseAction;
	else
	if ( field->groupBody->flags.hasTraits || field->groupBody->flags.hasMembers )
		field->groupBody->gParseMethod = ::parseRule;
	else
	if ( field->groupBody->flags.data )
		switch (field->groupBody->flags.data)
			{
			case 2:
				field->groupBody->gParseMethod = ::parseCharacter;
				break;
			case 3:
				field->groupBody->gParseMethod = ::parseSet;
				break;
			case 6:
				field->groupBody->gParseMethod = 0;
				break;
			default:
				field->groupBody->gParseMethod = ::parseString;
			}
	else
	if ( field->groupBody->gMethod )
		field->groupBody->gParseMethod = ::parseAction;
	else	field->groupBody->gParseMethod = ::parseString;
	::measureParseClass(field);
	if ( field->groupBody->flags.hasTraits || field->groupBody->flags.hasMembers )
		{
		GroupItem 	*grup = 0;
		while ( grup = field->next(grup) )
			{
			if ( grup->groupBody->flags.noPrint )
				continue;
			else	::setParseWalk(grup);
			}
		}
	// loopPerOccurrence a rule body's method slot is SHARED by every occurrence, so every rule body goes through parseLoop and each occurrence loops to its OWN max (ruling A -- reverted on trunk 2026-09-27 for want of this branch's staged compile and definer fix, SEQ 211-216)
	if ( ::repeatsInLoop(field) )
		field->setMethod(::parseLoop);
	else	field->setMethod(field->groupBody->gParseMethod);
	// flagFollowsInstall hasNewParse says a method is there to fire, so it is raised here and never at entry -- isGROUP installs null
	if ( field->groupBody->gMethod )
		field->groupBody->flags.hasNewParse = 1;
	return 0;
}

// setRuleAction link the action the block references and set its method type -- on the rule the block names, else on the block; returns the rule
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
				item->setParseAction(item->groupBody->gMethod);
			}
		else	::fprintf(stderr,"setRuleAction: could not set action for %s\n",block->groupBody->tag);
		}
	else	::fprintf(stderr,"setRuleAction: could not set action target\n");
	return item;
}

// setTargetFlag the new road's isTarget and nothing else -- getWhatFollows' target rule, run over every face at generation
extern "C" void setTargetFlag(RuleStuff *stuff, GroupItem *field)
{
	
	if ( !stuff || !field ) return;
	GroupItem *r = field;
	int computed = 0;
	if ( isMember(r->options.affiliation) && r->parent && !r->parent->groupBody->flags.binType )
	computed = 1;
	else if ( isEmbedded(r->options.affiliation) )
	{ if ( (r->groupBody->flags.data && r->groupBody->flags.data < 4) || stuff->max == 1 ) computed = 1; }
	::measureTargetAgree(stuff, computed, field);
	if ( computed ) stuff->isTarget = 1;
	
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
	Immediate method for the stop command.
*******************************************************************************/
extern "C" GroupItem *stopParsingInput(GroupItem *input)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
int 		bailing = 0;
	// measureStopCaller which verb, and which node the empty () handed back
	::measureStopCaller(input);
	// twoVerbs bail LEAVES THE FILE, stop LEAVES THE PROCESS -- never exit(0) on a bail
	if ( input )
		if ( ::compare(input->groupBody->tag,"bail") == 0 )
			bailing = 1;
	/*  THE DIVERT IS THE THING bail ENDS, so it is the OUTER question. NUL the mark
	BEFORE the pop: after it, atRuleMark is the PARENT's and truncating there
	would end the includer instead.
	⚠ A BAIL WITH NO DIVERTED INPUT DOES NOTHING -- it does not fall through to
	stop's road, because that block is gated on !bailing. Ruled to stay so
	unless it causes a problem (Tony, 2026-09-16).
	Commands.stop.twoVerbs  */
	if ( ruler->inputDiverted )
		{
		ruler->popInput();
		::printf("\nstop: ending input divert\n");
		}
	if ( !bailing )
		{
		*ruler->atRuleMark = 0;
		ruler->endParse = 1;
		::printf("\nstop: end parsing\n");
		::exit(0);
		}
	return input;
}

extern "C" GroupItem *testOP(GroupItem *field)
{
GroupItem 	*result = 0;
GroupItem 	*op = field->get(1);
GroupItem 	*argument = field->get(3);
	if ( argument && ::compare(argument->groupBody->tag,"instruct") == 0 )
		argument = ::testOP(argument);
GroupItem 	*target = field->get(2);
	if ( target && ::compare(target->groupBody->tag,"instruct") == 0 )
		target = ::testOP(target);
	if ( op->groupBody->flags.isUnary )
		result = op->groupBody->gMethod(argument);
	else	result = op->groupBody->gOp(argument,target);
	return result;
}

/*******************************************************************************
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
	COMPILE ONCE (SEQ 385 R1): an action the JIT already holds goes to
	jitRunAction too, which answers from its cache -- the first parse consumed
	isCoded, so without this a second testing(x) fell to jitRunIfTest.
	NB: keep this body free of `//` comments — they bleed field-resolution into
	the following extern (unWrap). Doc goes here, in the block.
*******************************************************************************/
extern "C" GroupItem *testing(GroupItem *input)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	
	if ( input && jitCacheFind(input->groupBody) )
	return ::jitRunAction(input) ? ruler->trueResult : 0;
	
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
	if ( !rule )
		{
		::fprintf(stderr,"treeOf: no ScafOUT on the search list\n");
		return 0;
		}
	// oneDoor a drive goes through driveStep -- its floor keeps a failed pass off the caller's input (P3a routing, SEQ 185)
	result = ::driveStep(argument,rule,0,0);
	::fprintf(stderr,"TREE %s\n",argument->getText());
	if ( result )
		::showTree(result,"    ");
	else	::fprintf(stderr,"    (parse FAILED)\n");
	return ruler->trueResult;
}

// truthOf THE OPERAND TRUTHINESS CONTRACT, in ONE place (Tony, 2026-08-11): absent is false, a numeric node answers by its value, any other node is true by presence
extern "C" int truthOf(GroupItem *field)
{
	if ( !field )
		return 0;
	if ( isCOUNT(field->groupBody->flags.data) || isNUMBER(field->groupBody->flags.data) )
		return field->groupBody->gCount != 0;
	return 1;
}

// unMark clear the buffer field's mark
extern "C" void unMark(GroupItem *bufField)
{
	if ( isBUFFER(bufField->groupBody->flags.data) )
		bufField->getBuffer()->unMark();
}

/*******************************************************************************
	Rule action for unWrap used in the gXpress generator action.
*******************************************************************************/
extern "C" GroupItem *unWrap(GroupItem *result)
{
GroupItem 	*grup = result;
	if ( isGROUP(grup->groupBody->flags.data) )
		while ( isGROUP(grup->groupBody->flags.data) )
			grup = grup->getGroup();
	return grup;
}

/*  unaryIsAccess -- THE UNARY CLASS PREDICATE, one question asked by two arms. ACCESS
    class binds to the PRIMARY, before the postfix chain; VALUE class binds to the
    chain's RESULT. The class is a REGISTRATION (`accessClass` in incant/setup) and not
    a list here, so adding one is an edit to setup and never to this file.
    ⚠ A HAND, NOT A WITNESS -- no measure prefix, and it is asked for effect on control
    flow.  */
extern "C" int unaryIsAccess(GroupItem *unary)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*reg = 0;
	if ( !unary )
		return 0;
	reg = ruler->opFields->get(unary->groupBody->tag);
	if ( !reg )
		return 0;
	if ( reg->get("accessClass") )
		return 1;
	return 0;
}

// verdictCount add one named count to a verdict
extern "C" void verdictCount(GroupItem *verdict, char *name, int value)
{
GroupItem 	*num = new GroupItem(name);
	num->setCount(value);
	verdict->addAttribute(num);
}

// wrapped quote output text for printing when it holds a space
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
	gParseActive = 0;
	atRuleMark = 0;
	ruleSTUFF = 0;
	currentDefine = 0;
	currentMETHOD = 0;
	currentRegistry = 0;
	debugJunk = 0;
	baseRegistryList = 0;
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
	branchKind = 0;
	chanBinds = 0;
	chanSame = 0;
	inputFloor = 0;
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
	compiling = 0;
	debugAllRules = 0;
	debugGuards = 0;
	defining = 0;
	divertToRule = 0;
	endParse = 0;
	ignoreThis = 0;
	ignoreNoPrint = 0;
	ignoreNoRoom = 0;
	inputDiverted = 0;
	isPERCENT = 0;
	isPRINTING = 0;
	isRELATIVE = 0;
	isRigorous = 0;
	noSkipping = 0;
	parseTrace = 0;
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
		if ( inCompile() || defining )
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
					if ( inCompile() )
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
						if ( inCompile() )
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
    inCompile -- is the parse I am inside a compile? The NEAREST drive floor
    answers: a compile's drive (processCode, compileIn) writes its owner on the
    floor it pushes, and a drive pushed inside a compile is its own root, with
    no owner (SEQ 297 R1). The pop of that floor is the restore, so an unwound
    compile cannot leave it set. floorOwner is the owner itself (SEQ 299 R3).
*******************************************************************************/
GroupItem *GroupRules::floorOwner()
{
ParseActivation 	*top = gParseActive;
	while ( top && !top->isFloor )
		top = top->prev;
	if ( top )
		return top->compileOwner;
	return 0;
}

int GroupRules::inCompile()
{
	if ( floorOwner() )
		return 1;
	return 0;
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

// stuffOf a record's stuff is its instance's own, derived and never stored (stroke 1.3) -- a floor has no instance, so none
RuleStuff *GroupRules::stuffOf(ParseActivation *rec)
{
	if ( rec && rec->instance )
		return rec->instance->getRStuff();
	return 0;
}
/*	Warning: the following methods were referenced but not declared
	read(int,char*,long)
	driveStep(GroupItem*,GroupItem*,GroupItem*,null*)
	accFold(GroupItem*)
	accFold(GroupItem*)
	accCompare(GroupItem*)
	accLogic(GroupItem*)
	interpretXPaccumWrap(GroupItem*,GroupItem*)
	accBare(GroupItem*,GroupItem*)
	interpretXPaccumWrap(GroupItem*,GroupItem*)
	clearRefusal(GroupItem*)
	clearRefusal(GroupItem*)
	jitHandOver(char*,GroupItem*)
	jitHandOver(char*,GroupItem*)
	jitHandOver(char*,GroupItem*)
	jitHandOver(char*,GroupItem*)
	jitHandOver(char*,GroupItem*)
	jitHandOver(char*,GroupItem*)
	jitHandOver(char*,GroupItem*)
	measurePlusEQWrite(GroupItem*)
	measureKindArm(char*,GroupItem*)
	measureKindArm(char*,GroupItem*)
	measureKindArm(char*,GroupItem*)
	measureKindArm(char*,GroupItem*)
	measureKindArm(char*,GroupItem*)
	measureKindArm(char*,GroupItem*)
	measurePlusPlusWrite(GroupItem*)
	measurePlusPlusWrite(GroupItem*)
	interpretXPaccumWrap(GroupItem*,int)
	floor(double)
*/
