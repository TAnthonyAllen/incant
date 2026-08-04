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
	if ( token && token->groupBody->registry == GroupControl::groupController->groupRules->keyWords )
		return 0;
	return input;
}

/*******************************************************************************
	The BlocK rule action.
*******************************************************************************/
/*******************************************************************************
    A BARE `return;` YIELDS THE PRIOR STATEMENT'S VALUE, not the keyword's tag.
    Tony's ratification, 2026-07-31: bare return means STOP, and an action's
    value is the value of the last executed statement. The old "return" string
    was CLAIM KANT-10 leaking -- aCTionBrancH falls back to the BrancheS keyword
    node when there is no expression, and a node with no data returns its own
    TAG. It was never a semantics.

    WHY THE FIX IS HERE AND NOT ONLY IN aCTionBrancH: the VALUE and the BRANCH
    SIGNAL ride the SAME NODE. aCTionBrancH stamps isBranch (1 break, 2
    continue, 3 return) on whatever it returns, and FOUR loop handlers read that
    flag back off the body's returned value (aCTionWhilE, aCTionDO, aCTionFOR,
    and this loop). Substituting a different node for the value would drop the
    signal with it and silently kill `break` and `continue` in every loop --
    measured, and nothing in the tree covered it before incant/loopBranchT.
    So the substitution re-stamps isBranch on the value it hands back.

    SCOPED TO isBranch == 3 (RETURN) AND TO A KEYWORD NODE, deliberately:
      - only a BARE branch returns the keyword node itself, so testing the
        registry is what distinguishes `return;` from `return someField;`
      - break/continue are handled at the LOOP boundary instead, not here.
        Ratified separately 2026-07-31: a break is CONSUMED by the innermost
        loop and propagates nothing. See the matching note in aCTionDO, and
        incant/loopBranchT for the fixture that covers all three.
    A bare return always reaches processAction, which clears isBranch at the
    action boundary, so the re-stamp cannot leak past the action.

    DEGENERATE CASE, left as-is and noted: an action whose FIRST statement is a
    bare return has no prior value, so it still yields the keyword node.
*******************************************************************************/
extern "C" GroupItem *aCTionBlocK(GroupItem *input)
{
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
		if ( GroupControl::groupController->groupRules->jitting )
			{
			 jitStoreResult(); 
			}
		if ( result && result->groupBody->flags.isBranch )
			{
			if ( prior && result->groupBody->flags.isBranch == 3 && result->groupBody->registry == GroupControl::groupController->groupRules->keyWords )
				{
				result = prior;
				result->groupBody->flags.isBranch = 3;
				}
			break;
			}
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
	/*  BRANCHES UNDER JITTING. `continue` emits a branch to the innermost
	loop's condition block; break and return DEGRADE LOUDLY rather than
	emitting nothing.
	
	⚠ THE DEGRADE ARM IS THE POINT, not politeness. In the displayForm dump
	`continue` appeared to work because both arms of the enclosing if fell
	through to a block that branched to `cond` -- which happened to be the
	back edge. A construct correct by accident of topology stays correct
	exactly until the block structure moves. break and return are in that
	same state RIGHT NOW, so they are COUNTED here instead of being left to
	look fine; a jitDegrade count the ladder already asserts at zero turns
	them from invisible into a red the moment a fixture reaches one.
	
	⚠ THE TAG IS READ DIRECTLY rather than testing the flags set two lines
	above. Those assignments are bare, so which node they land on is a
	bare-name-resolution question (the last mentioned field is BrancheS, not
	arg, and the header comment says the stamp is meant for what is
	returned). That discrepancy is NOT this edit's business -- reading
	*BrancheS.tag mirrors the switch exactly and settles nothing either way.  */
	if ( GroupControl::groupController->groupRules->jitting )
		{
		
		if (*BrancheS->groupBody->tag == 'c')    jitEmitContinue();
		else    jitDegrade("break/return under jit -- no emitter yet", input);
		
		}
	return arg;
}

/*******************************************************************************
	Immediate method for the CerR rule -- THE STDERR SINK, added 2026-08-01.
        CerR        cerr- followedBy PRINTing- stuff=PrintXP+ SemI- defer;

    Term-for-term identical to PrinT with one substitution, the keyword; and
    this body is aCTionPrinT's operand loop with one substitution, the closing
    call. That is Tony's ruling KANT-13 in force -- ONE print mechanism, several
    destinations: PrintXP+ is fixed and only the sink varies.

    ⚠ NO `generating` BRANCH, and that is a real difference from aCTionPrinT
    rather than an omission. aCTionPrinT's generating arm is documented there as
    "currently UNUSED on the bytecode print path" and kept as the future home
    for operand compilation. A diagnostic sink has no bytecode story yet, so
    inventing one here would be building a branch nothing can reach and nothing
    can test. When `cerr` needs to be emitted, it inherits that arm from the
    print work rather than having grown a speculative copy of it.
*******************************************************************************/
extern "C" GroupItem *aCTionCerR(GroupItem *input)
{
GroupItem 	*stuff = input->getLabelGroup("stuff");
Buffer 		*buffer = (Buffer*)GroupControl::groupController->groupRules->bufferSTAK->pop();
	/*  DEGRADE-BY-DEFAULT (Tony's ruling via Clay, 2026-08-05). BODY-REACHABLE
	CONTENT with no emitter, so under jitting it would otherwise EXECUTE AT
	EMIT TIME -- once, silently, in the wrong era. It now announces itself
	through the counter the ladder already asserts at zero, then FALLS
	THROUGH and runs interpreted, so behaviour is unchanged and the gap is
	COUNTED rather than invisible.
	docs/gateCensus.md: one of the five. The WALK MACHINERY (aCTionExpressioN
	et al.) is deliberately NOT in this set -- degrading the emit walk would
	stop the compiler rather than surface a bug.
	⚠ MUST SIT AFTER THE WHOLE DECLARATION BLOCK. Placed by a heuristic the
	first time, it landed INSIDE two multi-line declaration lists and wiped
	GroupRules.h's extern block to ZERO (bear-trap #24's signature, canary
	239 -> 0). Declarations here span lines and end on a bare `;`.  */
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
	Immediate method for the CouT rule -- THE EXPLICIT STDOUT SINK, 2026-08-01.
        CouT        cout- followedBy PRINTing- stuff=PrintXP+ SemI- defer;

    WHY IT EXISTS, and it is not symmetry for its own sake (Tony): `print` is
    DIVERTIBLE -- printTO() sends it to a buffer -- and the moment you have
    diverted it you invariably need a way to reach the terminal anyway. `cout`
    is that way. So the three keywords are not three names for one thing:

        print   divertible      -> buffer if armed, else stdout
        cout    NOT divertible  -> always stdout
        cerr    NOT divertible  -> always stderr

    That is the KANT-13 shape exactly: one mechanism (PrintXP+, one spacing
    default, one appendPrintXP walk), the keyword selecting only the sink.

    ⚠ THIS CLOSES KANT-23. The pinned defect was that a grafted `cout` WAS
    being captured by an armed diversion -- genLadder/printPop.sh calls that
    "the single most important byte in either file". A native CouT routed
    through opCout, which never consults toBUFFER, cannot be captured. The
    printFamilyNew divergence targets move accordingly and the move is
    accounted for in printPop.sh.
*******************************************************************************/
extern "C" GroupItem *aCTionCouT(GroupItem *input)
{
GroupItem 	*stuff = input->getLabelGroup("stuff");
Buffer 		*buffer = (Buffer*)GroupControl::groupController->groupRules->bufferSTAK->pop();
	/*  DEGRADE-BY-DEFAULT (Tony's ruling via Clay, 2026-08-05). BODY-REACHABLE
	CONTENT with no emitter, so under jitting it would otherwise EXECUTE AT
	EMIT TIME -- once, silently, in the wrong era. It now announces itself
	through the counter the ladder already asserts at zero, then FALLS
	THROUGH and runs interpreted, so behaviour is unchanged and the gap is
	COUNTED rather than invisible.
	docs/gateCensus.md: one of the five. The WALK MACHINERY (aCTionExpressioN
	et al.) is deliberately NOT in this set -- degrading the emit walk would
	stop the compiler rather than surface a bug.
	⚠ MUST SIT AFTER THE WHOLE DECLARATION BLOCK. Placed by a heuristic the
	first time, it landed INSIDE two multi-line declaration lists and wiped
	GroupRules.h's extern block to ZERO (bear-trap #24's signature, canary
	239 -> 0). Declarations here span lines and end on a bare `;`.  */
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
			if ( isContinue(result->groupBody->flags.isBranch) )
				continue;
			else
			if ( isReturn(result->groupBody->flags.isBranch) )
				return result;
			/*  BREAK IS CONSUMED HERE, ratified 2026-07-31. A break terminates
			the INNERMOST loop and propagates NOTHING -- statements after
			the loop run. Clearing isBranch is what makes that true: the
			flag and the value ride the same node, so leaving it set made
			the enclosing aCTionBlocK break too, and the code after the loop
			became unreachable (measured, incant/loopBranchT row 1).
			Dropping a bare break's keyword node as the VALUE kills the
			matching CLAIM KANT-10 leak -- the loop's value fell through to
			`if !result result = falseResult;` below.  */
			result->groupBody->flags.isBranch = 0;
			if ( result->groupBody->registry == GroupControl::groupController->groupRules->keyWords )
				result = 0;
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
			if ( ruler->currentRegistry->groupBody->flags.isRule )
				{
				NewGroup = ruler->currentRegistry->addMember(NewGroup);
				if ( !NewGroup->groupBody->flags.binType )
					NewGroup->groupBody->flags.isRule = 1;
				if ( !NewGroup->rStuff )
					NewGroup->setRStuff(new RuleStuff(NewGroup));
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
					if ( item->groupBody->flags.isRule && item->rStuff )
						{
						grup->setRStuff(new RuleStuff(item->rStuff));
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
					{
					RuleStuff 	*fresh = new RuleStuff(newMember);
					newMember->setRStuff(fresh);
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
	/***********************************************************************
	THE DEFINITION IS COMPLETE HERE — attributes and members are both in —
	so this is where a term's rStuff is materialised (Clay SEQ 27). Doing it
	at the completion point rather than per-attribute is what avoids the
	ordering hazard rung 7 hit with alternation binding: a definition
	attribute fires WHEN PARSED, which for an alternation is before its
	members exist.
	
	Almost always a no-op: `modify` has already materialised anything
	carrying a modifier, and terms from incant source come back with rStuff
	regardless. It is here so the INVARIANT holds at the define point rather
	than holding by luck.
	
	Note I commented this out because rStuff should be there already if
	the NewGroup is a rule and zero if it is not
	materialiseTerms(NewGroup);
	***********************************************************************/
	input->clearList();
	NewGroup->groupBody->flags.isInitialized = 1;
	if ( NewGroup->groupBody->registry && !NewGroup->parent )
		NewGroup->parent = ruler->currentRegistry;
	if ( NewGroup->groupBody->flags.addingMembers )
		NewGroup->groupBody->flags.addingMembers = 0;
	if ( ruler->currentDefine && ruler->currentDefine->groupBody == NewGroup->groupBody )
		ruler->currentDefine = 0;
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
	/*  DEGRADE-BY-DEFAULT (Tony's ruling via Clay, 2026-08-05). BODY-REACHABLE
	CONTENT with no emitter, so under jitting it would otherwise EXECUTE AT
	EMIT TIME -- once, silently, in the wrong era. It now announces itself
	through the counter the ladder already asserts at zero, then FALLS
	THROUGH and runs interpreted, so behaviour is unchanged and the gap is
	COUNTED rather than invisible.
	docs/gateCensus.md: one of the five. The WALK MACHINERY (aCTionExpressioN
	et al.) is deliberately NOT in this set -- degrading the emit walk would
	stop the compiler rather than surface a bug.
	⚠ MUST SIT AFTER THE WHOLE DECLARATION BLOCK. Placed by a heuristic the
	first time, it landed INSIDE two multi-line declaration lists and wiped
	GroupRules.h's extern block to ZERO (bear-trap #24's signature, canary
	239 -> 0). Declarations here span lines and end on a bare `;`.  */
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
			/*  BREAK IS CONSUMED HERE, ratified 2026-07-31. A break terminates
			the INNERMOST loop and propagates NOTHING -- statements after
			the loop run. Clearing isBranch is what makes that true: the
			flag and the value ride the same node, so leaving it set made
			the enclosing aCTionBlocK break too, and the code after the loop
			became unreachable (measured, incant/loopBranchT row 1).
			Dropping a bare break's keyword node as the VALUE kills the
			matching CLAIM KANT-10 leak -- the loop's value fell through to
			`if !result result = falseResult;` below.  */
			result->groupBody->flags.isBranch = 0;
			if ( result->groupBody->registry == ruler->keyWords )
				result = 0;
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
	if ( GroupControl::groupController->groupRules->jitting )
		{
		 return jitEmitGIF(input); 
		}
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

/*******************************************************************************
	The rule action for the Iterate rule
         Iterate     ANYtoken "on"- ANYtoken attributes? members?;
*******************************************************************************/
extern "C" GroupItem *aCTionIterate(GroupItem *input)
{
GroupItem 	*attributes = input->getLabelGroup("attributes");
GroupItem 	*members = input->getLabelGroup("members");
GroupItem 	*iterator = input->get(1);
GroupItem 	*source = input->get(2);
	/*  ⚠ EMIT, THEN FALL THROUGH -- the only gate in the tree that does not
	return, and deliberately so. The emit-time walk still needs the iterator
	ESTABLISHED, because the enclosing `while ++grup` must take opPlusPlus's
	iterator arm to reach jitEmitIterStep; gate-and-return would leave the
	node un-flagged and the advance would emit against the DATA arm.
	The emitted call re-establishes the iterator at RUN time, which is the
	gap that made displayForm hang: the advance was emitted and the setup
	was not, so the two lived at different times.  */
	if ( GroupControl::groupController->groupRules->jitting )
		{
		 jitEmitIterate(input); 
		}
	while ( isGROUP(iterator->groupBody->flags.data) )
		iterator = iterator->getGroup();
	while ( isGROUP(source->groupBody->flags.data) )
		source = source->getGroup();
	// here iterator gets a copy of the source groupList
	if ( iterator && source && source->groupBody->groupList )
		{
		iterator->groupBody->groupList = source->groupBody->groupList;
		/*  THE RESET, and this is the only place it can live. The poison means
		"the LAST iterate on this node was refused", so a fresh, successful
		iterate is exactly what un-poisons it -- and under Tony's 2026-08-02
		iterator design re-running the Iterate rule is the ONLY way to change
		an iterator's source, so nothing can become live again behind this
		line's back. Clearing anywhere else (at the advance, at action exit)
		would either un-poison a still-refused iterator or leave a live one
		poisoned.  */
		iterator->groupBody->flags.fLAG = 0;
		}
	else {
		/*  A REFUSED SOURCE IS ANNOUNCED ONCE AND POISONED (Tony's ruling,
		2026-08-02). Announced HERE, at the door, not per advance -- the
		advance is silent and merely refuses to move.
		Without this, a refused iterate returned 0 BEFORE setting
		isIterator, so `while ++grup` missed opPlusPlus's iterator arm
		entirely and fell through to the DATA arm: `if !data count = 1;`
		returns the node, which is truthy, so the loop never ends.
		Measured on iterT1m before the fix: 1,475,745 refusals, each with a
		DISTINCT source pointer and the iterator alternating leafA/leafB --
		so it is genuine mutual recursion re-entering, not a retry loop
		inside the rule machinery. That distinction was checked first
		because the two want opposite fixes.  */
		if ( iterator )
			iterator->groupBody->flags.fLAG = 1;
		::fprintf(stderr,"aCTionIterate: source %s has no list\n",source->groupBody->tag);
		return 0;
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
    NamE rule action

    BEAR COUNTRY: the `defining && ... isVirtual -> copyOf` line below is a
    virtual fork, and it is define-gated ON PURPOSE. Virtual forks are define-
    time only. Without the `defining` gate, a READ of a virtual field (naming
    it as an operand) would fork a fresh empty copy and you would silently read
    0 / write to a copy nobody can find. If you are tempted to fork a virtual
    here outside a defining context, you have a bug. See the jigcorpus virtual-
    tag pattern and the wakeup bear-trap log.
*******************************************************************************/
extern "C" GroupItem *aCTionNamE(GroupItem *input)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*action = ruler->currentMETHOD;
GroupItem 	*grup = 0;
GroupItem 	*result = 0;
char 		*arg = input->getText();
	result = GroupControl::groupController->locateInMethod(arg);
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
        NumbeR=[0-9]+               FloaT? tokenize:
            HeX='0'                 x=[xX] value=[0-9a-fA-F]+ tokenize;;
        FloaT='.'                   float=[0-9]+ PoweR?;
*******************************************************************************/
extern "C" GroupItem *aCTionNumbeR(GroupItem *input)
{
char 	*arg = input->getText();
	if ( arg )
		{
		/*  KANT'S NUMERIC TOWER IS count AND double. NO FLOATS, EVER (Tony,
		2026-08-01). A float-like literal IS a double literal and must
		survive as one -- so a decimal point mints isNUMBER here, at the
		literal's birth, and nothing rounds it.
		
		⚠ THIS TESTS THE TEXT, NOT THE `FloaT` LABEL, AND THAT IS THE FIX.
		The old code read `GroupItem FloaT:;` and branched on it. MEASURED
		2026-08-01 with a trace in this function: for input `3.5` the label
		is ABSENT while the token text is exactly "3.5" -- NumbeR matched
		the decimal fine, but `tokenize` on NumbeR flattens the match into a
		single token and the FloaT child label does not survive for this
		action to see. So the branch was ALWAYS taking atoi, and every
		double literal in the language silently truncated at birth:
		3.5 -> 3      0.25 -> 0      1.5e2 -> 1      3.5 + 1 -> 4
		No rounding, no diagnostic. The text, however, is intact and
		complete -- including the exponent -- so it is the reliable
		classifier and atof consumes it directly.
		
		Exponent-only forms (`1e5`) are NOT reachable to begin with: FloaT
		requires a leading '.', so NumbeR matches just "1" and "e5" tokenizes
		separately. A '.' test therefore covers everything that can reach
		here, and `1.5e2` works because FloaT spells '.' decimals PoweR?.
		
		Written as an explicit scan rather than a libc call: the surrounding
		code is plain tok, and a bare short C name here is precisely the
		collision class of bear-traps #12 and #17.  */
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
	/*  JITTED PRINT (work item 3, Tony's ruling via Clay, 2026-08-04). Under
	jitting a print USED TO FIRE AT COMPILE TIME -- once, reporting
	compile-time state -- which is worse than not printing at all because it
	appears to work. The emit-time walk must be EFFECT-FREE; the ladder's
	compile-once-fire-twice proof already assumed it was.
	
	THE WALK BELOW IS appendPrintXP's, TERM FOR TERM, with the append
	replaced by an emitted call. It is duplicated here and nowhere else
	because the two differ in exactly one line -- appendPrintXP appends NOW,
	this emits a call that appends LATER -- and the thing that must not be
	duplicated is what appendGroup owns: shortcut semantics, formats, indent.
	Those stay in the chain; appendGroupValue routes into them.  */
	/*  ⚠ THE THREE EMITTERS ARE CALLED AT tok LEVEL, NOT FROM PASSTHROUGH, and
	that is load-bearing twice over. Written as passthrough first, it hit
	BOTH documented hazards at once: `FormaT` is declared here but was
	referenced only inside the passthrough, so tok pruned it as unused
	(bear-trap #13) and the generated call named an undeclared identifier.
	A tok-level call is a tok-level USE, so nothing is pruned.
	⚠ AND THE DECLARATION ORDER BELOW MATCHES appendPrintXP's EXACTLY --
	FormaT, result, ExpressioN. Reordered to put result last, tok bound the
	bare `isMethod` to `result` instead of to `ExpressioN` (last-mentioned
	wins) and generated a read of an unassigned pointer. Copying the walk
	means copying its declaration order.  */
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
				::jitPrintItem(grup,FormaT,1);
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
	/*  DEGRADE-BY-DEFAULT (Tony's ruling via Clay, 2026-08-05). BODY-REACHABLE
	CONTENT with no emitter, so under jitting it would otherwise EXECUTE AT
	EMIT TIME -- once, silently, in the wrong era. It now announces itself
	through the counter the ladder already asserts at zero, then FALLS
	THROUGH and runs interpreted, so behaviour is unchanged and the gap is
	COUNTED rather than invisible.
	docs/gateCensus.md: one of the five. The WALK MACHINERY (aCTionExpressioN
	et al.) is deliberately NOT in this set -- degrading the emit walk would
	stop the compiler rather than surface a bug.
	⚠ MUST SIT AFTER THE WHOLE DECLARATION BLOCK. Placed by a heuristic the
	first time, it landed INSIDE two multi-line declaration lists and wiped
	GroupRules.h's extern block to ZERO (bear-trap #24's signature, canary
	239 -> 0). Declarations here span lines and end on a bare `;`.  */
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
	Immediate method for the StringXP rule.
        StringXP    ","- stuff=PrintXP+ defer;
*******************************************************************************/
extern "C" GroupItem *aCTionStringXP(GroupItem *input)
{
GroupItem 	*stuff = input->getLabelGroup("stuff");
Buffer 		*buffer = (Buffer*)GroupControl::groupController->groupRules->bufferSTAK->pop();
	/*  DEGRADE-BY-DEFAULT (Tony's ruling via Clay, 2026-08-05). BODY-REACHABLE
	CONTENT with no emitter, so under jitting it would otherwise EXECUTE AT
	EMIT TIME -- once, silently, in the wrong era. It now announces itself
	through the counter the ladder already asserts at zero, then FALLS
	THROUGH and runs interpreted, so behaviour is unchanged and the gap is
	COUNTED rather than invisible.
	docs/gateCensus.md: one of the five. The WALK MACHINERY (aCTionExpressioN
	et al.) is deliberately NOT in this set -- degrading the emit walk would
	stop the compiler rather than surface a bug.
	⚠ MUST SIT AFTER THE WHOLE DECLARATION BLOCK. Placed by a heuristic the
	first time, it landed INSIDE two multi-line declaration lists and wiped
	GroupRules.h's extern block to ZERO (bear-trap #24's signature, canary
	239 -> 0). Declarations here span lines and end on a bare `;`.  */
	if ( GroupControl::groupController->groupRules->jitting )
		jitDegrade("string expression under jit -- no emitter, builds at emit time",input);
	if ( !buffer )
		buffer = new Buffer("print buffer");
	::appendPrintXP(stuff,buffer);
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
				if ( isContinue(result->groupBody->flags.isBranch) )
					continue;
				else
				if ( isReturn(result->groupBody->flags.isBranch) )
					return result;
				/*  BREAK IS CONSUMED HERE -- see aCTionDO's copy of this block
				for the full note. Ratified 2026-07-31: break terminates the
				innermost loop and propagates nothing.  */
				result->groupBody->flags.isBranch = 0;
				if ( result->groupBody->registry == GroupControl::groupController->groupRules->keyWords )
					result = 0;
				break;
				}
			}
		else	break;
		}
	if ( !result )
		result = GroupControl::groupController->groupRules->falseResult;
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

/*******************************************************************************
    appendGroupValue -- THE VALUE ENTRY ON appendGroup. Tony's ruling via Clay,
    2026-08-04.

    WHY IT EXISTS. Print's chain is opPrint -> appendGroup -> printField, and
    appendGroup takes a GroupItem. The JIT's values are i32 SSA registers, and a
    LOCAL's live value sits in a frame slot until the epilogue writes it back --
    so handing appendGroup a field POINTER mid-function would read storage the
    epilogue has not written yet. That is a silent wrong answer, the worst class,
    and it is why the jitted path cannot simply reuse the pointer entry.

    THE ALTERNATIVE WAS REJECTED ON COST: spilling live values to their frame
    slots before every print turns each print into a SYNC BARRIER and requires
    the JIT to enumerate liveness -- heavier machinery, bought to keep one
    function signature pristine.

    ⚠ NOTHING IS DUPLICATED, WHICH IS THE POINT OF PUTTING IT HERE. This does not
    reimplement shortcut handling, formats or indent -- it routes INTO
    appendGroup's own switch. A shortcut token is passed straight through
    untouched; a value is stamped on a carrier node and handed to the same call
    every interpreted print uses. So `~ $ _ : + - ` ,` and FormaT stay
    single-sourced in the chain, and a change to shortcut semantics reaches the
    jitted path for free.

    A FRESH CARRIER PER CALL, not a static one. BDWGC makes it cheap, and a
    shared carrier would be a second name for a value in flight -- the
    one-channel-one-meaning failure this project has already paid for twice.

    ⚠ IT TAKES NO TOKEN, AND THAT IS A CORRECTION WORTH KEEPING. The first cut
    took the item node too and chose between "pass the node" and "stamp the
    value" by testing isShortcut -- which is the WRONG DISCRIMINATOR and printed
    `0` where a literal belonged, because a literal string is not a shortcut and
    fell into the value path. appendPrintXP keys off EXPRESSION PRESENCE, not
    shortcut-ness: an item with an ExpressioN contributes a computed value, and
    everything else -- literals AND shortcuts -- contributes ITSELF. So the
    caller makes that choice exactly as the interpreted walk does, and this entry
    is only ever reached with a real value in hand.

    PHASE SCOPE: i32 counts, matching what the emitters produce today. A double
    or string entry is the same shape with a different setter and wants a rung
    before it is written.
*******************************************************************************/
extern "C" GroupItem *appendGroupValue(int value, GroupItem *FormaT, Buffer *buffer)
{
GroupItem 	*carrier = new GroupItem("jitPrintValue");
	carrier->setCount(value);
	return ::appendGroup(carrier,FormaT,buffer);
}

/*******************************************************************************
	appendPrintXP -- THE ONE PrintXP WALK. Added 2026-08-01 (Tony's call) when
    the arrival of `cerr` and `cout` made it the FOURTH copy of the same loop.

    Callers: aCTionPrinT, aCTionStringXP, aCTionCerR, aCTionCouT. They now
    differ only in their TAIL -- which sink op they close with -- which is
    Tony's ruling KANT-13 made structural instead of merely observed: ONE print
    mechanism, several destinations. A per-destination spacing or formatting
    default is no longer something you could introduce by accident; there is one
    body and four call sites.

    ⚠ WHAT DELIBERATELY DID NOT MOVE IN HERE, because hoisting it would have
    been a silent behaviour change rather than a refactor:
      - `isPRINTING = false;`  aCTionPrinT sets it, aCTionStringXP does not.
        That asymmetry is PRE-EXISTING and load-bearing (see the isPRINTING note
        on aCTionTokenXP's guard); hoisting it would have started clearing a
        generating-path flag on the string path. It stays in the callers.
      - aCTionPrinT's `generating` branch, which is a whole separate arm above
        this loop and has no equivalent on the other three.
      - the closing sink call, obviously -- that IS the difference.
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
    the file. Returns the loaded field.
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

/*****************************************************************************
    auditTerms / auditRegistry -- materialiseTerms' walk with the OPPOSITE
    intent. It repairs nothing; it reports what is missing.

    Tony's ruling (2026-07-29): rStuff is set at DEFINITION time across the
    board, and the runtime setting goes away. materialiseRegistry is a backup
    plan, not the mechanism. This is what is left when the repairing is stripped
    out -- the verification, without the silent fixing-up behind the code's back.

    THE INVARIANT IT CHECKS, and it is a BICONDITIONAL: isRule IFF has rStuff.

    Direction 1 SPLITS, for the same reason direction 2 did -- splitting spurious
    took the answer from "20, act on it" to "4, and 16 you must not touch", and
    there was never a reason to think the missing were one population either:
      MISSRULE -- a RULE itself carrying no rStuff.
      MISSTERM -- a term OF a rule carrying none.
    Direction 2, auditSpurious -- rStuff on something that is NOT a rule, and it
    splits into TWO POPULATIONS that must not be added together:
      TERM  -- a term OF a rule. genParse REQUIRES these to carry rStuff; that is
               what "unmaterialised term" means, and Limit's min/max were given
               rStuff deliberately on 2026-07-29 to turn the census green. Counted
               and printed, but NOT totalled -- stripping these would regress the
               census immediately.
      LOOSE -- rStuff on a node that is neither a rule nor a rule's term. THIS is
               the population Tony described. Only these are totalled. Tony,
    2026-07-29: non-rules pick rStuff up off whatever rule matched them (the
    `--` entry in Operators carrying QuotE's), because GroupItem's copy
    constructor copies rStuff whenever the source has it and never asks whether
    the target is a rule. His `if !isRule rStuff = 0;` in aCTionDefinE corrects
    the symptom downstream; the cause is the constructor. That is Tony's
    `if !isRule rStuff = 0;` read as an assertion rather than an action, which is
    why the walk skips non-rules instead of flagging them -- a non-rule with no
    rStuff is CORRECT, not missing.

    WHY IT PRINTS EVEN WHEN CLEAN, and this is the whole point. The instrument
    it replaces was getRStuff's "no rStuff - creating" cerr, and grepping for
    that returns zero in TWO indistinguishable cases: nothing fired late, and
    the cerr was deleted. The second became true on 2026-07-29. An absence-based
    check passes by being removed; a presence-based one cannot. So the summary
    line is unconditional and pop.sh asserts it is THERE, not that a warning is
    absent.
*****************************************************************************/
extern "C" int auditMissingRules(GroupItem *registry)
{
GroupItem 	*entry = 0;
int 		missing = 0;
	while ( entry = registry->next(entry) )
		if ( entry->groupBody->flags.isRule && !entry->rStuff )
			{
			::fprintf(stderr,"AUDIT MISSRULE %s/%s -- isRule, no rStuff\n",registry->groupBody->tag,entry->groupBody->tag);
			missing++;
			}
	return missing;
}

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
				if ( term->groupBody->flags.isRule && !term->rStuff )
					{
					::fprintf(stderr,"AUDIT MISSTERM %s [%s] %s -- isRule term, no rStuff\n",entry->groupBody->tag,::toStringFromInt(i),term->groupBody->tag);
					missing++;
					}
				i++;
				}
			}
	return missing;
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
    The incant `audit` command invokes this. It reports every isRule node that
    is missing rStuff, and prints an UNCONDITIONAL summary line.

        audit();            every registry on `registries`
        audit(Grokking);    one named registry

    EMPTY PARENS ARRIVE AS AN InvokeArg NODE, not as null -- measured, not
    assumed: `audit()` reported the wrapper's own tag before this was handled.
    That is the test for "no argument given".

    Run it AFTER the definitions are in place -- the point of it is to check
    the whole board, not the bootstrap slice. (Tony, 2026-07-29: GroupMain was
    the wrong home precisely because it runs before setup is parsed.)

    The summary prints even when clean BY DESIGN. The instrument this replaces
    was getRStuff's "no rStuff - creating" cerr, and grepping for that returned
    zero both when nothing fired late AND when the cerr had been deleted. An
    absence-based check passes by being removed; a presence-based one cannot.

    NAMED auditRStuff, NOT audit: macOS declares a system audit(2), and extern "C"
    strips overload resolution so only the NAME matters -- `extern "C" GroupItem
    *audit(GroupItem*)` collides with `int audit(const char*, u_int)` and the
    build dies with "conflicting types for 'audit'". Bear-trap #12, one layer out
    from the in-repo case. The incant-facing command is still spelled `audit`;
    the `=value` registration form is exactly what bridges the two names.
***************************************************************************/
extern "C" GroupItem *auditRStuff(GroupItem *argument)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*registry = 0;
GroupItem 	*target = 0;
int 		missRules = 0;
int 		missTerms = 0;
int 		loose = 0;
	target = argument;
	if ( isGROUP(target->groupBody->flags.data) )
		target = target->getGroup();
	if ( ::compare(target->groupBody->tag,"InvokeArg") == 0 )
		target = 0;
	if ( target )
		{
		missRules = ::auditMissingRules(target);
		missTerms = ::auditMissingTerms(target);
		loose = ::auditSpurious(target);
		::fprintf(stderr,"AUDIT %s: %s missing rules, %s missing terms, %s loose\n",target->groupBody->tag,::toStringFromInt(missRules),::toStringFromInt(missTerms),::toStringFromInt(loose));
		}
	else {
		while ( registry = ruler->registries->next(registry) )
			{
			missRules += ::auditMissingRules(registry);
			missTerms += ::auditMissingTerms(registry);
			loose += ::auditSpurious(registry);
			}
		::fprintf(stderr,"AUDIT all registries: %s missing rules, %s missing terms, %s loose\n",::toStringFromInt(missRules),::toStringFromInt(missTerms),::toStringFromInt(loose));
		}
	return argument;
}

extern "C" int auditSpurious(GroupItem *registry)
{
GroupItem 	*entry = 0;
GroupItem 	*term = 0;
int 		i = 0;
int 		spurious = 0;
	while ( entry = registry->next(entry) )
		{
		if ( !entry->groupBody->flags.isRule && entry->rStuff )
			{
			::fprintf(stderr,"AUDIT LOOSE    %s/%s -- not a rule, not a rule term, has rStuff\n",registry->groupBody->tag,entry->groupBody->tag);
			spurious++;
			}
		i = 1;
		while ( term = entry->get(i) )
			{
			if ( !term->groupBody->flags.isRule && term->rStuff )
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
    demoRprime — INVARIANT R′, DEMONSTRATED, both clauses.

    A POP that only shows a passing run proves neither clause: at min <= 1 the
    rewind branch is never reached, and a recycled label and a fresh one look
    identical from outside. So this runs the two loop shapes side by side on the
    same input and reports the difference.

    WHY IT IS A CONTROLLED COMPARISON AND NOT A GENERATED RULE: the mark clause
    is only observable at min >= 2, and MIN >= 2 IS CURRENTLY UNREACHABLE
    THROUGH THE GRAMMAR. Measured 2026-07-28: `X[2]` is rejected outright
    (ERROR Operator - failed on isRule and Token) and `X[2 9]` parses, prints
    "nextGroup: ERROR max does not contain a list", and leaves min/max at 1/1 --
    the limit is SILENTLY NOT APPLIED. setLimits itself reads correctly, so the
    fault is upstream of it. That makes genParseSpec §2.2's "latent until
    someone writes X[2]" true in a stronger sense than it states.

    MARK CLAUSE. Input "a" against a term needing 2. The entry-saved loop (the
    emitted shape) gives back the whole run. The per-pass loop (parse()'s shape,
    where checkInput reassigns hereAt every iteration) rewinds to the start of
    the FAILED attempt, which is already past the match -- so the first match's
    input stays consumed. That is the defect §2.2 records, made visible.

    LABEL CLAUSE. Input "aa". Each pass goes through parse() and builds a fresh
    label, so two passes attach TWO children. A recycling loop -- parse()'s
    `isGROUP && max > 1` path, which clears the label and hands it back via the
    fLAG handshake -- would show one.
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
	if ( plan )
		::printPlan(plan,"  ");
	return GroupControl::groupController->groupRules->trueResult;
}

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
	ruleStuff = rule->rStuff;
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
		rs = term->rStuff;
		definer = term->definingRule();
		::fprintf(stderr,"    [%s] %s\n",::toStringFromInt(i),term->groupBody->tag);
		if ( term->groupBody->flags.noPrint )
			::fprintf(stderr,"         noPrint (SKIPPED by the walk)\n");
		else {
			::fprintf(stderr,"         ROW  %s\n",::row42(term));
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
    dumpSpellings — emitLeaf's OWN fixture, and it exists because emitLeaf was
    about to be replaced with nothing to diff the replacement against.

    THE ORACLE IS THE FUNCTION BEING REPLACED. That is the whole design: this
    prints, for a named rule, the spelling emitLeaf produces for every plan node
    it planned, under BOTH sinks. Capture it while the C++ emitLeaf is still the
    only implementation and it becomes a byte-exact target the kant emitLeaf must
    reproduce — the same discipline as `rung4.target` holding the emitted text
    against the compiled-in method.

    WHY NOT JUST USE THE RUNG TARGETS: emitLeaf writes every term spelling
    inside them, so they DO gate it — but only for the kinds the ladder reaches.
    LITTO is reached by no ladder rule (every Scaf term is noLabel), so both of
    its spellings, `litTo` and `litOption`, were UNGATED. `CodE` plans as a SEQ
    of two LITTO terms, so driving this off the census rules instead of the
    ladder covers the kind the ladder cannot.

    BOTH SINKS ON EVERY NODE, deliberately, even where the fold could never ask
    for one: `into` is the ALT sink and `label` the SEQ sink, and LITTO is the
    ONLY kind whose text differs between them. Printing both on every node costs
    two lines and means the target moves if that ever stops being true.
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
	/*  THE FOLD DECIDES THE SINK AND THE JOINER, and both are emitter-side
	(§4): the walk already said SEQ or ALT, this only spells it.
	
	S2.4 — AN ALTERNATION BUILDS NO LABEL OF ITS OWN and passes `into`
	straight through, so the winning option attaches to the ENCLOSING
	rule's label. Getting this wrong yields the right LANGUAGE over the
	WRONG TREE — an empty JSONvalue wrapping every value — which passes
	every mark-and-win check and only surfaces when a code={} action reads
	it. That is why rung 7's acceptance test is a TREE COMPARISON against
	the interpretive path, not a WIN/FAIL run.
	
	So an ALT emits no `label` local, its options take `into`, and a
	labelled literal option is spelled litOption (which attaches itself,
	because leaveAlt is label-transparent by design) rather than litTo.
	litOption's first parameter is already the term, matching the
	term-first convention, and is unused exactly as lit's is — re-read
	2026-07-28 before wiring it in.  */
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
		n++;
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
		::fprintf(stderr,"GroupItem   %s = rule[%s];\n",local,index);
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

/*******************************************************************************
    genParse — two passes now, and that is the rung-3 result: planRule DECIDES,
    emitPlan WRITES. Nothing between them knows about C++.

    The walk is walked TWICE by emitPlan, once to validate and once to write.
    That is deliberate and is one of the reasons the seam artifact is a plan and
    not a visitor: §3.3's helper functions are discovered mid-walk, and with
    text already going out you must buffer or emit out of order. With a plan you
    just walk it again. It costs nothing at this size and it is the shape rung 5
    needs.

    Every refusal now lives in planRule, where it belongs — a refusal is a
    validity question about the RULE, so it reads the same whichever emitter is
    downstream (§4).
*******************************************************************************/
extern "C" GroupItem *genParse(GroupItem *argument)
{
GroupItem 	*rule = ::ruleOrRefuse(argument->getText(),"genParse");
GroupItem 	*plan = 0;
	if ( !rule )
		return 0;
	plan = ::planRule(rule);
	if ( !plan )
		return 0;
	return ::emitPlan(plan);
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

/***************************************************************************
    jitDegrade -- THE CROSSOVER PRIMITIVE, lifted 2026-07-30.

    docs/jit.md S0 carries an OPEN RULING of Tony's: during crossover, what
    happens to a construct the JIT cannot emit yet? Falling back to the
    interpreter IS divergence, arriving as a schedule artifact. The candidate
    answer that made mixed mode safe is DEGRADE TO THE ORACLE LOUDLY.

    That answer was already IMPLEMENTED, exactly once, by whoever did the
    2026-07-29 iterator work -- opPlusPlus and opMinusMinus each announce on
    stderr before handing an iterator back to iterAdvance. It was the only
    instance in the tree and it had no name.

    ⚠ AND IT WAS ABOUT TO BE DELETED WITHOUT BEING NOTICED. Both instances sit
    inside `if result.isIterator`, and S0 schedules exactly that gate for
    removal -- the iterator becomes two stack slots, "no handle in the heap,
    and no isIterator" (docs/jit.md:33). So the JIT's only worked example of
    its own crossover policy would have vanished with its host, and the policy
    would have gone back to being a paragraph in a design doc. Lifted here
    FIRST, so the pattern outlives the code that happened to carry it.

    THE COUNTER IS THE POINT, not decoration. The 2026-07-30 recon found ~53
    places where an ungated construct silently runs interpreted at emit time
    (jitExecBlock walks the BlocK, so anything without a jitting gate simply
    EXECUTES). Silent fallback is what makes S0's ruling unanswerable: you
    cannot rule on a boundary nobody has enumerated. Every call to this turns
    one of those into a COUNTABLE ARTIFACT -- which is the same move the
    genParse walk made when it replaced quiet skips with named refusals.

    It lives in a C++ static rather than a node slot, for the reason CLAIM
    KANT-4 records: GroupBody's value slots are one union, and a counter
    parked in gCount destroys whatever pointer shares it. iterSpins
    (Instruct.rtn:457) is the existing precedent.

    fprintf(stderr) and not print: bear-trap #14 -- stdout is block-buffered
    and a run ending via stop() loses it, so a degrade notice would silently
    vanish exactly when a crash made it most valuable.

    DEGRADE, NOT REFUSE. It announces and returns; the caller then does the
    interpreted thing. That is deliberate and is the whole difference from
    jitRunAction's verifier, which REFUSES (-5) because invalid IR must never
    run. An unemittable construct is not an error -- it is unfinished work,
    and the run should still produce the right answer by the slow path.
***************************************************************************/
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

/* jitPrintOpen / jitPrintItem / jitPrintClose  THE THREE EMITTED CALLS of a
   jitted print. Work item 3, Tony's ruling via Clay, 2026-08-04.

   THE LAW THIS SERVES: the emit-time walk must be EFFECT-FREE. Until now a
   jitted print fired AT COMPILE TIME -- once, reporting compile-time state --
   which is worse than not printing, because it appears to work. The
   compile-once-fire-twice proof the whole ladder rests on already assumed the
   emit walk had no effects; this makes that true for print.

   THE SEAM IS appendGroup, READ RATHER THAN ASSUMED (2026-08-04):
       aCTionPrinT -> appendPrintXP  walks the PrintXP attributes and EVALUATES
                                     (result = method(ExpressioN))
                   -> appendGroup    RECEIVES EVALUATED VALUES  <- the seam
                        - printField for real fields
                        - the shortcut switch for ~ $ _ : + - ` , and indent
                   -> opPrint        the sink
   appendGroup does NOT evaluate its own input, so the seam is where the ruling
   put it: below evaluate, above shortcut/format handling.

   ⚠ THE ITEM CALL GOES TO THE VALUE ENTRY, NOT THE POINTER ENTRY, and that is
   forced rather than stylistic: a LOCAL's live value sits in a frame slot until
   the epilogue, so passing appendGroup a field pointer mid-function reads
   storage nothing has written yet -- silent wrong answer. appendGroupValue takes
   the evaluated i32 and stamps it on a carrier, routing into appendGroup's own
   switch so shortcuts, formats and indent stay single-sourced in the chain.
   The rejected alternative -- spill live values before every print -- makes each
   print a sync barrier and needs liveness enumeration.

   ⚠ SHORTCUT TOKENS TRAVEL AS IMMEDIATES. `print +` and `print $-` are nodes
   whose TEXT is the shortcut; their address is baked and appendGroupValue passes
   them through untouched. No format or indent decision is baked at emit time --
   they happen at run time, in the chain, exactly as interpreted. */
/* jitEmitBareRead  THE MISSING PRIMITIVE. Tony's ruling via Clay, 2026-08-05.

   ⚠ WHAT IT IS, AND WHY IT WENT MISSING FOR SO LONG: the JIT has never had to
   MATERIALIZE A BARE READ. Every certified rung to date reached its operands
   through an operator or a method, and runOP's seed gate seeded them on the way
   past -- so an operand was always already a value by the time anyone wanted
   one. displayForm is the first fixture whose statements simply LOOK AT THINGS,
   and it is the convergence rung, which is exactly the rung that should find
   this.

   IT CLOSES THREE THINGS AT ONCE, all one hole seen from three sides:
     - print values      (appendPrintXP's `else result = ExpressioN` makes no
                          call, so nothing was ever emitted for a bare operand)
     - the bare-flag-read item
     - finding #3, `if noPrinT` reading %iterCond -- the same hole from the
       CONDITION side, reusing whatever value was last in flight

   THE FORK IS EMIT-TIME KNOWLEDGE, SO IT COSTS NOTHING AT RUN TIME, and both
   arms already exist inside jitSeedField -- this does not reimplement them:
     arm 1  A JIT-TRACKED LOCAL. Its storage is a frame alloca, so the read is
            a load OF THE ALLOCA, which mem2reg promotes to the SSA value the
            function already holds. ⚠ Emitting a load of the FIELD'S OWN memory
            here would read the stale frame slot -- the epilogue has not written
            it yet -- which is the exact disease the print value entry exists to
            dodge, and it would be silently wrong.
     arm 2  ANYTHING ELSE -- a persistent field. A run-time load through the
            baked address, unchanged from how globals have always been read.
   jitSeedField keys the choice on the HOME ADDRESS rather than node identity,
   because each occurrence of a local in a body is its own GroupItem, so the
   token here is never the node the prologue walked.

   ⚠ A THIRD CATEGORY EXISTS AND IS NOT HANDLED HERE, deliberately: an accessor
   whose resolution is a run-time pointer-walk (`noPrinT` on the iterator's
   CURRENT node -- which node that is depends on the iteration). That is not a
   read of any fixed storage, so no load can express it. It goes through opDot's
   own gate instead, as a CALL to the accessor, so read semantics cannot drift.
   If a FOURTH category turns up while building on this, that is a report, not
   an improvisation.

   Returns 0 and emits nothing if there is no builder. */
extern "C" int jitEmitBareRead(GroupItem *token)
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	if (!b || !token) return 0;
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

/* jitEmitContinue  `continue`, EMITTED. Work item 2 of the convergence rung.

   THE GAP IT CLOSES: there was no continue emitter at all. In the displayForm
   dump `continue` APPEARED to work -- both arms of the enclosing if fell
   through to a block that branched to `cond`, which happens to be the back edge
   -- and that is worse than a missing feature. A construct that is correct by
   accident of topology stays correct exactly until the block structure moves,
   and then fails somewhere else entirely.

   THE TARGET IS THE LOOP'S CONDITION BLOCK, which the loop emitters already
   maintain as a stack (gLoopCondBlocks), so nested loops get the INNERMOST one
   for free -- the same rule the interpreter follows, where break and continue
   are consumed by the innermost loop.

   ⚠ A `do` LOOP'S CONTINUE GOES TO ITS COND TOO, not to its body. That matches
   the interpreter: a do re-tests before repeating. The two loop shapes differ in
   where they ENTER, not in where a continue lands, and gLoopCondBlocks holds the
   right block for both.

   ⚠ THE UNREACHABLE BLOCK IS DELIBERATE. LLVM requires a terminator per block
   and forbids code after one, so after the branch the builder is parked in a
   fresh block that nothing branches to. It is dead by construction and the
   optimiser drops it; emitting the following statements into the block we just
   terminated would be INVALID IR, which the verifier would refuse -- correctly.

   Returns 0 when there is no enclosing loop, so a stray continue cannot silently
   emit a branch to whatever happens to be on the stack. */
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

/* jitEmitDO  the do-while emitter (rung J4). Body first, condition second.

   ⚠ E1 AUDIT: clears gJitResult before returning, as every bracketing emitter
   must -- the body commits its own value to the result slot, so leaving one in
   flight would let the enclosing walk re-commit it in the exit block.

   ⚠ AND THE STORE MUST HAPPEN BEFORE jitDoCond MOVES THE INSERT POINT, or the
   body's value is committed into the CONDITION block, where it executes on
   every test rather than every iteration of the body. Same class of ordering
   trap as jitLoopBegin's. */
extern "C" GroupItem *jitEmitDO(GroupItem *input)
{
GroupItem 	*ExpressioN = input->getLabelGroup("ExpressioN");
GroupItem 	*StatemenT = input->getLabelGroup("StatemenT");
GroupItem 	*result = 0;
	::jitDoBegin();
	if ( StatemenT )
		result = StatemenT->groupBody->gMethod(StatemenT);
	/*  ⚠ THE EXPLICIT COMMIT IS REQUIRED HERE AND MUST NOT BE REMOVED, and the
	asymmetry with jitEmitWHILE is MEASURED, not assumed:
	
	while body -> aCTionBlocK commits it (one `store ... ptr %result`)
	do    body -> NOTHING commits it (zero stores)
	
	Removing this line on the strength of the while evidence made J4 emit
	NO result at all -- "no result emitted (gate did not fire?)" -- and the
	rung caught it immediately. So there is exactly ONE committer in each
	case: aCTionBlocK for a while body, this line for a do body.
	WHY the do body is not block-wrapped where the while body is has NOT
	been established -- the measurement stands, the mechanism is open.  */
	::jitStoreResult();
	::jitDoCond();
	result = ExpressioN;
	if ( isMethod(result->groupBody->flags.instructType) )
		result = result->groupBody->gMethod(result);
	::jitDoEnd();
	 gJitResult = nullptr; 
	return result;
}

/* jitEmitDot  THE ACCESSOR ARM -- the third category above, and it closes the
   whole GroupField accessor family in ONE gate rather than one emitter per
   accessor. `.` is registered `operateMethod=opDot`, so it is a two-argument
   operator and this is jitEmitRem's shape exactly:

       1. call opDot(argument, target)  ->  GroupItem*
       2. call jitUnboxCount(that)      ->  i32

   ⚠ THE CALL IS TO opDot ITSELF -- shared implementation, the same move as
   jitEmitIterStep's call to opPlusPlus and jitEmitIterate's call to
   aCTionIterate. opDot resolves ~40 numbered cases including the ones this is
   really for (noPrint 29, isAttribute 34, isMember 35), and reimplementing that
   switch in IR would be a second copy of a table that has grown twice this
   month. Read semantics cannot drift because there is only one reader.

   ⚠ AND IT IS WHY finding #3 LOOKED LIKE A CONDITION BUG: with no emitter here,
   `if noPrinT` emitted nothing and the enclosing `if` branched on whatever was
   last in flight -- the iterator's liveness. The condition was never wrong; it
   was reading a value nobody had produced. */
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
	
	if (resultNode) {
	if (!resultNode->jitData) resultNode->jitData = new JitData();
	resultNode->jitData->setJitter(val);
	gJitSeeded.push_back(resultNode); }
	gJitResult  = val;
	gJitEmitted = true;
	return resultNode;
	
}

/* jitEmitGIF  the gIF emitter — now rides the INTERPRET walk (pivot, 2026-06-30).
   Called from aCTionIF's jitting gate with the live if-node. It mirrors aCTionIF's
   own condition-eval (`result = ExpressioN; if isMethod result.gMethod`), but
   instead of branching at runtime it brackets the arm with jitIfBegin/jitIfEnd:
     - the condition gMethod drives its runOP tree -> opLT/opEQ jitting gate ->
       jitEmitCompare leaves the i1 in gJitResult;
     - jitIfBegin reads gJitResult, emits the CreateCondBr, enters the then block;
     - the then-arm gMethod drives ITS runOP tree -> opAssign gate -> jitEmitAssign
       stores INSIDE the then block;
     - jitIfEnd branches to endif and resumes there.
   No flat list, no jitXpress, no operand stack — the runOP walk owns its traversal
   and never re-parents live nodes (the structural cure for the by-reference stack
   corruption the deferred path hit). First POP: single compare, one then arm, no
   else (else + nesting are the next increment; gIfEndBlocks already nests). */
extern "C" GroupItem *jitEmitGIF(GroupItem *input)
{
GroupItem 	*ExpressioN = input->getLabelGroup("ExpressioN");
GroupItem 	*StatemenT = input->getLabelGroup("StatemenT");
GroupItem 	*ElsE = input->getLabelGroup("ElsE");
GroupItem 	*result = ExpressioN;
	if ( isMethod(result->groupBody->flags.instructType) )
		result = result->groupBody->gMethod(result);
	else	result = ExpressioN;
	::jitIfBegin();
	if ( StatemenT )
		result = StatemenT->groupBody->gMethod(StatemenT);
	/*  Commit the then-arm's value INSIDE thenBB, and the else-arm's INSIDE
	elseBB. This is the merge: the exit block's load reads whichever arm
	ran. Must sit BEFORE jitIfElse/jitIfEnd, which move the insert point. */
	::jitStoreResult();
	::jitIfElse();
	/*  ⚠ E1, ONE LEVEL DOWN, AND AN ABSENT ELSE IS WHY. jitIfElse has just moved
	the insert point into elseBB, but gJitResult still holds THE THEN ARM'S
	value -- so when there is no ElsE to overwrite it, the jitStoreResult
	below commits a then-block value INSIDE the else block. That is a
	dominance violation, and llvm::verifyFunction refuses the function:
	else:  store i32 %sub, ptr %result     ; %sub is defined in `then`
	Measured 2026-08-01 on a bare `if cond; body;` with no else -- a shape NO
	LADDER RUNG HAD, because J2 uses if/else. Clearing here makes the store
	below a no-op when the else arm emits nothing (jitStoreResult returns
	early on a null gJitResult), which is the honest statement: an absent
	else contributes NO value, so the slot correctly keeps whatever the
	statement before the `if` put there.
	Same rule as the clear at the foot of this function, applied per-arm
	rather than per-statement: THE EMITTER THAT COMMITS OWNS THE CLEARING. */
	 gJitResult = nullptr; 
	if ( ElsE )
		result = ElsE->groupBody->gMethod(ElsE);
	::jitStoreResult();
	::jitIfEnd();
	/*  ⚠ NOTHING IS LEFT IN FLIGHT. Both arms have already committed their own
	value to the result slot INSIDE their own block -- that is the merge.
	gJitResult still holds the else-arm's value, and the enclosing walk
	would commit it AGAIN in the merge block, clobbering the merge and
	making every path return the last arm EMITTED rather than the one that
	RAN. Measured: the endif block carried two extra `store i32 7` and the
	function returned 7 on both paths.
	Clearing it makes the enclosing jitStoreResult() calls no-ops, which is
	the honest statement: a control-flow statement's value is already
	committed, so there is no loose value for anyone else to commit.
	THIS IS A RULE FOR EVERY BRACKETING EMITTER, not a gIF quirk -- the loop
	emitters will need the same line.  */
	 gJitResult = nullptr; 
	return result;
}

/* jitEmitIterStep  THE JITTED ITERATOR ADVANCE. Tony's ruling, 2026-08-04:
   an unqualified iterate over a group visits EVERY DECLARED CHILD; the
   interpreter's measured behaviour is the intended semantics and THE JIT'S
   0-VISIT WALK IS THE DEFECT.

   THE DEFECT, precisely: opPlusPlus tests `isIterator` BEFORE its jitting gate,
   so an iterator under ++ took the interpreted arm and EMITTED NOTHING. The walk
   therefore happened once, at EMIT time, and the compiled function contained no
   loop at all -- hence 0 visits at run time against the interpreter's 3.

   ⚠ THE EMITTED CALL IS TO opPlusPlus ITSELF, AND THAT IS THE DESIGN, NOT A
   SHORTCUT. The obvious alternative -- re-implement the advance in a runtime
   helper -- would put the iterator semantics in TWO places, and this project has
   a name for what happens next. Model-not-oracle: the compiled code calls the
   interpreter's own arm, so the two CANNOT drift, and Tony's ruling ("the
   interpreter is right") is satisfied by construction rather than by a careful
   copy. It also sidesteps a real hazard -- that arm resolves several bare names
   (group, nextInParent, firstInList, lastREF) against opPlusPlus's own context,
   and re-hosting them elsewhere is precisely where a silent divergence would
   live.

   SAFE AT RUN TIME because jitRunAction lowers `jitting` to 0 after the walk, so
   the call re-enters opPlusPlus with the gate DOWN and takes the interpreted
   iterator arm -- which is the one whose answer we want.

   TWO LEGS, jitEmitRem's shape with a one-arg callee (runOP's isMethod arity):
     1. call opPlusPlus(result)  ->  GroupItem*   (advances, or null when spent)
     2. null-test that pointer   ->  i32 0/1      (the while's condition)
   The i32 is what the loop branches on, so the LOOP ITSELF now runs at run time
   and visits what the interpreter visits.

   Layout-free: baked addresses only, no new flag, no groups.ext, no tokall. */
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

/* jitEmitIterate  THE ITERATOR SETUP, EMITTED. Work item 1 of the convergence
   rung, 2026-08-04.

   THE GAP IT CLOSES: aCTionIterate had NO jitting gate, so `iterate g on x` was
   performed ONCE, AT EMIT TIME, and the compiled function inherited whatever
   state that left behind -- while the `++` advance WAS emitted. Setup and
   advance living at two different times is the shape of the displayForm hang:
   the second fire began on a spent iterator because nothing re-established it.

   ⚠ THE CALL IS TO aCTionIterate ITSELF, the same model-not-oracle move as
   jitEmitIterStep's call to opPlusPlus. Iterator semantics are Tony's and they
   are already written down once; emitting a re-implementation would make two
   copies of a thing he has changed twice this month.

   ⚠ THIS GATE EMITS AND THEN FALLS THROUGH -- it does NOT return, and that is
   the one place this differs from every other jitting gate in the tree. The
   emit-time walk still needs the iterator ESTABLISHED, because the enclosing
   `while ++grup` must take opPlusPlus's iterator arm to reach jitEmitIterStep
   at all; gate-and-return would leave the node un-flagged and the advance would
   emit against the DATA arm instead.
   ⚠ AND IT DOES NOT BREAK THE EFFECT-FREE-EMIT LAW, which is worth stating
   rather than assuming, since "it is only a little effect" is how that law
   erodes. The law is about OBSERVABLE effects -- output, and mutation of user
   data. aCTionIterate's effect is confined to the ITERATOR NODE's own list
   pointer and poison flag: compile scaffolding, invisible to the program's
   result. The emitted call re-establishes it at run time, so RUN-TIME BEHAVIOUR
   DOES NOT DEPEND ON THE EMIT-TIME STATE -- which is the property the law
   actually protects.

   NOTHING IS LEFT IN FLIGHT (E1). An iterate statement has no value anyone
   reads; the loop's condition is the ++, not this. Setting gJitResult here
   would hand aCTionBlocK a POINTER to commit into an i32 result slot. */
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

/* jitEmitRem  THE FALLBACK COLUMN MEETING A REAL opMethod -- the first emitted
   call to an existing operator rather than to a purpose-built helper.

   TWO CALLS, and both legs are layout-free:
     1. call opRem(argument, target)  ->  GroupItem*
     2. call jitUnboxCount(that)      ->  i32

   ⚠ THE ARITY IS TWO, AND THAT REFINES WHAT J6 ESTABLISHED. runOP has TWO
   calling conventions, not one:
       op.isOperator  ->  op.operat(arg,target)   TWO-arg   <- this one
       op.isMethod    ->  op.method(target)       ONE-arg   <- J6's
   `%` is registered `operateMethod=opRem`, so it is an OPERATOR and takes the
   two-arg form. J6's "the ground agrees, one-argument" was true OF THE isMethod
   ARM ONLY. The bulk of the fallback column is binary operators, so it is
   mostly two-arg -- which is precisely what the ruling's SIGNATURE-KIND TABLE
   COLUMN is for, and the column now has a concrete meaning: which arm, which
   arity.

   THE RESULT NODE IS SEEDED so the value composes downstream: an operator's
   result lands in tempField, and stamping its jitData lets the enclosing
   assignment read it exactly as it reads any other operand.

   The callee is the ONE hardcoded part; a table-driven callee is the
   generalisation and is the table arc's job, not this rung's. */
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

/* jitEmitSelfCall  THE RECURSIVE CALL, emitted rather than inlined.

   Returns 1 when it emitted (the callee IS the action being compiled), 0 when it
   did not -- and 0 is the common, correct answer: an ordinary call still inlines,
   which is measured to work (incant/jitJC).

   ⚠ THIS IS WHERE INLINING STOPS BEING A VALID STRATEGY. Emit-on-walk inlines a
   callee by re-executing its BlocK into the current builder. For a self-call that
   re-walks nodes which ALREADY carry jitData from the enclosing pass, and
   jitEmitCompare has by then written its i1 result into the condition target's
   jitValue -- so the second pass compares an i1 against an i32 and LLVM asserts
   (measured 2026-08-01, trace in jitEmitCompare). Terminating is not the only
   problem; the cached SSA state is.

   SIGNATURE NOTE: the function under construction is i32(), so this emits a
   no-argument self-call. That is enough to prove CALL EMISSION and is NOT enough
   to prove frames -- with globals the recursion accumulates through shared baked
   storage, which is a loop wearing recursion's clothes. Per-activation locals
   need the argument-passing signature, which is the next increment. */
extern "C" int jitEmitSelfCall(GroupItem *action)
{
	
	// ⚠ COMPARED ON groupBody, NOT ON THE NODE POINTER, AND THAT IS THE SAME
	// FINDING AS INCREMENT 1's: STORAGE IS IDENTITY, NODES ARE OCCURRENCES. The
	// first cut tested `action != gJitCurrentAction` and never matched --
	// measured, `callee=jrFact current=jrFact match=0`. The jrFact node
	// referenced INSIDE the body is a different GroupItem from the one
	// jitRunAction was handed, exactly as each occurrence of a local is its own
	// node. Second instance of this in one day; cross-filed to the name-scope
	// pack, which is where node-identity/copy behaviour accumulates.
	if (!gJitCurrentAction || !gJitCurrentFn) return 0;
	if (action->groupBody != gJitCurrentAction->groupBody) return 0;
	llvm::IRBuilder<> *b = gJitBuilder;
	llvm::Value *v = b->CreateCall(gJitCurrentFn, {}, "selfcall");
	gJitResult  = v;
	gJitEmitted = true;
	return 1;
	
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

/* jitEmitTrace  THE EMITTER HALF -- and the FIRST EMITTED CALL in this layer
   that is not the lonely concatEQ.

   Bakes the field's stable GroupItem address and jitTraceRT's address as
   constants, then emits ONE CreateCall of GroupItem*(GroupItem*).

   ⚠ THE SIGNATURE IS THE FALLBACK-COLUMN CONVENTION, and it was VERIFIED
   AGAINST THE TREE rather than adopted from the design: runOP's dispatch is
   `result = op->groupBody->gMethod(target)` -- ONE ARGUMENT, VALUE-RETURNING,
   GroupItem*(GroupItem*). The ruling and the ground agree, so every non-scalar
   op's emitted call can wear this shape.

   ⚠ NO STRUCT OFFSETS ARE BAKED INTO THE IR, deliberately. Reaching a field's
   value from a returned pointer would need GEP arithmetic over GroupItem ->
   groupBody -> gCount, and BAKED OFFSETS BREAK SILENTLY ON ANY GroupBody LAYOUT
   CHANGE -- bear-trap #10's blast radius, arriving in emitted code where no
   compiler would catch it. A helper call is layout-independent: the C++ side
   recomputes the offsets every build. Pay one call, keep the layout free.

   The call is left UNTAGGED (not readnone) so LLVM cannot DCE a callee it
   cannot see into -- the concatEQ lesson. */
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

/* jitEmitWHILE  the while emitter (rung J3). Mirrors jitEmitGIF's shape: gate
   in aCTionWhilE, bracket the sub-walks, let the runOP walk own its traversal.

   ⚠ E1 AUDIT (docs/jitDesign.md): A BRACKETING EMITTER LEAVES NOTHING IN
   FLIGHT. The body commits its own value to the result slot, so gJitResult is
   cleared before returning -- otherwise the enclosing walk commits the stale
   body value AGAIN, in the exit block, which is exactly the clobber that made
   every gIF path return the last arm emitted. This is E1's first audit customer
   and it obeys it by construction rather than by luck.

   ⚠ THE CONDITION IS WALKED ONCE, into `cond`, and that is the honest retest of
   the old ICmp abort: testWhilE used to die at 134 because aCTionWhilE had NO
   gate, so under jitting the loop EXECUTED at emit time and walked its
   condition repeatedly -- re-emitting a compare against a node whose jitData
   already held the previous i1. With a gate the condition is emitted exactly
   once and the loop runs at RUN time, which is what the ladder measures. */
extern "C" GroupItem *jitEmitWHILE(GroupItem *input)
{
GroupItem 	*ExpressioN = input->getLabelGroup("ExpressioN");
GroupItem 	*StatemenT = input->getLabelGroup("StatemenT");
GroupItem 	*result = 0;
	::jitLoopBegin();
	result = ExpressioN;
	if ( isMethod(result->groupBody->flags.instructType) )
		result = result->groupBody->gMethod(result);
	::jitLoopBody();
	if ( StatemenT )
		result = StatemenT->groupBody->gMethod(StatemenT);
	/*  NO jitStoreResult() HERE, and that is a correction rather than an
	omission. aCTionBlocK already commits EVERY statement under jitting, and
	a loop body is always block-wrapped -- measured on rung J5, whose
	two-statement body emitted THREE stores to the result slot: one per
	statement plus this one, duplicating the last. One committer per value
	(the one-channel family's cousin: two writers, one location, benign only
	while they agree).  */
	::jitLoopEnd();
	 gJitResult = nullptr; 
	return result;
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

/* jitFieldMethod  THE ONE NAMED SITE THAT OWNS SET-THEN-CALL for a field's
   compiled method. Clay SEQ 27 v2, 2026-08-04, and it is parseMethod's shape
   transplanted from rules to fields -- deliberately, so there is one pattern in
   the tree and not two.

   THE CONTRACT, in the order the code reads:
     1. slot set   -> CALL THROUGH THE POINTER. That is the whole dispatch. No
                      name lookup, no reconstruction from the `JiT` record, no
                      consultation of CodE or BlocK.
     2. slot empty -> compile (jitRunAction), then STASH BOTH: the function
                      pointer into rStuff.jitMethod, the emitted IR text into a
                      `JiT` attribute beside CodE and BlocK.
     3. compile refused -> leave the slot EMPTY and say so. A refusal must not
                      install a pointer, and it must not be silent; a field that
                      quietly stopped being jitted would read as a field that was
                      never jittable.

   ⚠ SEQ 38 HOLDS BY CONSTRUCTION, AND THIS IS THE PLACE IT WOULD HAVE BROKEN.
   locate is PROHIBITED, NOT PROVIDED: action execution resolves no names. The
   field arrives as the FIRST PARAMETER and everything else is a pointer walk
   from it -- rStuff off the node, the `JiT` attribute off its own list. Nothing
   here asks the registry for anything, and if a later change to this function
   seems to need locate, that change is misdesigned rather than blocked.

   ⚠⚠ THE SLOT IS READ AND WRITTEN ON definingRule(), NOT ON THE NODE THAT
   ARRIVES, AND THAT IS THE WHOLE MECHANISM RATHER THAN A DETAIL. Measured
   2026-08-04, because the first cut got it wrong and recompiled on every fire:

       call 1   field=0x1031ccf80   body=0x1031c6380
       call 2   field=0x1031df5c0   body=0x1031c6380
       call 3   field=0x1031ed9c0   body=0x1031c6380
       definer  0x100eaa3c0 on ALL THREE

   EVERY CALL SITE HANDS A FRESH GroupItem WRAPPER over the one shared
   GroupBody -- incant's field semantics, not a bug: a field is pointer-shaped
   storage with value-content semantics, so a reference is its own node. Storing
   the pointer on the arriving node therefore stores it on a temporary that is
   discarded the moment the statement ends. The store STUCK (readback confirmed
   it); it was simply written somewhere nothing would ever look again.

   definingRule() is a POINTER WALK to the node that OWNS the children, and
   parse() uses it for exactly this problem in exactly this way -- its comment
   says bind once and every reference sees it, "including references created
   LATER", with "no locate (S1.3 forbids it)". So the half that makes the shape
   work is the RESOLUTION, not the slot; transplanting the slot without the walk
   produces code that looks right and compiles forever. SEQ 38 is satisfied by
   the same fact: a pointer walk resolves no names.

   ⚠ WHY THE SLOT'S HOME IS MATERIALISED HERE AND NOT AT DEFINE TIME. aCTionDefinE
   ZEROES rStuff for a non-rule (`if !isRule rStuff = 0;`, ruleActions.rtn), so an
   ordinary attribute reaches this point with no shape struct at all -- the design
   as ruled says "the slot rides the attribute's stuff", and the attribute has
   none. Rather than change what a define does to every field in the language, the
   slot's owner mints its own home on the one path that needs it, using the same
   two lines aCTionDefinE already uses for member terms (`RuleStuff fresh =
   new(newMember); newMember.setRStuff(fresh);`). Cost is one struct per jitted
   field, paid on first fire, and the define-time invariant is untouched.

   ⚠ THE `JiT` ATTRIBUTE IS A RECORD AND NOT A CACHE. It is written after a
   successful compile and read by nobody in this function. Reconstructing a
   callable from it would mean re-entering LLVM to parse text we already hold a
   pointer to -- slower, and it would give the same fact two homes, which is the
   one-channel-one-meaning failure this project has now paid for twice.

   Returns trueResult when the method ran (either path), null when the compile
   was refused. */
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
	
	/*  THE RECORD. strdup'd, not aliased: gJitLastIR is overwritten by the next
	compile of ANY field, so handing the node a pointer into it would make
	every field's record silently become the last one compiled. */
	GroupItem *jt = definer->get("JiT");
	if (!jt) {
	jt = new GroupItem("JiT");
	jt->groupBody->flags.noPrint = 1;
	jt->setText(::strdup(gJitLastIR.c_str()));
	definer->addAttribute(jt); }
	else    jt->setText(::strdup(gJitLastIR.c_str()));
	
	printf("=== jitFieldMethod: %s COMPILED, result = %d, slot set, JiT %zu bytes ===\n",
	name, r, gJitLastIR.size());
	printf("=== jitCompile count = %d ===\n", gJitCompileCount);
	fflush(stdout);
	return ruler->trueResult;
	
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

/* jitIfElse  closes the THEN arm and opens the ELSE arm (2026-07-31). Branches
   the finished then block to the stacked endif, then resumes insertion in the
   stacked else block. Called UNCONDITIONALLY by jitEmitGIF, whether or not the
   source has an `else` -- with no else the block is simply left empty and
   jitIfEnd branches it to endif.

   WHY UNCONDITIONALLY: the missing else arm was not a hard bug, it was a SECOND
   TOPOLOGY that nobody exercised. jitEmitGIF declared only ExpressioN and
   StatemenT, so the else statement was never visited by anything -- neither
   emitted nor interpreted, it simply vanished, and a false condition then left
   the variable untouched and returned garbage AT EXIT 0. One topology, always
   three blocks, is the structural fix; the alternative (branch on hasElse)
   recreates the two paths that diverged. */
extern "C" void jitIfElse()
{
	
	llvm::IRBuilder<> *b = gJitBuilder;
	llvm::BasicBlock *endBB  = gIfEndBlocks.back();
	llvm::BasicBlock *elseBB = gIfElseBlocks.back();
	b->CreateBr(endBB);
	b->SetInsertPoint(elseBB);
	
}

/* jitIfEnd  closes the ELSE arm (2026-07-31; it used to close the then arm,
   before jitIfElse existed) and resumes at the endif merge block, popping BOTH
   stacks in lockstep.

   NO PHI IS NEEDED FOR FIELD STORES, and the old comment here got the reason
   wrong -- it credited PromotePass. There are NO ALLOCAS in this emitter: a
   field slot is a BAKED ABSOLUTE ADDRESS (inttoptr), so fields live in MEMORY
   and two stores to the same address on two paths need no merge at all. mem2reg
   is a documented no-op on this shape. What genuinely has no merge is the
   RETURN VALUE, which is capped from gJitResult -- a scalar C++ global -- and
   that is a separate defect from anything phi-shaped. */
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

/* jitLoopBegin  open a loop: create cond/body/exit, branch into cond, and set
   the insert point THERE so the condition sub-walk emits inside it.

   ⚠ ORDER IS THE OPPOSITE OF gIF AND IT MATTERS. jitIfBegin is called AFTER the
   condition has been emitted into the current block, because an if evaluates
   its condition once. A loop's condition must re-execute on every iteration, so
   it has to live in a block the back edge returns to -- which means the block
   must exist and be current BEFORE the condition walk runs. Get it backwards
   and the condition is evaluated once, ahead of the loop: infinite, or never
   entered. */
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

/* jitPrintArm  CLEAR THE IN-FLIGHT VALUE before an item's expression emits.

   ⚠ WITHOUT THIS, AN ITEM THAT EMITS NOTHING INHERITS THE PREVIOUS ITEM'S VALUE.
   Measured 2026-08-05, and it got WORSE as the emitters got better: before the
   bare-read primitive existed, gJitResult was null for everything and a
   non-emitting item printed 0 -- wrong, but stable. Once real values started
   flowing, the same item printed 80329152: whatever was last in flight. A stale
   read is worse than a zero because it looks like data.
   That is the one-channel-one-meaning family again -- gJitResult means "the
   value in flight", and "the value THIS item produced" is a different fact.
   Clearing per item is what makes the second question answerable, and it is why
   jitPrintItem can now REFUSE rather than substitute. */
extern "C" void jitPrintArm()
{
	 gJitResult = nullptr; 
}

/*******************************************************************************
    jitPrintBegin -- the chain's OPENING bracket, reached from emitted code.
    aCTionPrinT's own three lines, lifted verbatim so the jitted path acquires
    its buffer exactly as the interpreted path does. The closing bracket is
    opPrint itself, which the emitter calls directly -- there is no jitPrintEnd,
    because inventing one would put a second sink beside the real one.
*******************************************************************************/
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

/* jitPrintProbe  COMPILE-TIME DIAGNOSTIC for the jitted print walk. R3, Clay,
   2026-08-05: one aimed measurement before the third swing.

   ⚠ COMPILE-TIME LOGGING IS EXEMPT FROM THE EFFECT-FREE-EMIT LAW, and the
   distinction is worth stating because it looks like a violation: that law
   governs THE EMITTED PROGRAM, not the compiler's own mouth. This never appears
   in the IR. It is off unless INCANT_PRINT_PROBE is set.

   THE QUESTION IT AIMS AT. Two symptoms -- appendGroupValue handed a constant
   i32 0, and TWO parts walked where the statement reads as three -- are
   consistent with ONE cause: the emit walk's part-classification diverging from
   appendPrintXP's enumeration. So it reports, per part: WHAT THE WALK SAW
   (before any filter), how it CLASSIFIED it, and whether gJitResult moved
   across the expression emit.

   phase 0  a part, as the walk first sees it, BEFORE the noPrint filter
   phase 1  about to emit an expression   (gJitResult before)
   phase 2  expression emitted            (gJitResult after)
   phase 3  classified as a token (no expression)

   ⚠ NO LEFT-JUSTIFY FORMAT IN THIS printf, and the first draft of this very
   function re-tripped that trap -- canary 238 to 235, hours after the same trap
   was documented two functions up. Plain %s. */
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
	::fflush(stderr);
	
}

/* jitRefire  FIRE THE LAST COMPILED FUNCTION AGAIN, without recompiling.
   The jitLadder's proof-of-run-time-computation, and the reason every rung
   compiles once and fires twice.

   THE THREAT IT ANSWERS: under jitting the interpreter executes the action body
   for real at emit time (docs/jit.md S2.2 -- a jitted `print` printed during
   compilation). So an end-to-end POP that compiles, fires, and sees the right
   answer proves NOTHING on its own: the interpreter may have done the work
   while compiling, with the compiled function returning a baked constant. Right
   answer, wrong universe, exit 0 throughout.
   Change an input AFTER emission and fire again: if the answer tracks the new
   input, the computation is happening at RUN time in compiled code. That is the
   load-vs-fold distinction jit.md has listed as unobservable since Phase 1,
   and this is what makes it observable.

   Returns trueResult on a fire, null if nothing has been compiled yet -- LOUD,
   because a silent no-op here would make a rung green for the wrong reason. */
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
	gJitCurrentAction = action;      // so a self-call emits a CALL, not an inline
	gJitCurrentFn     = fn;
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
	for (GroupItem *seeded : gJitSeeded) seeded->jitData = nullptr;
	gJitSeeded.clear();
	gJitFrame.clear();
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
	if (isNUMBER(fb->flags.data)) { ty = llvm::Type::getDoubleTy(*ctx); addr = &(fb->gNumber); }
	else                          { ty = llvm::Type::getInt32Ty(*ctx);  addr = &(fb->gCount);  }
	if (jitFrameFind(addr)) continue;    // one slot per field, not per node
	llvm::Value *slot = B.CreateAlloca(ty, nullptr, fb->tag);
	llvm::Value *home = B.CreateIntToPtr(
	llvm::ConstantInt::get(llvm::Type::getInt64Ty(*ctx), (uint64_t)addr),
	llvm::PointerType::getUnqual(*ctx));
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
	
	// ================= FRAME EPILOGUE (Increment 1, 2026-08-01) =================
	// Store each frame slot back to the field's own storage, so the interpreter
	// and every later run see the action's effect. Walk order is the prologue's;
	// restoreLocalFields walks BACKWARD because it pops a stack, and this does
	// not -- each slot has its own address, so there is no ordering to honour.
	// That asymmetry is the point: the stack discipline was the bug surface, and
	// it is gone rather than reimplemented.
	for (JitFrameSlot &f : gJitFrame) {
	llvm::Value *home = B.CreateIntToPtr(
	llvm::ConstantInt::get(llvm::Type::getInt64Ty(*ctx), (uint64_t)f.home),
	llvm::PointerType::getUnqual(*ctx));
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
	mod->print(llvm::errs(), nullptr);
	llvm::errs() << "=== end PRE IR " << fnName << " ===\n";
	llvm::errs().flush(); }
	
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
	// Read by jitFieldMethod, which hangs it on the field's `JiT` attribute
	// beside CodE and BlocK.
	{
	std::string             irText;
	llvm::raw_string_ostream irOut(irText);
	mod->print(irOut, nullptr);
	irOut.flush();
	gJitLastIR = irText;
	}
	//  ONE COMPILE HAPPENED. Counted here rather than at entry so a run that
	//  refuses (-1..-5) does not inflate the count -- the POP asserts exactly
	//  one compile across two fires, and a refusal is not a compile.
	gJitCompileCount++;
	
	if (auto err = jit->addIRModule(
	llvm::orc::ThreadSafeModule(std::move(mod), std::move(ctx)))) {
	llvm::consumeError(std::move(err));
	printf("=== JIT addIRModule failed ===\n"); fflush(stdout); return -3; }
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

/* jitRunIfTest  control-flow smoke test — the jitRunAddTwo analog for a branch,
   and the first multi-basic-block IR in the JIT layer. Hand-builds
   i32 f(){ if (fld < 0) fld = 99; return fld; } against the field's baked gCount
   slot (the jitSeedField address-bake): load the slot, CreateICmpSLT against 0,
   CreateCondBr to then/end, CreateStore 99 in the then block, merge at end,
   ret the reloaded slot. The store lands in the field's real storage, so the
   mutation is observable by reading the field back in interpreted incant
   (the jitAssign readback pattern). Proves CondBr both directions + a
   store-to-field through a taken/untaken branch — independent of the JIT walk
   driver and the in-flight compare-operator design (the icmp is hand-built).
   Field assumed a count (i32 gCount); drive with testing(<count field>). */
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

/* jitShowRecord  READ-ONLY. Print what is CORESIDENT on a field's canonical
   node -- every attribute by name, with its size, INCLUDING the noPrint ones.

   WHY IT HAS TO EXIST AT ALL, and it is a consequence of a ruling rather than a
   gap: the 2026-08-03 print ruling gives two forms from one walk, and `display`
   -- today's behaviour and what listRules does -- ELIDES noPrint attributes.
   CodE, BlocK and JiT are all noPrint, so the display walk shows a jitted field
   as though nothing were attached to it. The `fidelity` form is the one that
   would show them and it is blocked on Tony's aCTionDefinE prerequisite (it
   never ATTACHES a noPrint attribute that has a method, so "stop deleting" is
   not the edit -- "start attaching" is).
   So this is NOT a second print family. It is one probe, for one claim: that
   the spec text, the source, the parsed block and the compiled artifact are all
   on the same node at the same time. When fidelity print lands it subsumes this
   and this should go.

   BEAR TRAP, MEASURED 2026-08-04 AND WITH A NEGATIVE CONTROL. A printf
   left-justify format -- percent, hyphen, width, s -- ANYWHERE INSIDE a
   passthrough block breaks the tok pass: extern canary 230 -> 226, ERROR
   FieldBody 0 -> 76, surfacing three files away as `use of undeclared
   identifier` inside genParse.rtn's dataName, which is merely the next extern
   downstream of this file. Reproduced FOUR times: in the printf mid-file, in
   the printf with this function moved to end-of-file (so it is not ordering),
   and twice more from a C-style comment placed INSIDE the passthrough.
   THE CONTROL: the identical characters in a tok-level comment OUTSIDE the
   passthrough are harmless -- canary stayed 228. So the boundary is the
   passthrough, not the file.
   MECHANISM IS TONY'S, recorded rather than derived: a print argument is an
   EXPRESSION, and when the expression is fired the sequence is fair game. My
   own first reading -- that tok scans for two literal characters because it has
   no lexer -- is WRONG and is named here only so nobody re-derives it.

   PRESENCE-WITH-VALUE THROUGHOUT (H4): each line carries the attribute's own
   byte count, so "JiT is there" and "JiT is there and holds 1111 bytes of IR"
   are different assertions and only the second can fail by the artifact going
   empty. Reports the total so a check cannot pass over an empty walk. */
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

/* jitStoreResult  commit the value just emitted into THE RESULT SLOT.
   Tony's ruling 2026-07-31: the compiled action returns what the interpreted
   action returns, and the interpreted rule is "the value of the LAST EXECUTED
   STATEMENT". So every statement stores here, and the cap loads.

   THE MERGE IS THE MEMORY LOCATION. On a two-armed if the answer differs per
   path; each arm calls this INSIDE its own block, so the store is what merges
   them and the exit load reads whichever ran. No phi is written -- the same
   reasoning that makes field stores need no merge, applied to results.

   Coerces to i32 the way the old cap did (double -> FPToSI, i1 -> ZExt), so the
   slot has one type and the function signature is unchanged. A null gJitResult
   is a no-op rather than an error: a statement that emitted nothing simply does
   not move the result, which is exactly the interpreted behaviour. */
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

/* jitUnboxCount  THE RETURN-VALUE UNBOX, and the second leg of the calling
   story. An emitted call hands back a GroupItem* -- this turns it into the i32
   the emitted code works in.

   ⚠ IT IS A CALL AND NOT GEP ARITHMETIC, ON PRINCIPLE (adopted 2026-07-31).
   Reaching gCount from a returned pointer in IR would mean baking the offsets
   of GroupItem -> groupBody -> gCount as constants. BAKED OFFSETS BREAK
   SILENTLY ON ANY GroupBody LAYOUT CHANGE -- bear-trap #10's blast radius,
   arriving in EMITTED CODE where no compiler catches it and the failure is a
   wrong number at run time. This helper is recompiled with the struct every
   build, so layout stays C++'s business and IR knows only addresses and calls.
   Any future GEP-for-speed proposal argues against this in writing. */
extern "C" int jitUnboxCount(GroupItem *node)
{
	
	return node ? node->groupBody->gCount : 0;
	
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
    emitLeaf — one PLAN node -> one leaf expression string.

    Everything here is about the TARGET and nothing about the rule: which
    support function spells a decision the walk already made, and how a literal
    is quoted. The walk decided LIT vs LITTO ("does this attach a label"); this
    decides that a LITTO inside a SEQ is spelled litTo. The same plan handed to
    a kant emitter produces different text and the same decisions — which is the
    whole reason the seam exists.

    NOTE, latent: litTo has no implementation in the support library. Never
    fires on the ladder (every Scaf/ScafA/ScafB term is noLabel). Flagged rather
    than silently carried.
*******************************************************************************/
/*******************************************************************************
    emitMany — the repetition helper, one per repeated term (§3.3).

    THIS IS WHERE INVARIANT R′ LIVES, and both clauses are properties of the
    emitted loop rather than promises made about it:

      MARK  — `from` is captured ONCE, at helper entry, and the rewind on a
              short run goes back to THERE. The interpretive path cannot do
              this: checkInput() reassigns hereAt at the top of every iteration
              (RuleStuff.twk:125) and the rewind targets hereAt
              (GroupItem.twk:1101), so after N passes it points at the start of
              pass N. A min >= 2 term that matches once then fails strands the
              first match. The generated loop is correct for every min/max.

      LABEL — each pass calls parseR, which goes through parse() and builds a
              FRESH label. Nothing here reads or writes fLAG, so parse()'s
              `isGROUP && max > 1` recycling handshake (writer GroupItem.twk:1087,
              reader RuleStuff.twk:141-144) is simply absent. R′ says do not
              invent one.

    A failing pass rewinds ITSELF (Invariant R in the callee's leaveRule), so
    the helper never has to unwind a partial pass — it only has to give back
    the whole run when the count is short. R and R′ compose; neither duplicates
    the other.

    min is baked as a literal. max is NOT bounded, matching the hand-written
    manyJSONblockFields/manyJSONlistItems: every repeated term in the census is
    unbounded (sentinel 268435457), so a bound would be dead code emitted at
    every site. Revisit when a finite max first appears — the plan carries what
    is needed.
*******************************************************************************/
/*******************************************************************************
    locateManier — is there a KANT emitMany on the search list?

    Mirrors locateSpeller exactly, one registry over. ⚠ THE SEPARATE REGISTRY IS
    THE POINT and it was minionA's call, improving on the foreman's note. Sharing
    `Spellers` would mean any fixture putting it on its search list turns on the
    kant spellLeaf TOO — so genScratch could not adopt a kant emitMany without
    switching every rung's leaf spelling in the same commit. Two registries, two
    independent switches, two independent pins.
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
    genParse.rtn — the parse-method emitter (genParseSpec §4).

    C++ prototype ("C++ first, kant second" — Tony 2026-07-27). genParse takes a
    rule (by name) and emits a C++ parse method that mirrors the hand-written
    RuleStuff.twk methods (§5.1). POP: text-diff the emission against the
    hand-written target, climbing Clay's ladder (docs/genParseLadder.md) from a
    synthetic single-literal scaffold up to the JSON rules.

    Emission substrate for v0 is cerr, line by line (bear-trap #14: stderr, not
    stdout — stop() does not flush). This is a C++ extern body, so all string
    literals are DOUBLE-quoted; a double-quote in the emitted output is escaped
    \" (single quotes here parse the inner ':' as an inheritance colon and
    cascade the whole file into ERROR Inheritance — found 2026-07-27).

    TRAPS THAT BITE THIS FILE SPECIFICALLY. All three cost a build cycle.

    1. A COMMENT CANNOT CONTAIN A STAR FOLLOWED BY A SLASH, and the modifier
       fold is the next thing anyone will document here — its comments will
       want to quote the repetition modifiers by name. tok has no lexer, so the
       terminator is matched wherever it appears: writing the two of them as a
       pair inside a block comment CLOSES THE COMMENT EARLY and the rest of the
       prose is parsed as code, taking the following extern with it. Spell them
       out as "star" and "plus". (Cost one build, 2026-07-28.)
    2. JUXTAPOSED CONCAT DOES NOT WORK IN ARGUMENT POSITION. `f(a, b " ")`
       reads as THREE arguments and is caught only by the C++ compiler. In
       return position it is loud (FAIL Block / ERROR Inheritance, taking the
       extern with it); here it is silent. Concat into a local first, always.
       Assignment position is fine.
    3. A METHOD CALL CANNOT APPEAR IN AN `if` CONDITION —
       `if term.definingRule() != term` fails to parse. Assign it to a local.
*******************************************************************************/
/*******************************************************************************
    dumpRuleTerms — MEASUREMENT TOOL, not part of the emitter. Kept because it
    is what settled the questions below, and re-measuring is one run.

    genParseShape §1.5 requires genParse to traverse with the SAME accessor the
    emitted code reads with (rule[i]), because the two agree only if the list
    holds exactly the terms in exactly that order. Whether a `fail` modifier or
    a `code={}` tail occupies a slot is a question about the TREE, not about
    the design — so it was measured, not reasoned about. Prints one line per
    rule[i] entry, in order, so the printed order IS the index.

    WHAT IT FOUND (2026-07-28, incant/termScratch):
      1. rule[i] is source order, 1-based. `fail` (JSONblock) occupies NO slot.
      2. A `code={}` tail DOES occupy slots, and FOUR of them, not one: CodE,
         this, tempField — and, appearing only AFTER the rule has been parsed
         once, the cached BlocK. So the tail of rule[] is not even stable
         across a run. §1.5's hazard is real and bigger than "one extra entry".
      3. ALL FOUR tail entries are noPrint; no real term is. So the classifier
         is `noPrint`, which is not an invention — it is the same test the
         interpretive walk already uses (testAttributes: `if noPrint continue`).
         Model-not-oracle applied to classification itself: take the oracle's
         own test rather than inventing a parallel one that can drift from it.
      4. Sequence terms are isAttribute; alternation options are isMember.
         One list, distinguished by affiliation.
      5. A rule-reference term (JSONblock's JSONfield) is a DISTINCT NODE from
         the registry rule of the same name — different parent — but the two
         SHARE a child list (the term shows the BlocK the parse added to the
         registry node). rStuff, however, is per-node: the term's own rStuff
         has its own onGroup/testMatch/followed state. See parseR for why that
         matters and what it leaves open.
      6. No rule-reference term is isGROUP, and none has onGroup set, even
         after a parse — getWhatFollows gates on isGROUP. §1.6's `t2.onGroup`
         does not exist to be written to. See parseR.
*******************************************************************************/
/*******************************************************************************
    locateRule — genParseShape §1.3's ruling, the half that had not landed.

    Emitted text has carried no locate since the shape brief; THE EMITTER still
    ran one, and a bare locate() resolves down the GENERAL search stack: search
    registries first, then the base registries (pROPERTIEs, Operators, cOMMANDs,
    fILEs, Keywords, GroupFields). Any rule sharing a name with a keyword or a
    command was a silent mis-target.

    MEASURED, and it corrects the guess in 41a3831's message: `debug` resolves
    to a NOT-isRule node in the **Keywords** registry (incant/setup:196 defines
    it as a bare keyword) -- not cOMMANDs as first supposed. The real grammar
    rule is **DEBUG**, isRule, in Grokking, with four terms. So there is no
    lowercase `debug` rule to find, and after this change genParse REFUSES it
    rather than planning a term-less node.

    That mis-target was only visible because the node happened to carry no terms
    and produced an empty fold. A collision with a node that HAS terms would
    have produced a plausible-looking plan instead, and nothing would have
    complained.

    Scope: the search list only, and only isRule hits. Base registries are not
    rule registries.
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
    locateSpeller — is there a KANT emitLeaf on the search list?

    SCOPED ON PURPOSE, and it is §1.3's lesson applied one more time: a bare
    locate() resolves down the general search stack (pROPERTIEs, Operators,
    cOMMANDs, Keywords, GroupFields), so anything sharing the name would be a
    silent mis-target. Only a registry literally named `Spellers` can supply the
    action, and only under the name `spellLeaf`.
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
    manyKant — call the kant emitMany and read its answer.

    ⚠ THE ANSWER IS TEXT, NOT A POINTER, AND THAT IS FORCED (CLAIM KANT-32). A
    kant action cannot return NULL across runAction (KANT-B1), and getText()
    falls back to the node's TAG when there is no data — so "empty" and "named"
    are indistinguishable and a null-test would read a refusal as a success.
    Testing for the literal "1" instead makes ANYTHING ELSE a refusal, including
    a kant body that failed to parse. That is the safe direction: a broken kant
    emitter degrades to the C++ one rather than silently emitting nothing.

    NOTHING RIDES IN ON THE NODE, unlike spellKant's `sink`. The MANY node already
    carries `site` and `min`, so no attribute is stamped — which also means the
    census cannot move underneath this.
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
	if ( !rule->rStuff )
		{
		rule->setRuleStuff();
		made++;
		}
	while ( term = rule->get(i) )
		{
		if ( !term->rStuff )
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
	if ( GroupControl::groupController->groupRules->jitting )
		{
		 return jitEmitAssign(argument, target); 
		}
	if ( argument )
		if ( argument->groupBody->flags.byRef )
			target->setGroup(argument);
		else	target->setContent(argument);
	else	target->clearData();
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
	Rule action for ** debug operator
***************************************************************************/
extern "C" GroupItem *opDebug(GroupItem *result)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*actionField = 0;
	actionField = ruler->currentMETHOD->get(result->parent->groupBody->tag);
	return result;
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
	if ( GroupControl::groupController->groupRules->jitting )
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

    CASES 403/404 -- THE GUARD USED TO DEREFERENCE THE POINTER IT WAS GUARDING.
    `!target.firstInList` reads as a null check and generates
    `!target->groupBody->groupList->firstInList`, so a node carrying NO LIST
    segfaulted on exactly the case the guard existed to handle (found 2026-07-30,
    exit 139, crash frame 0 here; corpus CLAIM KANT-18). 401/402 were never
    affected -- nextInParent/priorInParent are direct fields with no intermediate.
    The `target.groupList &&` prefix is the same idiom case 5 already uses eight
    lines up; this makes 403/404 agree with it.

    CASE 405 (firstMembeR) -- AFFILIATION-FILTERED FIRST. `.firsT` is plain
    firstInList and does NOT filter (CLAIM KANT-17): attributes and members share
    ONE list, so on any node built attribute-first `.firsT` returns the
    ATTRIBUTE. genParse's OPT plan node is exactly that shape (`opt +% at;` then
    `opt += node;`), so a walk wanting the wrapped term had no accessor for it and
    had to carry an iterator. nextMember(0) returns the first member, or null when
    there is none -- and the groupList guard is needed here too, because
    nextMember reaches nextGroup, which cerrs on a node with no list.
***************************************************************************/
extern "C" GroupItem *opDot(GroupItem *argument, GroupItem *target)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*product = 0;
	/*  THE ACCESSOR GATE (Tony's ruling via Clay, 2026-08-05). Emit a CALL to
	this very function and unbox its result -- jitEmitRem's shape, and the
	same shared-implementation move as jitEmitIterStep and jitEmitIterate.
	ONE gate closes the whole GroupField accessor family; opDot resolves ~40
	numbered cases and reimplementing that switch in IR would be a second
	copy of a table that has grown twice this month.
	⚠ THIS IS WHY finding #3 LOOKED LIKE A CONDITION BUG. With no emitter
	here, `if noPrinT` emitted nothing and the enclosing `if` branched on
	whatever was last in flight -- the iterator's liveness. The condition was
	never wrong; it was reading a value nobody had produced.  */
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
					if ( target->rStuff && target->rStuff->noLabel )
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
					if ( !target->groupBody->groupList || !target->groupBody->groupList->firstInList )
						product = 0;
					else	product = target->groupBody->groupList->firstInList;
					break;
				case 404:
					if ( !target->groupBody->groupList || !target->groupBody->groupList->lastInList )
						product = 0;
					else	product = target->groupBody->groupList->lastInList;
					break;
				case 405:
					if ( !target->groupBody->groupList )
						product = 0;
					else	product = target->nextMember(0);
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
	if ( GroupControl::groupController->groupRules->jitting )
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
				GroupControl::groupController->groupRules->tempField->setNumber(target->getNumber() - argument->getNumber());
				target->groupBody->gCount = GroupControl::groupController->groupRules->tempField->getCount();
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
	/*  POISONED ITERATOR (Tony's ruling, 2026-08-02). Its only reader is here.
	The refusal was already announced once at the Iterate; this is silent
	and simply does not move, so the enclosing `while` exits on the false
	it already trusts -- the loop needed no change at all.  */
	if ( result->groupBody->flags.fLAG )
		return 0;
	if ( result->groupBody->flags.isIterator )
		{
		/*******************************************************************
		note: because result is an iterator it is not unwrapped in runOP()
		also -- does not differentiate between members and attributes
		because GroupItem does not offer priorMember() or priorAttribute().
		*******************************************************************/
		GroupItem *iterator = 0;
		if ( !result->groupBody->flags.data )
			iterator = result->groupBody->groupList->lastInList;
		else {
			iterator = result->getGroup();
			iterator = iterator->priorInParent;
			}
		GroupControl::groupController->groupRules->lastREF->setGroup(iterator);
		result->setGroup(iterator);
		if ( !iterator )
			result = 0;
		return result;
		}
	if ( GroupControl::groupController->groupRules->jitting )
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
	/*  BINARY FAMILY PROMOTES (Tony, 2026-08-01, greenlight after Word 2).
	`.count` on a double operand narrowed it AT ENTRY, so 0 - 2.5 gave
	-3 as a COUNT before anything else ran. ⚠ THE FIX IS PROMOTION, NOT
	THE COMPOUND FAMILY'S NARROW-AT-RESULT: a binary op has NO COUNT SLOT
	to narrow into -- its result is a fresh temp -- so the ruling's POP
	(`0 - 2.5 -> -2.5 TYPED DOUBLE`) is asking for premise 2's
	promotion-first rule applied in the interpreter. Count OP count stays
	a count, so nothing that was already integral moves.  */
	if ( isCOUNT(argument->groupBody->flags.data) || isNUMBER(argument->groupBody->flags.data) )
		if ( isNUMBER(target->groupBody->flags.data) || isNUMBER(argument->groupBody->flags.data) )
			GroupControl::groupController->groupRules->tempField->setNumber(target->getNumber() * argument->getNumber());
		else
		if ( isCOUNT(target->groupBody->flags.data) )
			GroupControl::groupController->groupRules->tempField->setCount(target->getCount() * argument->getCount());
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
	if ( GroupControl::groupController->groupRules->jitting )
		{
		 jitEmitBinary(argument, target, jitMul);
		return jitEmitAssign(target, target); 
		}
	if ( target->groupBody->flags.data && argument->groupBody->flags.data )
		{
		if ( isCOUNT(target->groupBody->flags.data) )
			{
			GroupControl::groupController->groupRules->tempField->setNumber(target->getNumber() * argument->getNumber());
			target->groupBody->gCount = GroupControl::groupController->groupRules->tempField->getCount();
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
	if ( target )
		if ( target->groupBody->gCount )
			return GroupControl::groupController->groupRules->trueResult;
		else
		if ( argument && argument->groupBody->gCount )
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
	if ( isLIST(argument->groupBody->flags.binType) && (!target->groupBody->flags.data || isSTRING(target->groupBody->flags.data) || isTOKEN(target->groupBody->flags.data)) )
		{
		if ( GroupControl::groupController->groupRules->jitting )
			jitDegrade("+= list-concat into a string target",target);
		Buffer *concatBuf = (Buffer*)GroupControl::groupController->groupRules->bufferSTAK->pop();
		if ( !concatBuf )
			concatBuf = new Buffer("concat buffer");
		if ( target->groupBody->flags.data )
			::appendGroup(target,0,concatBuf);
		::appendGroup(argument,0,concatBuf);
		return ::opString(target,concatBuf);
		}
	if ( isLIST(argument->groupBody->flags.binType) )
		{
		if ( GroupControl::groupController->groupRules->jitting )
			jitDegrade("+= copyListTo a list argument",target);
		argument->copyListTo(target);
		}
	else
	if ( !target->groupBody->flags.isRule && !target->groupBody->flags.actionType && (target->groupBody->flags.binType || target->groupBody->groupList) )
		{
		if ( GroupControl::groupController->groupRules->jitting )
			jitDegrade("+= structural append (binType/groupList)",target);
		target->addMember(argument);
		}
	else
	if ( argument->groupBody->flags.data )
		if ( target->groupBody->flags.data )
			switch (target->groupBody->flags.data)
				{
				case 5:
					if ( GroupControl::groupController->groupRules->jitting )
						{
						 jitEmitBinary(argument, target, jitAdd);
						return jitEmitAssign(target, target); 
						}
					GroupControl::groupController->groupRules->tempField->setNumber(target->getNumber() + argument->getNumber());
					target->groupBody->gCount = GroupControl::groupController->groupRules->tempField->getCount();
					break;
				case 9:
					if ( GroupControl::groupController->groupRules->jitting )
						{
						 jitEmitBinary(argument, target, jitAdd);
						return jitEmitAssign(target, target); 
						}
					target->groupBody->gNumber += argument->getNumber();
					break;
				case 13:
				case 14:
					if ( GroupControl::groupController->groupRules->jitting )
						return jitEmitStringPlusEQ(argument,target);
					target->setText(::concat(2,target->getText(),argument->getText()));
					break;
				case 4:
					if ( GroupControl::groupController->groupRules->jitting )
						jitDegrade("+= on a Buffer target",target);
					target->getBuffer()->appendString(argument->getText(),0,0);
					// if buffer mark is set, argument is inserted into buffer at mark
					// otherwise it is appended at end of buffer. mark is left as is
					break;
				case 12:
					if ( GroupControl::groupController->groupRules->jitting )
						jitDegrade("+= on a Stak target",target);
					target->groupBody->gStak->push(argument);
					break;
				default:
					if ( GroupControl::groupController->groupRules->jitting )
						jitDegrade("+= on an unhandled datA",target);
					else	::fprintf(stderr,"ERROR Operator += failed on %s and %s\n",target->groupBody->tag,argument->groupBody->tag);
				}
		else {
			if ( GroupControl::groupController->groupRules->jitting )
				jitDegrade("+= into a target with no datA",target);
			target->copyData(argument);
			}
	else {
		if ( GroupControl::groupController->groupRules->jitting )
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
		if ( GroupControl::groupController->groupRules->jitting )
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
		GroupControl::groupController->groupRules->lastREF->setGroup(iterator);
		result->setGroup(iterator);
		if ( !iterator )
			result = 0;
		return result;
		}
	if ( GroupControl::groupController->groupRules->jitting )
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
	if ( printText )
		if ( ruler->toBUFFER )
			ruler->toBUFFER->appendString(printText,0,0);
		else	::printf("%s",printText);
	else	::fprintf(stderr,"print: recieved no print text\n");
	buffer->reset();
	ruler->bufferSTAK->push(buffer);
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
	if ( !ruler->tempField->groupBody->flags.data )
		::fprintf(stderr,"ERROR integer div operator failed on %s and %s\n",target->groupBody->tag,argument->groupBody->tag);
	return ruler->tempField;
}

/***************************************************************************
	Rule action for the :% replace operator.
***************************************************************************/
extern "C" GroupItem *opReplaceAttribute(GroupItem *argument, GroupItem *target)
{
GroupItem 	*grup = 0;
GroupItem 	*added = 0;
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
	if ( argument && target )
		switch (argument->groupBody->gCount)
			{
			case 12:
				target->groupBody->flags.fLAG = !target->groupBody->flags.fLAG;
				break;
			case 21:
				target->groupBody->flags.isPercent = !target->groupBody->flags.isPercent;
				break;
			case 25:
				target->groupBody->flags.isVirtual = !target->groupBody->flags.isVirtual;
				break;
			case 26:
				target->groupBody->flags.mergeOn = !target->groupBody->flags.mergeOn;
				break;
			case 29:
				target->groupBody->flags.noPrint = !target->groupBody->flags.noPrint;
				break;
			case 31:
				target->groupBody->flags.byRef = !target->groupBody->flags.byRef;
				break;
			case 32:
				target->groupBody->flags.binType = !isLIST(target->groupBody->flags.binType);
				break;
			case 33:
				target->groupBody->flags.binType = !isBIN(target->groupBody->flags.binType);
				break;
			default:
				::fprintf(stderr,"opSetFlag: setting %s not supported yet\n",target->groupBody->tag);
			}
	else	::fprintf(stderr,"opSetFlag: missing operand\n");
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
	Rule action for the <: set tag operator.
***************************************************************************/
extern "C" GroupItem *opSetTag(GroupItem *argument, GroupItem *target)
{
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
	return target;
}

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
		::fprintf(stderr,"ERROR Operator unary - failed on %s\n",result->groupBody->tag);
		return 0;
		}
	return GroupControl::groupController->groupRules->tempField;
}

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
				stuff = grup->getRStuff();
				live = ::countRuleTerms(grup);
				if ( !stuff->termCount )
					::fprintf(stderr,"parseMethod: WARNING binding %s to %s with no parseTerms -- indices unguarded\n",name,grup->groupBody->tag);
				else
				if ( stuff->termCount != live )
					{
					::fprintf(stderr,"parseMethod: REFUSING to bind %s to %s\n",name,grup->groupBody->tag);
					::fprintf(stderr,"             emitted against %s terms, rule now has %s\n",::toStringFromInt(stuff->termCount),::toStringFromInt(live));
					return grup->getGroup();
					}
				::setParseMethod(stuff,name);
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
GroupItem 	*into = rule->rStuff->parentLabel;
GroupItem 	*label = new GroupItem("Scaf");
GroupItem 	*t1 = rule->get(1);
char 		*from = GroupControl::groupController->groupRules->atRuleMark;
	return ::leaveRule(rule,into,label,from,::lit(t1,"x"));
}

/*  === GENERATED by genParse('Scaf2'), pasted verbatim (rung-2 emission) === */
extern "C" GroupItem *parseScaf2(GroupItem *rule)
{
GroupItem 	*into = rule->rStuff->parentLabel;
GroupItem 	*label = new GroupItem("Scaf2");
GroupItem 	*t1 = rule->get(1);
GroupItem 	*t2 = rule->get(2);
char 		*from = GroupControl::groupController->groupRules->atRuleMark;
	return ::leaveRule(rule,into,label,from,::lit(t1,"{") && ::lit(t2,"}"));
}

/*  === GENERATED by genParse('ScafA'), pasted verbatim (rung-4 callee) === */
extern "C" GroupItem *parseScafA(GroupItem *rule)
{
GroupItem 	*into = rule->rStuff->parentLabel;
GroupItem 	*label = new GroupItem("ScafA");
GroupItem 	*t1 = rule->get(1);
char 		*from = GroupControl::groupController->groupRules->atRuleMark;
	return ::leaveRule(rule,into,label,from,::lit(t1,"a"));
}

extern "C" GroupItem *parseScafALT(GroupItem *rule)
{
GroupItem 	*into = rule->rStuff->parentLabel;
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
GroupItem 	*into = rule->rStuff->parentLabel;
GroupItem 	*label = new GroupItem("ScafB");
GroupItem 	*t1 = rule->get(1);
GroupItem 	*t2 = rule->get(2);
char 		*from = GroupControl::groupController->groupRules->atRuleMark;
	return ::leaveRule(rule,into,label,from,::parseR(t1,label) && ::lit(t2,"b"));
}

extern "C" GroupItem *parseScafC(GroupItem *rule)
{
GroupItem 	*into = rule->rStuff->parentLabel;
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
GroupItem 	*into = rule->rStuff->parentLabel;
GroupItem 	*label = new GroupItem("ScafE");
GroupItem 	*t1 = rule->get(1);
GroupItem 	*t2 = rule->get(2);
GroupItem 	*t3 = rule->get(3);
char 		*from = GroupControl::groupController->groupRules->atRuleMark;
	return ::leaveRule(rule,into,label,from,::lit(t1,"e") && (::parseR(t2,label) || 1) && ::lit(t3,"f"));
}

extern "C" GroupItem *parseScafF(GroupItem *rule)
{
GroupItem 	*into = rule->rStuff->parentLabel;
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
GroupItem 	*into = rule->rStuff->parentLabel;
GroupItem 	*label = new GroupItem("ScafI");
GroupItem 	*t1 = rule->get(1);
char 		*from = GroupControl::groupController->groupRules->atRuleMark;
	return ::leaveRule(rule,into,label,from,::lit(t1,"i"));
}

extern "C" GroupItem *parseScafOUT(GroupItem *rule)
{
GroupItem 	*into = rule->rStuff->parentLabel;
GroupItem 	*label = new GroupItem("ScafOUT");
GroupItem 	*t1 = rule->get(1);
GroupItem 	*t2 = rule->get(2);
GroupItem 	*t3 = rule->get(3);
char 		*from = GroupControl::groupController->groupRules->atRuleMark;
	return ::leaveRule(rule,into,label,from,::lit(t1,"(") && ::parseR(t2,label) && ::lit(t3,")"));
}

/*******************************************************************************
    parseRuleMethod — genParseShape §4.1, the binding. What connects a compiled
    parseScaf to Scaf.rStuff.parseMethod.

    §4.1's candidate was the setRuleAction path in the `=value` form, and that
    is what this is, modelled line for line on interpretMethod (GroupActions.rtn)
    — the closest existing analogue, because it is the one command that binds a
    dlsym'd symbol somewhere OTHER than the plain method slot. Registered in
    cOMMANDs as `parseMethod`, used as a definition attribute:

        Scaf isRule "x"- parseMethod=parseScaf;

    exactly the shape the grammar already uses for ruleMethod= and
    interpretMethod=. In the kant world this whole function is one ORC-compile
    and a stored handle; here it is a dlsym.

    getRStuff, not rStuff: a rule reached at definition time may not have been
    parsed yet, and the fork reads the field off the rule's OWN stuff.
*******************************************************************************/
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
				stuff = grup->getRStuff();
				stuff->termCount = ::atoi(name);
				}
			else	::fprintf(stderr,"parseTerms: no rule to record against\n");
			}
		else	::fprintf(stderr,"parseTerms: expected a count in text\n");
	else	::fprintf(stderr,"parseTerms: should be invoked as a definition attribute\n");
	return input->getGroup();
}

/*******************************************************************************
    planRule — the §4.1 fold, then one plan node per real term. NULL means the
    whole rule is refused: a plan that is missing a term is worse than no plan.
*******************************************************************************/
extern "C" GroupItem *planRule(GroupItem *rule)
{
GroupItem 	*plan = 0;
GroupItem 	*term = 0;
GroupItem 	*node = 0;
GroupItem 	*lab = 0;
GroupItem 	*site = 0;
int 		i = 1;
	if ( ::unresolvedTerms(rule) )
		{
		::fprintf(stderr,"  REFUSE rule %s -- %s unmaterialised terms\n",rule->groupBody->tag,::toStringFromInt(::unresolvedTerms(rule)));
		return 0;
		}
	if ( rule->groupBody->flags.data )
		{
		::fprintf(stderr,"  REFUSE rule %s -- rule-level data %s (§4.1 rule-as-data, rung 5)\n",rule->groupBody->tag,::dataName(rule->groupBody->flags.data));
		return 0;
		}
	if ( !::countRuleTerms(rule) )
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
	while ( term = rule->get(i) )
		{
		if ( !term->groupBody->flags.noPrint )
			{
			node = ::planTerm(term,i);
			if ( !node )
				{
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
    THE PLAN (rung 3, Clay SEQ 26 §2/§3) — the seam artifact.

    The walk produces a plan tree of GroupItems: resolved decisions, baked
    literals, NO TARGET SYNTAX ANYWHERE. Emitters consume it. It is the bytecode
    move one level up — bytecode instructions are GroupItems, so is this, and
    the structure costs nothing.

    FIVE KINDS, and that is the WHOLE vocabulary for rungs 1, 2 and 4:

        SEQ    rule tag, label, ordered conjuncts   (members, in order)
        ALT    rule tag, ordered disjuncts, no label
        LIT    literal text (noLabel)               + `at` = baked rule[] index
        LITTO  literal text + slot                  + `at`
        CALL   the term to parse through            + `at`

    It grows ONE KIND AT A TIME as a rung demands it — MANY with rung 5, GUARD
    with the alternation rung, ACT when actions land. If the vocabulary ever
    comes back complete, it is too big: that is the tell that this rung has gone
    wrong, because designing against grammar features not yet on the ladder is
    exactly what the ladder exists to prevent.

    WHY A PLAN AND NOT A VISITOR, in this tree specifically: a plan diff is
    TARGET-INDEPENDENT (Scaf2's plan is identical whether the emitter writes C++
    or kant, so a POP can assert the DECISION rather than the TEXT); generate-
    time refusals belong here, validated once so every emitter inherits them;
    and §3.3's helper functions are discovered mid-walk, which with text already
    going out means buffering or emitting out of order, and with a plan means
    walking it twice. The cost, stated so it is not a surprise: a bug can now
    live in the walk, the plan, or the emitter. The mitigation is that a plan is
    PRINTABLE and an intermediate visitor state is not.

    Note LIT vs LITTO carries "does this attach a label", NOT which support
    function spells it. A labelled literal is litTo inside a SEQ and litOption
    inside an ALT — the plan already records the enclosing fold, so choosing the
    spelling is emitter-side work about the target, per §4.
*******************************************************************************/
/*******************************************************************************
    planTerm — one term -> one plan node, or NULL meaning REFUSED.

    EVERY NODE COMES FROM A POSITIVE TEST, and an unclassified term is a
    REFUSAL, never a default. This is the ruling the §1 census forced, and it is
    the one place genParse must NOT copy setTestMatch: there, references are
    classified by FALL-THROUGH — "no row matches" is the answer, and parse()
    picks them up on the hasAttributes arm. That residual class must not be
    inherited. If the walk treated "nothing matched" as CALL, every future term
    kind that fails to match would become a silent bogus CALL — and since the
    census says the unmatched group is the LARGEST one, that failure mode would
    be both easy to write and hard to see.

    definingRule() != term is what turns the residual into a positive property.
    It is a POINTER test, not a name test, and it is the same instrument rung 4
    already runs on.

    ORDER IS DELIBERATE. data is tested BEFORE the reference test, so a term
    that is BOTH content-is-a-group AND a reference REFUSES rather than silently
    becoming a CALL. Two such terms exist (JSONtoken[5] and DatA[2], both
    NumbeR). Their precedence is a NAMED OPEN ITEM, not an unnoticed one — no
    ladder rule reaches it, and what it means semantically is not settled.
*******************************************************************************/
extern "C" GroupItem *planTerm(GroupItem *term, int index)
{
RuleStuff 	*rs = term->rStuff;
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
	if ( isBIN(term->groupBody->flags.binType) || isREGISTRY(term->groupBody->flags.binType) )
		{
		::fprintf(stderr,"  REFUSE %s -- container (not on the ladder yet)\n",term->groupBody->tag);
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
	if ( definer != term )
		{
		node = new GroupItem("CALL");
		node->setText(definer->groupBody->tag);
		}
	else
	if ( term->groupBody->flags.data )
		{
		::fprintf(stderr,"  REFUSE %s -- inline group / character data %s (named future kind)\n",term->groupBody->tag,::dataName(term->groupBody->flags.data));
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
			if ( grup->groupBody->flags.isLocal && !grup->groupBody->flags.isLabel && !grup->groupBody->flags.noPrint && grup->groupBody != action->groupBody )
				grup->clear();
		ruler->useDefaultSpace = 1;
		if ( result = result->groupBody->gMethod(result) )
			result->groupBody->flags.isBranch = 0;
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
		if ( (grup->groupBody->flags.isArgument || grup->groupBody->flags.isLocal) && !grup->groupBody->flags.noPrint )
			{
			body = (GroupBody*)recurseSTAK->pop();
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
RuleStuff 	*rs = term->rStuff;
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
GroupItem 	*result = 0;
GroupItem 	*ruleArg = 0;
	if ( isCoded(field->groupBody->flags.actionType) )
		if ( !::processCode(field) )
			return 0;
	/*  THE SELF-CALL SEAM. Under jitting an ordinary call INLINES -- emit-on-walk
	re-executes the callee's BlocK into the current builder, which is measured
	to work and produces correct run-time answers with no `call` in the IR
	(incant/jitJC). A SELF-call cannot inline: the re-walk reuses nodes that
	already carry jitData from the enclosing pass, and the condition target's
	jitValue is by then an i1 (jitEmitCompare's result), so the second pass
	asserts inside LLVM. jitEmitSelfCall answers 0 for every other callee, so
	this gate changes nothing about ordinary calls.  */
	if ( GroupControl::groupController->groupRules->jitting )
		{
		 if (::jitEmitSelfCall(field)) return field; 
		}
	if ( ruleArg = field->get("argument") )
		if ( argument )
			ruleArg->setGroup(result = argument);
		else	ruleArg->setGroup(result = field);
	else	result = field;
	GroupControl::groupController->groupRules->lastREF->setGroup(result);
	if ( field->groupBody->flags.recursive )
		::saveLocalFields(field);
	result = ::processAction(field);
	if ( field->groupBody->flags.recursive )
		::restoreLocalFields(field);
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
extern "C" GroupItem *runOP(GroupItem *field)
{
GroupItem 	*result = 0;
GroupItem 	*op = field->get(1);
GroupItem 	*arg = field->get(3);
GroupItem 	*target = field->get(2);
	if ( isGROUP(target->groupBody->flags.data) && !target->groupBody->flags.isPointer && !target->groupBody->flags.isIterator && !op->groupBody->flags.isAssign )
		target = target->getGroup();
	if ( arg && isGROUP(arg->groupBody->flags.data) && !arg->groupBody->flags.isPointer )
		arg = arg->getGroup();
	if ( op->groupBody->flags.instructType && isMethod(target->groupBody->flags.instructType) && target->groupBody->flags.invoke )
		target = target->groupBody->gMethod(target);
	if ( arg )
		if ( isMethod(arg->groupBody->flags.instructType) && arg->groupBody->flags.invoke )
			arg = arg->groupBody->gMethod(arg);
	/* resolveList(arg) deliberately disabled: it returned a COPY of a
	list operand (losing tag/identity/byRef), which broke the list-
	consuming operators (:+ <- merge) that walk argument.isLIST and
	depend on the real node. Single-method args are still resolved
	one line up. Re-enable only by resolving members in place, and
	skip it for the list operators. */
	//or arg.isLIST   arg = resolveList(arg);
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
	if ( GroupControl::groupController->groupRules->jitting && (isOperator(op->groupBody->flags.instructType) || op->groupBody->flags.isUnary) )
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
int 		baseStak = 0;
	if ( ruler->inputSTAK )
		baseStak = ruler->inputSTAK->length;
	if ( field && field->groupBody->flags.data )
		{
		ruler->divertToRule = 1;
		ruler->pushInput(field);
		}
	result = rule->parse(0);
	while ( field && field->groupBody->flags.data && ruler->inputSTAK && ruler->inputSTAK->length > baseStak )
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
		if ( (grup->groupBody->flags.isArgument || grup->groupBody->flags.isLocal) && !grup->groupBody->flags.noPrint )
			{
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

/*******************************************************************************
    setParseMethod — dlsym a name into a RuleStuff's parseMethod slot.

    Passthrough because tok has no syntax for casting a void* to a typed fnptr
    member, and parseMethod is typed by construction (bear-trap #20). Body is
    ENTIRELY passthrough and everything it touches arrives as a PARAMETER —
    bear-trap #13: an incant-level local referenced only inside a passthrough
    gets pruned as unused, taking its initializing call with it. Parameters are
    never pruned, so the whole computation is pushed into the argument list.
    stderr, not stdout, for the failure report (bear-trap #14).
    
    The above comment on tok passthru is incorrect. Most of the code between -%
    and %- below can be replaced with one tok line; no need to qualify parseMethod:
        parseMethod = dlsym(RTLD_SELF,name);
*******************************************************************************/
extern "C" int setParseMethod(RuleStuff *stuff, char *name)
{
	
	void    *address = ::dlsym(RTLD_DEFAULT,name);
	if ( !address )
	{
	::fprintf(stderr,"setParseMethod: ERROR no method found %s\n",name);
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
    showTree / treeOf — §2.4's acceptance test, and it has to be a TREE test.

    An alternation builds no label and passes `into` through, so the winning
    option attaches to the ENCLOSING rule's label. Get that wrong and you get
    the right LANGUAGE over the WRONG TREE — an empty JSONvalue wrapping every
    value. Every mark-and-win check still reads green, because the parse
    accepted exactly the same strings; the damage only surfaces when a code={}
    action goes looking for a child by name and finds a wrapper instead.

    So the POP compares the TREE the generated method builds against the tree
    the interpretive walk builds, on a PASSING case (§6.5-style). Run the
    fixture with the parseMethod bindings in place and again with them stripped;
    the two dumps must be identical.

    nextGroup is stateless, so it is safe to recurse on (unlike the shared-entry
    next()).
*******************************************************************************/
extern "C" int showTree(GroupItem *node, char *pad)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*kid = 0;
char 		*deeper = 0;
	if ( !node )
		return 0;
	if ( node == ruler->trueResult )
		{
		::fprintf(stderr,"%s(trueResult — matched, no tree)\n",pad);
		return 1;
		}
	deeper = ::concat(2,pad,"  ");
	::fprintf(stderr,"%s%s\n",pad,node->groupBody->tag);
	if ( node->groupBody->flags.hasAttributes || node->groupBody->flags.hasMembers )
		while ( kid = node->nextGroup(kid) )
			::showTree(kid,deeper);
	return 1;
}

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
    spellKant — call the kant emitLeaf and hand back its text.

    ONE ARGUMENT, because a kant action takes one: the plan node. `local` is not
    passed at all — the kant side derives it from the node's own `at` attribute,
    which every node carries INCLUDING an OPT's wrapped inner node (planTerm
    builds `at` before the OPT wrap and both end up with the same index). `sink`
    is the one thing genuinely external to the node — it is the fold's decision —
    so it rides as an attribute.

    THE `sink` ATTRIBUTE IS REUSED, NOT STACKED, exactly as iterBind reuses its
    `source` child: a second call must retarget the first attribute rather than
    add another, or getAttribute keeps answering with the stale one. `sink` is
    not among the attributes printPlan prints, so the census cannot move under it.
*******************************************************************************/
/*******************************************************************************
    spellMode — WHICH implementation is live. One line, and it is the whole
    answer to "a green stub reads as coverage".

    emitLeaf's fork is silent by design: absent a kant speller it is the function
    it always was, so every target stays green — which means a round that never
    registered its action would ALSO be green, and the POP could not tell the
    difference. This prints the answer, `pop.sh` pins it, and the pin is the
    acceptance test: it says `c++` until the kant emitLeaf lands and `kant`
    afterwards, and whoever flips it accounts for the flip. Same shape as
    tree.divergence flipping from asserting a divergence to asserting agreement.

    Called BEFORE the first `SPELL` line on purpose — spell.target starts at
    `SPELL`, so the mode line is asserted separately and cannot move the target.
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
	return input;
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
	the following externs (unWrap/writeTempFile). Doc goes here, in the block.
***************************************************************************/
extern "C" GroupItem *testing(GroupItem *input)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	if ( isCoded(input->groupBody->flags.actionType) )
		return ::jitRunAction(input) ? ruler->trueResult : 0;
	return ::jitRunIfTest(input) ? ruler->trueResult : 0;
}

/***************************************************************************
	Gloms parent label components together into the label string
***************************************************************************/
extern "C" GroupItem *tokenize(GroupItem *label)
{
RuleStuff 	*ruleStuff = label->rStuff;
char 		*atEnd = GroupControl::groupController->groupRules->atRuleMark;
int 		tokenLength = (int)(atEnd - ruleStuff->parentStuff->hereAt);
	label->setToken(ruleStuff->parentStuff->hereAt,tokenLength);
	return label;
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
    unresolvedTerms — how many REAL terms have no rStuff yet.

    MEASURED 2026-07-28 (§1 census): rStuff is materialised LAZILY. The runtime
    creates it on demand through getRStuff -- caught in the act, printing
    "getRStuff: min no rStuff - creating" for one of the very terms this counts.
    So a missing rStuff means NOT YET, not NOT A TERM, and it is nothing like
    the noPrint code-tail entries it was briefly conflated with.

    That conflation was a real defect: with `!rStuff` in the skip test,
    genParse('CodE') emitted `leaveRule(rule,into,label,from, (null) )` -- a
    rule reduced to nothing -- and recorded parseTerms=0, which the §3 guard
    would have BOUND with a warning rather than refused. Rules outside the
    ladder only; Scaf/Scaf2/ScafA/ScafB terms all carry rStuff.

    Until the rung-3 walk decides how to classify an unmaterialised term (it
    cannot read modifiers that are not there yet, and whether they are merely
    absent or genuinely default is NOT yet established), genParse REFUSES
    rather than emitting a method it knows is missing terms. A refusal is a
    validity question about the rule, so it belongs walk-side either way.
*******************************************************************************/
extern "C" int unresolvedTerms(GroupItem *rule)
{
GroupItem 	*term = 0;
int 		i = 1;
int 		n = 0;
	while ( term = rule->get(i) )
		{
		if ( !term->groupBody->flags.noPrint && !term->rStuff )
			n++;
		i++;
		}
	return n;
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
	getRStuff()
*/
