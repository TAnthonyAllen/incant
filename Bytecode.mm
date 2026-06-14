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
#include "Bytecode.h"

// opGT / opMultiply / opAssign are declared via groupIncludes (included above).
/***************************************************************************
    The operand stack for an instruction's body -- a plain field used as a
    stack. interpret() hangs an `opStack` field off the bcLIST before walking
    it; every handler reaches it through the instruction's parent (the bcLIST).
***************************************************************************/
extern "C" GroupItem *opStackOf(GroupItem *instr)
{
GroupItem 	*body = instr->parent;
	return body->getAttribute("opStack");
}

/***************************************************************************
    bcBR — unconditional branch to the label carried as the non-interpret
    attribute (its tag names the label). Mirrors runBRZ's target resolution,
    minus the condition: resolve to the actual stream member by tag.
***************************************************************************/
extern "C" GroupItem *runBR(GroupItem *instr)
{
GroupItem 	*body = instr->parent;
	// the bcLIST
GroupItem 	*label = 0;
GroupItem 	*grup = 0;
	while ( grup = instr->nextAttribute(grup) )
		if ( ::compare(grup->groupBody->tag,"interpret") != 0 )
			label = grup;
	if ( label )
		{
		grup = body->getFromList(label->groupBody->tag);
		grup->groupBody->flags.byRef = 1;
		return grup;
		}
	return 0;
}

// ---------- control flow: cond from stack, target from instruction ----------
/***************************************************************************
    bcBRZ — pop the condition; if zero/false, branch to the label carried in
    the instruction's `dst` attribute. Otherwise fall through (null).
***************************************************************************/
extern "C" GroupItem *runBRZ(GroupItem *instr)
{
GroupItem 	*stack = ::opStackOf(instr);
GroupItem 	*cond = stack->pop();
GroupItem 	*body = instr->parent;
	// the bcLIST
GroupItem 	*label = 0;
GroupItem 	*grup = 0;
	if ( !cond || !cond->getCount() )
		{
		// the branch target is carried as the non-interpret attribute; its tag
		// names the label. The attribute is a COPY (shares GroupBody, different
		// node) so resolve to the actual stream member by tag.
		while ( grup = instr->nextAttribute(grup) )
			if ( ::compare(grup->groupBody->tag,"interpret") != 0 )
				label = grup;
		if ( label )
			{
			grup = body->getFromList(label->groupBody->tag);
			grup->groupBody->flags.byRef = 1;
			return grup;
			}
		}
	return 0;
}

/***************************************************************************
    bcCALL — invoke a callable; result lands on the stack. Stub: no calls in
    the current test surface.
    TODO: invoke instr's callee with its args; push the result.
***************************************************************************/
extern "C" GroupItem *runCall(GroupItem *instr)
{
	return 0;
}

/***************************************************************************
    runEQ / runNotEQ / runLT / runGE — relational mirrors of runGT/runLE.
    Each pops right then left, calls its opXXX(argument,target) (all four take
    (argument,target) and return a shared trueResult or null), and pushes a
    fresh 0/1 cond node -- never the shared return -- so bcBRZ reads a stable
    count. op(op2,op1) keeps the same argument=right, target=left order as runGT.
***************************************************************************/
extern "C" GroupItem *runEQ(GroupItem *instr)
{
GroupItem 	*stack = ::opStackOf(instr);
GroupItem 	*op2 = stack->pop();
GroupItem 	*op1 = stack->pop();
GroupItem 	*cond = new GroupItem("cond");
GroupItem 	*hit = ::opEQ(op2,op1);
	if ( hit )
		cond->setCount(1);
	else	cond->setCount(0);
	stack->push(cond);
	return 0;
}

/***************************************************************************
    bcForNext — the for-loop iterator op. Carries the loop variable (Looper),
    the iterable (ExpressioN), and optional LoopRestrict, all +%-attached by
    gFOR and read here by tag. Mirrors aCTionFOR's iteration on a single op:

      * Operands. Read by tag: the loop var is tagged "ANYtoken" (grammar
        `Looper=ANYtoken` -- the role is "Looper" but the parse node's tag is
        ANYtoken), the iterable "ExpressioN", the optional filter "LoopRestrict".
      * Descent. Looper is a group-typed wrapper whose .group is the real loop
        var; descend one level. ExpressioN is the (possibly nested) revisedList
        wrapper; descend by .group while isGROUP-typed until the list-bearing
        field (the descent keys on the isGROUP DATA TYPE, so it stops at a
        typed field like a string-valued `sumple` rather than its children).
      * Cursor (index form, v1). A live list member can't be round-tripped as
        a node's .group between passes -- setGroup re-parents it out of the
        iterable, so next() can no longer navigate from it (aCTionFOR sidesteps
        this by keeping its cursor in a C++ local; a re-entrant op has none). So
        instead the op carries a "cursor" child holding an INTEGER match-index
        (setCount/getCount -- pure data, no re-parenting). Each pass re-walks the
        iterable from the start, skipping match-index matches, and returns the
        next one. O(n^2) over the loop; fine for v1, optimize with a re-parent-
        safe cursor later.
      * Filter. LoopRestrict ("attributes"/"members") maps to affiliation 1/2;
        non-matching items are skipped during the walk (continue).
      * Result. On the next unseen match: bump the index, push a count-1 node ->
        bcBRZ falls through to the body. On exhaustion: reset the index to 0
        (self-clean so the NEXT run restarts) and push count-0 -> bcBRZ branches
        to the exit label.

    Deferred for v1 (documented gaps): reversE (prior() walk); loop-var VALUE
    binding (body can't read the current element yet -- binding via setGroup
    re-parents, same root cause as the cursor; the counter-body POP doesn't need
    it); byRef body-steering / break-mid-loop.
***************************************************************************/
extern "C" GroupItem *runForNext(GroupItem *instr)
{
GroupItem 	*stack = ::opStackOf(instr);
GroupItem 	*Looper = instr->getAttribute("Looper");
GroupItem 	*LoopOn = instr->getAttribute("ExpressioN");
GroupItem 	*restF = instr->getAttribute("LoopRestrict");
GroupItem 	*loopOn = 0;
GroupItem 	*grup = 0;
GroupItem 	*prod = 0;
GroupItem 	*cursorHolder = 0;
int 		restrict = 0;
int 		target = 0;
int 		seen = 0;
	loopOn = LoopOn;
	while ( isGROUP(loopOn->groupBody->flags.data) )
		loopOn = loopOn->getGroup();
	if ( ::compare(loopOn->groupBody->tag,"revisedList") == 0 )
		loopOn = loopOn->groupBody->groupList->firstInList;
	if ( restF )
		{
		char 	*restriction = restF->getText();
		if ( ::compare(restriction,"attributes") == 0 )
			restrict = 1;
		else
		if ( ::compare(restriction,"members") == 0 )
			restrict = 2;
		}
	cursorHolder = instr->getAttribute("cursor");
	if ( !cursorHolder )
		{
		cursorHolder = new GroupItem("cursor");
		instr->addAttribute(cursorHolder);
		}
	target = cursorHolder->getCount();
	seen = 0;
	while ( grup = loopOn->next(grup) )
		{
		if ( restrict && grup->options.affiliation != restrict )
			continue;
		if ( seen == target )
			{
			grup->groupBody->flags.byRef = 1;
			Looper->setGroup(grup);
			GroupControl::groupController->groupRules->lastREF->setGroup(grup);
			cursorHolder->setCount(target + 1);
			prod = new GroupItem("prod");
			prod->setCount(1);
			stack->push(prod);
			return 0;
			}
		++seen;
		}
	cursorHolder->setCount(0);
	prod = new GroupItem("prod");
	prod->setCount(0);
	stack->push(prod);
	return 0;
}

extern "C" GroupItem *runGE(GroupItem *instr)
{
GroupItem 	*stack = ::opStackOf(instr);
GroupItem 	*op2 = stack->pop();
GroupItem 	*op1 = stack->pop();
GroupItem 	*cond = new GroupItem("cond");
GroupItem 	*hit = ::opGE(op2,op1);
	if ( hit )
		cond->setCount(1);
	else	cond->setCount(0);
	stack->push(cond);
	return 0;
}

// ---------- op-shims: pop two, materialize a stable result, push ----------
/***************************************************************************
    runGT — pop right then left, compare, push a STABLE 0/1 cond node. opGT
    returns a shared trueResult (or null on false), so we never push its
    return directly: materialize a fresh count node instead.
***************************************************************************/
extern "C" GroupItem *runGT(GroupItem *instr)
{
GroupItem 	*stack = ::opStackOf(instr);
GroupItem 	*op2 = stack->pop();
	// right operand (pushed last)
GroupItem 	*op1 = stack->pop();
	// left  operand
GroupItem 	*cond = new GroupItem("cond");
GroupItem 	*hit = ::opGT(op2,op1);
	// keep opGT(argument, target) order
	if ( hit )
		cond->setCount(1);
	else	cond->setCount(0);
	stack->push(cond);
	return 0;
}

/***************************************************************************
    runLE — pop right then left, compare, push a STABLE 0/1 cond node. Mirror
    of runGT: opLE(argument,target) computes compareValues(target,argument)<=0,
    so the opLE(op2,op1) order matches runGT's. opLE returns a shared
    trueResult (or null), so we materialize a fresh count node, never push the
    return directly.
***************************************************************************/
extern "C" GroupItem *runLE(GroupItem *instr)
{
GroupItem 	*stack = ::opStackOf(instr);
GroupItem 	*op2 = stack->pop();
	// right operand (pushed last)
GroupItem 	*op1 = stack->pop();
	// left  operand
GroupItem 	*cond = new GroupItem("cond");
GroupItem 	*hit = ::opLE(op2,op1);
	// keep opLE(argument, target) order
	if ( hit )
		cond->setCount(1);
	else	cond->setCount(0);
	stack->push(cond);
	return 0;
}

extern "C" GroupItem *runLT(GroupItem *instr)
{
GroupItem 	*stack = ::opStackOf(instr);
GroupItem 	*op2 = stack->pop();
GroupItem 	*op1 = stack->pop();
GroupItem 	*cond = new GroupItem("cond");
GroupItem 	*hit = ::opLT(op2,op1);
	if ( hit )
		cond->setCount(1);
	else	cond->setCount(0);
	stack->push(cond);
	return 0;
}

/***************************************************************************
    runMultiply — pop two, multiply, push a COPY of the product. opMultiply
    returns the shared tempField (value overwritten by the next arith op), so
    we copy its value into a fresh node before pushing. prod is pushed even on
    a null result (stays empty), keeping the stack depth predictable.
***************************************************************************/
extern "C" GroupItem *runMultiply(GroupItem *instr)
{
GroupItem 	*stack = ::opStackOf(instr);
GroupItem 	*op2 = stack->pop();
GroupItem 	*op1 = stack->pop();
GroupItem 	*result = ::opMultiply(op2,op1);
GroupItem 	*prod = new GroupItem("prod");
	if ( result )
		prod->copyData(result);
	// copy value off the shared temp
	stack->push(prod);
	return 0;
}

extern "C" GroupItem *runNotEQ(GroupItem *instr)
{
GroupItem 	*stack = ::opStackOf(instr);
GroupItem 	*op2 = stack->pop();
GroupItem 	*op1 = stack->pop();
GroupItem 	*cond = new GroupItem("cond");
GroupItem 	*hit = ::opNotEQ(op2,op1);
	if ( hit )
		cond->setCount(1);
	else	cond->setCount(0);
	stack->push(cond);
	return 0;
}

/***************************************************************************
    runPlus — pop two, add, push a COPY of the sum. Mirror of runMultiply:
    opPlus (like opMultiply) returns the shared tempField, so we copy its
    value into a fresh node before pushing. sum is pushed even on a null
    result (stays empty), keeping the stack depth predictable.
***************************************************************************/
extern "C" GroupItem *runPlus(GroupItem *instr)
{
GroupItem 	*stack = ::opStackOf(instr);
GroupItem 	*op2 = stack->pop();
GroupItem 	*op1 = stack->pop();
GroupItem 	*result = ::opPlus(op2,op1);
GroupItem 	*sum = new GroupItem("sum");
	if ( result )
		sum->copyData(result);
	// copy value off the shared temp
	stack->push(sum);
	return 0;
}

// ---------- print: passthrough — walk the carried statement's stuff ----------
/***************************************************************************
    bcPrint — passthrough. gPrinT emitted this op carrying the whole print
    statement under the `src` attribute (src.group = the StatemenT). We do
    exactly what non-gen aCTionPrinT does: pull the statement's `stuff`, walk
    its PrintXP attributes, appendGroup each (the ExpressioN when present, else
    the shortcut grup itself, honoring FormaT), then opPrint. Reliable C++
    accessors reach the operands that incant accessors couldn't. Returns null
    (implicit-next); opPrint's trueResult must NOT be returned or interpret()
    reads it as a branch target.
***************************************************************************/
extern "C" GroupItem *runPrint(GroupItem *instr)
{
GroupItem 	*statement = instr->get(2);
	// gPrinT attached the print statement here (op +% argument)
	::aCTionPrinT(statement);
	// print directly (runOP unwrapping pooches it). Operand
	// order is handled by the fLAG flag aCTionExpressioN set
	// on the operand list, which appendGroup reads.
	return 0;
	// do NOT return its result: interpret() reads non-null
	// as a branch target.
}

/***************************************************************************
    bcPushField — push the referenced field's CURRENT value. The emit now
    carries the field by reference (gXpress: emitBC(copyOf(bcPushField) +%
    child)) -- the +% attribute shares the field's GroupBody, so reading it
    sees writes that bcStoreField makes to the same field (live read; this is
    what lets a while-loop condition observe the body's updates). Walk the
    attributes, skip the "interpret" handler, copyData the field node. Fallback
    to the instruction itself for the older folded-value form (bcPushField=x).
***************************************************************************/
extern "C" GroupItem *runPushField(GroupItem *instr)
{
GroupItem 	*stack = ::opStackOf(instr);
GroupItem 	*value = new GroupItem("fld");
GroupItem 	*field = 0;
GroupItem 	*grup = 0;
	while ( grup = instr->nextAttribute(grup) )
		{
		if ( ::compare(grup->groupBody->tag,"interpret") != 0 )
			field = grup;
		}
	if ( !field )
		field = instr;
	value->copyData(field);
	stack->push(value);
	return 0;
}

// ---------- producers: push a fresh value node onto the operand stack ----------
/***************************************************************************
    bcPushLit — push the literal the instruction carries. A fresh node copies
    the value off the instruction (setContent copies its data), so the live
    bcLIST member is never moved onto the stack.
***************************************************************************/
extern "C" GroupItem *runPushLit(GroupItem *instr)
{
GroupItem 	*stack = ::opStackOf(instr);
GroupItem 	*value = new GroupItem("lit");
	value->copyData(instr);
	stack->push(value);
	return 0;
}

/***************************************************************************
    bcRET — halt. Returns null; relies on runRET being the last instruction so
    the next-sibling lookup yields nothing. interpret() also asserts the
    operand stack is empty here.
***************************************************************************/
extern "C" GroupItem *runRET(GroupItem *instr)
{
	return 0;
}

// ---------- consumer: pop a value, store into a field ----------
/***************************************************************************
    bcStoreField — pop the top value, store it into the target field the
    instruction names (e.g. maximus). A bytecode store is a clean data copy
    into the live destination, so it does that directly (copyData) rather than
    routing through opAssign/setContent — decoupled from the `=` redesign and
    immune to setContent's empty-source-copies-tag pitfall.
***************************************************************************/
extern "C" GroupItem *runStoreField(GroupItem *instr)
{
GroupItem 	*stack = ::opStackOf(instr);
GroupItem 	*value = stack->pop();
GroupItem 	*target = instr->getAttribute("target");
GroupItem 	*dest = target->getGroup();
	dest->copyData(value);
	return 0;
}

/***************************************************************************
    bcString — same firing as bcPrint, but a string statement produces a VALUE
    (aCTionPrinT's opString branch returns it), so push that onto the operand
    stack. Untested by the print POP (the 'p' path); here for the StringXP rule.
***************************************************************************/
extern "C" GroupItem *runString(GroupItem *instr)
{
GroupItem 	*statement = instr->get(2);
GroupItem 	*stack = ::opStackOf(instr);
GroupItem 	*result = ::aCTionPrinT(statement);
	if ( stack )
		if ( result )
			stack->push(result);
	return 0;
}

void Bytecode::run()
{
	return;
}
