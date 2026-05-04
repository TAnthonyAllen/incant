//
//  Bytecode.mm — incant bytecode handlers (Phase 2 step 2a SCAFFOLDING)
//
//  Skeleton bodies — every handler returns null (implicit-next "no special
//  next, caller does next-sibling"). Real bodies arrive in step 2b after
//  the operand-layout convention is reviewed.
//
//  The runRET handler returns null too, but its semantic is "halt." That
//  works under the current convention because interpret()'s loop ends when
//  it can no longer find a next instruction; runRET being the last
//  instruction in the body means next-sibling lookup yields nothing.
//  (If we want runRET to halt explicitly mid-body, we'd need a sentinel
//  return value distinct from "fall through." Open question — flag for
//  step 2b.)
//

#include "Bytecode.h"
#include "GroupItem.h"
#include "GroupRules.h"
#include "GroupControl.h"

// Forward declarations of the existing op handlers we wrap.
extern "C" GroupItem *opGT       (GroupItem *argument, GroupItem *target);
extern "C" GroupItem *opMultiply (GroupItem *argument, GroupItem *target);
extern "C" GroupItem *opAssign   (GroupItem *argument, GroupItem *target);

// ---------- Control-flow handlers ----------

extern "C" GroupItem *runBR(GroupItem *instr)
{
    // TODO step 2b: return instr->getAttribute("target");
    return 0;
}

extern "C" GroupItem *runBRZ(GroupItem *instr)
{
    // TODO step 2b: read instr->getAttribute("cond"), test for zero,
    //               return instr->getAttribute("target") if zero, else 0.
    return 0;
}

extern "C" GroupItem *runRET(GroupItem *instr)
{
    // TODO step 2b: confirm null-return halt semantics (see file header note).
    return 0;
}

extern "C" GroupItem *runCall(GroupItem *instr)
{
    // TODO step 2b: invoke callee with args, store result in instr->getAttribute("dst").
    return 0;
}

// ---------- Operator-shim handlers ----------

extern "C" GroupItem *runGT(GroupItem *instr)
{
    // TODO step 2b: see preview body in chat; this stub returns null pending review.
    return 0;
}

extern "C" GroupItem *runMultiply(GroupItem *instr)
{
    // TODO step 2b: same shape as runGT, calling ::opMultiply.
    return 0;
}

extern "C" GroupItem *runAssign(GroupItem *instr)
{
    // TODO step 2b: read value + target attrs, call ::opAssign(value, target).
    return 0;
}
