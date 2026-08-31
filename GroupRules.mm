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
	if ( token && token->groupBody->registry == GroupControl::groupController->groupRules->keyWords && !token->groupBody->flags.noPrint )
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
			/*  ⚠ UNDER JITTING THE WALK MUST NOT STOP. Measured 2026-08-05.
			This break is INTERPRETER CONTROL FLOW, and under jitting it was
			terminating THE COMPILER'S WALK: a `continue` inside a loop body
			set isBranch, this break fired, and EVERY STATEMENT AFTER IT IN
			THE BLOCK WAS NEVER EMITTED. Visible in the IR as an `endif`
			block holding nothing but its back edge, with the increment that
			should follow simply absent -- and silent, degrade count 0.
			
			The two eras want opposite things from the same flag. At RUN time
			a branch means stop executing this block. At EMIT time the
			statements after a branch are REACHABLE -- they run whenever the
			branch is not taken -- so they must all be emitted. The branch
			itself is already expressed in the IR by jitEmitContinue's
			terminator; the emitter does not need, and must not take, the
			interpreter's shortcut.
			
			Same family as everything else found today: emit-time execution
			doing something that belongs only to run time.  */
			if ( GroupControl::groupController->groupRules->jitting )
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
	/*  ⚠ KE-3, REPAIRED 2026-08-13 (SEQ 67 C.1). THE LINE ABOVE OVERWRITES arg
	WITH WHATEVER THE METHOD RETURNS, AND UNDER JITTING THAT METHOD IS AN
	EMITTER THAT RETURNS NULL TO MEAN "I REFUSED". jitEmitShortCircuit ends
	its degrade path with a bare `return nullptr`, so a body whose operand
	the emitter cannot see -- a command invocation, which arrives as a bare
	Token -- left arg null and the stamp below dereferenced it. Exit 139,
	inside the EMIT walk, AFTER the degrade line had already announced the
	refusal. Measured with its control: the identical body interpreted exits
	0. Census and frames in docs/jit.md; entry in docs/knownErrors.md.
	
	⚠ AND IT IS THE ONE-CHANNEL-ONE-MEANING FAMILY AGAIN, in its sharpest
	form yet -- the two meanings belong to different ERAS, not different
	facts. A method's return value means THE NODE at run time and means
	WHETHER EMISSION SUCCEEDED at emit time. One channel, one reader, two
	eras. That is the fourth row of the standing table exactly, and the cure
	here is the cheap half of the standing cure: stop treating "no node" as
	a node. The structural half -- a separate emitted/refused channel -- is
	the invokable mechanism's business, not this repair's.
	
	FALLING BACK TO BrancheS IS NOT A NEW BEHAVIOUR: it is the same node the
	no-expression path two lines up already uses, so the stamp lands
	somewhere real and the walk continues instead of dying.  */
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
			/*  THE TRAILING-CONTINUE GUARD, 2026-08-25, Tony's word. Model is
			aCTionWhilE's fix (b88f33d) -- same defect, same cure.
			⚠ SITE-SPECIFIC READ, not a paste. In a do/while a `continue`
			jumps to the CONDITION rather than out, so the loop keeps
			running and this is the only arm that can leave a sentinel in
			`result` at exit. Unlike aCTionFOR there is no `result = 0;` at
			the head of the body, so `result` here is always whatever the
			last statement yielded -- which is exactly why the sentinel
			survives without this line.  */
			if ( isContinue(result->groupBody->flags.isBranch) )
				{
				result = GroupControl::groupController->groupRules->trueResult;
				continue;
				}
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
	/*  labelNO, not falseResult (director, 2026-08-07). This construct
	executed NO statement, and an action's value is the value of the LAST
	EXECUTED STATEMENT -- so it has no value. `false` was never a decision
	that false is correct; it was the least-bad approximation while "yields
	nothing" was unsayable. labelNO is isCOUNT 0, so the NUMERIC reading is
	unchanged and both engines still agree; what is new is that the attach
	can tell "nothing" from "the number zero".  */
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
				/*  ⚠ THE PRODUCER OWNS THE INVARIANT: EVERY LIVE RULE
				CARRIES rStuff. Mark 3, Tony 2026-08-22.
				
				GUARD THE CONSUMER GENTLY, ASSERT THE PRODUCER LOUDLY --
				R-4's shape, one layer up. The consumer-side guards added
				the same day (runRuleAction, opDot case 36, processFlags)
				make SILENCE out of a state that is lawful for a specimen
				and a DEFECT on a live rule, and per Ruling A the consumer
				must not try to tell those apart: rStuff-less IS the
				definition of specimen. So the loudness moves to where the
				invariant actually lives.
				
				This is the registration boundary -- filing into an isRule
				registry is what promotes a node to a rule -- so it is the
				one place that can promise a live rule has rStuff. The
				line above ensures it; this refuses if the ensure did not
				take, which would mean the allocation itself failed and
				every downstream guard is about to report "specimen" for
				something that is really a broken rule.  */
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
				if ( ::compare(item->groupBody->tag,"argument") == 0 )
					item->groupBody->flags.isArgument = 1;
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
	/***********************************************************************
	If NewGroup is a rule check to see if it has a rule method .
	Also makes sure if NewGroup isGROUP the group is made a rule
	
	THE CODED TEST WINS (Tony's order, SEQ 56, 2026-08-13). The arms
	were dlsym-first until now. An incant code body on a rule is what
	the rule MEANS, so it takes the dispatch and the dlsym probe is
	the fallback. Two measured carry-overs, not style.
	
	First, the not-isMethod guard stays on the DLSYM ARM ONLY. A coded
	re-definition of a rule that already carries isMethod from its
	original definition, which is every Grokking rule with a C++
	action, never reaches a guarded arm. That is M1b silent inertness,
	measured on Braced and Parens: exit 0, no warning, the CodE
	attached and read by nobody. See docs/parseCodeMeasurements.md.
	
	Second, the order only discriminates for a rule that is BOTH coded
	and dlsym resolvable. The five coded rules in the tree, list twice
	plus JSONfield, JSONarray and DelimOver, have no aCTion symbol of
	their own, so they fell through the failed dlsym to isCoded before
	and land on processAction directly now. Same destination either
	way. Censused against the 34 aCTion symbols in the binary before
	the build. The only collision anywhere in the tree is the coded
	Braced in incant/parseCode, which is unregistered in the setup
	fILEs registry and so is loaded by nothing.
	***********************************************************************/
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
			{
			ruler->lastREF->groupBody->gGroup = grup;
			ruler->lastREF->groupBody->flags.data = 6;
			}
		result = StatemenT->groupBody->gMethod(StatemenT);
		if ( result->groupBody->flags.byRef )
			grup = result->priorInParent;
		if ( result->groupBody->flags.isBranch )
			{
			/*  THE TRAILING-CONTINUE GUARD, 2026-08-25, Tony's word. Model is
			aCTionWhilE's fix (b88f33d): the sentinel must not survive the
			loop that consumed it, or the LAST iteration's continue is
			still sitting in `result` when the loop exits and propagates to
			the enclosing block as a continue, deleting every statement
			after the loop. Silent, exit 0.
			⚠ SITE-SPECIFIC READ, not a paste. This loop ALSO continues
			earlier, at the `restrict` test above -- that one is safe
			because `result = 0;` runs at the top of every iteration and so
			no sentinel is in flight there. Only this arm can carry one.  */
			if ( isContinue(result->groupBody->flags.isBranch) )
				{
				result = ruler->trueResult;
				continue;
				}
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
	/*  labelNO, not falseResult (director, 2026-08-07). This construct
	executed NO statement, and an action's value is the value of the LAST
	EXECUTED STATEMENT -- so it has no value. `false` was never a decision
	that false is correct; it was the least-bad approximation while "yields
	nothing" was unsayable. labelNO is isCOUNT 0, so the NUMERIC reading is
	unchanged and both engines still agree; what is new is that the attach
	can tell "nothing" from "the number zero".  */
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
	/*  ⚠ THE LAST CODE ALLOWED TO CRASH IS THE CODE THAT REPORTS CRASHES.
	Standing principle, Tony 2026-08-22, and it outlives this fix.
	
	Failure reporting must survive its own subject. `failedAt` lives on
	rStuff, and a subject arriving here with no rStuff is exactly the
	"something went wrong in the getting-there" case this reporter exists
	to announce -- so trusting the subject to be intact is the one
	assumption it must never make. It cannot say so dead.
	
	Print what exists, name what is absent. Reported unconditionally and
	with its value either way (rule H4): an absence that prints nothing
	would be indistinguishable from a parse that failed at offset zero.  */
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
	/*  MR, 2026-08-06. REFUSE LOUDLY, NEVER CRASH. The line below used to
	dereference StatemenT unguarded, so ANY `if` whose governed statement
	is absent exited 139 with ZERO bytes of output -- no diagnostic, no
	stop: line, nothing to grep. Smallest reproducer is `if 1;`, which
	involves no rule and no mention.
	
	⚠ THIS IS BEAR-TRAP #4's CRASH, AND THE TRAP NEVER SAID SO. A `//`
	wedged between an if's condition and its statement leaves exactly this
	terminal state, and the trap describes the symptom as a broken parse
	with field-resolution bleed. The bleed is real; the 139 underneath it
	was this line.
	
	It is also what a rule mention in condition position produces -- naming
	a rule FIRES it, and in `if Braced;` the fired rule consumes the
	following statement as its input, leaving nothing to govern. That is a
	real language hazard but it is NOT the crash, and conflating them sent
	one earlier reading of `if Braced;` up the wrong tree.
	
	Refuses rather than falling through to `or ElsE`: an if whose statement
	vanished is malformed, and running its else arm would invent an answer
	for a construct nobody wrote. Says which construct and where.  */
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
	/*  labelNO, not falseResult (director, 2026-08-07). This construct
	executed NO statement, and an action's value is the value of the LAST
	EXECUTED STATEMENT -- so it has no value. `false` was never a decision
	that false is correct; it was the least-bad approximation while "yields
	nothing" was unsayable. labelNO is isCOUNT 0, so the NUMERIC reading is
	unchanged and both engines still agree; what is new is that the attach
	can tell "nothing" from "the number zero".  */
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
GroupItem 	*iterator = ::unWrap(input->get(1));
GroupItem 	*source = ::unWrap(input->get(2));
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
		action to see. (⚠ `tokenize` RETIRED 2026-09-02. This account is
		dated 2026-08-01 and stands as what was measured then; the
		flattening survives it, carried now by the `tokened` bit and
		captureSpan, so the conclusion below is unaffected.) So the branch was ALWAYS taking atoi, and every
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
			
			if (!gNoUnwrap)
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
				if ( isContinue(result->groupBody->flags.isBranch) )
					{
					// result set to trueResult so result != continue or if continue is the last
					// statement in the while loop result will be passed on to the enclosing block
					// as continue which the pooches the block
					result = GroupControl::groupController->groupRules->trueResult;
					continue;
					}
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
	/*  labelNO, not falseResult (director, 2026-08-07). This construct
	executed NO statement, and an action's value is the value of the LAST
	EXECUTED STATEMENT -- so it has no value. `false` was never a decision
	that false is correct; it was the least-bad approximation while "yields
	nothing" was unsayable. labelNO is isCOUNT 0, so the NUMERIC reading is
	unchanged and both engines still agree; what is new is that the attach
	can tell "nothing" from "the number zero".  */
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
    actK — THE ACTION TAIL SHIM. 2026-08-12, the full-monty rung.

    Third of the litK/parseRK family and the same convention: ZERO information
    from the body. The body says "and now the rule's action runs"; the frame
    supplies WHICH rule and WHICH label, exactly as it supplies position and
    mark for the other two.

    ⚠ WHY A SHIM AT ALL, WHEN THE BODY COULD "JUST CALL aCTionBraced()".
    Measured 2026-08-12, both spellings, and both are unsound:
      · a BARE extern call from a kant body does not dispatch, and the negative
        control settles it -- aCTionNOSUCHatALL() behaves identically, exit 0,
        no diagnostic. There is no "it worked" to observe.
      · REGISTERED as a command it does dispatch, and then reports TRUE in an
        AND chain whatever the action did, because aCTionBraced hands back a
        clear()ed node and the AND contract reads a present non-numeric node as
        true. Bare `if` on the same call reads FALSE. One call, two readings --
        the bare-if truthiness fork, filed UNRULED in the 08-11 seal, landing
        on the tail spelling.
      · and underneath both: the action wants the LABEL, and the body holds no
        node by convention. aCTionBraced's first statement is input.clear(), so
        a bare call CLEARS THE WRONG NODE (bear-trap #22's family).

    ⚠ THE VERDICT IS THE SHIM'S, NEVER THE ACTION'S RETURN. That is the whole
    point of the third bullet above. A datumless return is aCTionBraced doing
    its job correctly -- it is not a failure, and it must not become a
    TRUE-by-presence either. So: dispatch happened => trueResult. Full stop.

    ⚠ AND THE FAILURE IS LOUD, because the negative control showed this exact
    family failing SILENTLY. A missing symbol REFUSES and says which name it
    looked for. Refuse, never substitute.

    ROUTE: dlsym at call time rather than a pointer stashed at mint. Priced
    2026-08-12: the stash would need actK to find the mint anyway, so it is not
    obviously cheaper; it adds a field whose only reader is this function; and
    step 2 (the kant body inlining the action) DELETES the question entirely.
    Cheap-to-remove beat cheap-to-run. If anyone ever measures a dlsym per
    bracket as hot, the stash is a local change with no callers to update.

    NOTE FOR STEP 2, recorded rather than assumed: the C++ arm's
    fireLabelMethod does `stuff.label = method(stuff.label)` and FAILS the rule
    when the action answers null. This shim does neither. For aCTionBraced the
    assignment is identity -- it mutates and returns the SAME node -- so the
    arms agree here; that is a Braced-specific equivalence and NOT a general
    one. A rule whose action returns a different node, or null, will need this
    revisited.

    ⚠ THE ARGUMENT IS DECLARED AND IGNORED, deliberately. traceParse is the
    proven precedent for an extern that is called both as `traceParse('on')`
    and as `traceParse()`; a zero-parameter incant command is untested here and
    this rung is not the place to test it.
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
    activateAll -- THE WHOLE-POPULATION FORM.

    Walks the corpus and binds every PENDING entry to the rule it was filed
    against. The rule is read back from the entry's group back-pointer, which
    storeBody set -- the same back-pointer idiom kantDoor uses for `this`.
    PRINTS the number activated, unconditionally and with its value, so a
    caller can assert a quantity rather than an absence (rule H4).

    ⚠ RETURNS GroupItem, NOT int, AND THAT IS LOAD-BEARING. An extern wired as
    an incant command MUST return a GroupItem: the command machinery takes the
    return value as a GroupItem*, so an int return is read as a pointer and the
    process dies ON THE STATEMENT AFTER THE CALL, never at the call itself.
    Measured 2026-08-21 -- the first cut of this function returned int, and the
    trace proved it by never firing: the crash happened before the callee was
    entered on the NEXT statement, which reads as "the command was never
    called". Census of incant/setup at that date: of every registered
    immediateAction command in the tree, ZERO return int. This one does not
    either.
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

    The per-rule form. THE ONLY WRITER of CodE and isCoded on the generated
    arc. A fresh node is minted and retagged rather than the stored one being
    moved, so the corpus entry survives activation and the census can still
    see it -- a corpus that empties itself on activation cannot report a
    zero remainder, it can only report an empty corpus.
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
		if ( entry->groupBody->flags.isRule && !entry->getRStuff() )
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
int 		unconsumed = 0;
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
		unconsumed += auditUnconsumed(target);
		::fprintf(stderr,"AUDIT %s: %s missing rules, %s missing terms, %s loose, %s unconsumed\n",target->groupBody->tag,::toStringFromInt(missRules),::toStringFromInt(missTerms),::toStringFromInt(loose),::toStringFromInt(unconsumed));
		}
	else {
		while ( registry = ruler->registries->next(registry) )
			{
			missRules += ::auditMissingRules(registry);
			missTerms += ::auditMissingTerms(registry);
			loose += ::auditSpurious(registry);
			unconsumed += auditUnconsumed(registry);
			}
		/*  ⚠ REPORTED UNCONDITIONALLY AND WITH ITS VALUE (rule H4). An absence
		check on the UNCONSUMED lines would go green the day the emitter is
		deleted; a count that is always printed and asserted at zero cannot.  */
		::fprintf(stderr,"AUDIT all registries: %s missing rules, %s missing terms, %s loose, %s unconsumed\n",::toStringFromInt(missRules),::toStringFromInt(missTerms),::toStringFromInt(loose),::toStringFromInt(unconsumed));
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

/*******************************************************************************
    auditUnconsumed -- THE CONSUMED-CHECK. Tony's rider, 2026-08-05.

    AN INSTALL ATTRIBUTE THAT FIRED LEAVES NO TERM BEHIND. `parseMethod=` and
    `parseTerms=` are define-time fire-and-forget commands of the isRule family:
    they change the group being defined and are then FORGOTTEN, never added as
    attributes (incant/setup:7-11 states the contract). So finding one sitting in
    a rule's TERM LIST is proof it was never a command in that context -- it was
    read as ordinary grammar.

    ⚠ WHY IT IS ITS OWN CHECK AND NOT LEFT TO MISSTERM. The generic missing-rStuff
    check DID fire on the specimen below, but it says "isRule term, no rStuff",
    which reads as a materialisation problem and points at rStuff -- bear country,
    and the wrong country. Two spurious terms in a rule the generator indexes by
    position is a DIFFERENT DISEASE with a different cure, and a check that names
    it saves the next reader the hunt.

    ⚠ H7 NEGATIVE CONTROL -- THE SPECIMEN IS REAL AND DATED. Installing
    `parseTerms=3 parseMethod=parseBraced` on incant/grammar:107 while the
    vocabulary was registered ONLY in incant/genScratch produced exactly this:
        AUDIT MISSTERM Braced [4] parseTerms  -- isRule term, no rStuff
        AUDIT MISSTERM Braced [5] parseMethod -- isRule term, no rStuff
        Braced 3 terms -> 5, against a method indexing rule[1..3]
        oneTest: Segmentation fault: 11
    That run is the control this check would have caught by NAME. The cure was to
    register both commands in incant/setup, where the grammar is read; this check
    is what makes a regression of that cure loud instead of silent.

    ⚠ PRESENCE-WITH-VALUE, NOT ABSENCE-OF-MESSAGE (rule H4): the caller prints the
    COUNT unconditionally and asserts it is zero, so deleting the emitter breaks
    the check rather than satisfying it.
*******************************************************************************/
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

/*******************************************************************************
    bodyCensus -- THE QUERY VERB.

    Reports the corpus as pending / activated / stray, PRINTED UNCONDITIONALLY
    AND WITH VALUES. That is rule H4: a census that stays silent when the
    corpus is empty is an absence check, and an absence check passes the day
    somebody deletes the code that would have spoken. Zero pending is a
    reportable answer here, not a silence.

    `stray` counts entries whose count is neither 1 nor 2. It should always be
    zero; it exists so that a corpus written by something other than these
    verbs is visible rather than silently partitioned into the two known bins.

    ⚠ RETURNS GroupItem for the reason spelled out on activateAll above.
*******************************************************************************/
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
		::fprintf(stderr,"compile: REFUSING %s -- no compiled body\n",field->groupBody->tag);
		return 0;
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
		::fprintf(stderr,"compile: REFUSING %s -- isCoded is set but there is no CodE attribute; the flag and the artifact disagree\n",field->groupBody->tag);
		return 0;
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
		
		::fprintf(stderr,"compile: REFUSING %s -- processCode would not parse the generated body; its message above names the position\n",field->groupBody->tag);
		return 0;
		}
endCompile:
	field->groupBody->flags.hasNewParse = 1;
	return field;
}

/*******************************************************************************
    compileStored -- PHASE 2 UNDER OPTION B. COMPILE THE BODY OUT OF THE
    REGISTRY, WITHOUT EVER WRITING THE RULE'S LIVE SLOT.

    THE SPELLING, FLAGGED AS THE CHARTER ASKS: a sixth verb rather than a new
    arm on compile, and it compiles THE CORPUS ENTRY, not the rule. The entry
    is a GroupItem like any other, so hanging a CodE on IT and compiling IT
    exercises the whole parse path while the rule stays untouched. That is
    kantDoor's mint pattern (genParse.rtn) -- it compiles a `kp<Rule>` mint in
    a separate registry for exactly this reason -- rather than a new mechanism.

    WHY NOT AN ARM ON compile: compile's contract is "compile the field you are
    given". Teaching it to go looking somewhere else for a body would make one
    function mean two things depending on a flag, which is the one-channel-two-
    meanings failure this project keeps paying for. The canary moves 313 -> 314
    and that is PRE-STATED here rather than discovered.

    STATES ON THE ENTRY: 1 pending · 3 COMPILED GREEN · 2 commissioned. Phase 2
    moves 1 -> 3 for a green compile and LEAVES 1 for a failure, so the residue
    is exactly the set still at 1. Phase 3 moves 3 -> 2. Never 0: a fresh node
    counts zero already, so zero can never mean a state we put it in.
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
		/*  ZERO MEANS SELF, THE BIND-SIDE HALF. Ruled 2026-08-24 with the emit
		side; landed here 2026-08-24 when the rule ladder fired break and
		the bind refused.
		
		`n` becomes the emitted `parseTerms=` value, and parseRuleMethod's
		staleness guard compares that against countRuleTerms(rule) -- REAL
		terms, non-noPrint. The marker-0 node is NOT A TERM; it is the
		rule's own data. Counting it made the bind line claim one term for a
		rule that has none, and the guard correctly refused:
		
		parseMethod: REFUSING to bind parsebreak to break
		emitted against 1 terms, rule now has 0
		
		⚠ THE GUARD WAS RIGHT AND IS DELIBERATELY UNTOUCHED. It protects
		every binding against a method emitted for a different shape, so
		weakening it to accommodate one convention would trade a real safety
		property for a counting convenience. The bind line was the thing
		telling an untruth, so the bind line is what changed.  */
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

/*******************************************************************************
    evictAction -- THE EVICTION, AND IT REFUSES RATHER THAN SUBSTITUTES.

    Tony's design, 2026-08-29. Step 3 of the earlier brief -- install the parse
    INTO gMethod -- is dead, killed by the parseAction finding: gMethod is read
    as THE ACTION by nine sites, one of which is a parse executor that would
    then call itself. The replacement is bear-trap 34's retirement clause.
    VACATE gMethod and install NOTHING. With the slot empty and isMethod
    retracted by the symmetric setter, runOP arm two stops claiming the rule,
    and a bare `QuotE()` in a generated body falls through to the isRule arm,
    into runRule, into builtinParsE. The new parse wins by having no
    competitor rather than by taking the old channel.

    ⚠ RELOCATE-THEN-NULL IS STRUCTURAL HERE, NOT REMEMBERED. The whole reason
    this is one extern rather than two statements in the driver is that the
    null must be unreachable until the relocation is VERIFIED. setParse already
    parks actionMethod for every rule it claims, so the relocation has usually
    happened -- but "usually" is what the brief said not to trust, and a rule
    that reached dual-flag by any road other than setParse is the burn case:
    null its gMethod and the action is gone with nothing holding a copy.

    ⚠ IT REPORTS A VALUE ON EVERY RULE, NOT A MESSAGE ON FAILURE (rule H4).
    An eviction pass that printed only its refusals would go quiet the day it
    stopped evicting anything, and quiet would read as success. Every rule
    prints its outcome by name, so the driver can count them and a zero is
    visible as a zero.

    The passthrough reads two function pointers and compares them. There is no
    kant spelling for that -- parseClassify above is the house precedent, and
    the comparison is all that sits inside the escape.
*******************************************************************************/
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

/*******************************************************************************
    frameProbe -- LOOK 1 of the handover brief. TEMPORARY, parseTrace gated.

    Question: at a bare sub-rule call, does runRule's `field` argument reach the
    INVOKING body's in-flight label? If it does, runRule can resolve the frame
    from its own arguments and no emitter change is owed. Prints what field is
    and every node reachable from it in one hop, with pointers, because the
    discriminator is whether four sub-calls yield four DIFFERENT nodes.

    Separate function, not lines inside runRule: runRule is a declared-field
    function and after parkOnMaster no new declarations go inside one.
    No percent-dash in the format string; that token closes passthrough.
*******************************************************************************/
extern "C" GroupItem *frameProbe(GroupItem *field, GroupItem *rule)
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
    genKant -- EMIT A RULE'S KANT PARSE BODY FROM ITS LIVE TERMS.

    THE POINT OF THE WHOLE RATCHET. A hand-written body is a MANUAL RUN OF THIS
    FUNCTION; this replaces the hand. Its oracle is byte-identity with the hand
    body that incant/bracedK already certified end to end (SEQ 63), so a
    byte-match inherits that certification rather than re-earning it -- identical
    bytes through a certified pipeline cannot behave differently.

    TEXT-FIRST, through the proven include chain (E0's route pricing). Tree
    synthesis is a later economy and is NOT what this does.

    ⚠ FROM THE LIVE TERMS, MEASURED, NOT BY EYE. It walks planRule's classified
    plan -- the same walk dumpSpellings makes -- so the indices and kinds come
    from the rule as it exists in the tree at this moment. Writing them by eye is
    exactly the staleness class the index-guard item exists to name.

    ⚠ EMITTED TO stderr, not stdout, and that is bear-trap #14: a run that ends
    via stop() exits hard with no flush, so buffered stdout vanishes and looks
    exactly like an emitter that never ran.
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
	/*  ⚠ THE FOLD GATE, AND IT IS A REPAIR, NOT A PRECAUTION. SEQ 71, found by
	the survey the same day the emitter landed. The join below is
	UNCONDITIONALLY " AND ", which is correct for a SEQ and WRONG FOR AN
	ALTERNATION -- an ALT means any option matches, and an AND chain means
	they all must. Three of the five rules the survey found emittable are
	fold=ALT (InvokeArg, ElsE, WardeD), so without this gate the emitter
	produced bodies that PARSE AND ANSWER WRONG for every one of them.
	
	⚠ NOTE WHAT DID NOT CATCH IT. kantLeaf refuses by KIND and covered every
	unknown TERM; nothing covered the wrong JOIN, because the join is not a
	term. A per-item guard does not see a whole-body property. That is the
	gap worth remembering, not the three rule names.
	
	REFUSING RATHER THAN EMITTING `OR`, deliberately: the template table's
	alternation row is dead for a second, independent reason -- an option
	attaches through a different frame (`into`, not `label`) -- so an OR
	chain would be the right operator on the wrong plumbing. One dead row,
	not half of one.  */
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
	
	/*  THE `ParsE` RECORD -- PJ-1, sited here rather than at the installer.
	============================================================
	THE BRIEF SAID "the site that installs rStuff.parseMethod". THAT SITE
	CANNOT DO IT, and the reason is worth keeping: parseRuleMethod (below)
	receives a METHOD NAME to dlsym-bind. The generated source text is not
	in its scope and is not even in its PROCESS -- genParse emits text in
	one run, a human pastes it into this file, it compiles into the binary,
	and a LATER run's `parseMethod=parseScaf` definition attribute binds the
	symbol. Two processes, days apart. So "one path, two effects" cannot
	join emitter and installer; they are not one path and cannot be made
	one.
	
	PJ-2 IS HONOURED MORE STRICTLY HERE, NOT LESS: the record is written by
	the emitter, which is the only thing that has the text, and
	parseRuleMethod stays the single source of truth for the BINDING and
	writes nothing at all. One writer per fact.
	
	WHY THE CAPTURE IS AT THE SINK AND NOT AT emitPlan's FOURTEEN `cerr`
	SITES. PJ-4 wants rule.ParsE byte-identical to the emitted text. Teeing
	at fourteen call sites is a DISCIPLINE -- every future cerr added to the
	emitter has to remember to tee, and the day one forgets, the record is
	silently short and still diffs clean against a target regenerated from
	it. Swapping the sink for the duration makes the record and the emission
	THE SAME BYTES BY CONSTRUCTION: there is no second stream to keep in
	step. That is CLAUDE.md's "prefer a structure that makes the failure
	unconstructable over a discipline that avoids it".
	
	⚠ THE CAPTURE IS AT THE `FILE *` LEVEL, AND THAT IS NOT A STYLE CHOICE.
	tok's `cerr` KEYWORD GENERATES `::fprintf(stderr,...)`, NOT `std::cerr`
	-- read the generated emitPlan in GroupRules.mm if you doubt it. A
	std::cerr.rdbuf() swap therefore captures NOTHING, silently: emission is
	perfect, the record is zero bytes, and the run exits 0. Measured
	2026-08-06 by writing exactly that bug. It is bear-trap #19's corollary
	in miniature -- the sink was reasoned about rather than grepped, and one
	grep of the codegen would have settled it in ten seconds. It is also the
	three-languages-share-the-tree hazard: `cerr` is a tok keyword and does
	not mean what the same word means in C++.
	
	REDIRECT-THEN-REPLAY, not a tee, so no custom stream machinery is
	needed. `stderr` on macOS is `__stderrp`, a modifiable FILE* lvalue, and
	`fprintf(stderr,...)` reads it per call -- so pointing it at a
	memstream for the duration catches every byte every callee writes,
	including ones added to the emitter years from now that nobody
	remembered to tee. The operator still sees every byte; it arrives after
	emitPlan returns instead of during. Rule-level interleaving is preserved
	because emitAll's `@@@ <rule>` / `DONE <rule>` markers come from the
	FIXTURE, around this call, not from inside it. planRule's refusals are
	deliberately OUTSIDE the swap and stay live and unbuffered.
	
	ONE STRAIGHT LINE, NO EARLY RETURN, between the swap and the restore --
	if that ever stops being true, stderr stays redirected and the operator
	loses the emitter's output with no symptom but silence. The `if (ms)`
	guard exists so a failed open_memstream degrades to "no record, normal
	output" rather than to a swallowed emitter.  */
	/*  PJ-7, ONE GATE. `INCANT_PARSE_RECORD` arms the whole record -- capture,
	attribute, and the optional file sink -- rather than arming a dump of an
	always-written attribute.
	
	unset     nothing happens at all: no redirect, no attribute, no file
	=1        capture + the ParsE attribute
	=<path>   capture + the ParsE attribute + a dump of it to <path>
	
	WHY THE ATTRIBUTE ITSELF IS GATED AND NOT JUST THE DUMP. An always-on
	attribute write changes the attribute LIST of every rule genParse
	touches, and this tree audits attribute lists -- pop.sh's census walks
	registries counting terms and loose entries, and `AUDIT` lines are
	baselined. A record that can move an audit is an instrument that can
	move a measurement, which is the 2026-08-02 defect (an instrument broke
	three POP targets by prepending ~290 lines with zero content
	divergence). With the gate closed the run is byte-identical to one
	built before any of this existed, and recordPop asserts exactly that on
	both streams.
	
	THE FILE SINK EARNS ITS KEEP AND SO IT STAYS, behind this same gate.
	It is the ONLY read path: a rule name in incant EXPRESSION POSITION
	INVOKES THE RULE rather than naming it -- `if Braced;` exits 139,
	measured -- so no ordinary incant statement can reach the attribute to
	diff it. The `showParse` command below is the director's window; the
	file is the POP's, because a byte-for-byte diff needs bytes in a file
	and not on a terminal.
	
	Both read pe->getText() and never the local -- the point is to prove
	what LANDED ON THE NODE, and dumping the local would pass even if
	addAttribute had silently done nothing.  */
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
		
		if (!gNoUnwrap)
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
		
		if (!gNoUnwrap)
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
					/*  TIER-3 BINDING, and THIS LINE IS THE TIER-3 SET.
					2026-08-11, docs/andOrRung.md section 6; seat ruled
					by Tony the same day.
					
					Section 6 splits the operator table three ways, and
					the third tier -- "evaluation-controlling
					constructs, NOT operators at all" -- cannot go
					through runOP, which resolves both operands before
					it dispatches. Binding a DIFFERENT method here is
					the whole promotion: the node is built identically
					([1]=op [2]=target [3]=arg), and only who walks it
					changes.
					
					⚠ DECIDED AT TREE BUILD, ON PURPOSE. The category
					of an operator is a parse-time fact, so it is paid
					once per expression rather than re-tested on every
					evaluation -- and runOP stays what section 6 calls
					it, the strict dispatcher and nothing else.
					
					⚠ THE SET IS CLOSED: `if`, AND/OR, iteration, then
					the door closes. The SYMBOL forms are deliberately
					NOT here -- `&&` is not even registered (setup:162
					has bare `'&'`, no operateMethod, the same state
					`'|'` was in before 2026-08-01) and `||` is strict.
					That asymmetry -- `OR` short-circuits, `||` does
					not, on one shared handler -- is FILED AND UNRULED,
					not overlooked. Widening tier 3 to the symbols is a
					ruling, and it costs an edit to this line.  */
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

/*******************************************************************************
    jitBindArgRT -- BIND A CALL'S ARGUMENT, AT RUN TIME. 2026-08-05.

    THE GAP: runAction's jitting gate returns on a self-call BEFORE the two lines
    below it that bind the argument, so an emitted self-call bound NOTHING. The
    callee's `argument` field kept whatever emit time left in it, and every fire
    at every depth saw the same node. Recursion with an argument -- displayForm's
    whole shape -- could not work.

    ⚠ THESE ARE runAction's OWN BINDING LINES, lifted verbatim rather than
    reimplemented, so the emitted call binds exactly as the interpreted call
    does and the two cannot drift. Same shared-implementation move as
    jitEmitIterStep's call to opPlusPlus and opDot's call to itself.

    ⚠ THE UNWRAP IS NOT OPTIONAL. The caller's operand may be an ITERATOR or a
    group node -- `displayForm(grup)` passes exactly that -- and what the callee
    must receive is the node it currently POINTS AT, which is a run-time fact.
    Baking the operand's emit-time target would pin the recursion to whatever
    node the compile happened to see. `if arg.isGROUP && !arg.isArgument
    arg = arg.group;` is the tree's existing unwrap idiom (ruleActions.rtn:419).
*******************************************************************************/
extern "C" GroupItem *jitBindArgRT(GroupItem *argument, GroupItem *field)
{
GroupItem 	*arg = argument;
GroupItem 	*ruleArg = 0;
	/*  THE CODED PATH'S HALF, both clauses in one motion. The exemption above
	was the wrapper's fingerprint -- "unwrap this, unless it is the argument"
	-- and it retires WITH the wrapper, not before it.  */
	
	if (!gNoUnwrap) {
	if ( isGROUP(arg->groupBody->flags.data) && !arg->groupBody->flags.isArgument )
	arg = arg->getGroup();
	if (( ruleArg = field->get("argument") ))  ruleArg->setGroup(arg);
	}
	else
	if (( ruleArg = field->get("argument") ))  ruleArg->groupBody = arg->groupBody;
	
	return arg;
}

/* jitBuildFunction  ONE FUNCTION, START TO FINISH. (S1 extraction, 2026-08-05,
   Tony's ruling "own function, sequential build".)

   THE SPLIT, and it is exactly the brief's list: this routine owns the function
   shell, the entry block, the result-slot alloca, the frame prologue, the body
   walk, the frame epilogue, the ret, the verifier and mem2reg. jitRunAction owns
   everything MODULE-scoped either side of it -- the engine, the LLVMContext, the
   Module, the IR text capture, the compile count, addIRModule, lookup and the
   call.

   ⚠ THIS IS A LIFT, NOT A MIGRATION, AND THE DISTINCTION IS THE BRIEF'S. The
   sixteen file-scope globals stay exactly where they are; JitContext is NOT
   adopted (see its note in jitContext.h). Sequential build never re-enters this
   routine, so nothing here needs save/restore -- and if a later change makes it
   re-enter, THAT is the moment the context object is owed, not before.

   WHY IT TAKES A GroupItem AND RETURNS AN int: a tok-extern signature carrying an
   llvm type poisons the generated header. So the two things it cannot name --
   the context and the module -- arrive through gJitCtx/gJitModule, and the two
   things it produces leave through gJitBuiltFn/gJitBuiltName.

   Returns 0 on success, and the SAME negative codes jitRunAction has always
   returned for the failures that now live in here -- -2 (nothing emitted, the
   gate never fired) and -5 (the verifier refused the IR) -- kept identical so no
   caller and no rung has to learn a new number. -6 means it was called with no
   context/module set up, which only a mis-sequenced caller can produce; -9 means
   two functions in one module wanted the same name, which the build loop's erase
   discipline should make unreachable. */
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

extern "C" GroupItem *jitEmitDiv(GroupItem *argument, GroupItem *target)
{
	 return jitEmitBinary(argument, target, jitSDiv); 
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
	//  PUBLISH THE NODE TOO. A consumer that wants a COUNT reads gJitResult; one
	//  that wants the GroupItem -- the print path, which must not guess a type --
	//  reads gJitResultNode. Two facts, two channels.
	gJitResultNode = res;
	
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

/* jitEmitFill  DS-4(b) -- THE DRAWING COMMAND, CALLABLE FROM COMPILED CODE.

   A CARBON COPY OF jitEmitTrace'S SHAPE, and deliberately so: that is the
   fallback-column convention, and it was verified against runOP's dispatch
   rather than adopted from a design -- `result = op->groupBody->gMethod(target)`
   is ONE ARGUMENT, VALUE-RETURNING, GroupItem*(GroupItem*). displayFillRT wears
   exactly that shape, which is why no new calling convention was needed for the
   first drawing method. FR section 4 predicted this route (the fallback column,
   not IR emission) on the grounds that a drawing method needs to be CALLABLE
   from emitted code rather than EMITTABLE as IR. It was right.

   NO STRUCT OFFSETS ARE BAKED, for jitEmitTrace's reason: reaching the frame or
   the style through GEP arithmetic over GroupItem -> groupBody would hard-code a
   layout that bear-trap #10 moves, in emitted code no compiler checks. The
   callee recomputes everything each build. One call, layout free.

   The call is left untagged so LLVM cannot DCE a callee it cannot see into. */
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

/*  BATCH ONE OF THE SWEEP, 2026-08-17 -- the four remaining comparisons, which
    completes the ordered half of the jitCmp family beside jitEmitGT above.

    All four are the same three lines, which is the tempo claim being tested and
    is now measured over six ops rather than argued. Nothing here decides
    anything: the selector is the whole content of each shim, which is the point
    of moving it from a gate parameter to a fact the op carries.

    ⚠ DO NOT ADD A COUNTER INCREMENT TO ANY OF THESE. The slot count lives at the
    fork in runOP precisely so a shim author cannot forget it. See
    docs/jitSlotMigration.md.  */
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
	/*  ⚠ A BARE CONDITION OPERAND MUST BE MATERIALIZED. `if isMethod` is false
	for a bare read -- a field, or a GroupField accessor like noPrinT -- so
	this else branch made NO CALL and the condition emitted nothing. The
	enclosing compare then branched on whatever was last in flight, which is
	finding #3 exactly: `if noPrinT` reading the iterator's liveness. The
	condition was never wrong; it was reading a value nobody had produced.
	THE CONDITION IS ONE OF THREE VALUE-CONSUMING POSITIONS with this hole
	(if / while / do) and they take the identical fix. The principle, Clay's:
	EVERY POSITION THAT CONSUMES A VALUE INVOKES THE PRIMITIVE WHEN ITS
	OPERAND IS BARE. Assignment RHS needs nothing -- opAssign is an operator,
	so runOP's seed gate already covers it.  */
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
	jitStoreResult();
	jitIfEnd();
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

/* jitEmitGT  OP TWO of the slot migration, and a jitCmp deliberately rather than
   a second arithmetic. The pathfinder proved the slot on the family whose gate
   already worked; the selector population being retired has THREE families
   (jitOp, jitCmp, jitUnary), so the second specimen is chosen to exercise a
   different one -- a binary-shaped assumption in the slot signature would hide
   behind a second jitOp and surface at op nine instead of op two.

   ⚠ THE FINDING IS THAT THERE WAS NO SUCH ASSUMPTION. jitEmitCompare has the
   same shape as jitEmitBinary -- (argument,target,op) returning target -- even
   though its RESULT type differs (an i1 rather than an operand-typed value).
   The slot's two-argument signature therefore spans jitOp and jitCmp with
   nothing special-cased, and this shim is the same three lines as jitEmitMul.

   `>` was picked from five structurally identical comparison gates because
   incant/jitJR already contains `if jrN > 1`, so migrating it converts an
   existing rung into a free 1 -> 2 cross-check on the slot count. */
extern "C" GroupItem *jitEmitGT(GroupItem *argument, GroupItem *target)
{
	 return jitEmitCompare(argument, target, jitGT); 
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

extern "C" GroupItem *jitEmitLE(GroupItem *argument, GroupItem *target)
{
	 return jitEmitCompare(argument, target, jitLE); 
}

extern "C" GroupItem *jitEmitLT(GroupItem *argument, GroupItem *target)
{
	 return jitEmitCompare(argument, target, jitLT); 
}

/* jitEmitMul  THE STEP-2 PATHFINDER. The emitter for `*`, installed on the op
   node's gJitEmitter slot by `jitEmitter=jitEmitMul` in the Operators registry,
   and called by runOP's fork instead of the `if jitting` gate inside opMultiply.

   ⚠ IT IS NAMED jitEmitMul AND NOT jitMul, AND THAT IS NOT A PREFERENCE.
   `jitMul` is already an unscoped enum constant — enum jitOp { jitAdd, jitSub,
   jitMul, jitSDiv } in jitContext.h — so a function of that name is a
   redeclaration in the same scope. Same class as the jitMethod/jitEmitter
   collision Clay ruled on, resolved the same way: keep the jitEmit* stem so the
   whole mechanism greps under one name.

   The body is deliberately ONE LINE ONTO jitEmitBinary. This shim exists to move
   the SELECTOR from a parameter passed at the gate to a fact baked into the
   function the op carries — which is the entire point of the slot model, and why
   the selector parameter can eventually retire. It adds no emission logic of its
   own and must not grow any: a shim that starts deciding things is a second home
   for the op's identity.

   Passthrough because jitMul is a jitContext.h enum and tok does not see it. */
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

/* jitEmitReturn  `return`, EMITTED. Item 2, Tony's ruling 2026-08-05.

   THE GAP IT CLOSES: return called jitDegrade. That is why EVERY green rung in
   the ladder asserts a FIELD's value after the action and never a RETURNED one,
   and why CLAIM KANT-8's jitted parity was not merely unanswered but NOT YET
   ASKABLE. This makes it askable.

   ⚠ E3 -- A BARE `return;` IS CORRECT BY CONSTRUCTION AND NOT BY A SPECIAL CASE,
   which is the nicest thing about this emitter. The interpreter's convention
   (Tony, 2026-07-31, and the header on aCTionBlocK states it): a bare return
   yields THE PRIOR STATEMENT'S VALUE, because an action's value is the value of
   the last executed statement and `return` only means STOP. Under jitting every
   statement has already called jitStoreResult, so THE SLOT ALREADY HOLDS exactly
   that value -- and jitStoreResult returns early on a null gJitResult. So a bare
   return stores nothing, keeps the prior value, and matches the ruling with no
   test for bareness anywhere in this function. `return expr;` differs only in
   that gJitResult is non-null when we arrive.

   ⚠ E1 -- THE UNREACHABLE CONTINUATION BLOCK IS jitEmitContinue's IDIOM, LIFTED
   RATHER THAN REINVENTED (its header argues the case in full). LLVM requires one
   terminator per block and forbids code after it, so after the branch the
   builder parks in a fresh block nothing branches to. It is dead by construction
   and the optimiser drops it. This matters more for return than for continue,
   because aCTionBlocK's `if jitting continue;` means the walk KEEPS EMITTING the
   statements after a return -- correctly, since at emit time they are reachable
   text even when at run time they are not.

   ⚠⚠ E2 -- BUILT 2026-08-09. WAS: "a return inside an inlined body is refused,
   loudly, deferred with Tony's sanction." The diagnosis that stood behind that
   refusal was right and is worth keeping, because it IS the fix's specification:
   an ordinary (non-self-test) callee INLINES into the enclosing function, so its
   `return` must terminate the INLINED REGION and not the enclosing function --
   branching to gJitEpilogueBB there would return from the caller, which is a
   wrong answer wearing valid IR. gJitInlining is non-empty exactly while a callee
   is being inlined, and empty while jitBuildFunction walks the function's own
   action (it calls processCode/jitExecBlock directly, not through runAction).

   THE FIX IS THAT AN INLINED REGION GETS AN EPILOGUE OF ITS OWN -- one
   JitInlineFrame per inline, bracketed by jitInlinePush/Pop, whose exit block is
   this return's branch target. See JitInlineFrame in jitContext.h for why the
   block is created unparented and inserted on first use (an H7 obligation: a
   return-free callee must emit byte-identical IR), and why the value needs no phi.

   ⚠ WHY IT WAS SURVIVABLE AT ALL, WHICH IS THE PART TO REMEMBER: a TAIL return
   needs no branch, so falling through was accidentally equivalent and every
   fixture in the fleet was tail-shaped. `incant/jitXe2` is the mid-body case --
   jitted 222/999 against an interpreted 111/0, at degrade count 2 either way.
   THE DEGRADE COUNTER COULD NOT TELL THE TWO POSITIONS APART, which is the
   worked example behind CLAUDE.md's "a degrade line asserts that a fallback
   OCCURRED, never that it was SOUND."

   ⚠ TWO RETURN VALUES NOW, AND THE RETIRED THIRD IS RECORDED RATHER THAN
   DELETED. The value 0 meant "E2, inside an inlined body, unbuilt" and E2 is
   built, so nothing produces it and the caller's arm for it would be an
   assertion nothing can fire. It was split out from -1 in the first place
   because one code for both "deferred with sanction" and "something is wrong"
   mis-reported an ordering bug as E2 -- one-channel-one-meaning, caught early,
   and the split did its job for the three days it was needed.
       1  emitted
      -1  REFUSED -- no builder, no epilogue block, or inlining with no frame:
          in every case a mis-sequenced caller, NOT a language gap  */
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

/* jitEmitShortCircuit  TIER 3 UNDER THE JIT (2026-08-11, docs/andOrRung.md
   section 3 part 2; ruling SEQ 32).

   ⚠ WHY THIS EXISTS AT ALL, measured the same day and worth keeping: promoting
   AND/OR to an intercepting action fixed the `AND`-under-jit 139 and REPLACED IT
   WITH THE SILENT WRONG ANSWER. With no emitter, runShortCircuit ran at EMIT
   time and folded its value -- jitXand2 and jitXor both wanted 1 on fire 2 and
   returned 0, at DEGRADE COUNT 0. Trading a crash for section 2's "dangerous
   one" is not progress, and this function is what makes the promotion honest.

   ⚠ WHAT THIS EMITTER CAN AND CANNOT SEE, stated precisely because the
   agreement claim depends on it. An arm that emits leaves an UNBOXED i32 in
   flight, and `icmp ne 0` on it IS truthOf's row 2 exactly -- so on the
   numeric row the two engines agree BY CONSTRUCTION, not by a careful copy.
   Rows 1, 3 and 4 are NOT representable from an unboxed integer: a null, a
   present-but-non-numeric node and a text node all arrive here as "no value in
   flight", which is one symptom for three causes. The emitter therefore does
   not GUESS among them -- it REFUSES (jitDegrade) and lets the interpreted arm,
   which can still see the node, answer. A refused emit falls back to
   interpretation, so this is one answer and a refusal to bake it, not two
   answers.

   ⚠ SO THE DEGRADE LINE HERE MEANS "NOT EMITTED", NEVER "SOUND". That is the
   standing rule about degrade lines and it applies to this one: whether the
   fallback is safe is a per-construct question, and for an AND/OR inside a
   multi-fire jitted action it is NOT -- an emit-time fold returns fire 1's
   answer forever. Rungs assert the VALUES on both fires; they must not accept
   the counter as the proof. */
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

/*******************************************************************************
    jitEmitter — binds an op's JIT emitter, step 2 of the jit separation.

    Modelled on ruleMethod directly above, with two deliberate differences.

    ⚠ IT SETS NO FLAG. ruleMethod sets isMethod or isOperator because those say
    how the INTERPRETER dispatches the op. An emitter must not disturb that: the
    op keeps its interpreter binding and gains an emitter alongside it. Presence
    of the slot is the only signal, which is what lets runOP's fork be a null
    test and nothing more.

    ⚠ IT DOES NOT FORK ON THE ATTRIBUTE TAG. ruleMethod reads input.tag == 'r' to
    tell ruleMethod= from operateMethod=, which is why a third spelling could not
    simply be added there — jitEmitter starts with 'j' and would silently take
    the operateMethod branch, installing an emitter into the operat slot and
    destroying the interpreter binding. A separate binder is the fix.

    The binary/unary split is interpreter dispatch anatomy and the jit does not
    inherit it, so one binder serves both families.
*******************************************************************************/
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

/* jitFlushTransient  THE TRANSIENT-STATE FLUSH, ONE MECHANISM, TWO CALL SITES.
   (S3 rider R1, Tony 2026-08-05.)

   Everything an emitted function leaves lying about that is scoped to THAT
   function and must not be visible while building the next one: the jitData
   hung on nodes, the frame slots, the values in flight, the block stacks, the
   inline stack.

   ⚠ WHY IT IS A FUNCTION AND NOT TWO COPIES OF FIVE LINES. It runs between
   FUNCTIONS (jitBuildFunction's own head) and on DISCARD (jitDiscardPartial),
   and those two had every chance to drift apart -- an llvm::Value is valid only
   inside the function that defines it, so a rebuild reading a stale jitData is
   the SSA-staleness class jitEmitSelfCall's header already measured: "the second
   pass compares an i1 against an i32 and LLVM asserts". A discard leaves exactly
   that debris, and an ERASED function makes it worse than stale -- it is a
   pointer into freed IR.

   gJitSeeded's own header states the obligation between COMPILES; this applies
   the identical rule between FUNCTIONS, which is the only thing S3 changed about
   it. It does NOT touch gJitBuilder or gJitResultSlot: jitBuildFunction sets
   those for itself immediately after calling this, and the discard path nulls
   them separately because there the function they point into is gone. */
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

/*  jitInlinePop  CLOSE THE INLINED REGION -- and, if any return branched out of
    it, land the builder on the region's own exit with the callee's value in hand.

    ⚠ THE `used` ARM IS THE ONLY BEHAVIOUR CHANGE E2 MAKES TO AN EXISTING GREEN
    PATH, AND IT IS GATED SO THERE IS NO CHANGE AT ALL WHEN NO RETURN FIRED.
    A callee without a return leaves `used` false: the unparented block is deleted,
    the builder is untouched, and the IR is what it was yesterday.

    ⚠ THE LOAD IS NOT TIDINESS -- IT IS THE VALUE CHANNEL BECOMING EXPLICIT.
    Until now an inlined callee's value reached its caller by ACCIDENT: the return
    degraded before jitEmitReturn's `gJitResult = nullptr`, so the last statement's
    value was left dangling in flight and the caller picked it up. That is
    one-channel-one-meaning in its purest form -- gJitResult meaning both "the value
    in flight" and "the callee's answer" -- and it is exactly why a TAIL return
    looked fine while a mid-body one did not. Now every return stores to the slot
    and branches; the merge point loads it once, deliberately.

    ⚠⚠ AND IT TAKES `resultNode` BECAUSE gJitResult IS NOT THE CHANNEL THE CALLER
    ACTUALLY READS -- measured, from the IR, after assuming otherwise and being
    wrong. An enclosing assignment reads its operand's `jitData->jitValue`
    (jitEmitAssign), and runAction's operand IS the node processAction returned.
    Setting only gJitResult produced a MERGE THAT WAS CORRECT AND IGNORED: the
    dump showed `%inlineRet = load %result` sitting unused one line above
    `store %unbox3` -- the last statement's value stored on BOTH paths, and a
    dominance violation as the early-return arm carried it out of its block.
    So the merged value is STAMPED, the same way jitEmitRem stamps its result
    node, and registered in gJitSeeded so it is cleared with every other seed at
    the end of the build.  */
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

/* jitNodeInFlight  is there a GroupItem result waiting? The tok-level test for
   the node channel, so the print walk can ask without a passthrough. */
extern "C" int jitNodeInFlight()
{
	 return gJitResultNode ? 1 : 0; 
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

/* jitPrintList  A MULTI-PART PRINT OPERAND, CLASSIFIED BY CONSTANCY.
   Tony's ruling via Clay, 2026-08-05, and the ruling is what makes the hard half
   evaporate.

   A print item's ExpressioN can be a LIST -- `print "P value =" pVal:;` carries
   ONE item whose expression holds two parts. Measured:
       part 0  tag=pVal   text=[7]           literal=0   COMPUTED
       part 1  tag=Token  text=[P value =]   literal=1   CONSTANT
   One of each, which is why the constancy split closes this case with no new
   evaluation machinery.

   ⚠ A CONSTANT NEEDS NO EVALUATION AND CANNOT CATCH THE STALE-FRAME DISEASE.
   That disease is why the value entry exists: a local's live value sits in a
   frame slot until the epilogue, so handing the chain a field POINTER reads
   storage nothing has written. A string literal is IMMUTABLE -- baked at emit
   time, identical at every fire -- so the pointer is safe, and the part goes
   through appendGroup's existing entry exactly as the interpreted walk sends it.
   The chain's shape rules; nothing new is added to it.

   ⚠ WALKED WITH prior(), NOT next(), and that is appendGroup's own order rather
   than a preference: its non-reversePrint arm walks `prior`, because the list is
   built in reverse. Measured here too -- pVal is part 0 and the literal is part
   1, while the source reads literal-then-value.

   COMPUTED STRINGS STAY BEHIND THE COUNTER. A part that is neither a constant
   nor a scalar read is out of the current phase scope (appendGroupValue takes an
   i32), so it degrades rather than emitting a wrong kind -- counted, not silent,
   per the refusal discipline that has already paid twice today. */
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

extern "C" void jitRestoreFrameRT(GroupItem *field)
{
	::restoreLocalFields(field);
}

/* jitRunAction  the generic compile driver — the JIT analog of generateCode. Owns
   the ENGINE, the LLVMContext and the Module; jitBuildFunction above owns each
   function inside them. Builds the driver's function, captures the module IR,
   ORC-compiles, looks the driver up BY NAME, and calls it. Returns the native
   result.

   ⚠ THE SPLIT IS S1 AND IT IS DELIBERATELY BEHAVIOUR-NEUTRAL. Nothing here does
   anything it did not do on 2026-08-05 before the extraction, in a different
   order or otherwise -- which is why its POP is "every baseline byte-identical"
   and why anything that moves is a defect rather than an improvement. */
extern "C" int jitRunAction(GroupItem *action)
{
	
	printf("=== jitRunAction: entering on %s ===\n", action->groupBody->tag);
	fflush(stdout);
	/*  PJ-8, THE JIT HALF OF THE LIFECYCLE. Cleared on ENTRY, written at the
	capture site near the foot. The gap between them is the whole point:
	a compile that REFUSES (-1..-5) never reaches the capture, so it leaves
	NO record rather than the previous compile's -- which is the exact
	staleness the ruling precludes. Clearing at the write instead would be
	a no-op, and detecting staleness with a check afterwards is what the
	ruling replaces: STALENESS IS PRECLUDED BY LIFECYCLE, NOT DETECTED.
	setText("") and not clear(): a field with NO data returns its TAG from
	getText(), so a clear()ed record would read back as the string "JiT"
	and every non-empty test in the fleet would pass on it.  */
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

/*******************************************************************************
    jitSaveFrameRT / jitRestoreFrameRT -- THE FRAME BRACKET, AT RUN TIME.

    ⚠ MEASUREMENT, NOT ARCHITECTURE. This is the experiment that asks whether the
    depth->=2 displayForm divergence is the missing frame bracket. It INVERTS
    docs/jit.md §0, which sentences saveLocalFields to be DELETED rather than
    depended on, so it is Tony's ruling whether this shape stays. Do not read a
    green run here as the architecture having been chosen.

    THE GAP, and it is the SAME SEAM jitBindArgRT closed one increment earlier:
    runAction's jitting gate returns at :705-707, ABOVE its own
    `if field.recursive saveLocalFields(field)` at :713 and the matching restore
    at :725. So an emitted self-call runs with NO frame bracket at all.
    (Those three were written as :670/:677/:689 -- b7a01c1 line numbers, stale
    the moment this very comment block was inserted above runAction and shifted
    it down ~36 lines. Corrected 2026-08-05 as S3's ride-along.)

    WHY THAT IS INVISIBLE UNTIL displayForm: the JIT's scalar locals live in
    ALLOCAS inside gJitCurrentFn, and allocas are per-activation for free -- which
    is why J-R and jitJRL are green with no bracket. Node-resident state is the
    other class: an ITERATOR's cursor lives in a baked GroupItem shared by every
    activation, so a recursive call walks the caller's cursor. saveLocalFields'
    own comment names exactly this case -- "no local carrying a list could survive
    recursion. Iterators were just the first to notice."

    ⚠ THE `field.recursive` GATE IS CARRIED, NOT REIMPLEMENTED, so the emitted
    path cannot drift from the interpreted one. The flag is set at PARSE time by
    identity (ruleActions.rtn:1310), so it is already live on the callee node.
*******************************************************************************/
/*  ⚠ THE GATE IS GONE, 2026-08-10, SEQ 27 rung B. The comment above says the
    gate is CARRIED so the emitted path cannot drift from the interpreted one,
    and that reasoning still holds -- both paths are now ungated together, so
    they still cannot drift. What changed is that the gate itself was the
    defect. It is set at parse time BY IDENTITY, so mutual recursion never sets
    it at all, and it is CLEARED at run time by restoreLocalFields, so whether
    the bracket runs depends on invocation history. Unconditional kills both.
    The prerequisite was rung A: while the return seam handed back the local's
    own node, ungating the sweep blanked every returned local rather than only
    the self-mentioning ones. With the value captured before the sweep, that
    coupling is gone.  */
extern "C" void jitSaveFrameRT(GroupItem *field)
{
	::saveLocalFields(field);
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
/* jitScBegin  opens the short-circuit diamond. Consumes the LEFT arm's value
   from gJitResult, allocates the merge slot in the ENTRY block (so it is a
   promotable alloca and mem2reg can retire it), pre-stores the short-circuit
   answer, and branches so that the RIGHT arm's block is entered only on the
   non-deciding value. Leaves insertion in scRhs so the right-arm walk emits
   there.

   ⚠ THE ALLOCA GOES IN THE ENTRY BLOCK, NOT HERE. An alloca in a conditionally
   entered block is not promotable, mem2reg leaves it as memory, and the phi we
   are refusing to write by hand never appears -- the IR stays correct but the
   whole never-write-a-phi argument silently stops applying. Entry-block
   placement is what makes "mem2reg inserts the phi itself" true rather than
   hoped for.

   isAND is passed rather than re-derived from the op, so the two callers of the
   contract (this and runShortCircuit's interpreted arm) cannot disagree about
   which word they are emitting. */
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

/* jitScEnd  closes the diamond. Stores the RIGHT arm's truth into the slot,
   branches to the merge, and leaves the loaded result in flight as the value of
   the whole conjunction.

   ⚠ A RIGHT ARM THAT EMITTED NOTHING IS A REFUSAL, NOT A ZERO. gJitResult null
   here means the sub-walk produced no value -- and storing a constant would be
   substituting an answer the emitter does not have, which is exactly the move
   jitPrintItem was corrected for on 2026-08-05. The slot keeps its pre-stored
   short-circuit answer and jitDegrade announces it, so the run fails a rung
   instead of returning a plausible number. */
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

/*******************************************************************************
    kantDoor — THE THREE DUTIES, lifted out of aCTionDefinE so the hunk there
    is three lines and the revert is one. 2026-08-12, the full-monty rung.

        mint kp<Tag>  ·  hang the CodE on it  ·  rStuff.parseMethod = parseViaKant

    ⚠ TWO THINGS THE ORDER'S SKELETON DOES NOT COVER, both measured, both
    load-bearing. Read these before editing.

    (1) THE isCoded ARM CANNOT SIT UNDER `!isMethod`, WHICH IS WHERE THE
        dlsym LINE LIVES. Braced already carries isMethod from its ORIGINAL
        definition in incant/grammar (dlsym found aCTionBraced then), so on the
        parseCode re-definition that guard is FALSE and the whole block is
        skipped. That is exactly the M1b measurement of 2026-08-12 -- code{} on
        a Grokking rule with a C++ action is silently inert -- and the mechanism
        is this guard. So the caller tests isCoded ABOVE `!isMethod`, and
        `!isMethod` stays on the dlsym arm only, unchanged for everyone else.

    (2) "THE METHOD SLOT STAYS EMPTY" REQUIRES AN ACTIVE CLEAR, NOT MERELY NOT
        BINDING. Braced arrives here with gMethod ALREADY set to aCTionBraced.
        Left alone, :1230's fireLabelMethod fires it AND actK fires it -- the
        double fire the order says is prevented by construction. So the door
        clears gMethod / isMethod / immediateACTION, which is what actually
        starves :1230.

    ⚠ AND THE SCOPING IS A REAL CONDITIONAL, NOT AN ORDERING CONSEQUENCE. The
    order says scoping falls out of ordering with no new conditionals. That
    holds for the C++ population (aCTionIF, aCTionFOR ... are not coded, so
    they take the else-arm untouched) but NOT for the CODED NON-GRAMMAR
    population, which the 2026-08-12 census measured at five: list x2,
    JSONfield, JSONarray, DelimOver -- and two of those are in incant/utilities,
    which every fixture preamble includes. A bare `if isCoded` would take all
    five through the kant door and break jsonTest. The caller therefore keeps
    the RATIFIED test -- registry.isRule, true only for Grokking
    (GroupMain.twk:16, the only live site) -- exactly as specced on 08-12.

    BOUNDS: the highest term position the body names, against the live term
    count. Scanned from the CodE text here because there is no parseTerms
    declaration to read -- Tony struck it. Note this is the EARLIER of two
    checks, not the only one: litK/parseRK already refuse loudly at call time
    naming the position, and that one cannot be bypassed. This one fails at
    DEFINITION, before any parse happens.
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
/*******************************************************************************
    kantLeaf -- ONE PLAN KIND, ONE KANT SPELLING. SEQ 67 part B / 66-r1 phase 2.

    The kant twin of emitLeaf, and deliberately much smaller: emitLeaf spells
    every kind for two sinks in C++, this spells the kinds the kant shim
    vocabulary actually HAS. Everything else returns null, which the caller
    turns into a loud refusal.

    ⚠ REFUSING IS THE FEATURE. The shim table in docs/kantParseTemplates.md has
    FOUR live rows -- literal (litK), captured-literal (litToK), rule-reference
    (parseRK) and optional-reference (optRK) -- and the dead ones are repetition,
    alternation, and the optional wrapping anything but a CALL. An emitter that
    GUESSED at those would produce a body that parses and answers wrong, which is
    this project's worst failure shape. It names the kind it could not spell
    instead.

    ⚠ LITTO WAS THE THIRD DEAD ROW UNTIL 2026-08-31 and its arrival is the
    discharge of incant/fixits/kantGenPath. Read litToK's own header for the one
    thing that was NOT obvious about it: the slot has two derivations, and the
    citizen's subject rule uses the one the naive reading misses.
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

/*******************************************************************************
    labelMinters -- HOW MANY OF THIS RULE'S SUB-TERMS WILL MINT A LABEL.
*******************************************************************************/
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
    litK / parseRK — THE KANT-CALLABLE SHIMS. SEQ 54, step 2.

    ⚠ BOTH TAKE A TERM POSITION -- ONE ARGUMENT -- AND THE :scope MULTI-ARG
    IDIOM PRICED IN docs/kantShims.md §4 IS NOT NEEDED AT ALL. Measurements,
    not concessions:

      A KANT BODY CANNOT INDEX A RULE'S TERMS. `argument[1]` in an action body
      does not reach term 1; measured 2026-08-11, the shim received a node
      whose tag was the COMMAND NAME and dutifully tried to match the literal
      "litK". Bear-trap #26's family -- a plausible string where a node was
      wanted. So the position is passed as a number and the FRAME does the
      indexing, in C++, where `rule[1]` is `rule->get(1)` and works.
      ⚠ This made the convention CLEANER rather than costing something: the
      body now names a term BY POSITION and holds no node at all.

      lit(field,str) uses `field` ONLY for its trace line -- the match runs off
      `str`. And for a noLabel literal term the TERM'S OWN TAG *IS* the literal:
      the 2026-08-05 narration reads `lit " [ " at term [`. So litK derives the
      literal from the same place the C++ emitter bakes it from, and a second
      argument would only be a chance for the two to disagree.

      parseR(term,into)'s `into` is the label to attach under, which door (a)
      makes FRAME-OWNED. The body says what to parse; the frame says where it
      goes.

    So the convention this establishes is stronger than "one argument fits":
    A KANT BODY NAMES A TERM AND NOTHING ELSE. Everything else -- position,
    label, invariant -- belongs to the frame, which is SEQ 54 item 3's standing
    convention expressed as a signature.

    ⚠ RETURN CONTRACT IS truthOf's, deliberately: non-null for success, null
    for failure, so an AND chain short-circuits on exactly the same contract
    both engines already share. No new notion of truth enters with the parser.
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
    litToK -- THE LABELLED LITERAL'S KANT SHIM. litK's twin, and the rung the
    kant generator stopped at (incant/fixits/kantGenPath, minted 2026-08-24).

    ⚠ TWO DERIVATIONS OF THE SLOT, NOT ONE, AND THAT IS THE FINDING THE CITIZEN
    ASKED FOR. The candidate was graded BEST GUESS on exactly one open judgement
    -- "is `term.tag` always the right slot" -- and the naive answer, yes-always,
    is WRONG on the very rule the citizen drives:

      at >= 1   a TERM position.  slot is `term.tag`   (planTerm, the `slot`
                mint beside the LITTO node)
      at == 0   THE ZERO-MEANS-SELF MARKER. There is no term -- `rule[0]` names
                nothing -- and the slot is `rule.tag`, the literal `rule.text`
                (planRule's `if literal` block)

    `break`, the citizen's subject, plans at 0. So a one-argument litToK that
    resolved through `gKantRule->get(n)` unconditionally would have refused the
    subject while looking correct on every term-position specimen.

    IT STILL TAKES ONE ARGUMENT, which is the convention litK's header states as
    a law -- A KANT BODY NAMES A TERM AND NOTHING ELSE -- because both slots are
    derivable from the index once the FRAME is consulted, and the frame already
    holds the rule. Zero-means-self is the landed convention of 2026-08-24
    (rule-ladder rung two), stated at the emit site in emitPlan; this is its
    first reader on the kant side.

    `into` is `gKantLabel`, read exactly as parseRK and optRK read it -- the
    body says what to match, the frame says where it goes.

    ⚠ THE LITERAL FOR A TERM POSITION IS `term.tag`, COPIED FROM litK RATHER
    THAN FROM emitLeaf, DELIBERATELY. emitLeaf bakes `node.text`, which planTerm
    sets to `term.text` when the term carries string data and to `term.tag` when
    it does not. litK has always used `term.tag` for both. That divergence is
    litK's, it predates this function, and making the twin disagree with its
    sibling would hide it rather than fix it. Captured as a row in docs/fixIts.md
    the day this landed; it is NOT repaired here.
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
int 	priorLimit = ::limitWriteGuard(target);
	if ( GroupControl::groupController->groupRules->jitting )
		{
		 return jitEmitAssign(argument, target); 
		}
	if ( argument )
		if ( argument->groupBody->flags.byRef )
			target->setGroup(argument);
		else	target->setContent(argument);
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
	Rule action for the $$ debug marker. Spelled ** until 2026-09-01, when
    Tony freed that token so ** can compose as a double unwrap without being
    claimed by this marker first.
***************************************************************************/
extern "C" GroupItem *opDebug(GroupItem *result)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*field = 0;
	field = ruler->currentMETHOD;
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
		 ::jitDegrade("unary * under jit -- no emitter yet",result); 
		}
	if ( isGROUP(result->groupBody->flags.data) )
		return result->getGroup();
	::fprintf(stderr,"ERROR unary * on %s -- it holds no group\n",result->groupBody->tag);
	return 0;
}

// unwraps to a FIXPOINT, not twice; total on a non-group   Instruct.opDerefAll
extern "C" GroupItem *opDerefAll(GroupItem *result)
{
int 	depth = 0;
	if ( GroupControl::groupController->groupRules->jitting )
		{
		 ::jitDegrade("unary ** under jit -- no emitter yet",result); 
		}
	while ( isGROUP(result->groupBody->flags.data) )
		{
		if ( depth >= 64 )
			{
			::fprintf(stderr,"ERROR unary ** on %s -- 64 levels, cycle suspected\n",result->groupBody->tag);
			return 0;
			}
		result = result->getGroup();
		depth++;
		}
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
					/*  hasTraitS -- the CONNECTIVE discriminant. hasAttributeS
					(case 7) answers "is this node marked up", and setParse
					hangs builtinParsE and builtinActoR on every rule it
					touches, so every walked rule reads TRUE there and an
					alternation is emitted as a conjunction. hasTraits counts
					only attributes that are NOT noPrint-class, so it answers
					"does this rule conjoin traits". Written to case 7's shape
					deliberately -- same product.count = 1, same else
					product = 0 -- so a gate swapping one for the other moves
					the QUESTION and nothing else. Write halves: addAttribute
					and updateContentFlags.  */
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
				case 406:
					if ( target->groupBody->flags.actionType )
						product->setCount(1);
					/*  binTypE -- ANY container kind, not just bin. binType is an
					ENUM and not a bitfield: isBIN 1, isCLASS 2, isLIST 3,
					isREGISTRY 4 (GroupBody.h:65-78), so a nonzero test answers
					"is this a container of some sort" in one read. That is
					deliberately WIDER than the isBIN || isREGISTRY pair
					setParse tests, and wider in the right direction -- a CLASS
					and a LIST are no more a rule than a bin is.  */
					break;
				case 407:
					if ( target->groupBody->flags.binType )
						product->setCount(1);
					/*  isActioN -- the PARSER-READ half of the actionType enum.
					actionTypE (406) is nonzero for isAction OR isCoded and so
					cannot witness the transition between them; parseRule tests
					isAction SPECIFICALLY. This makes the exact condition the
					parser reads assertable from incant, which is what lets a
					fixture demonstrate the isCoded -> isAction transition
					rather than assume it. See incant/enumT.  */
					break;
				case 408:
					if ( isAction(target->groupBody->flags.actionType) )
						product->setCount(1);
					/*  hasNewParse READ half. The write half is opSetFlag case 41.
					Both halves land together on purpose: a flag a fixture can
					set and cannot read is a gate nobody can assert, which is
					rule H4's absence-versus-value in flag form.  */
					break;
				case 41:
					if ( target->groupBody->flags.hasNewParse )
						product->setCount(1);
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
		GroupControl::groupController->groupRules->lastREF->groupBody->gGroup = iterator;
		GroupControl::groupController->groupRules->lastREF->groupBody->flags.data = 6;
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
			GroupControl::groupController->groupRules->lastREF->groupBody->gGroup = iterator;
			GroupControl::groupController->groupRules->lastREF->groupBody->flags.data = 6;
			iterator->groupBody->flags.isInitialized = 1;
			result->setGroup(iterator);
			}
		else {
			result->setGroup((GroupItem*)0);
			result = 0;
			}
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
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*flagDef = 0;
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
				::fprintf(stderr,"opSetFlag: groupField %s has no case yet -- gCount %s\n",argument->groupBody->tag,::toStringFromInt(flagDef->groupBody->gCount));
			}
	else	::fprintf(stderr,"opSetFlag: missing operand\n");
	return target;
}

/***************************************************************************
	Rule action for the := set group operator. It stashes argument as isGROUP
    in target without changing its parent or affiliation
***************************************************************************/
extern "C" GroupItem *opSetGroup(GroupItem *argument, GroupItem *target)
{
	if ( argument )
		{
		target->groupBody->gGroup = argument;
		target->groupBody->flags.data = 6;
		target->groupBody->flags.isInitialized = 1;
		}
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
	GroupControl::groupController->groupRules->useDefaultSpace = 1;
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

/*******************************************************************************
    optRK — THE OPTIONAL RULE-REFERENCE. Vocabulary item 3, rung one of the OPT
    charter (decision (a), ruled by Tony 2026-08-13 off SEQ 72's stamped table:
    OPT opens 5 of the 16 L/R rules, the measured maximum).

    THE CONTRACT, and it is parseRK's with ONE leg's answer flipped:
        attempt term N's parse;
        on success  -> proceed as any term       (trueResult)
        on failure  -> RESTORE THE CURSOR and    (trueResult)
                       still answer success
    Cursor discipline identical, only the verdict changes. That is why this is
    one small function beside parseRK and not a new mechanism: it names a term
    BY POSITION, holds no node, and leaves position/label/invariant to the
    frame — SEQ 54/55's standing convention, unchanged.

    ⚠ WHY A SEPARATE SHIM PER INNER KIND, rather than one optK that works out
    LIT-vs-CALL at run time. planTerm ALREADY MAKES THAT DECISION when it
    builds the plan, and a run-time re-derivation would be a SECOND IMPLEMENTER
    of it — the exact arrangement countRuleTerms' own comment refuses ("ONE
    implementer, deliberately"), because two implementers of one decision drift
    and the drift is silent. So the emitter keys on the plan node's inner kind
    and picks the shim; the shim does one thing. ⚠ THE LITERAL SIBLING optLK IS
    NOT BUILT — `RunRulE`'s `';'-?` is the only rung-population term that wants
    it and RunRulE is tomorrow's promotion. kantLeaf REFUSES that shape BY NAME
    rather than letting optRK guess, per the refuse-by-kind discipline that
    caught the ALT defect. An unexercised shim is a green row nobody cashed.

    ⚠ THE RESTORE IS BELT AND BRACES ON THIS SHAPE, AND SAID SO OUT LOUD SO
    NOBODY LATER READS IT AS LOAD-BEARING WHERE IT IS NOT. For an optional
    REFERENCE the callee owns a frame and its own leaveRule already rewinds to
    the callee's `from` on failure (planTerm's rung-6 note records exactly
    this, and records that the interpretive arm instead skips the rewind and
    re-skips before the next term, so the two are not observably different).
    Restoring here to OUR `from` is therefore at worst a no-op and at best one
    notch tighter than the generated arm. It is written because the CONTRACT
    says the failure leg restores, and a contract honoured by an accident of
    who-else-happens-to-rewind stops being honoured the day that changes.

    ⚠ A BROKEN FRAME IS NOT AN ABSENT OPTIONAL, and the return values say so.
    No `into`, no `term` -> return NULL, which fails the chain loudly. Only the
    real "the optional did not match" leg answers success. One channel, one
    meaning: trueResult out of here means THE CHAIN MAY PROCEED, and a missing
    frame is not that.
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
    canonOf -- name the node definingRule() resolves to, from incant.

    THE INSTRUMENT ROAD-1 EXISTS FOR (Clay dispatch amendment 8). Ruling E is
    about resolution, so the tree needs a way to ASK where a face resolves to,
    and until now it had none: definingRule() is a C++ method with no command,
    and it cannot be reconstructed from incant because parenT returns a WRAPPER
    whose unWrap lands back on the child it was applied to. Three spellings
    were tried on 2026-08-22 and none reached the parent.

    ⚠ THIS IS ALSO setParse's OWN PREREQUISITE, which is why it is not a
    detour: the provisional ruling needs setParse to resolve through
    definingRule() before binding, and for that the call has to be rtn-shaped.
    One build carries the instrument, the reads, and the edit.

    Reports with its value on every call (rule H4) rather than only on
    surprise -- a resolver that speaks only when it disagrees cannot be told
    from one that was never called.

    ⚠ definingRule() IS ASSIGNED TO A LOCAL, NEVER TESTED INLINE. genParse.rtn
    :1129 records that `if term.definingRule() != term` fails to parse. The
    hazard is documented, cheap to avoid, and expensive to rediscover -- it
    would surface as bear-trap #24's signature, the extern block wiped to zero
    three files away.
***************************************************************************/
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

/*  === GENERATED by genParse('Braced'), pasted verbatim === SEQ 58, 2026-08-13.

    THE ORACLE-BEARING CONTROL FOR THE BIND-READ SEAM. Byte-identical to
    docs/emitted/phaseB-twelve-emitted.txt lines 2-10, which docs/respellRung.md
    re-derived on 2026-08-11 and found unmoved, so this is the emitter's own
    output and not a hand-written imitation.

    WHY IT IS BEING ADDED NOW. SEQ 58 specified the C++ control as
    `parseMethod=parseBraced` on the grounds that parseBraced has an oracle
    (incant/bracedT). It had never been COMPILED -- `nm` showed zero hits and
    the only parseBraced in the tree was emitted text inside two .md files.
    Without it the control could only be run with a stand-in that fails to
    match, which answers the seam bit but cannot ring SEQ 58 section 5's bell.

    It costs one extern in one in-repo file. No groups.ext edit is owed: the
    binding door reaches it by dlsym on the name, exactly as the parseScaf
    family is reached, so nothing needs to see a declaration. No grammar line
    either -- the bind is made from a fixture, which is the whole point of the
    cross-file control.  */
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
    parseClassify -- WHICH ARM OF setParse CLAIMED THIS FIELD.

    ⚠ THE INSTRUMENT THE 2026-08-19 SESSION DID NOT HAVE, and both of that
    day's parse-generation defects were invisible without it and obvious with
    it. `tokenize` was silently bound to parseString -- which, before the
    parseString repair, reported success without matching anything -- and
    `CodE` came within one arm order of being moved off parseAction. Neither
    needed a PARSE to be visible; both are decided the moment setParse runs,
    and nothing printed that decision.

    ⚠ IT READS THE BOUND POINTER, IT DOES NOT RE-DERIVE THE ARM. A classifier
    that recomputed the answer from the flags would be a second implementation
    of setParse's chain, and the day it disagreed with the real one it would
    say so about the wrong thing. Comparing the actual fnptr cannot drift.

    cerr rather than print: this is a diagnostic, a fixture may have print
    diverted, and stdout is block-buffered so a run that ends badly loses it.
    Returns the field so a walk can chain it.

    ⚠ THE SECOND LINE, ADDED 2026-08-29 ON A SEPARATE PREFIX ON PURPOSE.
    `PA` answers Tony's recon question -- setParse parks `actionMethod` for
    EVERY rule it claims, not only the ones that get parseRule, so an action
    can be parked on a rule whose executor never fires it. The PC line is
    unchanged and genLadder/parseClass.target greps `^PC `, so this adds a
    column without moving a pinned target.

    ⚠ THREE FACTS, THREE FIELDS, because they can disagree and one of them
    disagreeing is the finding:
      act   -- what setParse parked in rStuff->actionMethod
      hung  -- whether the builtinActoR attribute is actually on the node
      fires -- whether anything on this executor's path ever runs it
    act and hung are READ, like pcName. `fires` is DERIVED, and it is a table
    over the pointer just read rather than a second implementation of
    setParse's chain -- its authority is the READER side: parseRule's
    generated tail reaches runRuleAction, which fires builtinActoR;
    parseAction calls field.method(field) itself; every other builtin ends at
    parseSetLabel, which does label work and no action. ⚠ IF A BUILTIN EVER
    GAINS A FIRE, THIS TABLE IS THE THING THAT GOES STALE -- it is named here
    so that lands as an edit and not as a silent wrong answer.
*****************************************************************************/
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

    ensureRStuff, not rStuff: a rule reached at definition time may not have
    been parsed yet, and the fork reads the field off the rule's OWN stuff. This
    is a definition-attribute door, so it fires DURING attachment -- which is
    exactly the moment the 2026-08-31 ruling says construction belongs, and why
    this site keeps its mint rather than losing it. (Spelled getRStuff until
    that ruling split the getter's two jobs apart.)

    definingRule(), not parent -- SEQ 58, 2026-08-13, and it is a MEASURED
    repair, not a tidy-up. Both doors used to bind onto the node aCTionDefinE
    hands them, which for a definition written in the SAME place as the rule is
    the rule itself, so every binding that had ever been made worked. A
    CROSS-FILE re-definition is different: the node being defined is a satellite
    that shares the real rule's child list, and the two addresses were measured
    apart in one run --

        SEAM bind  Braced  boundNode=0x104c60840 boundStuff=0x104c5c100
        SEAM read  Braced  definer=0x104c36a80   defStuff=0x104c34000
                           defParseMethod=0x0    boundParseMethod=0x10406f3c8

    -- so the write TOOK and the reader never saw it. parse() forks on
    definingRule().rStuff.parseMethod (GroupItem.twk), so the cure is for the
    door to resolve its target the same way the reader does. In the same-file
    case definingRule() returns `this` (a node that owns its children routes
    back to itself), so nothing that worked before changes.

    BOTH DOORS MOVE TOGETHER, and that is not optional. parseTermCount writes
    termCount and parseRuleMethod's refusal guard reads it; leaving one on the
    satellite would compare a count nobody wrote against a rule's live terms and
    silently downgrade the refusal to the no-parseTerms warning -- which still
    binds. The guard would have been lost quietly, which is the failure mode
    this fleet's rules exist to prevent.
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
    parseViaKant — THE TRAMPOLINE. Loop closure step 1, 2026-08-11 (SEQ 52).

    WHAT PROBLEM THIS SOLVES, because it is not the one the shims solve.
    rStuff.parseMethod is a C++ FUNCTION POINTER — RuleStuff.twk:88 declares
    `GroupItem &parseMethod(GroupItem);` — and parse() forks on it and calls
    through it. A kant method is NOT a function pointer: it is a GroupItem
    carrying CodE/BlocK, reached through processAction. So a kant parse method
    cannot be installed into the slot that dispatches parse methods, and making
    lit/parseR/leaveRule callable FROM kant does not touch that at all. The
    shims govern what the body may call; this governs who may call the body.
    Two distinct costs, and only the first is the "cheap" the charter promised.

    THE CHEAP DOOR, AND THE OTHER ONE. RuleStuff.twk's jitMethod block named
    this seam on 2026-08-05 and ruled that widening the pointer's signature is
    a LAYOUT change — bear-trap #10's whole apparatus, groups.ext sync plus
    tokall plus rebuild. This function is the other door: an ordinary C++
    function OF THE EXISTING SIGNATURE that stands in the slot and forwards.
    No layout change, no groups.ext edit, and it binds through the existing
    parseMethod= dlsym path with no new vocabulary.

    RESOLUTION IS BY CONVENTION, DELIBERATELY, so that v1 adds no binding verb:
    rule `Foo` is served by the kant action named `kpFoo`. One rule, one name,
    derivable in both directions by a reader. If a binding attribute is wanted
    later it can carry the node itself and this lookup goes away — the
    convention is v1's scaffolding and is not load-bearing on the design.

    ⚠ IT REFUSES RATHER THAN FALLING THROUGH, and that is the tier-3 lesson
    applied here. A missing or uncoded action returns null, which parse() reads
    as "this rule did not match" — the honest answer — and says so on stderr
    once. Quietly falling back to the interpretive arm would make an
    unregistered action indistinguishable from a rule that legitimately failed,
    which is the fold-and-be-quiet failure the degrade-zero rule exists to
    catch.

    ⚠ ONE CHANNEL, ONE MEANING: this returns what processAction returns and
    invents nothing. A null is "no match", exactly as the emitted C++ methods'
    leaveRule null is, so parse()'s caller cannot tell the arms apart by shape.
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
	/*  ⚠ GAP B FAMILY B -- RULE-LEVEL LITERAL. Phase R rung 1, 2026-08-09.
	The charter's smallest family with a fully-known treatment: SemI=";",
	loopOnAttributes="attributes", loopOnMembers="members". A rule whose OWN
	data is a quoted literal matches that literal, which is precisely what
	planTerm already emits for a literal in TERM position -- so this family
	needs no new plan kind and no new support function. It reuses LIT/LITTO.
	
	⚠ THE SPLIT IS ON THE RULE'S OWN rStuff.noLabel, MIRRORING planTerm
	EXACTLY, because LIT vs LITTO carries "does this attach a label" and
	nothing else (see the kind table above). Copying that decision rather
	than re-deciding it is the whole reason this family is cheap.
	
	⚠ AND THE FAMILY IS isSTRING ONLY, DELIBERATELY. The other five kinds
	keep the refusal verbatim. Three constructs used to share one refusal
	message; the taxonomy exists so each gets its own treatment and its own
	text, and widening this test to `rule.data` would re-merge them on day
	one. isCHAR (FloaT) LOOKS like a one-character member of this family and
	is an OPEN row on purpose -- it carries sub-fields, so it is not this
	shape (docs/gapBPhaseT.md, OPEN row 1).
	
	⚠ A CONTAINER IS EXEMT BECAUSE ITS DATA IS DERIVED, NOT AUTHORED.
	Measured 2026-08-19: GroupItem::addGroup builds a bin or registry's
	character set incrementally at ADD-MEMBER time -- `if binType { ...
	binGuard->set((int)*group->tag); ... }` -- one character per member, and
	nothing anywhere authors it. So a container's `data` is a cache of its
	own membership, not a rule-level alternative to its members, and
	refusing it as rule-as-data reports a hybrid that was never written.
	`!rule.binType` is deliberately the SAME test addGroup writes under, so
	the reader cannot drift from the writer. No new flag: the only existing
	candidate, `altered`, is the stak-invalidation bit and is CLEARED by
	resetStak, so a derived mark stored there would silently evaporate.  */
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
	/*  A literal-valued rule legitimately has NO terms -- its data IS its
	content -- so the no-terms refusal must not fire on it.
	
	⚠ THE TAG-AS-DATA FALLBACK, added 2026-08-24 (rung one of the rule
	ladder). A rule with no terms and no data is NOT degenerate: its match
	content lives in a channel this planner never read. Measured -- for
	DEFINing and break every readable channel is empty (listLength 0, data
	0, no attributes, no members) and only `text` answers, carrying the
	rule's own TAG. That is bear-trap 26's fallback doing real work: a field
	with no data reads back as its name, and for these rules the name IS the
	token to match.
	
	So the rule's own tag is planned as its literal, through the SAME
	LIT/LITTO block the data-carrying case already uses -- no second
	mechanism, and `node.text = rule.text` picks the tag up by that same
	fallback.
	
	⚠ THE REFUSAL BELOW STAYS REACHABLE ON PURPOSE and is not dead code. It
	still fires for a no-terms rule with no rStuff, because LIT vs LITTO is
	undecidable without it -- exactly the reason the data-carrying path
	refuses one line above. A rule whose tag-fallback also comes up empty
	must refuse LOUD rather than emit a match on nothing.  */
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
    planTally — THE RULING-4 NUMBERS, PRINTED AS SCALARS. Phase R rung 1's H4
    obligation (Tony, 2026-08-09): the charter demands two numbers at every rung,
    and until now BOTH were derived by grepping phaseA's output. A quantity
    nobody prints is a quantity that can drift silently — and the SEQ 42 census
    is this session's own proof that a derived-and-transcribed number outlives
    the moment it was true.

    ⚠ IT COUNTS AT THREE SITES, NOT SEVENTEEN, AND THE LICENCE IS A MEASURED
    INVARIANT RATHER THAN A GUESS: every refusal line is immediately followed by
    a `return null`, and planRule stops at its FIRST bad term. So
        total refusals == (planRule nulls) + (planTerm nulls)
    which is countable at the two CALL sites. Verified against the pre-change
    corpus before being relied on:
        97 total  ==  65 `REFUSE rule` (== 65 distinct rules refused)
                  +   32 term-level    (== 32 `unclassified`)
    ⚠ AND THE INVARIANT IS ASSERTED, NOT ASSUMED. It couples the tally to "one
    line per null return", which a future two-line refusal path would break
    silently. `genLadder/gapB.sh` therefore cross-checks the printed scalar
    against the grep every run: the cheap instrument guards the cheap counter,
    and a divergence names itself instead of quietly moving the metric.

    mode 1 bump refusals · 2 bump plannable · 3 read refusals · 4 read plannable
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
	/*  CONTAINER FIRST, AND THAT ORDER IS THE CLASSIFICATION. A bin term is
	ALSO a reference -- UnaryOPS is defined in pROPERTIEs and referenced in
	UnaryXP -- so testing the reference first would plan it as a CALL and
	emit parseR against a container that is not a rule. A container matches
	longest-entry-first and deposits the matched ENTRY; that is a different
	consumption from every other kind on the ladder, which is why it is a
	kind and not a literal with a set.
	Measured on the specimen: noLabel=0, min=1, max=1. A noLabel container
	has no spelling yet and refuses rather than guessing at one.  */
	/*  THE LABELLED-LITERAL REPRESENTATION. Tony's ruling via Clay, 2026-08-16.
	A literal term now carries its spelling as character data, so the data arm
	below, which used to be a pure refusal, classifies it instead.
	
	WHAT MOVED is the representation, not a flag. aCTionDefinE used to
	substitute a literal term with a fresh node TAGGED with the spelling and
	carrying no data. That branch is gone, the term itself is attached, and
	aCTionTraiT now sets the spelling as CONTENT. So the spelling left the tag
	and lives in the data, and every literal fell into the refusal, which is
	why the whole Scaf family reported no plan.
	
	KEYED TO THE REPRESENTATION, NEVER TO isLiteral. That flag does not
	survive rStuff duplication or the TraiTdata handoff into TraiT. Tony
	observed it directly and the census is in docs/gateCensus.md section B0-2.
	It lies at exactly the read sites that matter, so the material signature is
	what is tested here.
	
	THE MEASURED SPLIT, from incant/litProbe beside countScratch's bare Ladder
	rules. Both halves carry isSTRING data and noLabel is the ONLY
	discriminator, which is why LIT versus LITTO needs no new test. A labelled
	literal is tagged with its LABEL and has noLabel clear; a bare one is
	tagged with the generic container name and has noLabel set. Because that
	bare tag is now generic, sourcing the spelling from the tag would emit the
	container name as the literal. It comes from the data instead.
	
	AND THE FIREWALL KEEPS ITS TEETH: isSTRING only, mirroring the rule-level
	literal family further down, which records the same restriction and the
	same reason. The other kinds still refuse, isGROUP above all, since the
	genuine inline-group construct is what that refusal was written for.
	isCHAR stays out for the reason recorded there, that it carries sub-fields
	and so is not this shape. Reading the text is guarded by data, which is
	bear-trap 26 exactly: a dataless field answers with its own tag.
	
	PLACEMENT IS LOAD-BEARING AND THIS COMMENT MUST STAY ABOVE THE CHAIN. A
	block comment wedged BETWEEN two arms, immediately before an or, wipes the
	whole extern block to zero. Measured three ways 2026-08-16: above the chain
	OK, inside an arm body OK, between arms fatal. Bear-trap 4 one level up.  */
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

/*****************************************************************************
    probeNode -- POINTER-LEVEL READ FOR THE parseSelfRecursion STATION.

    Reports the three facts the docket's candidates disagree about, all as
    POINTERS rather than names, because two faces of one rule share a tag by
    construction and a reader that reports names cannot answer an identity
    question (canonOf's own comment argues this at length).

        gMethod     the dispatch target line 1487 reads
        groupBody   the substance, which copyOf copies wholesale
        parentLabel the rStuff link candidate 3 turns on

    Passthrough because %p on a GroupItem* is not sayable in tok. Reports on
    stderr, unbuffered, so a run that ends at a signal still carries it.

    STATION INSTRUMENT, 2026-08-26. Returns the field so a walk can chain it.
*****************************************************************************/
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
	else	::reportCodeFail(field);
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

extern "C" GroupItem *recordParse(GroupItem *argument)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	
	gParseRecordArmed = 1;
	
	return ruler->trueResult;
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
Stak 		*recurseSTAK = 0;
GroupBody 	*body = 0;
GroupItem 	*frame = 0;
GroupItem 	*grup = 0;
	frame = ::frameFind(action);
	if ( frame )
		recurseSTAK = frame->getStak();
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
	while ( grup = action->prior(grup) )
		if ( (grup->groupBody->flags.isArgument || grup->groupBody->flags.isLocal) && !grup->groupBody->flags.noPrint )
			{
			body = (GroupBody*)recurseSTAK->pop();
			
			if (gNoUnwrap && grup->groupBody->flags.isArgument) {
			grup->groupBody = body;
			body = 0;
			continue;
			}
			
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
/*******************************************************************************
    showParse — PJ-7's director's window: print a rule's recorded ParsE.

        registry(cOMMANDs);
        define showParse immediateAction=showParse; ;
        showParse('Braced');

    WHY THIS IS A COMMAND AND NOT A KANT ACTION, which was the brief's first
    preference and is not available: A RULE NAME IN INCANT EXPRESSION POSITION
    INVOKES THE RULE. `print Braced.ParsE;` prints nothing and `if Braced;`
    exits 139 — both measured 2026-08-06 — because naming a rule runs it
    against the current input. There is no ordinary incant statement that names
    a rule without firing it, so the window has to come in through the same door
    genParse itself uses: a command taking the name as TEXT and resolving it
    with locateRule via ruleOrRefuse. That is the proven lookup, and it also
    sidesteps the members gate that makes bare lookup unreliable for a rule.

    PRINTS TO STDOUT AND SAYS SO WHEN THERE IS NOTHING. An empty or absent
    record prints a named line rather than nothing at all — an instrument whose
    silence means two different things (no record / no output) is the
    one-channel-one-meaning failure, and here the two are a gate left closed
    versus a genParse that never ran.

    NOT REGISTERED IN incant/setup, DELIBERATELY. Registering it there would add
    a member to a base registry that pop.sh's census walks and baselines. The
    fixture registers it, exactly as the genParse fixtures already register
    genParse — zero baseline risk, and the same two lines.
*******************************************************************************/
/*******************************************************************************
    recordParse — GX-6: arm the ParsE record from INSIDE a fixture, so a
    looksee needs no environment variable and no preparation.

        registry(cOMMANDs);
        define recordParse immediateAction=recordParse; ;
        recordParse();

    Same relationship to INCANT_PARSE_RECORD that `traceParse` has to a debug
    switch: one more door onto the SAME gate, not a second gate. genParse reads
    the env var first and falls back to this flag, so an armed fixture behaves
    exactly as `INCANT_PARSE_RECORD=1` does -- attribute only, no file. A
    fixture that wants the file sink still uses the env var, because a path has
    to come from somewhere.

    A FILE-STATIC AND NOT A GroupRules FIELD, deliberately: a new field in a
    class shifts nothing here but a new GroupBody flag would, and the habit
    worth keeping is that a debug affordance never drags in bear-trap #10's
    apparatus (groups.ext sync + tokall). Off unless a fixture asks.
*******************************************************************************/
/*******************************************************************************
    ruleNameArg — GA, 2026-08-06. What a rule-name argument may be.

    THREE FORMS ACCEPTED, and the ruling is "text, or a field resolving to
    text; anything unresolvable refuses loudly by name":

        genParse('Parens')   quoted literal   — the baseline
        genParse(Parens)     bare name        — works, see below
        genParse(gaName)     field holding "Parens"

    ⚠ MEASURED, AND BOTH SURPRISES ARE THE SAME TRAP. A field with no data
    returns its TAG from .text (bear-trap #26), and that single fact explains
    the whole table:

      · the BARE form already worked, by accident of the trap rather than by
        design — `Parens` arrives as a node with no data of its own, so .text
        echoes the tag, which happens to BE the rule name.
      · the FIELD form failed for the identical reason and in the opposite
        direction — `gaName` arrives as a REFERENCE node with no data, so .text
        echoed "gaName" and genParse dutifully refused a rule by that name. The
        DEFINED gaName holds "Parens"; the reference passed in does not.

    It was NOT a silent failure, which an earlier note claimed: it printed
    `genParse: REFUSING gaName -- not a rule` on STDERR the whole time, and the
    first reading only looked at stdout. The refusal was working; the
    resolution was missing.

    So: try the name as given (covers literal and bare); if that is not a rule,
    look it up and, if it is a field CARRYING DATA, take its text and try that.
    Unresolvable falls through to ruleOrRefuse, which already refuses by name.
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
			return 0;
	/*  THE SELF-CALL SEAM. Under jitting an ordinary call INLINES -- emit-on-walk
	re-executes the callee's BlocK into the current builder, which is measured
	to work and produces correct run-time answers with no `call` in the IR
	(incant/jitJC). A SELF-call cannot inline: the re-walk reuses nodes that
	already carry jitData from the enclosing pass, and the condition target's
	jitValue is by then an i1 (jitEmitCompare's result), so the second pass
	asserts inside LLVM. jitEmitSelfCall answers 0 for every other callee, so
	this gate changes nothing about ordinary calls.  */
	if ( ruler->jitting )
		{
		 if (::jitEmitSelfCall(argument, field)) return field; 
		}
	/*  ⚠ BIND-BY-BODY, the flip's other half. Under gNoUnwrap the argument node
	ADOPTS the caller's groupBody, so every read and write through the
	argument name reaches caller storage with no hop -- which is what the
	auto-unwrap was silently providing (filmed 2026-08-30: `argument = 5`
	already reaches the caller today, via runOP's !op.isAssign arm). The two
	retire together or the write stops arriving, silently.
	⚠ THE BODY IS THE STABLE IDENTITY AND THE NODE IS NOT: two calls passing
	the same source field arrive as DIFFERENT NODES OVER ONE BODY. Binding
	by body binds to what is already invariant.  */
	
	if (( ruleArg = field->get("argument") )) {
	result = argument ? argument : field;
	if (gNoUnwrap)  ruleArg->groupBody = result->groupBody;
	else            ruleArg->setGroup(result);
	}
	else    result = field;
	
	ruler->lastREF->groupBody->gGroup = result;
	ruler->lastREF->groupBody->flags.data = 6;
	/*  UNCONDITIONAL, 2026-08-10, SEQ 27 rung B. See the note above
	jitSaveFrameRT for why the gate was the defect rather than the
	protection, and why rung A's return seam had to land first.  */
	::saveLocalFields(field);
	/*  BRACKET THE INLINE. Under jitting this call is being INLINED -- the
	BlocK below re-executes into the caller's builder -- so for the duration
	the action being walked is `field`, and a recursive call inside it must
	be recognised as such. See gJitInlining.  */
	if ( ruler->jitting )
		{
		 jitInlinePush(field); 
		}
	result = ::processAction(field);
	/*  ⚠ `result` IS PASSED BECAUSE IT IS THE VALUE CHANNEL. An enclosing
	assignment reads its operand's jitData, and this node is that operand --
	so when E2's merge produces the callee's answer, this is what has to
	carry it. Measured the hard way: a merge that set only gJitResult was
	emitted correctly and then ignored.  */
	if ( ruler->jitting )
		{
		 jitInlinePop(result); 
		}
	/*  THE RETURN SEAM -- VALUE-CAPTURE. Tony, 2026-08-10, SEQ 27 rung A.
	
	restoreLocalFields overwrites a local's body IN PLACE, so returning the
	local's own node hands the caller a pointer INTO the frame that is about
	to be swept. The caller then reads it back blanked -- it answers with its
	own tag instead of its value, which is CLAIM KANT-8. The cure is to take
	the value BEFORE the sweep and hand back the copy.
	
	THE BRACKET IS NOT TOUCHED. M1 measured the locals restoring perfectly at
	every depth on both engines; the only defect was the returned pointer
	aiming into the frame. So this is a seam repair, not a bracket repair.
	
	Three clauses, each load-bearing, each with a caller that proves it:
	1. MINT A FRESH NODE and copy the value in -- never the local's node, and
	never a bare scalar. manyKant and spellKant (genParse.rtn) both
	null-check this result and then read .text off it, which a raw number
	breaks. Note the copy constructor is NOT usable here: it SHARES the
	body, which is precisely what the sweep overwrites. Minting and then
	calling setContent is the detaching form, and setContent already
	carries the contentless case (it stamps the tag as the text), so a
	result with no value reads back the same string it does today.
	2. MINT ON THE RESULT'S OWN TAG, so both the tag and the text answer
	exactly as they did before this seam existed.
	3. PRESERVE NULL AS NULL. Minting an empty node instead would invert the
	two null checks at those same sites, and an empty answer would then
	read as a successful one -- silently, and in the flattering direction.
	⚠ MEASURED 2026-08-10, AND THE GUARD IS DEFENSIVE RATHER THAN LOAD-
	BEARING, WHICH IS WORTH KNOWING BEFORE ANYONE "SIMPLIFIES" IT AWAY.
	There are TWO ways this method answers with nothing. The reachable one
	is the early return above, when a coded body fails to parse; it
	returns before this block and so preserves nothing-ness for free. The
	other is a run that gets past that and still yields no result, and a
	sweep of the whole fixture population found it happening ZERO times in
	128 files. So this guard is currently uncontrolled by any fixture: it
	is here because without it the mint would dereference a null and take
	the process down, not because a green run proves it fires. incant's
	kant8N certifies the reachable path and says plainly that it does not
	reach this one.
	
	NOT UNDER jitting. The jitted arm already returns by capture and is the
	certified one; the node in flight there is the value channel an enclosing
	assignment reads through jitData, which a fresh node would not carry.
	The interpreter is adopting the jit's semantics here, so the jitted arm
	owes byte-agreement and must emit unchanged.  */
	if ( result && !ruler->jitting )
		{
		capture = new GroupItem(result->groupBody->tag);
		capture->setContent(result);
		result = capture;
		}
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

extern "C" GroupItem *runOP(GroupItem *field)
{
GroupItem 	*result = 0;
GroupItem 	*op = field->get(1);
GroupItem 	*arg = field->get(3);
GroupItem 	*target = field->get(2);
	/*  ⚠ THE FLIP LIVES HERE. Both lines are the ORIGINAL generated code, moved
	into passthrough unchanged and wrapped in the one gate. Under gNoUnwrap
	they do not run, and an operand reaches its operator AS THE FIELD.
	`!isPointer` is measured dead (0 suppressions in 29,634 runOP entries)
	and `!op.isAssign` retires with the line rather than despite it -- the
	exemption becomes the rule. See docs/unwrapRecon.md.  */
	
	if (!gNoUnwrap) {
	if ( isGROUP(target->groupBody->flags.data) && !target->groupBody->flags.isPointer && !target->groupBody->flags.isIterator && !op->groupBody->flags.isAssign )
	target = target->getGroup();
	if ( arg && isGROUP(arg->groupBody->flags.data) && !arg->groupBody->flags.isPointer )
	arg = arg->getGroup();
	}
	
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
	
	if (!gNoUnwrap)
	if ( isGROUP(target->groupBody->flags.data) && !target->groupBody->flags.isPointer && !target->groupBody->flags.isIterator )
	target = target->getGroup();
	
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
	
	if (!gNoUnwrap)
	if ( isGROUP(arg->groupBody->flags.data) && !arg->groupBody->flags.isPointer )
	arg = arg->getGroup();
	
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
			
			if (gNoUnwrap && grup->groupBody->flags.isArgument) {
			recurseSTAK->push(grup->groupBody);
			continue;
			}
			
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
		else	::fprintf(stderr,"setMark: ERROR mark offset exceeds current buffer length\n");
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
	if ( isREGISTRY(field->groupBody->flags.binType) )
		return 0;
	if ( !ruleStuff )
		{
		::fprintf(stderr,"setParse: ERROR field passed in %s has no rStuff\n",field->groupBody->tag);
		return 0;
		}
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
		field->updateContentFlags();
		}
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

/***************************************************************************
    showBody -- PRINT A FIELD'S NODE AND groupBody ADDRESSES. 2026-08-17.

    An instrument, not a feature. Flags live in groupBody, so two field
    instances either share one body and see each other's flags, or they do not
    and they cannot. That is a pointer question and incant cannot ask it: every
    incant-side accessor is snapshot-by-value, so two probes returning the same
    text prove text equality and never node identity.

    Its purpose is to settle copy-versus-share seams by measurement rather than
    by reasoning about which of the two copy mechanisms in the tree a given
    operation went through -- the copy constructor shares the body, setContent
    copies content and drops flags, and knowing which one an operation used is
    the whole question at such a seam.

    stderr and not stdout, deliberately: a run that ends in stop() loses
    buffered stdout, and a probe whose output vanishes on the interesting runs
    is not a probe.
***************************************************************************/
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
    THE GENERATED-BODY CORPUS -- storeBody / activateBody / activateAll /
    bodyCensus. Charter A, SEQ 78, Ruling 1 (Fork 2).

    THE INVARIANT THESE FOUR EXIST TO ENFORCE, and it is the whole point:
    GENERATION NEVER WRITES THE LIVE SLOT. The live slot on the generated arc
    is CodE plus isCoded, and activateBody is the ONLY thing in this file that
    writes it. Phase one files bodies pending; phase two binds them. F-31's
    mechanism was a body installed over a rule the reader was still using, and
    that is unconstructable once the two steps are separate.

    THE HANDOFF IS `StorE`, NOT `CodE`, AND THAT IS NOT A DETAIL. The walk
    builds its body copy tagged StorE and hangs it on the rule; storeBody moves
    it off into the corpus. A StorE attribute is inert -- nothing in parse()
    or processCode reads that tag -- so at no point during generation does a
    rule carry a body the reader can be diverted into. Retagging to CodE
    happens in activateBody, at bind time, on a fresh node.

    ⚠ COUNT IS 1 FOR PENDING AND 2 FOR ACTIVATED, NEVER 0. A fresh GroupItem's
    count is already zero, so a zero-means-pending encoding cannot tell
    "filed pending" from "never touched" -- the census would report a corpus
    that was never written as a corpus full of pending work. Same reason the
    JIT ladder pairs every zero-expecting row with a non-zero sibling.

    THE MINT COPIES kantDoor's DOOR (genParse.rtn) rather than inventing a
    second one, including its groupList guard: indexing a registry that has
    just been created prints `nextGroup: ERROR ... does not contain a list`.
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
    storedBody -- THE PER-RULE QUERY VERB. Returns the corpus entry for a rule,
    or null if nothing is filed against it.

    ⚠ THIS EXTERN WAS NOT IN THE PRE-REGISTERED SET, AND THAT IS REPORTED AS A
    FINDING RATHER THAN RE-PINNED. The pre-registration named four verbs and a
    canary delta of +4; this makes it five and +5. The gap it closes was found
    by the build and could not have been reasoned out beforehand:

    THE DIRECT-INSTALL IDIOM WAS DOING DOUBLE DUTY. A phase-one walk recurses
    into a rule's terms, and its only termination guard is `actionType != 0` --
    which became non-zero *because the body had just been installed*. Installing
    was simultaneously the STORE and the VISITED MARK. Separating the two, which
    is the whole point of this charter, deleted the visited mark: walkPhase went
    StatemenT -> BlocK -> StatemenT for ever and died at exit 139.

    So the corpus has to answer "is this rule already filed", and A1 already
    says the corpus is censusable BY QUERY VERB. This is that verb at per-rule
    granularity. It is a READ -- it writes nothing and never mints an entry --
    so it cannot itself become a second writer of anything.
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
	the following externs (unWrap/writeTempFile). Doc goes here, in the block.
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
		if ( !term->groupBody->flags.noPrint && !term->getRStuff() )
			n++;
		i++;
		}
	return n;
}

/***************************************************************************
	tokenize -- RETIRED 2026-09-02, and this is its obituary rather than a gap.

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
