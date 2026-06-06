#include <Cocoa/Cocoa.h>
#include <string.h>
#include <stdio.h>
#include "OCroutines.h"
#include "GroupItem.h"
#include "GroupRules.h"
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
    bcBR — unconditional branch to the `dst` label.
***************************************************************************/
extern "C" GroupItem *runBR(GroupItem *instr)
{
	return instr->getAttribute("dst");
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
	if ( !cond || !cond->getCount() )
		return instr->getAttribute("dst");
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

/***************************************************************************
    bcPushField — push the referenced field's value. The emit folds the
    field's value onto the instruction as data (gXpress: emitBC(bcPushField=
    child)), so a clean copyData lifts just that value onto the stack — never
    the instruction's structure (tag, interpret child). When the emit later
    carries a real field reference, this reads + pushes the field's CURRENT
    value instead.
***************************************************************************/
extern "C" GroupItem *runPushField(GroupItem *instr)
{
GroupItem 	*stack = ::opStackOf(instr);
GroupItem 	*value = new GroupItem("fld");
	value->copyData(instr);
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

void Bytecode::run()
{
	return;
}
