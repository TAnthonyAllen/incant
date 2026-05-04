//
//  Bytecode.h — incant bytecode handlers (Phase 2 scaffolding)
//
//  Per-op interpreter handlers, dispatched from incant's `interpret()` loop
//  via the `interpret` sub-attribute on op GroupItems (in `Operators` and
//  `bcOPs` registries — see XML/WorkingOn/setup). Each op has an
//  `interpret` field whose method is one of these handlers, so dispatch
//  is two steps: `handler = grup.interpret;` then `handler(grup);` —
//  honouring the one-method-per-field invariant.
//
//  Handler convention (Phase 2 step 2a — STUB BODIES):
//    * Argument: pointer to the instruction GroupItem.
//    * Return:
//        - GroupItem*  — branch target; interpret() jumps to this instruction next.
//        - 0 / nullptr — implicit-next; interpret() falls through to next sibling.
//    * Operands: read by named attribute on the instruction
//                (op1, op2, cond, target, value, dst, ...) per the per-handler
//                operand layout. Exact slot semantics resolved in step 2b.
//
//  Hand-edited (.mm direct, not via Tok) per the current TAWK-autopsy-pending
//  workflow. Will migrate back to .twk once TAWK is fixed.
//

#ifndef Bytecode_h
#define Bytecode_h

#include "GroupItem.h"

extern "C" {

// Control-flow handlers (registered in bcOPs registry)
GroupItem *runBR   (GroupItem *instr);   // unconditional branch to instr.target
GroupItem *runBRZ  (GroupItem *instr);   // branch to instr.target if cond is zero, else fall through
GroupItem *runRET  (GroupItem *instr);   // halt — caller treats null return as "stop"
GroupItem *runCall (GroupItem *instr);   // invoke a callable; result lands in dst

// Operator-shim handlers (registered as `interpret` sub-attribute on Operators entries)
GroupItem *runGT       (GroupItem *instr);   // result = (op1 > op2); store to dst
GroupItem *runMultiply (GroupItem *instr);   // result = (op1 * op2); store to dst
GroupItem *runAssign   (GroupItem *instr);   // target := value

}   // extern "C"

#endif   // Bytecode_h
