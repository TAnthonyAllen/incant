#include <Cocoa/Cocoa.h>
#include <string.h>
#include <stdio.h>
#include "OCroutines.h"
#include "StringRoutines.h"
#include "GroupItem.h"
#include "Buffer.h"
#include "GroupRules.h"
#include "GroupControl.h"
#include "GroupList.h"
#include "GroupBody.h"
#include "RuleStuff.h"
#include "PLGset.h"
#include "Stylish.h"
#include "GroupDraw.h"

extern "C" int containerTo(GroupItem *term, GroupItem *into, char *slot)
{
GroupItem 	*grup = 0;
GroupItem 	*fresh = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = term->rStuff;
PLGset 		*inSet = term->getCharacterSet();
char 		*atInput = ruler->atRuleMark;
int 		advance = 0;
Buffer 		*buffer = ruler->stringBUFFER;
	buffer->reset();
	while ( *atInput )
		if ( inSet->contains(*atInput) )
			{
			buffer->appendChar(*atInput,0,0);
			atInput++;
			}
		else	break;
	while ( advance = buffer->length() )
		{
		if ( grup = term->get(buffer->string()) )
			{
			if ( !ruleStuff->noAdvance )
				ruler->atRuleMark += advance;
			if ( into )
				{
				fresh = new GroupItem(slot);
				fresh->setGroup(grup);
				into->addAttribute(fresh);
				}
			return 1;
			}
		buffer->shorten(1);
		}
	return 0;
}

/*******************************************************************************
    containerTo — CT, 2026-08-07. The generated arm's spelling of a CONTAINER
    term, and the support-library twin of testContainer.

    A container term (`UnaryOPS` in `UnaryXP UnaryOPS ANYtoken;`) is a `bin`
    whose entries are matched LONGEST-FIRST: scan greedily over the container's
    own character set, then look the buffer up and back off one character at a
    time until it IS an entry or is empty. That back-off is not an optimisation
    -- set membership can say "this character could belong to some entry" but
    never "is this prefix an entry", so the greedy scan is an UPPER BOUND. The
    same lesson `Buffer::shorten` was added for.

    ⚠ MODELLED ON testContainer LINE FOR LINE, INCLUDING ITS BARE NAMES, and
    that is deliberate rather than lazy: `reset()`, `contains()`, `length()`,
    `get(string())` each resolve against a different object here (buffer, inSet,
    buffer, term), and the resolution was VERIFIED IN THE GENERATED .mm rather
    than reasoned about. Change the declaration order and you change what the
    bare names mean.

    ⚠ THE ONE DIVERGENCE FROM testContainer IS THE DESTINATION, AND IT IS THE
    WHOLE POINT. testContainer writes the matched entry into the TERM'S OWN
    label (`ruleStuff.label.group = grup`), which the interpretive arm then
    attaches upward. A generated method has no per-term label, so this mints one
    tagged with the term's slot name, hangs the entry on it, and attaches it
    under `into` -- attach-under, no promotion, no retag (IA-0). Measured: the
    specimen term is LABELLED (`noLabel=0`), so the label is not optional.

    NOTE, and it is a sibling gap rather than this one: `litTo` -- the labelled
    LITERAL spelling -- still has no implementation (genParse.rtn's own latent
    note). CT adds the labelled CONTAINER road and does not pave the literal one.
*******************************************************************************/
/*******************************************************************************
    ctProbe -- MEASUREMENT SCAFFOLD, rule-ladder rung two, 2026-08-24.

    containerTo is emitted-but-never-executed: its only caller is genParse's
    emitter, and no generated parse method that calls it has ever been built.
    So the question "does containerTo attach only at the success boundary" could
    not be answered by running anything, and a structural read is not a
    measurement. This drives it directly, on a hit and on a miss, and prints
    the `into` child count either side of the call.

    ⚠ TEMPORARY. Remove with its groups.ext declaration once the answer is
    banked; it exists to make one ruling checkable, not to ship.
*******************************************************************************/
extern "C" GroupItem *ctProbe(GroupItem *term)
{
GroupItem 	*into = new GroupItem("ctInto");
int 		before = 0;
int 		after = 0;
int 		ok = 0;
	if ( into->groupBody->groupList )
		before = into->groupBody->groupList->listLength;
	ok = containerTo(term,into,"ctSlot");
	if ( into->groupBody->groupList )
		after = into->groupBody->groupList->listLength;
	::fprintf(stderr,"  ctProbe term  %s  match= %d  into  %d  ->  %d\n",term->groupBody->tag,ok,before,after);
	return GroupControl::groupController->groupRules->trueResult;
}

/*******************************************************************************
    True if ch is one of the characters in chars -- a guard test for baked
    guard sets. PLGset stays the default for larger sets (banked, S5.2); this
    covers the single/small-explicit-set cases in the JSONblock family.
*******************************************************************************/
extern "C" int inGuard(GroupItem *field, char *chars, char ch)
{
	while ( *chars )
		if ( *chars == ch )
			return 1;
		else	chars++;
	return 0;
}

/*******************************************************************************
    Alternation exit. No label of its own (S2.4) -- the winning option has
    already attached (rule-reference options attach via their own leaveRule
    against the same `into`; literal options attach via litOption). Only
    handles the rewind-on-failure half of Invariant R.

    S4.2 (knowingly conservative): `from` is kept because `lit` commits its
    skip pass to atRuleMark BEFORE matching, so a failing lit returns false
    with the mark advanced. Until that is made non-destructive, leaveAlt
    cannot drop to (rule, ok).
*******************************************************************************/
extern "C" GroupItem *leaveAlt(GroupItem *rule, char *from, int ok)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
char 		*at = ruler->atRuleMark;
	if ( ruler->parseTrace )
		::fprintf(stderr,"  HIT  %s\n",rule->groupBody->tag);
	if ( ok )
		{
		/*  labelNO, not trueResult (PC-3). S2.4 rules an alternation
		LABEL-TRANSPARENT: it builds no label and its winning option has
		already attached one level down through the bridge. It succeeded and
		has nothing to plumb, which is what labelNO says. trueResult said
		"succeeded" in a channel that also had to mean "here is your node",
		and the shared attach then planted the boolean in the tree -- GM-19.  */
		if ( ruler->parseTrace )
			::fprintf(stderr,"  WIN  %s\n",rule->groupBody->tag);
		return ruler->labelNO;
		}
	ruler->atRuleMark = from;
	if ( ruler->parseTrace )
		{
		::fprintf(stderr,"  FAIL %s\n",rule->groupBody->tag);
		if ( at == from )
			::fprintf(stderr,"       R OK   mark unmoved\n");
		else	::fprintf(stderr,"       R OK   mark rewound\n");
		}
	return 0;
}

/*******************************************************************************
    Sequence exit -- Invariant R lives here and in leaveAlt, nowhere else.
    On success: attach label into `into`'s list, return the label. On failure:
    rewind atRuleMark to `from`, return null (label is simply not attached;
    GC reclaims it, same as parse()'s own comment on label leaks).

    First parameter is the RULE, not a term (genParseShape S1.4: `field` means
    term, `rule` means rule). It is what the S1.8 instrumentation reports
    against.

    NULL `into` IS LEGAL and RETURNS THE LABEL -- settled, Clay SEQ 26 S4. The
    parse succeeded, the tree exists, there is simply no parent to attach it
    to; this is the sequence analogue of leaveAlt's success exit. Retiring the
    entry wrappers (S1.7) is what makes it reachable: a generated rule can now
    be called from top-level incant, and runRule invokes `rule.parse(0)` with
    no parent stuff, so parentLabel -- and therefore `into` -- is null. The
    interpretive path has always guarded this (parse()'s attachment block is
    `if label && pStuff`); this is the same guard one implementer down. Without
    it, `Scaf('x')` dereferences null on its FIRST success.

    S1.8 instrumentation: HIT/WIN (S6.1) and Invariant R live HERE rather than
    in emitted lines -- one implementation, every rule, and it survives the
    kant handover. leaveRule holds `from` and atRuleMark at exactly the moment
    the R question is asked, which is why the check belongs here and not in a
    bespoke wrapper. R is a property of the FAILURE path, so `Scaf()` on its
    own could never show it; this is what replaces runScaf's R-inner prints.
    Note the rewind is unconditional, so R cannot be "violated" here -- what
    the report carries is whether the rewind had ground to give back, which is
    the thing runScaf actually measured. Gate: GroupRules.parseTrace.
*******************************************************************************/
extern "C" GroupItem *leaveRule(GroupItem *rule, GroupItem *into, GroupItem *label, char *from, int ok)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
char 		*at = ruler->atRuleMark;
	if ( ruler->parseTrace )
		::fprintf(stderr,"  HIT  %s\n",rule->groupBody->tag);
	if ( ok )
		{
		/*  ⚠ NO ATTACH HERE (PC-4, 2026-08-07). This did `if into into +% label`
		-- attach-under, which is now exactly what parse() performs for the
		generated arm, once, for both this and every other emitted method.
		A second writer here is what produced GM-17's divergence. `into` is
		still taken and still passed by every emitted method: the emitter is
		untouched and parse() derives the same node from pStuff.  */
		if ( ruler->parseTrace )
			::fprintf(stderr,"  WIN  %s\n",rule->groupBody->tag);
		return label;
		}
	ruler->atRuleMark = from;
	if ( ruler->parseTrace )
		{
		::fprintf(stderr,"  FAIL %s\n",rule->groupBody->tag);
		if ( at == from )
			::fprintf(stderr,"       R OK   mark unmoved\n");
		else	::fprintf(stderr,"       R OK   mark rewound\n");
		}
	return 0;
}

/*******************************************************************************
    genParse Step 1/2 prototype (docs/genParseSpec.md S3/S5): hand-written
    support library + the seven JSONblock methods + entry wrapper. No tok
    macros -- every primitive below is a real function, so &&/|| composition
    works natively.
*******************************************************************************/
/*******************************************************************************
    Match a literal string at atRuleMark (skip-set pass first). No label --
    for "-"/noLabel attribute terms (JSONblock's "{"-/"}"-,  JSONfield's ":"-,
    JSONitem's ","?-).

    `field` is the TERM, not the rule (genParseShape S1.4) -- the same
    convention testSet(field) already uses. Callers pass the frame's term local
    (`lit(t1,"{")`), which is what gives every leaf frame its own identity: a
    breakpoint in here during parseJSONfield can now tell the ":" match from
    the "," one, which is the question a debugger frame usually needs answered.
*******************************************************************************/
extern "C" int lit(GroupItem *field, char *str)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
char 		*atText = 0;
char 		*matchStr = 0;
	if ( ruler->parseTrace )
		::fprintf(stderr,"  lit \" %s \" at term  %s\n",str,field->groupBody->tag);
	if ( ruler->skipSet->contains(*ruler->atRuleMark) )
		ruler->atRuleMark = ruler->checkSkip(ruler->atRuleMark);
	atText = ruler->atRuleMark;
	matchStr = str;
	while ( *matchStr )
		if ( *atText == *matchStr )
			{
			atText++;
			matchStr++;
			}
		else	return 0;
	ruler->atRuleMark = atText;
	return 1;
}

/*******************************************************************************
    Match a literal string as an alternation MEMBER (JSONtoken's "false"/
    "true"). A plain literal member is not noLabel, so on success this
    creates a label tagged with the literal text and attaches it into `into`
    directly -- leaveAlt is label-transparent by design, so literal options
    must attach themselves (rule-reference options attach via their own
    leaveRule against the same `into`).
*******************************************************************************/
extern "C" int litOption(GroupItem *field, GroupItem *into, char *str)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*fresh = 0;
char 		*atText = 0;
char 		*matchStr = 0;
	if ( ruler->skipSet->contains(*ruler->atRuleMark) )
		ruler->atRuleMark = ruler->checkSkip(ruler->atRuleMark);
	atText = ruler->atRuleMark;
	matchStr = str;
	while ( *matchStr )
		if ( *atText == *matchStr )
			{
			atText++;
			matchStr++;
			}
		else	return 0;
	ruler->atRuleMark = atText;
	fresh = new GroupItem(str);
	into->addAttribute(fresh);
	return 1;
}

/*******************************************************************************
    Generated per-term iteration helper for JSONblock's `JSONfield*` (min 0).
    Same treatment S5.2 already gives character-level accumulators, extended
    to group-reference iteration -- one small function per loop site rather
    than a reusable macro (S2.5).
*******************************************************************************/
extern "C" int manyJSONblockFields(GroupItem *label, GroupItem *term)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
char 		*from = ruler->atRuleMark;
int 		kount = 0;
	while ( ::parseR(term,label) )
		kount++;
	if ( kount >= 0 )
		return 1;
	ruler->atRuleMark = from;
	return 0;
}

/*******************************************************************************
    Generated per-term iteration helper for JSONlist's `JSONitem+` (min 1).
*******************************************************************************/
extern "C" int manyJSONlistItems(GroupItem *label, GroupItem *term)
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

/*******************************************************************************
    Bridge to the GENERIC driver for rules genParse hasn't converted yet
    (GrouP, NumbeR -- pre-existing bootstrap rules, out of scope for this
    prototype). Builds a throwaway RuleStuff whose .label IS `into`, so
    parse()'s own attach logic (`pStuff.label +% label;`) appends directly
    where a converted callee's leaveRule/leaveAlt would have. Generated
    methods and the generic driver coexist rule by rule (S0) -- this is the
    seam.
*******************************************************************************/
extern "C" GroupItem *parseGeneric(GroupItem *into, char *ruleName)
{
GroupItem 	*rule = GroupControl::groupController->locate(ruleName);
RuleStuff 	*bridge = new RuleStuff(rule);
	bridge->label = into;
	return rule->parse(bridge);
}

/*******************************************************************************
    JSONarray isRule "["- JSONlist? "]"- code={
        if JSONlist; for grup in JSONlist; grup <: grup; };
*******************************************************************************/
extern "C" GroupItem *parseJSONarray(GroupItem *rule)
{
GroupItem 	*into = rule->rStuff->parentLabel;
GroupItem 	*label = new GroupItem("JSONarray");
GroupItem 	*t1 = rule->get(1);
GroupItem 	*t2 = rule->get(2);
GroupItem 	*t3 = rule->get(3);
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*freshStuff = 0;
char 		*from = ruler->atRuleMark;
int 		ok = 0;
	if ( !label->rStuff )
		{
		freshStuff = new RuleStuff(rule);
		label->setRStuff(freshStuff);
		}
	ok = ::lit(t1,"[") && (::parseR(t2,label) || 1) && ::lit(t3,"]");
	if ( ok )
		{
		ruler->ruleSTUFF = label->rStuff;
		label = rule->groupBody->gMethod(label);
		}
	return ::leaveRule(rule,into,label,from,ok && label);
}

/*******************************************************************************
    JSONblock isRule fail "{"- JSONfield* "}"-;
*******************************************************************************/
extern "C" GroupItem *parseJSONblock(GroupItem *rule)
{
GroupItem 	*into = rule->rStuff->parentLabel;
GroupItem 	*label = new GroupItem("JSONblock");
GroupItem 	*t1 = rule->get(1);
GroupItem 	*t2 = rule->get(2);
GroupItem 	*t3 = rule->get(3);
GroupRules 	*ruler = GroupControl::groupController->groupRules;
char 		*from = ruler->atRuleMark;
int 		ok = 0;
	ok = ::lit(t1,"{") && ::manyJSONblockFields(label,t2) && ::lit(t3,"}");
	return ::leaveRule(rule,into,label,from,ok);
}

/*******************************************************************************
    JSONfield isRule JSONtoken ":"- JSONvalue ","?- code={
        token <: JSONtoken; token = JSONvalue; return token; };

    RETAGGING NOTE (Clod, 2026-07-25): parseJSONtoken/parseJSONvalue attach
    their result tagged by whatever their OWN winning internal path produced
    (e.g. "GrouP", from JSONtoken's alternation resolving through GrouP's
    label-transparent alternation down to QuotE) -- NOT retagged to the
    ATTRIBUTE'S OWN NAME the way the generic parse() driver retags an
    attribute term to its own tag via isTarget handling. The tail action
    looks children up BY the attribute name ("JSONtoken"/"JSONvalue"), so
    each sub(R)-style attach here must be retagged explicitly. This is a gap
    in genParseSpec's sub(R) semantics generally (S2.1/S4.1 don't mention
    retagging), not specific to JSONfield -- found empirically via this
    exact bug (the action received two children both tagged "GrouP" and
    could find neither "JSONtoken" nor "JSONvalue", so it silently returned
    null and the whole field's content was discarded).
*******************************************************************************/
extern "C" GroupItem *parseJSONfield(GroupItem *rule)
{
GroupItem 	*into = rule->rStuff->parentLabel;
GroupItem 	*label = new GroupItem("JSONfield");
GroupItem 	*t1 = rule->get(1);
GroupItem 	*t2 = rule->get(2);
GroupItem 	*t3 = rule->get(3);
GroupItem 	*t4 = rule->get(4);
GroupItem 	*tokenChild = 0;
GroupItem 	*valueChild = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*freshStuff = 0;
char 		*from = ruler->atRuleMark;
int 		ok = 0;
	if ( !label->rStuff )
		{
		freshStuff = new RuleStuff(rule);
		label->setRStuff(freshStuff);
		}
	ok = ::parseR(t1,label) != 0;
	if ( ok )
		{
		tokenChild = label->next(tokenChild);
		tokenChild->groupBody->tag = "JSONtoken";
		}
	ok = ok && ::lit(t2,":");
	ok = ok && ::parseR(t3,label);
	if ( ok )
		{
		valueChild = label->next(tokenChild);
		valueChild->groupBody->tag = "JSONvalue";
		}
	ok = ok && (::lit(t4,",") || 1);
	if ( ok )
		{
		ruler->ruleSTUFF = label->rStuff;
		label = rule->groupBody->gMethod(label);
		}
	return ::leaveRule(rule,into,label,from,ok && label);
}

/*******************************************************************************
    JSONitem isRule JSONtoken@ ","?-;
    @ (isTarget/promote): the child's label becomes JSONitem's own result,
    retagged. No fresh label of its own and no leaveRule call -- JSONtoken's
    own leaveAlt/leaveRule already rewinds on failure (Invariant R), so
    promotion needs nothing extra on the failure path.
*******************************************************************************/
extern "C" GroupItem *parseJSONitem(GroupItem *rule)
{
GroupItem 	*into = rule->rStuff->parentLabel;
GroupItem 	*t1 = rule->get(1);
GroupItem 	*t2 = rule->get(2);
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	if ( !::parseR(t1,into) )
		return 0;
	into->groupBody->tag = "JSONitem";
	::lit(t2,",");
	return ruler->trueResult;
}

/*******************************************************************************
    JSONlist isRule JSONitem+;
*******************************************************************************/
extern "C" GroupItem *parseJSONlist(GroupItem *rule)
{
GroupItem 	*into = rule->rStuff->parentLabel;
GroupItem 	*label = new GroupItem("JSONlist");
GroupRules 	*ruler = GroupControl::groupController->groupRules;
char 		*from = ruler->atRuleMark;
	return ::leaveRule(rule,into,label,from,::manyJSONlistItems(label,rule->get(1)));
}

/*******************************************************************************
    JSONtoken isRule JSONblock; "false"; "true"; GrouP; NumbeR;
*******************************************************************************/
extern "C" GroupItem *parseJSONtoken(GroupItem *rule)
{
GroupItem 	*into = rule->rStuff->parentLabel;
GroupItem 	*t1 = rule->get(1);
GroupItem 	*t2 = rule->get(2);
GroupItem 	*t3 = rule->get(3);
GroupItem 	*t4 = rule->get(4);
GroupItem 	*t5 = rule->get(5);
GroupRules 	*ruler = GroupControl::groupController->groupRules;
char 		*from = ruler->atRuleMark;
	return ::leaveAlt(rule,from,(::inGuard(t1,"{",*ruler->atRuleMark) && ::parseR(t1,into)) || ::litOption(t2,into,"false") || ::litOption(t3,into,"true") || ::parseR(t4,into) || ::parseR(t5,into));
}

/*******************************************************************************
    JSONvalue isRule JSONblock; JSONarray; JSONtoken;
*******************************************************************************/
extern "C" GroupItem *parseJSONvalue(GroupItem *rule)
{
GroupItem 	*into = rule->rStuff->parentLabel;
GroupItem 	*t1 = rule->get(1);
GroupItem 	*t2 = rule->get(2);
GroupItem 	*t3 = rule->get(3);
GroupRules 	*ruler = GroupControl::groupController->groupRules;
char 		*from = ruler->atRuleMark;
	return ::leaveAlt(rule,from,(::inGuard(t1,"{",*ruler->atRuleMark) && ::parseR(t1,into)) || (::inGuard(t2,"[",*ruler->atRuleMark) && ::parseR(t2,into)) || ::parseR(t3,into));
}

/*******************************************************************************
    parseR (genParseShape S1.6) -- the set-then-call primitive for a term that
    references another rule. Two jobs the emitted `&&` chain cannot do itself:

    1. The `into` handover is an ASSIGNMENT, and an assignment is not a term
       (S2.5's expression-vs-statement problem in a new place). Keeping it in
       one primitive leaves emitted text a pure boolean expression.
    2. It routes THROUGH parse(), not directly at a generated method, so the
       fork decides. Generation is per-rule, so a generated rule can call an
       interpretive one and vice versa: mixed mode is free, conversion is
       order-independent, and the interpretive walk stays the oracle for
       everything not yet converted. The cost is an indirect call opaque to
       LLVM's inliner -- not a correctness cost, and reversible later inside
       this one function, with no emitted file regenerated.

    No name lookup (S1.3): the term IS the thing to parse. That is a
    CORRECTION to S1.6's stated mechanism, made against the tree rather than
    against the design -- see the measurement in genParse.rtn's dumpRuleTerms
    header. S1.6 writes `t2.onGroup.parentLabel = label`, but NO rule-reference
    term is isGROUP and none has onGroup set, before or after a parse
    (getWhatFollows gates on isGROUP). There is no onGroup there to write to.
    What a reference term actually is: a distinct node carrying isRule and
    SHARING the referenced rule's child list. So it parses directly, which is
    exactly what the interpretive walk does -- testAttributes calls
    `grup.parse(stuff)` on the term itself, never on a dereferenced target.
    Parity with the oracle, not a parallel mechanism that can drift from it.

    The handover travels as the bridge stuff's label, exactly as parseGeneric
    already does it: parse() derives parentLabel from it on the generated path
    and attaches through `pStuff.label +% label` on the interpretive one. ONE
    mechanism serves both halves of mixed mode, and it is why a null pStuff is
    never handed down (which would silently orphan the callee's result).

    OPEN, and it is Tony's/Clay's call, not a coding decision -- see the seal.
    parseMethod lives on rStuff, and rStuff is PER NODE: the term has its own,
    separate from the registry rule's. So binding a rule's parseMethod does NOT
    reach the term nodes that reference it, and a converted rule would be used
    when invoked BY NAME but not when referenced from another rule. Mixed mode
    (S1.6's whole justification) needs an answer to that before rung 4, which
    is the first cross-method call. It does not bite rungs 1-2: Scaf/Scaf2 have
    no rule-reference terms.
*******************************************************************************/
extern "C" GroupItem *parseR(GroupItem *term, GroupItem *into)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*bridge = 0;
GroupItem 	*got = 0;
	if ( !term )
		return 0;
	/*  FU-2', 2026-08-05 -- THE LOCALIZER, BUILT ONCE IN THE SUPPORT LAYER.
	Instrumenting parseR rather than the emitted methods means every
	generated method self-narrates FOR FREE and rules 13-78 inherit it
	unwritten. A full-monty verify is a DETECTOR (corpus GM-14); this is
	the localizer that names the fork point.
	
	⚠ GATED ON THE EXISTING parseTrace, not on a new flag: leaveRule above
	already uses it, so this joins the standing debug idiom instead of
	minting a second switch. Default OFF, and the fleet is asserted
	byte-identical with the gate closed -- a gate that leaks is not a gate.
	
	⚠ IDENTITY-PRINTING ONLY -- taG and shape facts, NEVER a bare node.
	Printing a group prints its ATTRIBUTE COUNT, which is a legal-looking
	number in the same range as an answer and does not announce itself as
	the wrong quantity. That near-miss is kant8T's K6c, and it nearly
	inverted a diagnosis; this is that lesson written into an instrument.  */
	if ( ruler->parseTrace )
		{
		::fprintf(stderr,"  parseR term= %s  into= %s\n",term->groupBody->tag,into->groupBody->tag);
		}
	bridge = new RuleStuff(term);
	bridge->label = into;
	got = term->parse(bridge);
	if ( ruler->parseTrace )
		{
		if ( got )
			::fprintf(stderr,"  parseR term= %s  -> attached as  %s  under  %s\n",term->groupBody->tag,got->groupBody->tag,into->groupBody->tag);
		else	::fprintf(stderr,"  parseR term= %s  -> NULL (no attachment)\n",term->groupBody->tag);
		}
	return got;
}

/*******************************************************************************
	This sets the data of rule to the value of a previously processed label
    with the same name as rule
*******************************************************************************/
extern "C" int setMacroValue(GroupItem *field)
{
RuleStuff 	*ruleStuff = field->rStuff;
GroupItem 	*grup = 0;
GroupItem 	*macro = field->getGroup();
GroupItem 	*ancestor = 0;
	if ( ruleStuff->parentStuff )
		ancestor = ruleStuff->parentStuff->label;
	if ( ancestor )
		while ( grup = ancestor->next(grup) )
			if ( ::compare(macro->groupBody->tag,grup->groupBody->tag) == 0 )
				{
				macro->copyData(grup);
				return 1;
				}
	::fprintf(stderr,"setMacroValue: could not find macro for %s\n",field->groupBody->tag);
	return 0;
}

/*******************************************************************************
	Process a parseAction
*******************************************************************************/
extern "C" int testAction(GroupItem *field)
{
	if ( parseACTION(field->groupBody->flags.methodType) || !field->rStuff->label )
		{
		if ( field->groupBody->gMethod(field) )
			return 1;
		}
	else
	if ( field->rStuff->label && field->groupBody->gMethod(field->rStuff->label) )
		return 1;
	return 0;
}

/*******************************************************************************
	Run a wild card test on this group against current input
*******************************************************************************/
extern "C" int testAny(GroupItem *field)
{
int 		counter = 0;
int 		more = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = field->rStuff;
	ruleStuff->isOK = 0;
	if ( *ruler->atRuleMark )
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
			return ::reportMaxLimit(field);
		if ( counter && counter >= ruleStuff->min )
			{
			if ( ruleStuff->noAdvance )
				ruler->atRuleMark = ruleStuff->hereAt;
			if ( ruleStuff->label )
				ruleStuff->label->setToken(ruleStuff->hereAt,counter);
			ruleStuff->isOK = 1;
			}
		}
	if ( ruleStuff->isOK )
		return 1;
	return 0;
}

/*******************************************************************************
	Parse field attributes and return true if they all succeed
*******************************************************************************/
extern "C" int testAttributes(RuleStuff *stuff)
{
GroupItem 	*grup = 0;
int 		result = 0;
	while ( grup = stuff->rule->nextAttribute(grup) )
		if ( grup->groupBody->flags.noPrint )
			continue;
		else
		if ( grup->parse(stuff) )
			result = 1;
		else {
			result = 0;
			break;
			}
	return result;
}

/*******************************************************************************
	Run a character test on this group against current input
*******************************************************************************/
extern "C" int testCharacter(GroupItem *field)
{
int 		counter = 0;
int 		more = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = field->rStuff;
	ruleStuff->isOK = 0;
	if ( *ruler->atRuleMark )
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
			return ::reportMaxLimit(field);
		if ( counter && counter >= ruleStuff->min )
			{
			if ( ruleStuff->noAdvance )
				ruler->atRuleMark = ruleStuff->hereAt;
			if ( ruleStuff->label )
				ruleStuff->label->setToken(ruleStuff->hereAt,counter);
			ruleStuff->isOK = 1;
			}
		}
	if ( ruleStuff->isOK )
		return 1;
	return 0;
}

/*******************************************************************************
	Process a condition
*******************************************************************************/
extern "C" int testCondition(GroupItem *field)
{
RuleStuff 	*ruleStuff = field->rStuff;
	if ( ruleStuff->min )
		return 1;
	return 0;
}

/*******************************************************************************
    Registry and Container test looks for an entry that matches the input stream.

    LONGEST-ENTRY MATCH (Tony's finding and ruling, 2026-08-02). The greedy
    character scan is an UPPER BOUND, not the answer. Character-set membership
    can only say "this character could belong to SOME entry"; it can never say
    "this prefix IS an entry", because a set has no notion of where an entry
    ends. So the scan runs to the end of the run, and then the buffer is backed
    off one character at a time until it either IS an entry or is empty. The
    longest prefix that is an actual entry wins.

    THE PRESENTING BUG: `--grup;` against Operators. `negate` and `modedOP` are
    word-spelled entries, so their letters are in the container's character set
    -- `g` among them. The scan therefore built `--g`, which is an entry of
    nothing, and the whole match failed. It is a design flaw and not an edge
    case: any container holding both a symbol and a word can produce it.
    Backing off finds `--` and advances 2, which is the answer.

    Same disease class as the ShortcuT `+`-merge that sank `,` as the string
    opener (2026-07-31): set-based character grouping making token decisions.
*******************************************************************************/
extern "C" int testContainer(GroupItem *field)
{
GroupItem 	*grup = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = field->rStuff;
PLGset 		*inSet = field->getCharacterSet();
char 		*atInput = ruler->atRuleMark;
int 		advance = 0;
Buffer 		*buffer = ruler->stringBUFFER;
	buffer->reset();
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
			return 1;
			}
		buffer->shorten(1);
		}
	return 0;
}

/*******************************************************************************
	Process the first field member that passes its guard
*******************************************************************************/
extern "C" int testOptions(RuleStuff *stuff)
{
GroupItem 	*grup = 0;
	while ( grup = stuff->rule->nextMember(grup) )
		{
		if ( stuff->checkGuard(grup) )
			{
			grup->rStuff->guardOK = 1;
			if ( grup->parse(stuff) )
				return 1;
			}
		}
	return 0;
}

/*******************************************************************************
	Run a character set test on this group against current input
*******************************************************************************/
extern "C" int testSet(GroupItem *field)
{
PLGset 	*set = field->getCharacterSet();
int 		counter = 0;
int 		more = 0;
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = field->rStuff;
	ruleStuff->isOK = 0;
	if ( *ruler->atRuleMark )
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
			return ::reportMaxLimit(field);
		if ( counter && counter >= ruleStuff->min )
			{
			if ( ruleStuff->noAdvance )
				ruler->atRuleMark = ruleStuff->hereAt;
			if ( ruleStuff->label )
				ruleStuff->label->setToken(ruleStuff->hereAt,counter);
			ruleStuff->isOK = 1;
			}
		}
	if ( ruleStuff->isOK )
		return 1;
	return 0;
}

/*******************************************************************************
	Run a string test on this group against current input
*******************************************************************************/
extern "C" int testString(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = field->rStuff;
char 		*matchedString = ruleStuff->rule->matches(ruler->atRuleMark);
	if ( matchedString )
		{
		if ( ruleStuff->noAdvance )
			ruler->atRuleMark = ruleStuff->hereAt;
		if ( ruleStuff->label )
			ruleStuff->label->setText(matchedString);
		return 1;
		}
	return 0;
}

/***************************************************************************
	Capture input until it gets a match. It returns a token and the input
    stream is left pointing at the match if upTo or after the match if upToOver.
    If the current rule is a set, the set is matched against.
    If the current rule isSTRING its text is matched against. Otherwise
    the default match is against a comma.
***************************************************************************/
extern "C" int testUpTo(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
RuleStuff 	*ruleStuff = field->rStuff;
char 		*atText = ruler->atRuleMark;
char 		*endString = 0;
int 		counter = 1;
int 		lngth = 0;
int 		matched = 0;
int 		matchLength = 1;
int 		skipping = 0;
Buffer 		*buffer = ruler->stringBUFFER;
GroupItem 	*grup = isGROUP(field->groupBody->flags.data) ? field->getGroup() : field;
	buffer->reset();
	endString = grup->getText();
	matchLength = (int)::strlen(endString);
	if ( ruleStuff->noLabel && isCOUNT(grup->groupBody->flags.data) )
		{
		counter = field->getCount();
		skipping = 1;
		}
	grup = 0;
	while ( counter-- )
		{
		/*******************************************************************
		Advance atText until the rule matches
		*******************************************************************/
		for ( ; *atText; atText++, lngth++ )
			{
			if ( isSET(field->groupBody->flags.data) && field->getCharacterSet()->contains(*atText) )
				matched++;
			else
			if ( field->groupBody->groupList )
				{
				while ( grup = field->next(grup) )
					if ( !::compareToStream(grup->groupBody->tag,atText) )
						{
						matchLength = (int)::strlen(grup->groupBody->tag);
						matched++;
						goto gotMatch;
						}
				}
			else
			if ( matchLength == 1 )
				{
				if ( *atText == '\\' )
					{
					atText++;
					switch (*atText)
						{
						case 'r':
							*atText = '\r';
							break;
						case 't':
							*atText = '\t';
							break;
						case 'n':
							*atText = '\n';
						}
					}
				else
				if ( *atText == *endString )
					matched++;
				}
			else
			if ( !::compareToStream(endString,atText) )
				matched++;
			if ( matched )
				break;
			else
			if ( *atText )
				buffer->appendChar(*atText,0,0);
			}
		/*******************************************************************
		Fields w/o label are skips. The number of fields skipped is
		determined by the counter set above from the field count
		*******************************************************************/
gotMatch:
		if ( skipping )
			{
			atText += matchLength;
			lngth += matchLength;
			if ( counter > 0 )
				continue;
			else	ruler->atRuleMark += lngth;
			}
		/*******************************************************************
		If succeeds, update rule label and advance atRuleMark
		*******************************************************************/
		if ( matched )
			{
			if ( lngth )
				{
				if ( ruleStuff->label )
					{
					ruleStuff->label->setText(buffer->toString());
					if ( grup )
						ruleStuff->label->addAttribute(grup);
					}
				ruler->atRuleMark = atText;
				}
			if ( upToOver(ruleStuff->overTo) )
				ruler->atRuleMark += matchLength;
			return 1;
			}
		}
	return 0;
}

/*******************************************************************************
	RuleStuff constructors.
*******************************************************************************/
RuleStuff::RuleStuff(GroupItem *grup)
{
	testMatch = 0;
	parseMethod = 0;
	jitMethod = 0;
	actionMethod = 0;
	hereAt = 0;
	failedAt = 0;
	label = 0;
	onFail = 0;
	onGroup = 0;
	parentLabel = 0;
	sourceLine = 0;
	kount = 0;
	termCount = 0;
	parentStuff = 0;
	banged = 0;
	doNothing = 0;
	followed = 0;
	guardOK = 0;
	guardFAIL = 0;
	hasMacro = 0;
	inProcess = 0;
	isOK = 0;
	isOption = 0;
	isTarget = 0;
	limitsSet = 0;
	noAdvance = 0;
	noLabel = 0;
	noSkip = 0;
	notifyFail = 0;
	overTo = 0;
	sukcess = 0;
	rule = grup;
	ruleName = grup->groupBody->tag;
	// min and max may be overwritten by the TraiT rule action
	max = 1;
	maxRepeat = 1;
	min = 1;
	if ( grup = grup->parent )
		if ( parentStuff = grup->rStuff )
			parentLabel = parentStuff->label;
}

RuleStuff::RuleStuff(RuleStuff *r)
{
	testMatch = 0;
	parseMethod = 0;
	jitMethod = 0;
	actionMethod = 0;
	ruleName = 0;
	hereAt = 0;
	failedAt = 0;
	onFail = 0;
	onGroup = 0;
	parentLabel = 0;
	sourceLine = 0;
	rule = 0;
	max = 0;
	maxRepeat = 0;
	min = 0;
	termCount = 0;
	banged = 0;
	doNothing = 0;
	followed = 0;
	guardOK = 0;
	guardFAIL = 0;
	hasMacro = 0;
	inProcess = 0;
	isOK = 0;
	isOption = 0;
	isTarget = 0;
	limitsSet = 0;
	noAdvance = 0;
	noLabel = 0;
	noSkip = 0;
	notifyFail = 0;
	overTo = 0;
	*this = *r;
	label = 0;
	sukcess = 0;
	kount = 0;
	parentStuff = 0;
}

/*******************************************************************************
	checkGuard returns true if rule is unGuarded or input pointer is in guardSet
*******************************************************************************/
int RuleStuff::checkGuard(GroupItem *field)
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	if ( guardInProcess(field->groupBody->flags.guarding) )
		field->groupBody->flags.guarding = 0;
	if ( !field->groupBody->flags.guarding )
		field->getGuard();
	if ( unGuarded(field->groupBody->flags.guarding) )
		return 1;
	else
	if ( guarded(field->groupBody->flags.guarding) && field->groupBody->guardSet->contains(*ruler->atRuleMark) )
		return 1;
	return 0;
}

/*******************************************************************************
	checkInput sets hereAt and atRuleMark, handles input diversion, and returns
    true if current input is valid. Called by GroupItem match()
*******************************************************************************/
int RuleStuff::checkInput()
{
GroupRules 	*ruler = GroupControl::groupController->groupRules;
GroupItem 	*field = rule;
	guardFAIL = 0;
	if ( !ruler->atRuleMark )
		{
		::fprintf(stderr,"checkInput: no input source\n");
		goto checkFailed;
		}
	if ( *ruler->atRuleMark )
		if ( !noSkip && ruler->skipSet->contains(*ruler->atRuleMark) )
			ruler->atRuleMark = ruler->checkSkip(ruler->atRuleMark);
	/***************************************************************************
	Check for end of input
	***************************************************************************/
	if ( *ruler->atRuleMark )
		if ( !noSkip && ruler->skipSet->contains(*ruler->atRuleMark) )
			ruler->atRuleMark = ruler->checkSkip(ruler->atRuleMark);
	if ( !*ruler->atRuleMark )
		goto checkFailed;
	/***************************************************************************
	Check the rule guard if there is one
	***************************************************************************/
	hereAt = ruler->atRuleMark;
	if ( guardOK )
		{
		guardOK = 0;
		sukcess = 1;
		}
	else {
		if ( guardInProcess(field->groupBody->flags.guarding) )
			field->groupBody->flags.guarding = 0;
		if ( !field->groupBody->flags.guarding )
			field->getGuard();
		if ( unGuarded(field->groupBody->flags.guarding) )
			sukcess = 1;
		else
		if ( guarded(field->groupBody->flags.guarding) && field->groupBody->guardSet->contains(*ruler->atRuleMark) )
			sukcess = 1;
		else	guardFAIL = 1;
		}
	/***************************************************************************
	Set the label
	***************************************************************************/
	if ( sukcess )
		if ( noLabel || (field->groupBody->flags.isRule && field->groupBody->flags.hasMembers && !field->groupBody->flags.binType) )
			label = 0;
		else {
			if ( !label || !label->groupBody->flags.fLAG )
				{
				label = new GroupItem(field->groupBody->tag);
				label->groupBody->flags.isLabel = 1;
				}
			else	label->groupBody->flags.fLAG = 0;
			if ( !label->rStuff || ::compare(ruleName,field->groupBody->tag) != 0 )
				label->setRStuff(this);
			}
checkFailed:
	return sukcess;
}

/*****************************************************************************
    Return the member following this group in the parent list
    Called by getWhatFollows() in RuleStuff
*****************************************************************************/
GroupItem *RuleStuff::followingMember()
{
	if ( rule->parent )
		{
		GroupItem 	*grup = rule;
		while ( grup = grup->nextInParent )
			if ( isMember(grup->options.affiliation) )
				break;
		return grup;
		}
	return 0;
}

/*******************************************************************************
	Sets the fields of RuleStuff.
*******************************************************************************/
void RuleStuff::getWhatFollows()
{
GroupItem 	*grup = 0;
	followed = 1;
	if ( isGROUP(rule->groupBody->flags.data) )
		{
		grup = rule->getGroup();
		if ( grup->groupBody->flags.isMacro )
			hasMacro = 1;
		else	onGroup = grup;
		}
	if ( isMember(rule->options.affiliation) && !rule->parent->groupBody->flags.binType )
		{
		isTarget = 1;
		if ( grup = followingMember() )
			onFail = grup;
		}
	else
	if ( isEmbedded(rule->options.affiliation) )
		{
		if ( (rule->groupBody->flags.data && rule->groupBody->flags.data < 4) || max == 1 )
			isTarget = 1;
		if ( !min && rule->parent->rStuff->min && rule->parent->allAttributesOptional() )
			rule->parent->rStuff->min = 0;
		}
	if ( !testMatch )
		setTestMatch();
}

/*******************************************************************************
	Set testMatch
*******************************************************************************/
void RuleStuff::setTestMatch()
{
	if ( upTo(overTo) || upToOver(overTo) )
		testMatch = ::testUpTo;
	else
	if ( isBIN(rule->groupBody->flags.binType) || isREGISTRY(rule->groupBody->flags.binType) )
		testMatch = ::testContainer;
	else
	if ( rule->groupBody->flags.data )
		switch (rule->groupBody->flags.data)
			{
			case 1:
				testMatch = ::testAny;
				break;
			case 2:
				testMatch = ::testCharacter;
				break;
			case 3:
				testMatch = ::testSet;
				break;
			case 6:
				testMatch = 0;
				break;
			default:
				testMatch = ::testString;
			}
	else
	if ( rule->groupBody->flags.isMacro )
		testMatch = ::setMacroValue;
	else
	if ( rule->groupBody->flags.isCondition )
		testMatch = ::testCondition;
	else
	if ( parseACTION(rule->groupBody->flags.methodType) )
		testMatch = ::testAction;
	else
	if ( !rule->contents() )
		if ( !isMethod(rule->groupBody->flags.instructType) )
			testMatch = ::testString;
}
/*	Warning: the following methods were referenced but not declared
	allAttributesOptional()
*/
