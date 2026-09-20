class GroupItem;

// SEQ 166: the drive string's extent, recorded by measureMarkArm and read by
// measureMarkPoint. Instrument-only state -- nothing in the program reads it.
static char *gMarkDriveBase = 0;
static long  gMarkDriveLen  = 0;


class measure
{
public:
int dummy;
void run();
};
extern "C" GroupItem *addrOf(GroupItem *field);
extern "C" int auditMissingRules(GroupItem *registry);
extern "C" int auditMissingTerms(GroupItem *registry);
extern "C" GroupItem *auditRStuff(GroupItem *argument);
extern "C" int auditSpurious(GroupItem *registry);
extern "C" int auditUnconsumed(GroupItem *registry);
extern "C" GroupItem *bodyCensus(GroupItem *ignored);
extern "C" GroupItem *canonOf(GroupItem *argument);
extern "C" GroupItem *chanReport(GroupItem *input);
extern "C" GroupItem *evictAction(GroupItem *field);
extern "C" int labelMinters(GroupItem *rule);
extern "C" GroupItem *measureBlockResult(GroupItem *input, GroupItem *result, int stopped);
extern "C" GroupItem *measureDotOperands(GroupItem *argument, GroupItem *target);
extern "C" GroupItem *measureFireLabelActionIn(GroupItem *field, GroupItem *myLabel);
extern "C" GroupItem *measureFireLabelActionOut(GroupItem *field, GroupItem *myLabel);
extern "C" GroupItem *measureFireLabelEntry(GroupItem *field);
extern "C" GroupItem *measureFireLabelFork(GroupItem *field, GroupItem *myLabel);
extern "C" GroupItem *measureFrameProbe(GroupItem *field, GroupItem *rule);
extern "C" GroupItem *measureLabelMint(GroupItem *field, GroupItem *myLabel, GroupItem *into);
extern "C" GroupItem *measureLabelProbe(GroupItem *field, GroupItem *myLabel, GroupItem *into, GroupItem *result, int yielded);
extern "C" GroupItem *measureMarkArm(GroupItem *driveNode);
extern "C" GroupItem *measureMarkPoint(char *where);
extern "C" GroupItem *measureParentProbe(GroupItem *field);
extern "C" GroupItem *measurePlusEQWrite(GroupItem *field);
extern "C" GroupItem *measurePlusPlusWrite(GroupItem *field);
extern "C" GroupItem *measureRuleDispatch(GroupItem *op, GroupItem *target, GroupItem *arg);
extern "C" GroupItem *measureRuleDoor(GroupItem *field, GroupItem *rule);
extern "C" GroupItem *measureStopCaller(GroupItem *caller);
extern "C" GroupItem *measureTokenArm(char *arm, GroupItem *ANYtoken, GroupItem *InvokeArg, GroupItem *unary);
extern "C" GroupItem *parseClassify(GroupItem *field);
extern "C" GroupItem *probeNode(GroupItem *argument);
extern "C" GroupItem *showBody(GroupItem *field);
