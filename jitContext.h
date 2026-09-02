// jitContext.h — Phase JIT codegen state (LLVM 22). Hand-written C++ — NOT tok-processed.
// JitData mirrors OLDtawkDoNotTouch/Tokf/JitData.h (the proven pattern): a global
// struct with fully-qualified llvm:: pointer fields + get/set methods. See
// docs/jitDesign.md (codegen) and docs/jit.md (frame/calling convention).
#ifndef JITCONTEXT_H
#define JITCONTEXT_H

#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/Value.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Support/TargetSelect.h"
#include "llvm/ExecutionEngine/Orc/LLJIT.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Transforms/Utils/Mem2Reg.h"
#include "llvm/Support/raw_ostream.h"
#include <memory>
#include <vector>
#include <string>

// gParseRecordArmed — genParse's in-fixture ParsE-record switch (GX-6), set by
// the `recordParse` command and read by `genParse`, both in genParse.rtn. It
// lives in THIS header and not in that file because tok relocates a file-scope
// `-% %-` passthrough to the END of the generated .mm, so a static declared
// there is emitted AFTER both of its users ("use of undeclared identifier").
// This header is hand-written and NOT tok-processed, so the declaration
// survives a retok — bear-trap #5 drops #include lines and anything else tok
// regenerates. Nothing to do with the JIT; it is here for the retok property.
static int gParseRecordArmed = 0;

// The builder the emitters write into. Set by the compile driver before walking
// an action body; grabbed by each emitter in a one-line -% %- (the only passthrough
// the otherwise tok-native emitters need). C++17 inline var → one definition across
// TUs, header-defined so it never reaches GroupRules.h.
inline llvm::IRBuilder<> *gJitBuilder = nullptr;

// The SSA value the action body last produced. The jitting gate (aCTionExpressioN)
// emits into gJitBuilder and leaves the running result here; the compile driver
// (jitRunAction) reads it after the body walk to emit the function's CreateRet.
// Single-result for the Phase-1 straight-line proof; widens to per-field rebox later.
inline llvm::Value *gJitResult = nullptr;

// Stack of pending "endif" merge blocks for the gIF emitter. jitIfBegin pushes
// the endif block (after emitting the CreateCondBr that splits to the then
// block); jitIfEnd branches the finished then block to it and resumes insertion
// there, popping. A stack (not a scalar) so nested ifs nest correctly. Header-
// inline like gJitBuilder so it never reaches GroupRules.h.
inline std::vector<llvm::BasicBlock*> gIfEndBlocks;

// Stack of pending "else" blocks, parallel to gIfEndBlocks and pushed/popped in
// lockstep with it (2026-07-31, the else arm). jitIfBegin now ALWAYS creates
// three blocks -- then, else, endif -- and branches the condition to then/else.
// jitIfElse closes the then arm and resumes in the else block; jitIfEnd closes
// whichever arm is current and resumes at endif.
//
// ALWAYS three, even when the source has no `else`, and that is deliberate: an
// if-without-else then emits an EMPTY else block that branches straight to
// endif. That is valid IR, it costs one branch that LLVM folds, and it means
// there is exactly ONE block topology instead of two -- so the no-else case
// cannot drift away from the with-else case, which is precisely how the else arm
// came to be missing in the first place.
inline std::vector<llvm::BasicBlock*> gIfElseBlocks;

// LOOP BLOCK TOPOLOGY (2026-07-31, rung J3). The loop analog of gIfElseBlocks
// /gIfEndBlocks, pushed and popped in lockstep so nested loops nest.
//
//   preheader -> br cond
//   cond:  <condition sub-walk emits HERE>  ; br i1 %c, body, exit
//   body:  <body sub-walk emits HERE>       ; br cond      <-- back edge
//   exit:  (emission continues here)
//
// ⚠ THE CONDITION IS EMITTED INSIDE `cond`, WHICH IS WHY jitLoopBegin RUNS
// BEFORE THE CONDITION WALK -- the opposite order from gIF, where the condition
// is emitted into the CURRENT block and jitIfBegin then splits. A loop's
// condition must re-execute every iteration, so it has to live in a block the
// back edge returns to. Get this backwards and the condition is evaluated once,
// before the loop, and the loop is infinite or never runs.
inline std::vector<llvm::BasicBlock*> gLoopCondBlocks;
inline std::vector<llvm::BasicBlock*> gLoopExitBlocks;

// The loop BODY block, needed only by `do` -- a while's back edge targets cond,
// a do's targets body. Pushed/popped in lockstep with the other two.
inline std::vector<llvm::BasicBlock*> gLoopBodyBlocks;

// SHORT-CIRCUIT TOPOLOGY (2026-08-11, the AND/OR rung -- docs/andOrRung.md
// section 3 part 2). Two blocks, not three, and ONE SLOT:
//
//   <left arm emits into the current block>
//   store <short-circuit answer> -> slot     ; 0 for AND, 1 for OR
//   br i1 %left, scRhs, scEnd                ; AND: true evaluates the right
//   br i1 %left, scEnd, scRhs                ; OR:  false evaluates the right
//   scRhs: <right arm emits HERE>  store %right -> slot   br scEnd
//   scEnd: %out = load slot
//
// ⚠ NO BLOCK FOR THE SKIPPED PATH, and that is the point rather than a saving.
// PRE-STORING the short-circuit answer before the branch means the skipped arm
// needs no block, so there is no second place where a "false" could be written
// and no way for the two writers to disagree. The whole construct has ONE
// writer per path into ONE location.
//
// ⚠ NO PHI IS WRITTEN, per the never-write-a-phi rule. This DOES allocate --
// unlike the gIF emitter, whose comment correctly notes it has no allocas
// because a field slot is a baked absolute address. An AND/OR result is an
// EXPRESSION TEMPORARY with no field behind it, so it has no address to store
// to and genuinely needs a slot; mem2reg then inserts the phi. That is the
// documented resultSlotLanded pattern, and the difference from gIF is worth
// stating because the gIF comment would otherwise read as a blanket claim.
//
// Stacks, not scalars, so nested/chained conjunctions nest -- `a AND b AND c`
// builds two of these, and the inner must pop before the outer reads.
inline std::vector<llvm::BasicBlock*> gScEndBlocks;
inline std::vector<llvm::Value*>      gScSlots;

// THE RESULT SLOT (2026-07-31, Tony's ruling). An i32 alloca in the function's
// entry block holding the action's value. Every statement stores to it; the cap
// loads it and rets. gJitResult-as-last-value retires.
//
// WHY A SLOT AND NOT A PHI: the ruling is that the compiled action returns what
// the interpreted action returns, and the interpreted rule is "the value of the
// LAST EXECUTED STATEMENT" -- so on a two-armed if the answer differs per path
// and has to be merged. RESULTS ARE MEMORY, exactly as fields are: each arm
// STORES and the exit LOADS, and the merge is the memory location. No phi is
// written, and unlike the field slots this one IS an alloca, so mem2reg can
// promote it and insert the phi itself if it wants to.
//
// ⚠ It is the FIRST alloca this emitter has ever produced. The standing note
// that "mem2reg has nothing to promote" was true of field slots (baked absolute
// addresses) and is no longer true of the function as a whole.
inline llvm::Value *gJitResultSlot;

// Did ANY statement commit a value this run? Set by jitStoreResult, reset by
// jitRunAction. This replaces the old "is gJitResult non-null at the end" test,
// which the result slot falsified: a bracketing emitter (gIF, and later the
// loops) COMMITS its arms and then clears gJitResult on purpose, so a null
// in-flight value at the end became the NORMAL case for any action ending in
// control flow -- and the old guard read it as "the gate never fired" and
// bailed before emitting the return.
inline bool gJitEmitted;

// THE COMPILED FUNCTION, kept so it can be FIRED AGAIN without recompiling
// (2026-07-31, the jitLadder). Every rung must compile ONCE and fire TWICE at
// different inputs, because a right answer is not proof the COMPILED code
// produced it: under jitting the interpreter executes the body for real at emit
// time, so a naive end-to-end POP can go green on an emit-time side effect with
// the compiled function returning a baked constant -- right answer, wrong
// universe, exit 0 throughout. If the second fire tracks an input changed AFTER
// emission, the computation happened at RUN time. Nothing else proves it.
inline int (*gJitLastFn)() = nullptr;

// Degrade count as a readable global rather than a function-local static, so a
// rung can ASSERT it. Zero is the claim "this rung's constructs are all covered
// -- nothing silently fell through to emit-time interpretation". Still a C++
// static and not a node slot, for CLAIM KANT-4's reason: GroupBody's value slots
// are one union and a counter parked in gCount destroys whatever shares it.
inline int gJitDegradeCount = 0;

// THE SLOT COUNTER (step 2, 2026-08-17). Counts emissions that went through an
// op's gJitEmitter slot rather than through its `if jitting` gate inside the
// interpreter op.
//
// ⚠ IT EXISTS BECAUSE THE MIGRATION IS VALUE-TRANSPARENT AND THEREFORE INVISIBLE
// TO EVERY VALUE ASSERTION. A migrated `*` and an unmigrated `*` emit the same
// IR and return the same answer -- that is the whole point of a presence-gated
// fork -- so a rung that checks the product cannot tell whether the slot fired,
// and would stay green with the registration deleted. This counter is the
// discriminator, and it is a COUNT rather than a message for H4's reason: an
// absence check on a trace line passes the day someone removes the line.
inline int gJitSlotCount = 0;

// THE UNARY REFUSAL COUNT (step 2 hardening, 2026-08-17). runOP's fork accepts
// any node carrying a gJitEmitter, and its seed gate spans isOperator AND
// isUnary -- so a unary op given a slot would be dispatched through a path that
// has never had an op-one-grade specimen. Nothing but convention prevented that.
//
// ⚠ IT IS A COUNT AND A LOUD LINE, NOT A SILENT SKIP, and that is KE-4's posture:
// REFUSALS ARE COUNTED, QUIET ACCEPTANCES ARE COUNTED BY NOTHING. A guard that
// merely declined would be indistinguishable from a guard that was never reached,
// which is the whole failure class this project keeps paying for.
//
// RETIRE THIS WHEN UNARY OPENS with its own specimen -- see the parked section of
// docs/jitSlotMigration.md. Retiring it means deleting the guard AND this counter
// AND the rung row that asserts it, by mapping, not by letting the line vanish.
inline int gJitSlotUnaryRefused = 0;

// THE COMPILE COUNTER (Clay SEQ 27 v2, 2026-08-04). Compile-on-first-fire is the
// ruling, so "did the second fire recompile?" is the POP's central question and
// it needs an instrument rather than an inference. Incremented ONCE per
// jitRunAction compile and printed with its VALUE on every fire (H4:
// presence-with-value, never absence-of-message). A check that asserted "no
// second compile happened" by the absence of a message would go green the day
// the message was deleted; asserting `count == 1` across two fires cannot.
inline int gJitCompileCount = 0;

// THE EMITTED IR, captured as TEXT for the `JiT` attribute. Captured in
// jitRunAction immediately BEFORE addIRModule, and that placement is forced, not
// stylistic: addIRModule std::move()s the module and the context into the JIT, so
// after that line there is no module left to print. Post-mem2reg, matching the
// INCANT_JIT_DUMP=1 dump, because what is recorded should be what RUNS.
// ⚠ RECORD, NOT DISPATCH. Nothing reconstructs a function pointer from this
// string. It exists for persistence and inspection, and Clay SEQ 27 v2 rules that
// boundary explicitly: dispatch is only ever through rStuff.jitMethod.
inline std::string gJitLastIR;

// THE PRINT BUFFER IN FLIGHT (2026-08-04). jitEmitPrint brackets a print
// statement: one emitted call to jitPrintBegin acquires the buffer, one emitted
// call per item appends into it, one emitted call to opPrint sinks it. The
// buffer is an SSA value produced by the first call and consumed by the rest, so
// it has to survive between the emitter's own statements -- exactly the job
// gJitBuilder and the block stacks already do. A C++ local could not, because
// the walk between them is tok code, not one passthrough block.
// Cleared by jitEmitPrint on the way out (E1: nothing left in flight).
inline llvm::Value *gJitPrintBuf = nullptr;

// THE RESULT NODE IN FLIGHT (2026-08-05). A SECOND CHANNEL, on purpose, and the
// reason is one-channel-one-meaning rather than convenience: gJitResult means
// "the i32 value in flight", and "the GroupItem the last emitted op produced" is
// a DIFFERENT FACT. Conflating them is how a string accessor printed as a number.
//
// WHY IT EXISTS. opDot unboxes its result to a count, which is right for
// noPrinT/isMethoD and wrong for taG -- and the emitter CANNOT KNOW WHICH:
// the gate returns before opDot's interpreted body, so nothing populates
// tempField at emit time, and the accessor node's own datA describes the
// accessor, not its result. The type is a RUN-TIME fact.
// So the print path does not try to type it. It takes the NODE and hands it to
// appendGroup's existing pointer entry, which formats by the node's real datA at
// run time -- the same call the interpreted walk makes.
// ⚠ AND THE STALE-FRAME DISEASE CANNOT APPLY HERE, which is what makes the
// pointer safe in this one case: this node is FRESHLY COMPUTED by the emitted
// call, not a field whose live value is sitting in an unflushed frame slot.
inline llvm::Value *gJitResultNode = nullptr;
// ⚠ A SECOND CHANNEL, NOT A CLEVERER TEST OF THE FIRST (SEQ 138). gJitResultNode
// non-null means "a node value is in flight"; it does NOT mean "the thing being
// assigned is a node", because the slot survives its consumer. This flag says the
// latter and only the latter, is raised by jitEmitDeref, and is cleared by the
// consumer that acts on it. One channel, one meaning.
inline bool gJitLastIsNode = false;

// Nodes seeded with JitData during the current compile. JitData is transient (one
// compile, into a per-run LLVMContext that jitRunAction destroys), but the field/
// literal GroupItems that carry it persist (BDWGC). The runOP seeding gate skips a
// node that already has jitData (bear-trap #9: never re-seed an inner op-result),
// and that same guard would make a STALE jitData from a PRIOR run look "already
// seeded" — so the driver must null these between runs, else run 2 reads a Value*
// from run 1's freed context. Recorded by jitSeedField/jitSeedLiteral; reset at the
// top of jitRunAction. (The old jitXpress re-seeded unconditionally, so it never
// needed this; the #9 guard makes it necessary.)
class GroupItem;
inline std::vector<GroupItem*> gJitSeeded;

// gKantLabel / gKantFrom — THE KANT PARSE FRAME (SEQ 54, 2026-08-11). Nothing to
// do with the JIT; they are here for the same retok property gParseRecordArmed is,
// and that reason is worth not re-learning: a file-scope `-% %-` passthrough in a
// .rtn is RELOCATED BY TOK TO THE END of the generated .mm, so a static declared
// there is emitted AFTER its users and every use is "undeclared identifier". A bare
// tok-level declaration at file scope is simply dropped. Measured both ways on
// 2026-08-11; this header is hand-written and not tok-processed, so it survives.
//
// WHAT THEY ARE. Tony ruled 2026-08-11 that THE MARK NEVER CROSSES into kant: a
// position is not a value, so it cannot travel as kant data at all, and keeping it
// here keeps Invariant R with one writer (RuleStuff.twk:657 — leaveRule/leaveAlt
// "and nowhere else"). parseViaKant saves both around the body and restores them
// after, so the C++ call stack IS the frame stack and nested rules cost nothing.
// The kant body names a term; the frame owns position and destination.
static GroupItem *gKantLabel = 0;
static char      *gKantFrom  = 0;
static GroupItem *gKantRule  = 0;

// gNewParseInFlight — ABOLISHED 2026-08-29, WITH THE TWO-CHANNEL WORLD IT
// GUARDED. Obituary kept deliberately: it was a correct answer to a question
// that has since stopped being asked, and a reader who finds its name in the
// git history or in a 2026-08-25 seal should land here rather than nowhere.
//
// WHAT IT WAS. A file-scope int raised by parseRule around the generated
// body's run and read by runRuleAction, saved and restored in C++ locals so
// the call stack was the frame stack. It gated captureSpan, because
// runRuleAction is NOT reached only by the new parse — aCTionBrancH
// (GroupRules.mm:157) and runOP both dispatch a rule action through gMethod
// and land there, and on those roads rStuff.hereAt is whatever the last parse
// left behind, so a stale start against a live atRuleMark yields a plausible
// span written silently into the label the action is about to read.
//
// WHY IT IS GONE, and it is not because the hazard stopped existing. It is
// because the hazard's PREMISE did. Those roads reach a rule action by finding
// it in gMethod; after the eviction there is nothing in gMethod to find, and
// the only road to a rule action is builtinActoR through runRuleAction, from
// inside its own parse. The guard was making an unwanted road safe. The
// eviction deletes the road.
//
// AND THE SPELLING WAS THE SMALLER HALF OF THE OBJECTION. Tony objected to the
// -% escape pockets it forced at both ends before anyone noticed the gate
// could be structural. runRuleAction now asks pMethod — does THIS FIELD carry
// a builtinParsE — which is a property of the subject rather than of time, so
// it needs no global, no save, no restore, and no escape. The lesson worth
// keeping is that an awkward spelling was the visible symptom of a guard asking
// its question about the wrong thing.

// THE FRAME (Increment 1, 2026-08-01). The action's own field list IS the frame
// schema -- (isArgument || isLocal) && !noPrint -- which is not a new invention:
// it is the exact predicate saveLocalFields/restoreLocalFields have walked in the
// interpreter since the beginning (GroupActions.rtn). INHERIT THE SCHEMA, NOT THE
// BUG: the enumeration is taken, the save/restore discipline is not.
//
// Holds the nodes given a frame alloca by this compile's prologue, in walk order,
// so the epilogue can store them back. A subset of gJitSeeded -- every frame local
// is seeded (the prologue IS its seed), but literals and globals are not framed.
// Cleared at the top of jitRunAction alongside gJitSeeded.
//
// ⚠ INCREMENT 1 IS NOT INDEPENDENTLY PROVABLE, and the rung says so itself.
// Without recursion, allocas-for-locals is BEHAVIOUR-NEUTRAL -- the same answers
// come out, because one activation's alloca and one field's storage hold the same
// value at every observable point. What a structure rung can assert is that the
// allocas EXIST and that no local kept a baked address, plus a value-regression
// net. THE PROOF IS J-R: per-call storage only becomes observable when two calls
// are live at once, and depth-1 passes on aliased slots where depth-N cannot.
// ⚠ KEYED ON THE FIELD'S STORAGE ADDRESS, NOT ON THE NODE, AND THAT IS THE
// FINDING OF INCREMENT 1. The first cut keyed on GroupItem* and pre-seeded each
// framed node's jitData. It framed nothing: MEASURED with a node-identity trace,
// the action's field-list entry for a local is a DIFFERENT NODE from the ones the
// runOP tree references, and each OCCURRENCE in the body is its own node again --
// `jfTmp` framed at 0x10243e080, then baked twice at 0x102452540 and 0x102453780.
// All three resolve to the same storage, which is exactly why the baked-address
// model never had to care about node identity.
//
// So the frame cannot be keyed on identity the emitter does not preserve. It is
// keyed on `home` -- the address of the field's gCount/gNumber -- which is the
// one thing every occurrence agrees on.
struct JitFrameSlot {
    void        *home;   // &gCount or &gNumber -- the identity that survives
    llvm::Value *slot;   // the alloca
    llvm::Type  *ty;
};
inline std::vector<JitFrameSlot> gJitFrame;

// THE FUNCTION AND ACTION CURRENTLY BEING COMPILED. Needed so a SELF-CALL can be
// emitted as a real `call` instead of being inlined by emit-on-walk.
// ⚠ WHY A CALL IS MANDATORY HERE AND OPTIONAL EVERYWHERE ELSE: a non-recursive
// call INLINES correctly today (measured, incant/jitJC -- fire 2 tracks the
// input and there is no `call` in the IR). A SELF-call cannot, and not merely
// because it would not terminate: the re-walk reuses nodes that already carry
// jitData from the enclosing pass, and jitEmitCompare has written its i1 RESULT
// into the target node's jitValue. Measured -- the second pass sees
// `jrN type=[i1]` against a literal i32 and LLVM asserts. That is one channel
// carrying two meanings (the field's value and the last op's result), and the
// cure is a second channel, not a cleverer test: emit a CALL and stop re-walking.
class GroupItem;
// THE INLINE STACK (2026-08-05). gJitCurrentAction names the action the COMPILED
// FUNCTION was built for; this names the actions currently being INLINED INTO it.
// The distinction is the whole point: a non-recursive call inlines (emit-on-walk
// re-executes the callee's BlocK into the caller's builder), so while that is
// happening the "current action" for self-detection purposes is the CALLEE, not
// the function's own action.
// ⚠ WITHOUT IT, RECURSION INSIDE AN INLINED CALLEE IS NOT RECOGNISED AS
// RECURSION. It is compared against the wrong action, fails the self-test, and
// INLINES AGAIN -- over nodes that already carry jitData from the enclosing
// pass. jitEmitSelfCall's own header predicted the consequence before anyone hit
// it: "the condition target's jitValue is by then an i1 (jitEmitCompare's
// result), so the second pass asserts inside LLVM."
// Measured 2026-08-05, identical body both ways: fired DIRECTLY (so the guard
// matches) it compiles clean; driven through a one-line wrapper it dies on
// "Both operands to ICmp instruction are not of the same type".
// Keyed on GroupBody, not the node -- storage is identity, nodes are
// occurrences, the same finding Increment 1 and jitEmitSelfCall both record.
//
// ⚠ IT IS A STACK MATCHED BY "ANY OF THEM", AND THAT MUST NOT BE "SIMPLIFIED"
// TO A SINGLE SLOT. Matching any entry makes MUTUAL recursion correct by
// construction as well as self-recursion: A -> B -> A resolves as a self-call at
// the third frame because A is still on the stack. A one-slot version would see
// only B, misclassify the call to A as ordinary, and inline it again -- the same
// defect this exists to fix, wearing a longer cycle.
// That property is not incidental: genParse's grammar rules reference each other
// constantly, so mutual recursion is the NORMAL case on the road ahead, and this
// fix bought more than the bug cost. Keep the stack.
class GroupBody;
inline std::vector<GroupBody*> gJitInlining;

// ================== E2: THE INLINED CALLEE'S OWN EXIT (2026-08-09) ============
// ⚠ THE WHOLE OF E2 IS "AN INLINED REGION NEEDS AN EPILOGUE OF ITS OWN."
// A `return` inside an inlined callee must terminate THE INLINED REGION. Branching
// to gJitEpilogueBB there returns from the CALLER -- a wrong answer wearing valid
// IR -- which is why jitEmitReturn refused the case outright until now.
//
// ONE FRAME PER INLINE, PARALLEL TO gJitInlining and pushed/popped by the same two
// functions, so the two stacks cannot drift. `exitBB` is created UNPARENTED and is
// inserted into the function only on FIRST USE:
//
// ⚠ THAT LAZINESS IS AN H7 REQUIREMENT, NOT AN OPTIMISATION. An inlined callee
// with no return must emit BYTE-IDENTICAL IR to what it emits today, or every
// currently-green rung's topology moves for a reason unrelated to its subject --
// H3's assertion-that-cries-wolf, manufactured on purpose. `used` is the second
// channel that makes "did any return actually target this" answerable, rather than
// inferring it from the block having predecessors.
//
// THE VALUE CHANNEL IS THE RESULT SLOT, and it needs no phi for the same reason
// jitStoreResult's header already gives for a two-armed if: THE MERGE IS THE MEMORY
// LOCATION. Every return stores before it branches, the fall-through path has
// stored via the ordinary per-statement commit, so the load at exitBB reads
// whichever path ran.
struct JitInlineFrame {
    llvm::BasicBlock *exitBB = nullptr;
    bool              used   = false;
};
inline std::vector<JitInlineFrame> gJitInlineFrames;

inline GroupItem       *gJitCurrentAction = nullptr;
inline llvm::Function  *gJitCurrentFn     = nullptr;

// ================= THE S1 EXTRACTION'S SEAM (2026-08-05) =====================
// jitBuildFunction builds ONE function start to finish -- shell, entry block,
// result slot, prologue, body walk, epilogue, ret, verify, mem2reg -- and
// jitRunAction owns everything module-scoped either side of it (the engine, the
// context, the module, the IR capture, addIRModule, lookup, call).
//
// ⚠ WHY THESE THREE ARE GLOBALS AND NOT PARAMETERS, WHICH LOOKS LIKE THE WRONG
// CHOICE UNTIL YOU TRY IT: jitBuildFunction is a tok extern, and a tok-extern
// signature carrying an llvm type POISONS THE GENERATED HEADER -- the same
// constraint JitContext's own comment records, and the reason jitEngine() hands
// back a void*. So the routine takes `GroupItem action` and returns `int`, and
// the two llvm objects it cannot name in its signature travel here.
// The brief's rule was "parameters over globals only where the extraction forces
// it". This is where it forces it.
inline llvm::LLVMContext *gJitCtx    = nullptr;   // owned by jitRunAction
inline llvm::Module      *gJitModule = nullptr;   // owned by jitRunAction

// THE FUNCTION jitBuildFunction JUST FINISHED, and the name it was given.
// ⚠ THE NAME IS CARRIED, NOT RECONSTRUCTED, because S4's whole point is that the
// driver is looked up BY NAME rather than by being the last one created. With one
// function those are the same string; with two they are not, and "correct by
// position" is exactly the accident rung JC is currently green on.
inline llvm::Function    *gJitBuiltFn = nullptr;
inline std::string        gJitBuiltName;

// ============ THE CALLEE MAP (S3, build-on-discovery, 2026-08-05) ============
// ⚠ THIS MAP IS THE PREDICATE, and that is the ruling rather than an
// implementation detail. At every emit site the question is "IS THERE A Function*
// FOR THIS CALLEE'S groupBody" -- not "is the recursive flag set", which misses
// A->B->A and is cleared at run time by GroupActions.rtn:587, and not "is it on
// the inline stack", which is only answerable at the INNER self-call, by which
// time the enclosing function is half-built and there is no "before the driver"
// left to build anything in front of.
//
// The map is populated BY the inline-stack test, at discovery. So the correct
// predicate still does the finding; the map is what makes its answer available
// EARLY, at the outer call, where a decision can still be acted on.
//
// KEYED ON GroupBody, like every other identity in this file: storage is
// identity, nodes are occurrences. The GroupItem is carried alongside because
// jitBuildFunction needs a node to walk, not because it identifies anything.
// ⚠ NOTE NEITHER POINTER IS DEREFERENCED HERE -- both classes are only
// forward-declared in this header, and the find below is a pointer compare. Keep
// it that way; a deref would drag GroupItem.h into every JIT translation unit.
//
// CLEARED PER COMPILE by jitRunAction: an llvm::Function belongs to the Module,
// and the Module is moved into the JIT and destroyed at the end of every compile.
// A surviving entry would be a pointer into a dead module wearing the shape of a
// cache hit.
struct JitFnSlot { GroupBody *body; GroupItem *action; llvm::Function *fn; };
inline std::vector<JitFnSlot> gJitFnMap;

inline llvm::Function *jitFnMapFind(GroupBody *b) {
    for (JitFnSlot &s : gJitFnMap) if (s.body == b) return s.fn;
    return nullptr;
}

// DISCOVERED, NOT YET BUILT. An inlined callee found calling itself; the enclosing
// function is about to be discarded and this is what the rebuild must build first.
struct JitPending { GroupBody *body; GroupItem *action; };
inline std::vector<JitPending> gJitNeedOwnFn;

inline bool jitPendingHas(GroupBody *b) {
    for (JitPending &p : gJitNeedOwnFn) if (p.body == b) return true;
    return false;
}

// ============ THE EPILOGUE BLOCK (item 2, the return emitter, 2026-08-05) ====
// ⚠ THE EPILOGUE USED NOT TO BE A BLOCK AT ALL. It was a run of stores emitted
// into whatever block the body walk happened to end in, followed by CreateRet --
// which is correct for exactly one control-flow shape: fall off the end. A
// `return` has to LEAVE from somewhere else, and it cannot duplicate the frame
// writeback at every exit without the two copies drifting. So the epilogue
// becomes a real block that every exit BRANCHES to, and the frame writeback and
// the ret live there once.
//
// ⚠ ONE NEW GLOBAL, AND THE BRIEF SAID NONE -- FLAGGED RATHER THAN SMUGGLED.
// Making the epilogue reachable from a return needs the emitter to name it, and
// the only two ways are this pointer or a lookup by block name. The pointer wins
// on the project's own grounds: it is exactly parallel to gJitResultSlot and
// gJitCurrentFn, which are already per-function globals set by jitBuildFunction
// and cleared between functions, whereas a stringly-typed lookup can silently
// find nothing and would be a second mechanism for the same fact.
//
// Created WITHOUT a parent so it can be appended AFTER every body block, which
// costs nothing and makes the dumps read in execution order.
inline llvm::BasicBlock *gJitEpilogueBB = nullptr;

// SET BY DISCOVERY, READ BY THE BUILD LOOP. The function currently under
// construction is now known to be wrong and must be erased rather than finished
// into the module -- so this is not an error channel, it is "start over knowing
// one more thing". A SECOND CHANNEL on purpose: "a discovery happened" is a
// different fact from "the build failed", and jitBuildFunction's return code
// already carries the second one.
inline bool gJitRestartNeeded = false;

// Look a field's storage up in the current frame. Returns null when the field is
// a GLOBAL, which is the common case and the correct one -- globals keep baked
// addresses and immediate store-through (Part III's phase scope).
inline JitFrameSlot *jitFrameFind(void *home) {
    for (JitFrameSlot &f : gJitFrame) if (f.home == home) return &f;
    return nullptr;
}

// Binary-op selector for jitEmitBinary — readable names, not magic ints. Each
// arithmetic opMethod's jitting gate passes one of these; the int/float variant
// of the actual LLVM instruction is picked inside jitEmitBinary from operand type.
enum jitOp { jitAdd, jitSub, jitMul, jitSDiv };

// Compare-op selector for jitEmitCompare — the relational sibling of jitOp,
// same style and same home. jitEQ/jitNE are sign-agnostic (ICmp EQ/NE, FCmp
// OEQ/ONE); the ordered four resolve to signed-int (ICmp SLT/SLE/SGT/SGE) on
// the integer path and ordered-float (FCmp OLT/OLE/OGT/OGE) on the double path.
// The emitter yields an i1, distinct from jitOp's operand-typed result.
enum jitCmp { jitEQ, jitNE, jitLT, jitLE, jitGT, jitGE };

// Unary-op selector for jitEmitUnary — ++/-- write back in place; jitNeg
// (unary minus) is value-producing: negate the operand, NO store-back.
enum jitUnary { jitInc, jitDec, jitNeg };

// Per-field JIT state, hung on the GroupItem node during emission (the Emitter.twk
// JitData pattern). Transient: meaningful only while an action is being compiled.
class JitData {
public:
    llvm::Value *jitSlot;    // the alloca for this field (set in prologue)
    llvm::Value *jitValue;   // current SSA value (load/store traffic)
    llvm::Type  *jitType;    // LLVM type for this field (set at gate check)
    llvm::Value *getJitter()              { return jitValue; }
    void         setJitter(llvm::Value *v){ jitValue = v; }
    JitData() : jitSlot(0), jitValue(0), jitType(0) {}
};

// Per-action emission context. C++-internal — never appears in a tok-extern
// signature (that would poison the generated header). Reached from emitters via a
// file-static current-context pointer, not passed as a parameter.
//
// ⚠ RESERVED FOR THE FRAME-MODEL ARC; DO NOT ADOPT PIECEMEAL. Declared and used
// by NOTHING as of 2026-08-05 (verified by grep: two hits, both in this file).
// The sixteen file-scope globals above are the live mechanism, and the S1
// extraction below deliberately did NOT migrate them -- a lift, not a migration,
// because a half-migrated context is two mechanisms for one fact, which is the
// one-channel-one-meaning failure this project has now paid for four times.
// Adopt it whole, in the frame-model arc, or leave it alone.
class JitContext {
public:
    llvm::LLVMContext &ctx;
    llvm::IRBuilder<> &builder;
    llvm::Function    *fn;        // the function being built
    llvm::BasicBlock  *entryBB;   // entry block (allocas live here)
    bool               ok;        // cleared on any emit error → fall back

    JitContext(llvm::LLVMContext &c, llvm::IRBuilder<> &b)
        : ctx(c), builder(b), fn(0), entryBB(0), ok(true) {}
};

// jitInitOnce() / jitEngine() are emitted by jitEmitters.rtn as extern "C"
// (tok generates their prototypes in GroupRules.h). jitEngine() returns the
// llvm::orc::LLJIT* as void* to keep its tok-extern signature header-clean.

// ---------------------------------------------------------------------------
// THE COMPILE CENSUS — Tony's ruling 2026-08-26 (tally-then-exit).
//
// Two counters, not one, because a tally is only readable beside the
// population it came out of: "3 refused" means nothing without "of how many".
// ATTEMPTED counts every field that reached compile() carrying a body;
// REFUSED counts those processCode would not parse.
//
// ⚠ IT LIVES IN THIS HEADER FOR ONE MECHANICAL REASON, not a design one: tok
// honours a -% passthrough only INSIDE a function body, so a .rtn cannot
// declare a file-scope C++ global at all. gNewParseInFlight above was the
// standing precedent for exactly this; it was abolished 2026-08-29 and its
// obituary now holds that slot, so this is the last resident of the idiom. It
// is not JIT machinery and does not belong to this header's subject; move it
// the day a hand-written header for runtime globals exists.
//
// ⚠ NOT AN INCANT FIELD, DELIBERATELY. An incant field would be visible to the
// very grammar this road rewrites, and a census that can be read — or written
// — by its own subject is not a census.
// ---------------------------------------------------------------------------
// ===========================================================================
// gNoUnwrap -- THE MIGRATION SWITCH for the no-auto-unwrap flip, 2026-08-30.
//
// ONE GATE, governing every retiring line in one motion: runOP's two unwraps,
// runShortCircuit's two, the three `&& !arg.isArgument` exemptions, and the
// wrapper's transparency dependence at both bind sites. There is deliberately
// no per-site flag -- a half-flipped state is exactly what the two-half law
// forbids, and a single int cannot express one.
//
//   0  LEGACY   auto-unwrap live, argument binds by GROUP (the wrapper)
//   1  FLIPPED  no auto-unwrap, argument binds by BODY
//
// ⚠ THE FLIP-BACK IS THIS ONE LINE, which is the whole point of the switch:
// if certification breaks, this becomes 0 and the stroke closes as measurement
// rather than as failure, with nothing partial shipped.
//
// ⚠ OBITUARY PRE-REGISTERED, per standing scaffolding doctrine: this switch
// RETIRES IN THE MIGRATION'S CLOSING STROKE, together with the dead code its
// legacy arm holds. It is a probe arm with its death written down in advance --
// NOT a gNewParseInFlight resurrection, which was a temporal guard with no
// retirement plan. When the legacy arm is deleted, delete this too.
static int gNoUnwrap = 0;

// ⚠ THE EMITTED PATH'S CHANNEL BRACKET (F-45, Tony SEQ 129). runAction saves the
// argument attribute's previous gGroup/data pair across its own processAction
// call and restores after; the emitted path spans THREE functions, so the state
// cannot live in a local and needs a stack.
//
// ⚠ WHY A PENDING SLOT AND NOT A PUSH IN jitBindArgRT. The emitter's order is
// bindArg -> saveFrame -> selfcall -> restoreFrame, and bindArg is emitted ONLY
// `if (argument)` while the frame pair is emitted UNCONDITIONALLY. A stack pushed
// at the bind and popped at the restore therefore goes out of step the first time
// a jitted call has no argument. Instead the bind records into a single PENDING
// slot; jitSaveFrameRT pushes that slot -- or an EMPTY entry -- and clears it, and
// jitRestoreFrameRT pops. Push and pop are then both unconditional and paired, and
// the pending slot is live only between two adjacent emitted calls, so nothing can
// interleave. Both frame wrappers were checked ungated: the `if field.recursive`
// lives inside saveLocalFields/restoreLocalFields, not in them.
#define GCHAN_DEPTH 256
static GroupBody *gChanPendBody  = 0;
static GroupItem *gChanPendGroup = 0;
static int        gChanPendData  = 0;
static GroupBody *gChanStkBody[GCHAN_DEPTH];
static GroupItem *gChanStkGroup[GCHAN_DEPTH];
static int        gChanStkData[GCHAN_DEPTH];
static int        gChanStkTop = 0;

// ⚠ THE CHANNEL'S DAILY INSTRUMENT (SEQ 132 item 2). Counted at ALL FOUR bind
// sites -- both arms of both roads -- so the pair is readable BARE, where the
// non-flip arm now also goes through setGroup, as well as flipped. H4's shape:
// printed unconditionally and compared by value, never asserted by absence.
static int gChanBinds = 0;
static int gChanSame  = 0;

static int gCompileAttempted = 0;
static int gCompileRefused   = 0;
static int gCompileReported  = 0;

// Fires at COMPLETION, never at the refusal: F-17e's full sweep is preserved,
// all refusals report, and only then does the run refuse to call itself
// successful. Exiting at the first refusal would report one.
//
// SILENT WHEN THE ROAD WAS NEVER TRAVELLED. A run that never called compile
// has no compile census, so nothing prints and no baseline moves. That is not
// a gate on the assertion; it is the difference between a zero and an absence.
static inline void reportCompileCensus(void)
{
    if ( gCompileReported )         return;
    if ( gCompileAttempted == 0 )   return;
    gCompileReported = 1;
    ::fprintf(stderr,"compile census: %d attempted, %d refused\n",
        gCompileAttempted,gCompileRefused);
    if ( gCompileRefused )
        ::exit(1);
}

#endif // JITCONTEXT_H
