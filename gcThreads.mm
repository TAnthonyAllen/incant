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
****************************************************************************/
#include <new>
#include <cstdlib>
#include <cstdio>
#include <atomic>
#include <pthread.h>
#include <malloc/malloc.h>
#include "gc/gc.h"

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

static inline void *gcThreadsAlloc(size_t n)
{
    if ( ::pthread_main_np() ) return GC_malloc_uncollectable(n);
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
