#include <Cocoa/Cocoa.h>
#include <dirent.h>
#include <dlfcn.h>
#include <math.h>
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
	if ( token && token->groupBody->registry == GroupControl::groupController->groupRules->keyWords )
		return 0;
	return input;
}

/*******************************************************************************
	The BlocK rule action.
*******************************************************************************/
extern "C" GroupItem *aCTionBlocK(GroupItem *input)
{
GroupItem 	*grup = 0;
GroupItem 	*result = 0;
	while ( grup = input->next(grup) )
		{
		if ( isMethod(grup->groupBody->flags.instructType) )
			result = grup->groupBody->gMethod(grup);
		else	result = grup;
		if ( result && result->groupBody->flags.isBranch )
			break;
		}
	if ( result && isGROUP(result->groupBody->flags.data) )
		result = result->groupBody->gGroup;
	return result;
}

/*******************************************************************************
	Rule action for Braced rule.
        Braced      "["- ExpressioN "]"-;
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
	return arg;
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
GroupItem 	*label = rule->rStuff->label;
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
	Immediate method for DEBUG rule
        DEBUG       "debug"- followedBy rules?=NamE+;
*******************************************************************************/
extern "C" GroupItem *aCTionDEBUG(GroupItem *input)
{
GroupItem 	*lastRule = 0;
GroupItem 	*rules = input->getLabelGroup("rules");
GroupItem 	*subrule = 0;
GroupItem 	*GUARD = 0;
GroupItem 	*grup = 0;
	if ( rules )
		while ( grup = rules->next(grup) )
			{
			if ( grup->groupBody->flags.isRule )
				{
				if ( GUARD )
					grup->groupBody->flags.debugGuard = 1;
				lastRule = grup;
				grup->groupBody->flags.debugged = 1;
				}
			else
			if ( ::compare(grup->getText(),"GUARD") == 0 )
				{
				GUARD = GroupControl::groupController->groupRules->trueResult;
				continue;
				}
			else
			if ( lastRule && (subrule = lastRule->get(grup->groupBody->tag)) )
				{
				subrule->groupBody->flags.debugged = !subrule->groupBody->flags.debugged;
				if ( GUARD )
					subrule->groupBody->flags.debugGuard = !subrule->groupBody->flags.debugGuard;
				}
			else	::fprintf(stderr,"aCTionDebuG: %s is not a rule\n",grup->groupBody->tag);
			}
	else	GroupControl::groupController->groupRules->debugAllRules = !GroupControl::groupController->groupRules->debugAllRules;
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
	do	{
		result = StatemenT->groupBody->gMethod(StatemenT);
		if ( result->groupBody->flags.isBranch )
			{
			if ( isContinue(result->groupBody->flags.isBranch) )
				continue;
			else
			if ( isReturn(result->groupBody->flags.isBranch) )
				return result;
			break;
			}
		}
	while ( ExpressioN->groupBody->gMethod(ExpressioN) );
	if ( !result )
		result = GroupControl::groupController->groupRules->falseResult;
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
			if ( NewGroup->groupBody->registry != ruler->currentRegistry )
				NewGroup = ruler->currentRegistry->addMember(NewGroup);
			if ( ruler->currentRegistry->groupBody->flags.isRule )
				{
				if ( !NewGroup->groupBody->flags.binType )
					NewGroup->groupBody->flags.isRule = 1;
				if ( !NewGroup->rStuff )
					NewGroup->rStuff = new RuleStuff(NewGroup);
				}
			}
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
					if ( ::compare(item->groupBody->tag,"argument") == 0 )
						item->groupBody->flags.isArgument = 1;
					if ( NewGroup->groupBody->flags.isMacro )
						item->groupBody->flags.noPrint = 1;
					item->groupBody->flags.isInitialized = 1;
					if ( NewGroup->groupBody->flags.isRule && !item->groupBody->flags.binType )
						item->groupBody->flags.isRule = 1;
					if ( item->groupBody->flags.isLiteral )
						{
						grup = new GroupItem(item->getText());
						if ( item->rStuff )
							{
							grup->rStuff = item->rStuff;
							grup->rStuff->ruleName = grup->groupBody->tag;
							}
						}
					else	grup = item;
					grup = NewGroup->addAttribute(grup);
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
				if ( newMember->groupBody->flags.isRule && newMember->rStuff && (!newMember->groupBody->flags.data || newMember->groupBody->flags.data > 3) )
					if ( newMember->rStuff->max != 1 || newMember->rStuff->min != 1 )
						newMember->rStuff = new RuleStuff(newMember);
				}
		}
	/***********************************************************************
	If NewGroup is a rule check to see if it has a rule method .
	Note: method is fired even if there is an incant action associated with
	the rule, in which case the method is expeced to run the action.
	Also makes sure if NewGroup isGROUP the group is made a rule
	***********************************************************************/
	if ( NewGroup->groupBody->flags.isRule )
		{
		if ( !isREGISTRY(NewGroup->groupBody->flags.binType) && !isMethod(NewGroup->groupBody->flags.instructType) )
			{
			char 	*methodName = ::concat(2,"aCTion",NewGroup->groupBody->tag);
			void 	*methodAddress = 0;
			if ( methodAddress = ::dlsym(RTLD_SELF,methodName) )
				NewGroup->groupBody->gMethod = (GroupItem*(*)(GroupItem*))methodAddress;
			else
			if ( isCoded(NewGroup->groupBody->flags.actionType) )
				NewGroup->setMethod(::processAction);
			::free(methodName);
			if ( NewGroup->groupBody->gMethod )
				{
				NewGroup->groupBody->flags.instructType = 1;
				NewGroup->groupBody->flags.methodType = 1;
				}
			}
		}
	input->clear();
	NewGroup->groupBody->flags.isInitialized = 1;
	if ( NewGroup->groupBody->registry && !NewGroup->parent )
		NewGroup->parent = ruler->currentRegistry;
	input->setGroup(NewGroup);
	return input;
}

/*******************************************************************************
	ExpressioN rule immediate action. Note: operators including unary operators
    have to preceed their arguments.
        ExpressioN      Token+ SemI?- defer;
*******************************************************************************/
extern "C" GroupItem *aCTionExpressioN(GroupItem *xpList)
{
GroupItem 	*op = 0;
GroupItem 	*target = 0;
GroupItem 	*arg = 0;
GroupItem 	*xl = 0;
GroupItem 	*token = 0;
	if ( GroupControl::groupController->groupRules->jitting )
		{
		GroupItem 	*grup = 0;
		GroupItem 	*result = 0;
		if ( xpList->groupBody->groupList->listLength == 1 )
			{
			arg = xpList->groupBody->groupList->firstInList;
			if ( isGROUP(arg->groupBody->flags.data) && !arg->groupBody->flags.isArgument )
				arg = arg->getGroup();
			if ( arg->groupBody->flags.isLiteral )
				::jitSeedLiteral(arg);
			xpList->clear();
			xpList->setGroup(arg);
			return xpList;
			}
		while ( token = xpList->prior(token) )
			{
			grup = token;
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
				if ( arg )
					if ( target )
						{
						if ( target->groupBody->flags.isLiteral )
							::jitSeedLiteral(target);
						else	::jitSeedField(target);
						if ( arg->groupBody->flags.isLiteral )
							::jitSeedLiteral(arg);
						else	::jitSeedField(arg);
						result = op->groupBody->gOp(arg,target);
						op = 0;
						target = 0;
						arg = result;
						}
			}
		xpList->clear();
		xpList->setGroup(arg);
		return xpList;
		}
	if ( GroupControl::groupController->groupRules->generating )
		{
		GroupItem 	*revisedList = new GroupItem("revisedList");
		GroupItem 	*grup = 0;
		GroupItem 	*store = 0;
		GroupItem 	*tgt = 0;
		if ( xpList->groupBody->groupList->listLength == 1 )
			{
			arg = xpList->groupBody->groupList->firstInList;
			if ( isGROUP(arg->groupBody->flags.data) && !arg->groupBody->flags.isArgument )
				arg = arg->getGroup();
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
	if ( xpList->groupBody->groupList->listLength == 1 )
		{
		arg = xpList->groupBody->groupList->firstInList;
		if ( isGROUP(arg->groupBody->flags.data) && !arg->groupBody->flags.isArgument )
			arg = arg->getGroup();
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
					xl = new GroupItem("xl");
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
					xl = new GroupItem("xl");
					xl->addMember(op);
					xl->addMember(target);
					xl->addMember(arg);
					xl->setMethod(::runOP);
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

/*******************************************************************************
	Runs the action associated with a for statement
        Looper=ANYtoken;
        LoopRestrict:
            loopOnAttributes="attributes";
            loopOnMembers="members";;
        FOR         for- followedBy Looper in- reversE="<-"? ExpressioN SemI- LoopRestrict? BLOCKing- StatemenT defer;
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
		LoopOn = LoopOn->getGroup();
	LoopRestrict = ruler->lastREF->getGroup();
	while ( grup = reversE ? LoopOn->prior(grup) : LoopOn->next(grup) )
		{
		result = 0;
		Looper->setGroup(grup);
		if ( restrict && grup->options.affiliation != restrict )
			continue;
		if ( !LoopOn->groupBody->flags.byRef )
			ruler->lastREF->setGroup(grup);
		result = StatemenT->groupBody->gMethod(StatemenT);
		if ( result->groupBody->flags.byRef )
			grup = result->priorInParent;
		if ( result->groupBody->flags.isBranch )
			{
			if ( isContinue(result->groupBody->flags.isBranch) )
				continue;
			else
			if ( isReturn(result->groupBody->flags.isBranch) )
				return result;
			break;
			}
		}
	if ( !result )
		result = ruler->falseResult;
	if ( LoopRestrict )
		if ( !LoopRestrict->groupBody->flags.byRef )
			ruler->lastREF->setGroup(LoopRestrict);
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
	::printf("Rule %s\n",input->groupBody->tag);
	::printf("\tFailed at:\t%s\n",::getDebugText(input->rStuff->failedAt,40));
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
	if ( isMethod(result->groupBody->flags.instructType) )
		result = result->groupBody->gMethod(result);
	else	result = ExpressioN;
	if ( result && result->groupBody->flags.isInitialized )
		result = StatemenT->groupBody->gMethod(StatemenT);
	else
	if ( ElsE )
		result = ElsE->groupBody->gMethod(ElsE);
	if ( !result )
		result = GroupControl::groupController->groupRules->falseResult;
	return result;
}

/***************************************************************************
    NamE rule action
***************************************************************************/
extern "C" GroupItem *aCTionNamE(GroupItem *input)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*action = ruler->currentMETHOD;
GroupItem 	*result = 0;
char 		*arg = input->getText();
	result = GroupControl::groupController->locateInMethod(arg);
	if ( !result )
		if ( ruler->currentRegistry == ruler->opFields || ruler->alphaSet->contains(*arg) )
			{
			result = new GroupItem(arg);
			if ( ruler->processingCode )
				{
				result = action->addAttribute(result);
				result->groupBody->flags.isLocal = 1;
				}
			}
	input->setGroup(result);
	return input;
}

/*******************************************************************************
	immediate method for the incant Number rule.
        NumbeR=[0-9]+               FloaT? tokenize:
            HeX='0'                 x=[xX] value=[0-9a-fA-F]+ tokenize;;
        FloaT='.'                   float=[0-9]+ PoweR?;
*******************************************************************************/
extern "C" GroupItem *aCTionNumbeR(GroupItem *input)
{
char 	*arg = input->getText();
	if ( arg )
		{
		GroupItem 	*FloaT = input->getLabelGroup("FloaT");
		if ( FloaT )
			input->setNumber(::atof(arg));
		else	input->setCount(::atoi(arg));
		input->groupBody->flags.isLiteral = 1;
		}
	return input;
}

/*******************************************************************************
	Rule action for Parens rule.
        Braced      "("- ExpressioN? ")"-;
*******************************************************************************/
extern "C" GroupItem *aCTionParens(GroupItem *input)
{
GroupItem 	*ExpressioN = input->getLabelGroup("ExpressioN");
	if ( ExpressioN )
		{
		input->clear();
		input->setGroup(ExpressioN);
		}
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
GroupItem 	*command = input->groupBody->groupList->firstInList;
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
			if ( isGROUP(result->groupBody->flags.data) && !result->groupBody->flags.isArgument )
				result = result->getGroup();
			if ( FormaT )
				result->addMember(FormaT);
			revisedList->addMember(result);
			}
		input->setGroup(revisedList);
		return input;
		}
Buffer 		*buffer = (Buffer*)ruler->bufferSTAK->pop();
	if ( !buffer )
		buffer = new Buffer("print buffer");
	ruler->isPRINTING = 0;
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
	if ( *command->groupBody->tag == 'p' )
		return ::opPrint(input,buffer);
	else	return ::opString(command,buffer);
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
				grup->setGroup(field);
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
RuleStuff 	*ruleStuff = input->rStuff;
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
	TokenXP returns a token or a token expression.
*******************************************************************************/
extern "C" GroupItem *aCTionTokenXP(GroupItem *xpress)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*arg = 0;
GroupItem 	*op = 0;
GroupItem 	*UnaryOPS = xpress->getLabelGroup("UnaryOPS");
GroupItem 	*InvokeArg = xpress->get("InvokeArg");
GroupItem 	*ANYtoken = xpress->get("ANYtoken");
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
			else	op = ruler->falseResult;
			if ( isGROUP(InvokeArg->groupBody->flags.data) )
				arg = InvokeArg->getGroup();
			if ( !arg )
				arg = InvokeArg;
			xpress->addAttribute(op);
			xpress->addAttribute(ANYtoken);
			xpress->addAttribute(arg);
			}
		xpress->groupBody->flags.invoke = 1;
		}
handleUnary:
	if ( UnaryOPS )
		{
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
		if ( trait->rStuff )
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
		if ( DatA->rStuff )
			DatA = new GroupItem(DatA);
		else	DatA->setRuleStuff();
		if ( Modifier )
			::modify(DatA,Modifier->getText());
		if ( Limit )
			::setLimits(DatA,Limit);
		DatA->groupBody->flags.isRule = 1;
		}
	if ( DatA->groupBody->flags.isRule || DatA->groupBody->registry == GroupControl::groupController->groupRules->opFields )
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
GroupItem 	*result = 0;
	while ( ExpressioN->groupBody->gMethod(ExpressioN) )
		if ( result = StatemenT->groupBody->gMethod(StatemenT) )
			{
			if ( result->groupBody->flags.isBranch )
				{
				if ( isContinue(result->groupBody->flags.isBranch) )
					continue;
				else
				if ( isReturn(result->groupBody->flags.isBranch) )
					return result;
				break;
				}
			}
		else	break;
	if ( !result )
		result = GroupControl::groupController->groupRules->falseResult;
	return result;
}

/*******************************************************************************
	Xpress rule method.
*******************************************************************************/
extern "C" GroupItem *aCTionXpress(GroupItem *input)
{
GroupItem 	*ExpressioN = input->getLabelGroup("ExpressioN");
	if ( !GroupControl::groupController->groupRules->processingCode && ExpressioN->groupBody->gMethod )
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

/***************************************************************************
	Register one or more directives on a target action and splice each newly
	registered one into the target's BlocK. opReplace-shaped: list-recurse via
	prior(), single registration per directive. Idempotent: a directive already
	in the target's DiRs list is not registered or spliced again, so a re-apply
	or double-trigger cannot stack a second copy. The target's executed BlocK is
	built once and cached, so a one-time splice persists across later runs.
***************************************************************************/
extern "C" GroupItem *applyDirectives(GroupItem *argument, GroupItem *target)
{
GroupItem 	*grup = 0;
GroupItem 	*DiRs = 0;
	if ( isLIST(argument->groupBody->flags.binType) )
		while ( grup = argument->prior(grup) )
			::applyDirectives(grup,target);
	else {
		DiRs = target->get("DiRs");
		if ( !DiRs )
			{
			DiRs = target->addString("DiRs");
			DiRs->groupBody->flags.noPrint = 1;
			}
		if ( !DiRs->get(argument->groupBody->tag) )
			{
			DiRs->addMember(argument);
			::spliceDirectives(target,argument);
			}
		}
	return target;
}

/***************************************************************************
    Text-substrate directive orchestrator. Parallel to applyDirectives but
    operates on a buffer-bearing target rather than an AST target. Walks
    the buffer doing find-and-replace via the mark machinery: for each
    occurrence of fromText in target's buffer, delete the matched chars
    and insert toText in their place. Mark threads naturally through
    opIN (sets it on match), += (insert at mark, advance), -= (delete
    at mark, stay). Idempotent via the target's DiRs registry.
***************************************************************************/
extern "C" GroupItem *applyTextDirective(GroupItem *argument, GroupItem *target)
{
GroupItem 	*grup = 0;
GroupItem 	*DiRs = 0;
GroupItem 	*fromText = 0;
GroupItem 	*toText = 0;
Buffer 		*buf = 0;
	if ( isLIST(argument->groupBody->flags.binType) )
		while ( grup = argument->prior(grup) )
			::applyTextDirective(grup,target);
	else {
		DiRs = target->get("DiRs");
		if ( !DiRs )
			{
			DiRs = target->addString("DiRs");
			DiRs->groupBody->flags.noPrint = 1;
			}
		if ( DiRs->get(argument->groupBody->tag) )
			return target;
		DiRs->addMember(argument);
		fromText = argument->groupBody->groupList->firstInList;
		if ( !fromText )
			{
			::fprintf(stderr,"Text directive needs 'from' as first child: %s\n",argument->groupBody->tag);
			return target;
			}
		toText = fromText->nextInParent;
		if ( !isBUFFER(target->groupBody->flags.data) )
			return target;
		buf = target->getBuffer();
		buf->setMark();
		while ( buf->findInBuffer(fromText->getText()) )
			{
			buf->deleteFromBuffer(fromText->getCount());
			if ( toText )
				buf->appendString(toText->getText(),0,0);
			}
		buf->unMark();
		}
	return target;
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

/***************************************************************************
	Returns a string version of data
***************************************************************************/
extern "C" char *dataType(GroupItem *input)
{
char 	*name = 0;
	switch (input->groupBody->flags.data)
		{
		case 2:
			name = "char";
			break;
		case 3:
			name = "Set";
			break;
		case 4:
			name = "Buffer";
			break;
		case 5:
			name = "int";
			break;
		case 6:
			name = "GroupItem";
			break;
		case 7:
			name = "PLGitem";
			break;
		case 8:
			name = "BitMAP";
			break;
		case 9:
			name = "double";
			break;
		case 10:
			name = "object";
			break;
		case 11:
			name = "regex";
			break;
		case 12:
			name = "Stak";
			break;
		case 13:
			name = "String";
			break;
		case 14:
			name = "Token";
			break;
		default:
			name = "null";
		}
	return name;
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
	if isCoded          cout ,alignLeft("coded",10);
	if isMethod || isOperator   cout ,alignLeft("has method",10);
	if isRule           cout ,alignLeft("is rule",10);
	if isAction         cout ,alignLeft("is action",10);
	if registry         cout ,"registry:",registry.tag;
	*/
	::printf("%s",::alignLeft(debugStuff->groupBody->tag,20));
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
		::printf(" %s",::alignLeft("attribute",10));
	else
	if ( isMember(debugStuff->options.affiliation) )
		::printf(" %s",::alignLeft("member",10));
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

/******************************************************************************
    This incant command method reads the field passed in as a file spec and
    loads the field buffer (creating it if necessary) with text read in from
    the file. Returns the loaded field.
******************************************************************************/
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
		else	::fprintf(stderr,"getMarkLineAt: ERROR no match field provided\n");
	else	::fprintf(stderr,"getMarkLineAt: ERROR no source or source is not a buffer\n");
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
	if ( item->groupBody->flags.isRule && item->groupBody->guardSet )
		{
		item->groupBody->guardSet = 0;
		item->groupBody->flags.guarding = 0;
		}
	else	::fprintf(stderr,"ERROR guard should be used as an attribute when defining\n");
	item->clearData();
	return item;
}

/***************************************************************************
    interpretBC — C++ dispatch loop over a bcLIST. Replaces the incant
    interpretBC. A plain C++ cursor sidesteps the :=/byRef weld and the
    for-loop's non-steerable advance (see docs/branch-dispatch-findings.md).
    runByteFn returns the branch-target stream member on a taken branch
    (null on every non-branch op); relocate the cursor to it by tag, then
    advance. opStack is hung off the bcLIST so the bcOP handlers reach it
    via opStackOf (parent.getAttribute("opStack")).
***************************************************************************/
extern "C" GroupItem *interpretBC(GroupItem *argument)
{
GroupItem 	*stack = new GroupItem("opStack");
GroupItem 	*cursor = 0;
GroupItem 	*result = 0;
	argument->addAttribute(stack);
	cursor = argument->nextMember(0);
	while ( cursor )
		{
		result = runByteFn(cursor);
		if ( result )
			cursor = argument->getFromList(result->groupBody->tag);
		else	cursor = argument->nextMember(cursor);
		}
	return argument;
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

/* jitEmitAssign  the store-back emitter — commits a value into a target field's
   slot. Assign is a single store operation, so no jitOp selector. SKELETON — not
   wired (no gate, no fixtures).

   STORE DESTINATION (resolved): target->jitData->jitSlot is now populated by
   jitSeedField (it stashes the baked field-storage address), so a field target
   has a live CreateStore destination. A literal target has no slot, correctly —
   it is not assignable.

   STORE-ONLY BY DESIGN (resolved): jitEmitAssign does the plain `=` store and
   nothing else. A compound assign (+= *= ...) is NOT a second branch here — it is
   composed at the opMethod gate: jitEmitBinary(argument,target,<jitOp>) first,
   which leaves the new value in target->jitData->jitValue (and gJitResult), then
   this same store-back commits it. Keeping the emitter op-free is the deliberate
   choice (vs. an op param + jitNone sentinel) — it reuses jitEmitBinary untouched
   and keeps the binary/store responsibilities separate. */
extern "C" GroupItem *jitEmitAssign(GroupItem *argument, GroupItem *target)
{
	
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

/* jitEmitCompare  the shared relational emitter — jitEmitBinary's sibling for the
   six predicates (== != < <= > >=). Same header-clean signature, same operand-load
   and gJitResult-stash boilerplate, and the SAME int/float promotion block:
   a mixed count/number pair is unified first (CreateSIToFP) because LLVM has no
   cross-type compare — promotion is retained here, not dropped (only the same-type
   case skips it, as in jitEmitBinary). Two real differences from binary: the result
   is an i1 (a boolean, not the operand type), and the instruction comes from the
   ICmp (integer) / FCmp (double) predicate matrix rather than add/sub/mul/div.
   EQ/NE are sign-agnostic; the ordered four take signed-int / ordered-float
   predicates. `op` is a jitCmp (jitContext.h). NOTE: when this is wired into an
   opMethod gate later, jitRunAction's return-cap needs an i1->i32 ZExt branch
   (it currently only widens double->i32) and a groups.ext extern decl is required. */
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

extern "C" void jitInitOnce()
{
	
	static bool done = false;
	if (done) return;
	llvm::InitializeNativeTarget();
	llvm::InitializeNativeTargetAsmPrinter();
	llvm::InitializeNativeTargetAsmParser();
	done = true;
	
}

/* jitRunAction  the generic compile driver — the JIT analog of generateCode. Sets
   up an i32() function shell + builder, raises the `jitting` gate, walks the action
   body via processCode (which fires aCTionExpressioN's jitting branch per
   expression, emitting IR straight into the builder), then caps with CreateRet of
   the running result, ORC-compiles, looks up, and calls. Returns the native result.
   Phase-1 scope: straight-line count arithmetic, no prologue unbox of real fields
   yet (literals are folded as constants). */
extern "C" int jitRunAction(GroupItem *action)
{
	
	printf("=== jitRunAction: entering on %s ===\n", action->groupBody->tag);
	fflush(stdout);
	jitInitOnce();
	llvm::orc::LLJIT *jit = (llvm::orc::LLJIT*)jitEngine();
	if (!jit) { printf("=== JIT engine null ===\n"); fflush(stdout); return -1; }
	
	auto ctx = std::make_unique<llvm::LLVMContext>();
	auto mod = std::make_unique<llvm::Module>("jitMod", *ctx);
	llvm::IRBuilder<> B(*ctx);
	
	llvm::Type *i32 = llvm::Type::getInt32Ty(*ctx);
	// Unique name per run: the LLJIT engine is long-lived, so reusing "jitFn"
	// collides on the second addIRModule (duplicate symbol in the JITDylib).
	static int jitFnSeq = 0;
	char fnName[32];
	snprintf(fnName, sizeof(fnName), "jitFn%d", jitFnSeq++);
	llvm::Function *fn = llvm::Function::Create(
	llvm::FunctionType::get(i32, false),
	llvm::Function::ExternalLinkage, fnName, mod.get());
	B.SetInsertPoint(llvm::BasicBlock::Create(*ctx, "entry", fn));
	
	gJitBuilder = &B;
	gJitResult  = nullptr;
	
	GroupRules *ruler = GroupControl::groupController->groupRules;
	ruler->jitting = 1;
	if (isCoded(action->groupBody->flags.actionType))
	::processCode(action);
	ruler->jitting = 0;
	
	if (!gJitResult) {
	printf("=== jitRunAction: no result emitted (gate did not fire?) ===\n");
	fflush(stdout); return -2; }
	if (gJitResult->getType()->isDoubleTy())
	gJitResult = B.CreateFPToSI(gJitResult, i32, "ret");
	else if (gJitResult->getType()->isIntegerTy(1))
	gJitResult = B.CreateZExt(gJitResult, i32, "ret");   // i1 compare result -> i32
	B.CreateRet(gJitResult);
	
	if (auto err = jit->addIRModule(
	llvm::orc::ThreadSafeModule(std::move(mod), std::move(ctx)))) {
	llvm::consumeError(std::move(err));
	printf("=== JIT addIRModule failed ===\n"); fflush(stdout); return -3; }
	auto sym = jit->lookup(fnName);
	if (!sym) { llvm::consumeError(sym.takeError());
	printf("=== JIT lookup failed ===\n"); fflush(stdout); return -4; }
	int (*fp)() = sym->toPtr<int(*)()>();
	int r = fp();
	printf("=== jitRunAction result = %d ===\n", r); fflush(stdout);
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

/* jitSeedField  unbox a real count/number field operand — the past-constant-folding
   path. Bakes the field's stable GroupItem storage address as a constant pointer and
   emits a CreateLoad of its gCount/gNumber, so the operand reads the LIVE field value
   at run time rather than a folded compile-time constant. The field's address is
   stable (BDWGC-managed, persists), so baking it is sound. (Slot-array calling
   convention per jit.md is the later refinement; this proves the unbox mechanism.)
   Also stashes that baked address into jitData->jitSlot, so an assign store-back
   (jitEmitAssign) has a destination — immediate writeback to the field's own
   storage. Literals get no slot (jitSeedLiteral), which is correct: a literal
   is not an assignable target. */
extern "C" GroupItem *jitSeedField(GroupItem *token)
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	llvm::LLVMContext &ctx = b->getContext();
	JitData *d = new JitData();
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
	return token;
	
}

/*****************************************************************************
	The input argument is expected to be a listenTo attribute that contains
    a list of groups that will be listened to by listenTo's parent (the listener).
    The listenTo attribute is noPrint and runs when its parent gets defined.
    It runs thru its list of groups and adds its parent to the notifyList
    of every group on that list.
    The notifyList is an attribute of the group being listened to. If the
    listened to group changes, it runs updateListeners(), which will notify
    its listeners that something changed and time to do what needs done.
*****************************************************************************/
extern "C" GroupItem *listenTo(GroupItem *input)
{
GroupItem 	*listener = input->parent;
GroupItem 	*grup = 0;
GroupItem 	*notifyList = 0;
	listener->groupBody->flags.hasListeners = 1;
	if ( input->groupBody->flags.fLAG )
		while ( grup = input->nextAttribute(grup) )
			{
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
	Command to make a new field w/tag set from input text
*****************************************************************************/
extern "C" GroupItem *makeNew(GroupItem *input)
{
char 		*strung = input->getText();
GroupItem 	*grup = new GroupItem(strung);
	grup->groupBody->flags.isInitialized = 1;
	return grup;
}

/***************************************************************************
	Match engine. Walks targetLines looking for the first member that
	starts a span structurally equal to fromBlock's Lines. Returns that
	anchor member, or null.
***************************************************************************/
extern "C" GroupItem *matchSpanInLines(GroupItem *targetLines, GroupItem *fromBlock)
{
GroupItem 	*fromBlocK = fromBlock->get("BlocK");
GroupItem 	*fromLines = 0;
GroupItem 	*firstFrom = 0;
GroupItem 	*candidate = 0;
GroupItem 	*tWalk = 0;
GroupItem 	*fWalk = 0;
	if ( !fromBlocK )
		return 0;
	fromLines = fromBlocK;
	if ( !fromLines || !fromLines->groupBody->groupList )
		return 0;
	firstFrom = fromLines->groupBody->groupList->firstInList;
	candidate = targetLines->groupBody->groupList->firstInList;
	while ( candidate )
		{
		if ( ::statementMatches(candidate,firstFrom) )
			{
			tWalk = candidate->nextInParent;
			fWalk = firstFrom->nextInParent;
			while ( fWalk && tWalk && ::statementMatches(tWalk,fWalk) )
				{
				tWalk = tWalk->nextInParent;
				fWalk = fWalk->nextInParent;
				}
			if ( !fWalk )
				return candidate;
			}
		candidate = candidate->nextInParent;
		}
	return 0;
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
				field->rStuff->max = -0xefffffff;
				break;
			case '*':
				field->rStuff->min = 0;
				field->rStuff->max = -0xefffffff;
				break;
			case '?':
				field->rStuff->min = 0;
				break;
			case '!':
				field->rStuff->banged = 1;
				break;
			case '<':
				field->rStuff->noAdvance = 1;
				break;
			case '%':
				field->groupBody->flags.isPercent = 1;
				break;
			case '&':
				field->groupBody->flags.isPointer = 1;
				break;
			case '@':
				field->rStuff->isTarget = 1;
				break;
			case '-':
				field->rStuff->noLabel = 1;
				break;
			case '_':
				field->groupBody->flags.guarding = 2;
				break;
			case '^':
				field->rStuff->noSkip = 1;
				break;
			case '{':
				field->rStuff->overTo = 1;
				field->groupBody->flags.guarding = 2;
				break;
			case '}':
				field->rStuff->overTo = 2;
				field->groupBody->flags.guarding = 2;
				break;
			case '$':
				field->groupBody->flags.isMacro = 1;
			}
}

/***************************************************************************
	Rule action for the AND operator
***************************************************************************/
extern "C" GroupItem *opAND(GroupItem *argument, GroupItem *target)
{
	if ( target->groupBody->gCount && argument->groupBody->gCount )
		return GroupControl::groupController->groupRules->trueResult;
	return 0;
}

/***************************************************************************
	Rule action for the +% operator
***************************************************************************/
extern "C" GroupItem *opAddAttribute(GroupItem *argument, GroupItem *target)
{
GroupItem 	*grup = 0;
	if ( isLIST(argument->groupBody->flags.binType) )
		while ( grup = argument->prior(grup) )
			target->addAttribute(grup);
	else	target->addAttribute(argument);
	return target;
}

/***************************************************************************
	Rule action for the = assign operator. A byRef argument (one that came
	through := / opSetGroup) is stored BY REFERENCE so the `=` does not undo the
	reference via setContent. Everything else copies via setContent exactly as
	before — the non-byRef path is byte-identical. (2026-06-09)
***************************************************************************/
extern "C" GroupItem *opAssign(GroupItem *argument, GroupItem *target)
{
	if ( argument )
		if ( argument->groupBody->flags.byRef )
			target->setGroup(argument);
		else	target->setContent(argument);
	return target;
}

/***************************************************************************
	Rule action for the +* copy list operator
***************************************************************************/
extern "C" GroupItem *opCopyList(GroupItem *argument, GroupItem *target)
{
	if ( argument->groupBody->groupList )
		argument->copyListTo(target);
	else	::fprintf(stderr,"ERROR Operator +* failed because missing list for %s\n",argument->groupBody->tag);
	return target;
}

/***************************************************************************
	Rule action for ** debug operator
***************************************************************************/
extern "C" GroupItem *opDebug(GroupItem *result)
{
GroupItem 	*grup = 0;
GroupItem 	*action = GroupControl::groupController->groupRules->currentMETHOD;
	if ( action )
		grup = action->get(result->groupBody->tag);
	//print result.tag:;
	return result;
}

/***************************************************************************
	Rule action for the / divide operator
***************************************************************************/
extern "C" GroupItem *opDiv(GroupItem *argument, GroupItem *target)
{
	if ( isCOUNT(argument->groupBody->flags.data) || isNUMBER(argument->groupBody->flags.data) )
		if ( isCOUNT(target->groupBody->flags.data) )
			GroupControl::groupController->groupRules->tempField->setCount((int)::lround(target->getNumber() / argument->getNumber()));
		else
		if ( isNUMBER(target->groupBody->flags.data) )
			GroupControl::groupController->groupRules->tempField->setNumber(target->getNumber() / argument->getNumber());
	if ( !GroupControl::groupController->groupRules->tempField->groupBody->flags.data )
		{
		::fprintf(stderr,"ERROR Operator / not supported for %s and %s\n",target->groupBody->tag,argument->groupBody->tag);
		return 0;
		}
	return GroupControl::groupController->groupRules->tempField;
}

/***************************************************************************
	Rule action for the /= slash equal operator
***************************************************************************/
extern "C" GroupItem *opDivEQ(GroupItem *argument, GroupItem *target)
{
GroupItem 	*result = 0;
	if ( (isCOUNT(target->groupBody->flags.data) || isNUMBER(target->groupBody->flags.data)) && (isCOUNT(argument->groupBody->flags.data) || isNUMBER(argument->groupBody->flags.data)) )
		{
		if ( isCOUNT(target->groupBody->flags.data) )
			target->setCount((int)::lround(target->getNumber() / argument->getNumber()));
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
			while ( target && isGROUP(target->groupBody->flags.data) && target->getGroup() )
				target = target->getGroup();
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
					else	product->setGroup(target->parent);
					break;
				case 3:
					if ( !target->groupBody->registry )
						product = 0;
					else	product->setGroup(target->groupBody->registry);
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
					break;
				case 8:
					if ( target->groupBody->flags.hasMembers )
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
				case 24:
					if ( target->groupBody->flags.isShortcut )
						product->setCount(1);
					break;
				case 28:
					if ( target->groupBody->flags.noPrint )
						product->setCount(1);
					break;
				case 401:
					if ( !target->nextInParent )
						product = 0;
					else	product = target->nextInParent;
					break;
				case 402:
					if ( !target->priorInParent )
						product = 0;
					else	product = target->priorInParent;
					break;
				case 403:
					if ( !target->groupBody->groupList->firstInList )
						product = 0;
					else	product = target->groupBody->groupList->firstInList;
					break;
				case 404:
					if ( !target->groupBody->groupList->lastInList )
						product = 0;
					else	product = target->groupBody->groupList->lastInList;
					break;
				default:
					product->setText(::concat(3,"access to ",argument->groupBody->tag," not supported yet"));
				}
			if ( product )
				if ( !product->groupBody->flags.isInitialized )
					return 0;
				else
				if ( !product->parent )
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
	if ( ::compareValues(target,argument) < 0 )
		return GroupControl::groupController->groupRules->trueResult;
	return 0;
}

/***************************************************************************
	Rule action for @ operator
***************************************************************************/
extern "C" GroupItem *opLastREF(GroupItem *result)
{
	GroupControl::groupController->groupRules->lastREF->setGroup(result);
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
	if ( (isCOUNT(target->groupBody->flags.data) || isNUMBER(target->groupBody->flags.data)) && (isCOUNT(argument->groupBody->flags.data) || isNUMBER(argument->groupBody->flags.data)) )
		{
		if ( isCOUNT(target->groupBody->flags.data) )
			GroupControl::groupController->groupRules->tempField->setCount(target->groupBody->gCount - argument->getCount());
		else
		if ( isNUMBER(target->groupBody->flags.data) )
			GroupControl::groupController->groupRules->tempField->setNumber(target->groupBody->gNumber - argument->getNumber());
		}
	else
	if ( (isSTRING(target->groupBody->flags.data) || isTOKEN(target->groupBody->flags.data)) && argument->getCount() > 0 )
		if ( target->groupBody->gCount > argument->getCount() )
			GroupControl::groupController->groupRules->tempField->setText(::headToCount(target->getText(),target->groupBody->gCount - argument->getCount()));
	if ( !GroupControl::groupController->groupRules->tempField->groupBody->flags.data )
		{
		::fprintf(stderr,"ERROR Operator - failed on %s and %s\n",target->groupBody->tag,argument->groupBody->tag);
		return 0;
		}
	return GroupControl::groupController->groupRules->tempField;
}

/***************************************************************************
	Rule action for the -= operator
***************************************************************************/
extern "C" GroupItem *opMinusEQ(GroupItem *argument, GroupItem *target)
{
GroupItem 	*result = 0;
	if ( target->groupBody->flags.binType )
		result = target->remove(argument->groupBody->tag);
	else
	if ( target->groupBody->flags.data && argument->groupBody->flags.data )
		{
		result = target;
		switch (target->groupBody->flags.data)
			{
			case 5:
				target->groupBody->gCount -= argument->getCount();
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
	else	::fprintf(stderr,"ERROR Operator -- not supported for data type of %s\n",result->groupBody->tag);
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
	if ( isCOUNT(argument->groupBody->flags.data) || isNUMBER(argument->groupBody->flags.data) )
		if ( isCOUNT(target->groupBody->flags.data) )
			GroupControl::groupController->groupRules->tempField->setCount(target->getCount() * argument->getCount());
		else
		if ( isNUMBER(target->groupBody->flags.data) )
			GroupControl::groupController->groupRules->tempField->setNumber(target->getNumber() * argument->getNumber());
	if ( !GroupControl::groupController->groupRules->tempField->groupBody->flags.data )
		{
		::fprintf(stderr,"ERROR Operator * failed on %s and %s\n",target->groupBody->tag,argument->groupBody->tag);
		return 0;
		}
	return GroupControl::groupController->groupRules->tempField;
}

/***************************************************************************
	Rule action for the *= operator
***************************************************************************/
extern "C" GroupItem *opMultiplyEQ(GroupItem *argument, GroupItem *target)
{
GroupItem 	*result = 0;
	if ( target->groupBody->flags.data && argument->groupBody->flags.data )
		{
		if ( isCOUNT(target->groupBody->flags.data) )
			target->groupBody->gCount *= argument->getCount();
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
	if ( !(result->groupBody->flags.isInitialized && result->groupBody->flags.data && result->groupBody->gCount) )
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
	if ( ::compareValues(target,argument) )
		return GroupControl::groupController->groupRules->trueResult;
	return 0;
}

/***************************************************************************
	Rule action for the OR operator
***************************************************************************/
extern "C" GroupItem *opOR(GroupItem *argument, GroupItem *target)
{
	if ( target )
		if ( target->groupBody->gCount )
			return GroupControl::groupController->groupRules->trueResult;
		else
		if ( argument && argument->groupBody->gCount )
			return GroupControl::groupController->groupRules->trueResult;
	return 0;
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
	if ( target->groupBody->flags.data && (isCOUNT(argument->groupBody->flags.data) || isNUMBER(argument->groupBody->flags.data)) )
		{
		if ( isCOUNT(target->groupBody->flags.data) )
			GroupControl::groupController->groupRules->tempField->setCount(target->groupBody->gCount + argument->getCount());
		else
		if ( isNUMBER(target->groupBody->flags.data) )
			GroupControl::groupController->groupRules->tempField->setNumber(target->groupBody->gNumber + argument->getNumber());
		else
		if ( isSTRING(target->groupBody->flags.data) || isTOKEN(target->groupBody->flags.data) )
			if ( target->groupBody->gCount > argument->getCount() )
				GroupControl::groupController->groupRules->tempField->setText(target->groupBody->gText + argument->getCount());
			else	::fprintf(stderr,"ERROR Operator + tried to advance string past length of %s\n",target->groupBody->tag);
		}
	if ( !GroupControl::groupController->groupRules->tempField->groupBody->flags.data )
		{
		::fprintf(stderr,"ERROR Operator + failed on %s and %s\n",target->groupBody->tag,argument->groupBody->tag);
		return 0;
		}
	return GroupControl::groupController->groupRules->tempField;
}

/***************************************************************************
	Rule action for the += operator
***************************************************************************/
extern "C" GroupItem *opPlusEQ(GroupItem *argument, GroupItem *target)
{
GroupItem 	*grup = 0;
	if ( isLIST(argument->groupBody->flags.binType) )
		while ( grup = argument->prior(grup) )
			::opPlusEQ(grup,target);
	else
	if ( target->groupBody->flags.binType || target->groupBody->groupList )
		target->addMember(argument);
	else
	if ( argument->groupBody->flags.data )
		if ( target->groupBody->flags.data )
			switch (target->groupBody->flags.data)
				{
				case 5:
					target->groupBody->gCount += argument->getCount();
					break;
				case 9:
					target->groupBody->gNumber += argument->getNumber();
					break;
				case 13:
				case 14:
					target->setText(::concat(2,target->getText(),argument->getText()));
					break;
				case 4:
					target->getBuffer()->appendString(argument->getText(),0,0);
					// if buffer mark is set, argument is inserted into buffer at mark
					// otherwise it is appended at end of buffer. mark is left as is
					break;
				case 12:
					target->groupBody->gStak->push(argument);
					break;
				default:
					::fprintf(stderr,"ERROR Operator += failed on %s and %s\n",target->groupBody->tag,argument->groupBody->tag);
				}
		else	target->copyData(argument);
	return target;
}

/***************************************************************************
	Rule action for ++ operator
***************************************************************************/
extern "C" GroupItem *opPlusPlus(GroupItem *result)
{
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
	else	::fprintf(stderr,"ERROR Operator ++ not supported for data type of %s\n",result->groupBody->tag);
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
	ruler->useDefaultSpace = 1;
	if ( printText )
		if ( ruler->toBUFFER )
			ruler->toBUFFER->appendString(printText,0,0);
		else	::printf("%s",printText);
	else	::fprintf(stderr,"print: recieved no print text\n");
	ruler->useDefaultSpace = 1;
	buffer->reset();
	ruler->bufferSTAK->push(buffer);
	return ruler->trueResult;
}

/***************************************************************************
	Rule action for the % integer div operator
***************************************************************************/
extern "C" GroupItem *opRem(GroupItem *argument, GroupItem *target)
{
	if ( (isCOUNT(target->groupBody->flags.data) || isNUMBER(target->groupBody->flags.data)) && (isCOUNT(argument->groupBody->flags.data) || isNUMBER(argument->groupBody->flags.data)) )
		GroupControl::groupController->groupRules->tempField->setCount(target->getCount() % argument->getCount());
	if ( !GroupControl::groupController->groupRules->tempField->groupBody->flags.data )
		::fprintf(stderr,"ERROR integer div operator failed on %s and %s\n",target->groupBody->tag,argument->groupBody->tag);
	return GroupControl::groupController->groupRules->tempField;
}

/***************************************************************************
	Rule action for the :+ replace operator.
***************************************************************************/
extern "C" GroupItem *opReplaceAttribute(GroupItem *argument, GroupItem *target)
{
GroupItem 	*grup = 0;
	if ( isLIST(argument->groupBody->flags.binType) )
		while ( grup = argument->prior(grup) )
			if ( isMember(grup->options.affiliation) )
				{
				grup->options.affiliation = 1;
				target->replace(grup);
				grup->options.affiliation = 2;
				}
			else	target->replace(grup);
	else	target->replace(argument);
	return target;
}

/***************************************************************************
	Rule action for the :+ replace operator.
***************************************************************************/
extern "C" GroupItem *opReplaceMember(GroupItem *argument, GroupItem *target)
{
GroupItem 	*grup = 0;
	if ( isLIST(argument->groupBody->flags.binType) )
		while ( grup = argument->prior(grup) )
			if ( isAttribute(grup->options.affiliation) )
				{
				grup->options.affiliation = 2;
				target->replace(grup);
				grup->options.affiliation = 1;
				}
			else	target->replace(grup);
	else	target->replace(argument);
	return target;
}

/***************************************************************************
	Rule action for the := set group operator. Stamps byRef on the argument so
	setGroup stores it BY REFERENCE (no copy). byRef is left SET (sticky) on
	purpose: a later `=` of the same field then also references, because opAssign
	honors byRef too. (2026-06-09. See TODO: audit := sites whose fields later
	get legitimately =-copied — sticky byRef would alias them.)
***************************************************************************/
extern "C" GroupItem *opSetGroup(GroupItem *argument, GroupItem *target)
{
	if ( argument )
		target->setGroup(argument);
	return target;
}

/***************************************************************************
	operator method for the string rule.
***************************************************************************/
extern "C" GroupItem *opString(GroupItem *target, Buffer *buffer)
{
	target->setText(buffer->toString());
	GroupControl::groupController->groupRules->useDefaultSpace = 1;
	buffer->reset();
	GroupControl::groupController->groupRules->bufferSTAK->push(buffer);
	return target;
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
		::printf("printToBuffer: diverting print output to %s\n",bufferField->groupBody->tag);
		}
	else
	if ( GroupControl::groupController->groupRules->toBUFFER )
		{
		GroupControl::groupController->groupRules->toBUFFER = 0;
		::printf("printToBuffer: stopping print to buffer (buffer not reset)\n");
		}
	else	::fprintf(stderr,"printToBuffer: ignored\n");
	return GroupControl::groupController->groupRules->trueResult;
}

/*****************************************************************************
     Run an action. If called as a rule action, the field passed in will be
     a label; otherwise it will be a field with an action.
*****************************************************************************/
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
	ruler->currentMETHOD = action;
	if ( action->groupBody->flags.isLabel )
		action = ruleStuff->rule;
	/*************************************************************************
	if action is a rule, update local fields from label contents.
	*************************************************************************/
	if ( action->groupBody->flags.isRule )
		{
		code = action->get("CodE");
		while ( grup = label->nextAttribute(grup) )
			if ( result = code->get(grup->groupBody->tag) )
				{
				if ( grup->groupBody->groupList )
					result->groupBody->groupList = grup->groupBody->groupList;
				if ( grup->groupBody->flags.data )
					result->copyData(grup);
				}
			else {
				grup->groupBody->flags.isLocal = 1;
				code->addAttribute(grup);
				}
		}
	if ( isCoded(action->groupBody->flags.actionType) && !::processCode(field) )
		return 0;
	if ( result = action->get("BlocK") )
		{
		/*********************************************************************
		The following clears local fields after action ends.
		*********************************************************************/
		if ( action->groupBody->flags.isRule )
			action = code;
		while ( grup = action->nextAttribute(grup) )
			if ( grup->groupBody->flags.isLocal && !grup->groupBody->flags.isLabel )
				grup->clear();
		if ( ruler->runningActions->get(field->groupBody->tag) )
			field->groupBody->flags.recursive = 1;
		ruler->runningActions->addMember(field);
		if ( field->groupBody->flags.recursive )
			::saveLocalFields(field);
		if ( result = result->groupBody->gMethod(result) )
			result->groupBody->flags.isBranch = 0;
		if ( field->groupBody->flags.recursive )
			::restoreLocalFields(field);
		ruler->runningActions->pop();
		}
	ruler->currentMETHOD = priorMETHOD;
	ruler->tempField = priorTempField;
	return result;
}

/*****************************************************************************
    Parse an action. Note: the coded field is made an action before its
    code is parsed otherwise a recursive call will complain
*****************************************************************************/
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
	if ( field->groupBody->flags.isLabel )
		field = field->rStuff->rule;
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
	else	::fprintf(stderr,"ERROR processCode: %s parse failed\n",field->groupBody->tag);
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
***************************************************************************/
extern "C" GroupItem *processFlags(GroupItem *item)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
char 		*command = item->groupBody->tag;
GroupItem 	*target = item->parent;
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
				if ( target->groupBody->flags.isRule )
					target->rStuff->notifyFail = 1;
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
					if ( !target->rStuff )
						target->rStuff = new RuleStuff(target);
					}
				break;
			case 'm':
				if ( ::compare(command,"macro") == 0 )
					target->groupBody->flags.isMacro = 1;
				else	target->groupBody->flags.mergeOn = 1;
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

/***************************************************************************
	Detach the matched span from targetLines (proper bookkeeping via
	GroupItem.remove), then splice toBlock's Lines members in at the
	same position. toBlock may be null (delete case). Uses the parent=null
	move idiom for the toLines side since toLines is abandoned after
	the splice (cousin of spliceDirectives' move loop).
***************************************************************************/
extern "C" void replaceAtAnchor(GroupItem *targetLines, GroupItem *anchor, GroupItem *fromBlock, GroupItem *toBlock)
{
GroupItem 	*fromBlocK = fromBlock->get("BlocK");
GroupItem 	*fromLines = 0;
GroupItem 	*toBlocK = 0;
GroupItem 	*toLines = 0;
GroupItem 	*spanWalk = 0;
GroupItem 	*adjacent = 0;
GroupItem 	*priorAnchor = anchor->priorInParent;
int 		spanLength = 0;
int 		i = 0;
	if ( !fromBlocK )
		return;
	fromLines = fromBlocK;
	if ( !fromLines )
		return;
	spanLength = fromLines->groupBody->groupList->listLength;
	spanWalk = anchor;
	for ( i = 0; i < spanLength; i++ )
		{
		if ( !spanWalk )
			break;
		adjacent = spanWalk->nextInParent;
		spanWalk->remove();
		spanWalk = adjacent;
		}
	if ( toBlock )
		{
		toBlocK = toBlock->get("BlocK");
		if ( toBlocK )
			{
			toLines = toBlocK;
			if ( toLines && toLines->groupBody->groupList )
				{
				spanWalk = toLines->groupBody->groupList->lastInList;
				while ( spanWalk )
					{
					adjacent = spanWalk->priorInParent;
					spanWalk->parent = 0;
					if ( priorAnchor )
						priorAnchor->insertAfter(spanWalk);
					else	targetLines->insertGroup(spanWalk);
					spanWalk = adjacent;
					}
				}
			}
		}
}

/***************************************************************************
	Replace-directive orchestrator. Parallel to applyDirectives but does
	match-and-swap rather than splice-into-end. Idempotent via the target's
	DiRs registry. Routes here from opReplace's DiR-prefix hook.
***************************************************************************/
extern "C" GroupItem *replaceDirective(GroupItem *argument, GroupItem *target)
{
GroupItem 	*grup = 0;
GroupItem 	*DiRs = 0;
GroupItem 	*fromAttr = 0;
GroupItem 	*toAttr = 0;
GroupItem 	*fromBlk = 0;
GroupItem 	*toBlk = 0;
GroupItem 	*anchor = 0;
GroupItem 	*targetLines = 0;
	if ( isLIST(argument->groupBody->flags.binType) )
		while ( grup = argument->prior(grup) )
			::replaceDirective(grup,target);
	else {
		DiRs = target->get("DiRs");
		if ( !DiRs )
			{
			DiRs = target->addString("DiRs");
			DiRs->groupBody->flags.noPrint = 1;
			}
		if ( DiRs->get(argument->groupBody->tag) )
			return target;
		DiRs->addMember(argument);
		if ( !target->get("BlocK") )
			::processCode(target);
		/* Positional access (Tony 2026-05-28): directive's children are the
		from-ref (first) and to-ref (second). No from=/to= labels.
		Try .group first (parser-resolved reference); fall back to the
		child itself in case the child IS the resolved field directly. */
		fromAttr = argument->groupBody->groupList->firstInList;
		if ( !fromAttr )
			{
			::fprintf(stderr,"Replace directive needs 'from' as first child: %s\n",argument->groupBody->tag);
			return target;
			}
		fromBlk = fromAttr->getGroup();
		if ( !fromBlk )
			fromBlk = fromAttr;
		if ( !fromBlk->get("BlocK") )
			::processCode(fromBlk);
		toAttr = fromAttr->nextInParent;
		if ( toAttr )
			{
			toBlk = toAttr->getGroup();
			if ( !toBlk )
				toBlk = toAttr;
			if ( !toBlk->get("BlocK") )
				::processCode(toBlk);
			}
		targetLines = target->get("BlocK");
		if ( !targetLines )
			return target;
		anchor = ::matchSpanInLines(targetLines,fromBlk);
		if ( !anchor )
			{
			::fprintf(stderr,"Replace directive could not match 'from' in target: %s\n",target->groupBody->tag);
			return target;
			}
		::replaceAtAnchor(targetLines,anchor,fromBlk,toBlk);
		}
	return target;
}

/***************************************************************************
	Text-substrate substring replace. Uses containsString (returns char* to
	match position, hand-edited in support/Frame/StringRoutines.C). Single-
	occurrence; returns text unchanged if from not found. Transitional
	helper for the incant text-directive hybrid prototype (2026-05-28);
	will be retired when Buffer extern incant methods provide in-place
	span surgery directly.
***************************************************************************/
extern "C" char *replaceUsingFind(char *text, char *fromTxt, char *toTxt)
{
char 	*position = ::containsString(text,fromTxt);
int 	fromLen = 0;
int 	toLen = 0;
int 	prefixLen = 0;
int 	suffixLen = 0;
char 	*result = 0;
	if ( !position )
		return text;
	fromLen = (int)::strlen(fromTxt);
	toLen = (int)::strlen(toTxt);
	prefixLen = (int)(position - text);
	suffixLen = (int)::strlen(text) - prefixLen - fromLen;
	result = (char*)::calloc((size_t)(prefixLen + toLen + suffixLen + 1),sizeof(char));
	::strncpy(result,text,(size_t)prefixLen);
	::strcpy(result + prefixLen,toTxt);
	::strcpy(result + prefixLen + toLen,position + fromLen);
	return result;
}

/*****************************************************************************
    reset — incant command (bound as reset immediateAction=resetField in
    setup). Self-describing by argument: for now it knows buffers (resets the
    mark). A fuller incant action dispatching on argument.taG comes later.
*****************************************************************************/
extern "C" GroupItem *resetField(GroupItem *argument)
{
	if ( isBUFFER(argument->groupBody->flags.data) )
		argument->getBuffer()->unMark();
	return 0;
}

/*****************************************************************************
	Process an argument list to run any list elements that are methods
    or actions and return a new field containing the resolved list.
*****************************************************************************/
extern "C" GroupItem *resolveList(GroupItem *input)
{
GroupItem 	*result = new GroupItem("resolvedList");
GroupItem 	*grup = 0;
	while ( grup = input->next(grup) )
		if ( isMethod(grup->groupBody->flags.instructType) )
			result->addMember(grup->groupBody->gMethod(grup));
		else	result->addMember(grup);
	result->groupBody->flags.binType = 3;
	return result;
}

/*****************************************************************************
	Restore local fields after a recursive call.
*****************************************************************************/
extern "C" void restoreLocalFields(GroupItem *action)
{
Stak 		*recurseSTAK = action->getStak();
GroupBody 	*body = 0;
GroupItem 	*grup = 0;
	if ( !recurseSTAK->length )
		action->groupBody->flags.recursive = 0;
	else
	while ( grup = action->prior(grup) )
		if ( grup->groupBody->flags.isLocal && !grup->groupBody->flags.noPrint )
			{
			body = (GroupBody*)recurseSTAK->pop();
			*grup->groupBody = *body;
			body = 0;
			}
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
	Run an action that may need code processing.
*******************************************************************************/
extern "C" GroupItem *runAction(GroupItem *argument, GroupItem *field)
{
GroupItem 	*result = 0;
GroupItem 	*ruleArg = 0;
	if ( isCoded(field->groupBody->flags.actionType) )
		if ( !::processCode(field) )
			return 0;
	if ( ruleArg = field->get("argument") )
		if ( argument )
			ruleArg->setGroup(result = argument);
		else	ruleArg->setGroup(result = field);
	else	result = field;
	GroupControl::groupController->groupRules->lastREF->setGroup(result);
	result = ::processAction(field);
	return result;
}

/***************************************************************************
    runByteFn — Track A dispatch primitive. A bytecode op carries a
    method-bound `interpret` child (built by interpretMethod). Invoking that
    child's method from incant is the poochifier (`=` drops the binding), so
    interpretBC delegates here: fetch the child and call its bound handler in
    place, with the op as the instruction. No copy, no `=`. Label ops have no
    `interpret` child -> null -> interpretBC treats it as a no-op fall-through.
***************************************************************************/
extern "C" GroupItem *runByteFn(GroupItem *instr)
{
GroupItem 	*interp = instr->get("interpret");
GroupItem 	*result = 0;
	if ( interp )
		result = interp->groupBody->gMethod(instr);
	if ( interp )
		return result;
	return 0;
}

/***************************************************************************
    runOP fires off a field that might be an action, a rule, a method,
    or an operator
***************************************************************************/
extern "C" GroupItem *runOP(GroupItem *field)
{
GroupItem 	*result = 0;
GroupItem 	*op = field->get(1);
GroupItem 	*arg = field->get(3);
GroupItem 	*target = field->get(2);
	if ( isGROUP(target->groupBody->flags.data) && !target->groupBody->flags.isPointer )
		target = target->getGroup();
	if ( arg && isGROUP(arg->groupBody->flags.data) && !arg->groupBody->flags.isPointer )
		arg = arg->getGroup();
	if ( op->groupBody->flags.instructType && isMethod(target->groupBody->flags.instructType) && target->groupBody->flags.invoke )
		target = target->groupBody->gMethod(target);
	if ( arg )
		if ( isMethod(arg->groupBody->flags.instructType) && arg->groupBody->flags.invoke )
			arg = arg->groupBody->gMethod(arg);
		else
		if ( isLIST(arg->groupBody->flags.binType) )
			arg = ::resolveList(arg);
	if ( target && target->groupBody->flags.isVirtual )
		target = ::copyOf(target);
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
	if ( field && field->groupBody->flags.data )
		{
		ruler->divertToRule = 1;
		ruler->pushInput(field);
		}
	result = rule->parse(0);
	if ( field && field->groupBody->flags.data )
		ruler->popInput();
	return result;
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
GroupItem 	*grup = 0;
	if ( !isSTAK(action->groupBody->flags.data) )
		{
		recurseSTAK = new Stak();
		action->setStak(recurseSTAK);
		}
	else	recurseSTAK = action->getStak();
	while ( grup = action->next(grup) )
		if ( grup->groupBody->flags.isLocal && !grup->groupBody->flags.noPrint )
			{
			body = new GroupBody();
			*body = *grup->groupBody;
			grup->clear();
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
			block->groupBody->flags.instructType = 1;
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

/***************************************************************************
    setLabel sets the rule label to input.
***************************************************************************/
extern "C" GroupItem *setLabel(GroupItem *input)
{
RuleStuff 	*ruleStuff = input->rStuff;
GroupItem 	*pLabel = ruleStuff->parentStuff->label;
GroupItem 	*JSONtoken = pLabel->getLabelGroup("JSONtoken");
GroupItem 	*JSONvalue = pLabel->getLabelGroup("JSONvalue");
GroupItem 	*grup = new GroupItem(JSONtoken->getText());
	grup->setText(JSONvalue->getText());
	return grup;
}

/*****************************************************************************
	setLimits() checks field passed in for limits (min and max).
*****************************************************************************/
extern "C" void setLimits(GroupItem *rule, GroupItem *limits)
{
RuleStuff 	*ruleStuff = rule->rStuff;
GroupItem 	*maximum = limits->getAttribute("max");
GroupItem 	*minimum = limits->getAttribute("min");
	ruleStuff->min = minimum->getCount();
	if ( maximum )
		ruleStuff->max = maximum->getCount();
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
		else	::fprintf(stderr,"setMark: ERROR mark offset exceeds current buffer length\n");
		}
	else	::fprintf(stderr,"setMark: ERROR no buffer source provided\n");
	return 0;
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

/***************************************************************************
	Splice one directive's statements into a target action's BlocK. The
	target's BlocK is built (processCode) if it does not exist yet, then the
	directive's own BlocK is built and its statements (BlocK->Lines members)
	are moved into the target's Lines: appended at the body bottom for
	at=ending, or front-inserted at the body top otherwise (at=starting /
	default, walked in reverse so original order leads the target's body).
	Statements are moved, not copied: addGroup copies a node that still has a
	parent and the copy loses instructType (aCTionBlocK then skips it), so each
	statement is detached (parent = 0) before it is added.
***************************************************************************/
extern "C" void spliceDirectives(GroupItem *target, GroupItem *directive)
{
GroupItem 	*BlocK = target->get("BlocK");
GroupItem 	*targetLines = 0;
GroupItem 	*dBlocK = 0;
GroupItem 	*dLines = 0;
GroupItem 	*at = 0;
GroupItem 	*stmt = 0;
GroupItem 	*adjacent = 0;
int 		ending = 0;
	if ( !BlocK )
		{
		::processCode(target);
		BlocK = target->get("BlocK");
		}
	if ( !BlocK )
		return;
	targetLines = BlocK;
	if ( !targetLines )
		return;
	::processCode(directive);
	dBlocK = directive->get("BlocK");
	if ( !dBlocK )
		return;
	dLines = dBlocK;
	if ( !dLines || !dLines->groupBody->groupList )
		return;
	at = directive->get("at");
	ending = at && ::compare(at->getText(),"ending") == 0;
	if ( ending )
		{
		stmt = dLines->groupBody->groupList->firstInList;
		while ( stmt )
			{
			adjacent = stmt->nextInParent;
			stmt->parent = 0;
			targetLines->addMember(stmt);
			stmt = adjacent;
			}
		}
	else {
		stmt = dLines->groupBody->groupList->lastInList;
		while ( stmt )
			{
			adjacent = stmt->priorInParent;
			stmt->parent = 0;
			targetLines->insertGroup(stmt);
			stmt = adjacent;
			}
		}
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
	return input;
}

/***************************************************************************
	Immediate method for the testing command — scratch verification harness,
	rewritten per the current need (see CLAUDE.md). Currently drives the JIT
	compile path: testing(<action>) runs jitRunAction on the action, which
	raises the jitting gate, walks the body via processCode (emitting LLVM IR
	through the operators' jit dispatch), then ORC-compiles and fires. Invoke:
		testing(jitAdd);
	(The earlier bcLIST-priming bytecode harness is in git history; restore it
	here when bytecode-emit verification is the need again.)
	NB: keep this body free of `//` comments — they bleed field-resolution into
	the following externs (unWrap/writeTempFile). Doc goes here, in the block.
***************************************************************************/
extern "C" GroupItem *testing(GroupItem *input)
{
	::jitRunAction(input);
	return input;
}

/***************************************************************************
	Gloms parent label components together into the label string
***************************************************************************/
extern "C" GroupItem *tokenize(GroupItem *label)
{
RuleStuff 	*ruleStuff = label->rStuff;
char 		*atEnd = GroupControl::groupController->groupRules->atRuleMark;
int 		tokenLength = (int)(atEnd - ruleStuff->hereAt);
	label->setToken(ruleStuff->hereAt,tokenLength);
	return label;
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

/***************************************************************************
    Write a buffer field's contents to /tmp/<field.tag> and close. Used as
    the buffer-to-disk handoff for pipelines that need to run an external
    tool (tok, etc.) on the buffer contents and consume the tool's output.
    Returns the field unchanged so it can be threaded through a pipeline.
    Used in incant directives processing.
***************************************************************************/
extern "C" GroupItem *writeTempFile(GroupItem *bufField)
{
char 	*tempPath = 0;
	if ( isBUFFER(bufField->groupBody->flags.data) )
		{
		tempPath = ::concat(2,"/tmp/",bufField->groupBody->tag);
		bufField->getBuffer()->setFile(tempPath);
		bufField->getBuffer()->closeFile();
		}
	return bufField;
}

/*******************************************************************************
	GroupRules constructor
*******************************************************************************/
GroupRules::GroupRules()
{
	atRuleMark = 0;
	ruleSTUFF = 0;
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
	lastREF = 0;
	lastStatement = 0;
	generator = 0;
	printSPACE = 0;
	ruleSkipSet = 0;
	searchList = 0;
	setupFILE = 0;
	sourceFILE = 0;
	trueResult = 0;
	skipSet = 0;
	inputSTAK = 0;
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
	noSkipping = 0;
	processingCode = 0;
	showWarnings = 0;
	jitting = 0;
	blockSTAK = new Stak();
	bufferSTAK = new Stak();
	alphaSet = new PLGset("a-zA-Z");
	nameSet = new PLGset("a-zA-Z0-9");
	punctuateSet = new PLGset("]{}[();");
	runningActions = new GroupItem("runningActions");
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
			GroupItem 	*sourceFILE = (GroupItem*)inputSTAK->pop();
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
	insertAfter(GroupItem*)
*/
