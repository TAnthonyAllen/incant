class GroupItem;
//
//  Bytecode.twk — incant bytecode handlers (STACK-FORM)
//
//  Source of truth for the per-op interpreter handlers. Compile with
//  `tok Bytecode.twk` -> Bytecode.mm + Bytecode.h. Replaces the hand-written
//  three-address Bytecode.mm (2026-05-30 stack-form rewrite, Clay's call).
//
//  Dispatched from incant's interpret() loop via the `interpret` sub-attribute
//  on op GroupItems: `handler = grup.interpret; handler(grup)`.
//
//  STACK-FORM contract:
//    * The operand stack is a PLAIN GroupItem field used directly as a stack:
//      field.push(x) appends to its list, field.pop() removes from the end
//      (LIFO) and detaches the node (parent = 0). No embedded Stak object.
//      It hangs off the bcLIST body as the `opStack` attribute; interpret()
//      creates/clears it at entry (incant/bytecode change, landing next).
//      Reached here via opStackOf(instr) -> instr.parent's opStack.
//    * Because push/pop manipulate the list directly (no copy-on-add), a
//      producer must push a FRESH node, never a live bcLIST member.
//    * Producers (bcPushLit, bcPushField) push a value node; consumers
//      (op-shims, bcStoreField) pop. Op-shims pop two, MATERIALIZE a stable
//      result node (never the shared opGT/opMultiply temp), push it. prod is
//      always pushed -- empty / count-0 on a null op result.
//    * The branch target is the ONLY operand carried on the instruction, under
//      the `dst` attribute (emitted inline; named consistently so it survives
//      a future bcOPs->Operators fold). runBRZ/runBR read it via
//      getAttribute("dst").
//    * Return: null  = implicit-next (interpret() falls to next sibling).
//             non-null = branch; interpret() jumps to that instruction.
//

// Dummy class so tok emits Bytecode.mm (the output is named after the class).
// The real content is the extern handlers below.

class Bytecode
{
public:
int dummy;
void run();
};
extern "C" GroupItem *opStackOf(GroupItem *instr);
extern "C" GroupItem *runBR(GroupItem *instr);
extern "C" GroupItem *runBRZ(GroupItem *instr);
extern "C" GroupItem *runCall(GroupItem *instr);
extern "C" GroupItem *runGT(GroupItem *instr);
extern "C" GroupItem *runMultiply(GroupItem *instr);
extern "C" GroupItem *runPrint(GroupItem *instr);
extern "C" GroupItem *runPushField(GroupItem *instr);
extern "C" GroupItem *runPushLit(GroupItem *instr);
extern "C" GroupItem *runRET(GroupItem *instr);
extern "C" GroupItem *runStoreField(GroupItem *instr);
extern "C" GroupItem *runString(GroupItem *instr);
