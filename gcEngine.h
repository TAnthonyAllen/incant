/***************************************************************************
    gcEngine -- the base that makes an engine object collectable (GC stroke 2,
    SEQ 589, R1 and R2). Hand-written; no .twk behind it.

    GroupItem, GroupBody, GroupList and RuleStuff extend it (R1: the node
    classes together, because an uncollectable block is a root and one left
    out keeps everything it points at alive -- docs/gcRecon.md 1). R1's fifth,
    ParseActivation, cannot be spelled: tok's struct grammar takes no extends
    (Tokf/declare.g, Structure). It has no heap sites -- it lives on the C
    stack, which the collector scans -- so it is no root either way.

    THE RULE (R2), gcThreads.mm's style: on the MAIN THREAD `new` makes a
    collectable, scanned block (GC_MALLOC) and registers the poison when
    GCSTRESS is set; OFF the main thread it REFUSES BY NAME -- one stderr line
    naming gcEngine, the size and the thread, then abort(). The collector is
    built single-threaded and its free list takes no lock (F-152), so an engine
    object made off the main thread is the race F-152 cured, and the refusal
    is louder than the race.

    Like gc_cpp's `gc`, it runs NO destructor and holds no data (an empty base:
    no layout moves). `delete` frees on the main thread and leaks, counted,
    off it -- nothing in the engine deletes today (recon 4).

    THE INCLUDE. tok writes `: public gcEngine` for `extends gcEngine` (the
    type is known from gcExterns, first in groupIncludes) and emits this
    header's #include into a .mm -- but in its type table's HASH order, so in
    most .mm it lands after GroupItem.h, too late for a base class. So the
    Groups target compiles every C++ and Objective-C++ file with
    `-include .../Groups/gcEngine.h` (TOK.xcodeproj, OTHER_CPLUSPLUSFLAGS):
    it is in scope before line 1 of every file, generated or hand-written.
****************************************************************************/
#ifndef gcEngine_h
#define gcEngine_h
#ifdef __cplusplus
#include <cstddef>

class gcEngine
{
public:
    static void *operator new(size_t n);
    static void  operator delete(void *p) noexcept;
};

#endif
#endif
