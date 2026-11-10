/***************************************************************************
    gcThreads -- the global operator new / delete, in place of libgccpp's
    (F-152, SEQ 573, Tony's option (b)). Hand-written C++; no .twk behind it.

    WHY: libgccpp replaces new / delete for the WHOLE PROCESS, Apple's
    frameworks included, and libgc is built single-threaded, so its allocator
    takes no lock. Reading a PDF starts a CoreAnalytics thread whose C++
    allocations came through here, at the same time as the main thread: two
    threads on an unlocked free list, and the free list ends up holding text.

    THE RULE: the MAIN THREAD makes exactly libgccpp's calls (new ->
    GC_malloc_uncollectable, bad_alloc on null for the throwing forms;
    delete -> GC_free for a collector block). EVERY OTHER THREAD uses the
    system allocator and never calls the collector at all: off the main
    thread a block is identified by malloc_size (the system heap's own
    query), not by GC_base, so nothing there reads collector structures.
    A collector block deleted off the main thread is LEAKED and counted --
    freeing it would touch the free list from the wrong thread.

    The collector stays single-threaded and unchanged (R1). KE-5 (plain new
    is uncollectable) is not this file's business.

    GCTHREADS_REPORT=1 in the environment prints the counts at exit, on
    stderr; unset, nothing is printed, so no fixture's output moves.

    THE GC INSTRUMENTS (SEQ 588, GC stroke 1; docs/gcRecon.md section 5).
    Unset, every one is inert, so no fixture's output moves.
    - GCSTRESS=N (N > 0): a forced collection every N main-thread
      allocations, so a missed root breaks at an allocation point.
    - THE POISON: while GCSTRESS is set (any value), gcPoisonOnFree(obj)
      registers a finalizer that fills obj with 0xDE when the collector
      finds it unreachable, so a missed root reads 0xdededede... and
      faults where it is used. The base class of GC stroke 2 calls it;
      nothing calls it today, because nothing is collectable yet.
    - collect (kant command, collectNow): one collection now, finalizers
      run; answers how many poisoned objects it found unreachable -- an
      OBJECT count, not bytes (gcCollectOnce says why). 0 today.
    - poisonProbe (kant command, gcPoisonProbe): validates the poison
      against a known-bad end (H16) -- 16 collectable blocks held by
      nothing but hidden pointers, one collection; answers how many came
      back filled with the pattern. Runs whether or not GCSTRESS is set.
****************************************************************************/
#include <new>
#include <cstdlib>
#include <cstdio>
#include <atomic>
#include <pthread.h>
#include <malloc/malloc.h>
#include <cstring>
#include "gc/gc.h"
#include "GroupItem.h"

//  noThrowHere the target builds with exceptions off; libgccpp's own gc_badalc.o raises the same std::bad_alloc
void GC_throw_bad_alloc();

static std::atomic<long> gOffNew{0}, gOffDel{0}, gOffDelLeaked{0}, gMainDelSystem{0};

static void gcThreadsReport()
{
    ::fprintf(stderr,"=== gcThreads: off-main new %ld, off-main delete %ld (collector blocks leaked %ld), main delete of a system block %ld ===\n",
        gOffNew.load(), gOffDel.load(), gOffDelLeaked.load(), gMainDelSystem.load());
}

static struct GcThreadsArm {
    GcThreadsArm() { if ( ::getenv("GCTHREADS_REPORT") ) ::atexit(gcThreadsReport); }
} gcThreadsArm;

//  stressN GCSTRESS read once, at the first main-thread allocation: -1 unread, 0 unset or off, N > 0 a collection every N
static long gStressN = -1, gStressCount = 0;
static bool gPoisonArmed = false, gInStress = false;
static std::atomic<long> gPoisoned{0};

static inline void gcStressTick()
{
    if ( gStressN < 0 ) {
        const char *e = ::getenv("GCSTRESS");
        gPoisonArmed = e != 0;
        gStressN = e ? ::atol(e) : 0;
        if ( gStressN < 0 ) gStressN = 0; }
    if ( gStressN == 0 || gInStress ) return;
    if ( ++gStressCount % gStressN ) return;
    gInStress = true;
    GC_gcollect();
    gInStress = false;
}

static inline void *gcThreadsAlloc(size_t n)
{
    if ( ::pthread_main_np() ) { gcStressTick(); return GC_malloc_uncollectable(n); }
    gOffNew++;
    return ::malloc(n ? n : 1);
}

static inline void gcThreadsFree(void *p)
{
    if ( !p ) return;
    if ( ::pthread_main_np() ) {
        if ( GC_base(p) )   GC_free(p);
        else                { gMainDelSystem++; ::free(p); }
        return; }
    gOffDel++;
    if ( ::malloc_size(p) ) ::free(p);
    else                    gOffDelLeaked++;
}

void *operator new(size_t n)
{
    void *p = gcThreadsAlloc(n);
    if ( !p ) GC_throw_bad_alloc();
    return p;
}
void *operator new[](size_t n)
{
    void *p = gcThreadsAlloc(n);
    if ( !p ) GC_throw_bad_alloc();
    return p;
}
void *operator new(size_t n, const std::nothrow_t &) noexcept     { return gcThreadsAlloc(n); }
void *operator new[](size_t n, const std::nothrow_t &) noexcept   { return gcThreadsAlloc(n); }
void operator delete(void *p) noexcept                            { gcThreadsFree(p); }
void operator delete[](void *p) noexcept                          { gcThreadsFree(p); }
void operator delete(void *p, const std::nothrow_t &) noexcept    { gcThreadsFree(p); }
void operator delete[](void *p, const std::nothrow_t &) noexcept  { gcThreadsFree(p); }
void operator delete(void *p, size_t) noexcept                    { gcThreadsFree(p); }
void operator delete[](void *p, size_t) noexcept                  { gcThreadsFree(p); }


/***************************************************************************
    THE GC INSTRUMENTS (SEQ 588) -- see the header.
****************************************************************************/
//  poisonFill a finalizer: the object was found unreachable; fill it, so a missed root reads the pattern
static void gcPoisonFill(void *obj, void *)
{
    ::memset(obj, 0xDE, GC_size(obj));
    gPoisoned++;
}

//  poisonOnFree register the fill on one collectable object; inert unless GCSTRESS is set (the base class of stroke 2 calls it)
extern "C" void gcPoisonOnFree(void *obj)
{
    if ( gStressN < 0 ) gcStressTick();
    if ( !gPoisonArmed || !obj ) return;
    GC_register_finalizer_no_order(obj, gcPoisonFill, 0, 0, 0);
}

//  collectOnce one collection, finalizers run; answers how many objects carrying the poison were found unreachable.
//  countObjects it counts OBJECTS through the poison's finalizer, never bytes. Both byte measures failed, measured SEQ 588:
//  countObjects in-use counts whole heap blocks and shows an explicit delete only at the next collection (a jittered run read
//  countObjects 77824 with nothing collectable -- LLVM's deletes), and libgc's bytes_reclaimed_since_gc reads 0 after a
//  countObjects collection that finalized 15 blocks, because the sweep is lazy. A finalizer runs once per unreachable object.
static long gcCollectOnce()
{
    long before = gPoisoned.load();
    GC_gcollect();
    GC_invoke_finalizers();
    return gPoisoned.load() - before;
}

//  collectNow the kant command collect: one collection; answers the poisoned objects it found unreachable (0 unless
//  collectNow GCSTRESS is set and something collectable registered the poison -- nothing does before stroke 2)
extern "C" GroupItem *collectNow(GroupItem *)
{
    long found = gcCollectOnce();
    GroupItem *answer = new GroupItem((char*)"collected");
    answer->setCount((int)found);
    return answer;
}

//  probeBlocks allocate in a frame of their own and keep only hidden pointers, so no scanned word holds them
static __attribute__((noinline)) void gcProbeAllocate(GC_hidden_pointer *hidden, int n)
{
    for (int i = 0; i < n; i++) {
        void *p = GC_malloc(64);
        ::memset(p, 0x11, 64);
        GC_register_finalizer_no_order(p, gcPoisonFill, 0, 0, 0);
        hidden[i] = GC_HIDE_POINTER(p); }
}

//  poisonProbe the kant command poisonProbe: the known-bad end, through collect's own counter -- 16 collectable blocks held
//  poisonProbe only by hidden pointers, one gcCollectOnce; answers how many came back filled, and prints what the counter said
extern "C" GroupItem *gcPoisonProbe(GroupItem *)
{
    enum { N = 16 };
    GC_hidden_pointer *hidden = (GC_hidden_pointer*)::malloc(sizeof(GC_hidden_pointer) * N);
    gcProbeAllocate(hidden, N);
    long found = gcCollectOnce();
    int filled = 0;
    for (int i = 0; i < N; i++) {
        unsigned char *p = (unsigned char*)GC_REVEAL_POINTER(hidden[i]);
        if ( p[0] == 0xDE && p[63] == 0xDE ) filled++; }
    ::free(hidden);
    ::fprintf(stderr,"=== poisonProbe: of %d unreachable blocks, collect's counter found %ld, %d filled ===\n", (int)N, found, filled);
    GroupItem *answer = new GroupItem((char*)"poisoned");
    answer->setCount(filled);
    return answer;
}

//  heapBase GC_base for jitContext.h's pin list (GC stroke 2, R3): the start of the collector block p points into, or 0
extern "C" void *gcHeapBase(void *p)
{
    return GC_base(p);
}
