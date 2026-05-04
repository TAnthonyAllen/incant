//
//  Bytecode.mm — incant bytecode handlers (Phase 2 step 2b)
//
//  Per-op interpreter handlers, dispatched from incant's interpret() loop
//  via the `interpret` sub-attribute on op GroupItems (registered in
//  XML/WorkingOn/setup under Operators and bcOPs registries). Two-step
//  dispatch: `handler = grup.interpret; handler(grup);` — incant's
//  one-method-per-field invariant means the attribute's method IS the
//  handler.
//
//  Convention (locked in step 2a discussion):
//    * Operands read by named attribute on the instruction GroupItem
//      (op1, op2, cond, target, value, dst).
//    * Return null = implicit-next (interpret() falls through to next sibling).
//    * Return non-null = jump to that instruction next.
//
//  Vreg slots: there aren't any. A "vreg" in the bytecode design is just
//  a GroupItem field being used as a register — `dst->setGroup(result)` is
//  the storage primitive. No special type, no per-action vreg array. The
//  field IS the register. (Everything is a field — same principle that
//  makes incant reflective.)
//
//  Open / verify-on-first-run:
//    * runRET halt semantics — currently returns null (implicit-next),
//      relying on runRET being the last instruction so next-sibling lookup
//      yields nothing. If we need a mid-body halt, introduce a sentinel.
//

#include "Bytecode.h"
#include "GroupItem.h"
#include "GroupRules.h"
#include "GroupControl.h"

// Forward declarations of the existing op handlers we wrap.
extern "C" GroupItem *opGT       (GroupItem *argument, GroupItem *target);
extern "C" GroupItem *opMultiply (GroupItem *argument, GroupItem *target);
extern "C" GroupItem *opAssign   (GroupItem *argument, GroupItem *target);

// ---------- Control-flow handlers (registered in bcOPs) ----------

extern "C" GroupItem *runBR(GroupItem *instr)
{
    // Unconditional branch: jump to instr.target.
    return instr->getAttribute("target");
}

extern "C" GroupItem *runBRZ(GroupItem *instr)
{
    // Branch if zero: read cond, jump to target if zero, else fall through.
    GroupItem *cond   = instr->getAttribute("cond");
    GroupItem *target = instr->getAttribute("target");
    // "Zero" interpretation: a null cond, a count of 0, or a falsy GroupItem
    // (no result from preceding op handler — opGT etc. return trueResult or
    // null, so the natural test is "is cond null/falsy?"). Using getCount()
    // covers numeric zero; falling through to null-check covers the
    // null-result case from comparison ops.
    if ( !cond || !cond->getCount() )
        return target;
    return 0;
}

extern "C" GroupItem *runRET(GroupItem *instr)
{
    // Halt — see file header note on null-return semantics.
    return 0;
}

extern "C" GroupItem *runCall(GroupItem *instr)
{
    // Step 2b stub: real implementation lands when the first test exercises
    // a composite operand like A(B). For testByteCode (no calls), returning
    // null is harmless.
    // TODO: invoke instr.callee with instr.args; store result in instr.dst.
    return 0;
}

// ---------- Operator-shim handlers (registered as interpretMethod on Operators) ----------

extern "C" GroupItem *runGT(GroupItem *instr)
{
    GroupItem *op1 = instr->getAttribute("op1");   // left  operand (target)
    GroupItem *op2 = instr->getAttribute("op2");   // right operand (argument)
    GroupItem *dst = instr->getAttribute("dst");

    // opGT signature: opGT(argument, target). op1 is left/target, op2 is
    // right/argument. Pass (op2, op1) to preserve compareValues(target, arg).
    GroupItem *result = ::opGT(op2, op1);

    if ( dst )
        dst->setGroup(result);
    return 0;
}

extern "C" GroupItem *runMultiply(GroupItem *instr)
{
    GroupItem *op1 = instr->getAttribute("op1");
    GroupItem *op2 = instr->getAttribute("op2");
    GroupItem *dst = instr->getAttribute("dst");

    // Same arg-order rule as runGT: (argument, target) → (op2, op1).
    GroupItem *result = ::opMultiply(op2, op1);

    if ( dst )
        dst->setGroup(result);
    return 0;
}

extern "C" GroupItem *runAssign(GroupItem *instr)
{
    // For assignment the operand naming flips slightly — the destination is
    // the field being assigned to (target), and the value is the right-hand
    // side. opAssign signature: opAssign(argument, target). Pass (value,
    // target) so target := value semantically.
    GroupItem *target = instr->getAttribute("target");
    GroupItem *value  = instr->getAttribute("value");

    GroupItem *result = ::opAssign(value, target);

    // opAssign already mutates target; no separate dst write needed.
    // Some emit patterns may also want the assigned value in a dst slot
    // for downstream use — wire that here if it turns out to matter.
    (void)result;
    return 0;
}
