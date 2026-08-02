/*****************************************************************************
    shortenPop -- the unit POP for Buffer::shorten, added 2026-08-02 as the
    back-off primitive testContainer's longest-entry match is built on.

    Standalone on purpose: shorten is a Frame primitive with no incant surface,
    so wiring it to a command would cost an extern and move the canary to test
    twenty lines. This compiles Buffer.C directly and asserts values.

    Rule H4: every row PRINTS its quantity and compares it. No row can pass by
    a message being absent.
    Rule H2: the summary line is unreachable except through the last section.
*****************************************************************************/
#include <stdio.h>
#include <string.h>
#include "Buffer.h"

static int failures = 0;
static int checks   = 0;

static void row(const char *name, const char *got, const char *want)
{
    checks++;
    if (strcmp(got, want) == 0)
        printf("  ok    %-42s [%s]\n", name, got);
    else {
        printf("  FAIL  %-42s got [%s] want [%s]\n", name, got, want);
        failures++; }
}

static void rowLen(const char *name, int got, int want)
{
    checks++;
    if (got == want)
        printf("  ok    %-42s length = %d\n", name, got);
    else {
        printf("  FAIL  %-42s length = %d, want %d\n", name, got, want);
        failures++; }
}

int main(void)
{
Buffer  b("shortenPop");

    printf("shortenPop -- Buffer::shorten\n");

    /*  DOWN, one at a time: the back-off testContainer actually performs      */
    b.reset();
    b.appendString((char *)"--g", 0, 0);
    row("start", b.string(), "--g");
    b.shorten(1);   row("shorten(1) once", b.string(), "--");
    b.shorten(1);   row("shorten(1) twice", b.string(), "-");
    b.shorten(1);   row("shorten(1) to empty", b.string(), "");
    rowLen("length after emptying", b.length(), 0);

    /*  UNDERFLOW: shortening an already-empty buffer is a clamp, not a crash
        and not a negative length. This is the guard the back-off loop leans on
        -- it exits on length() == 0, but a caller that miscounts must not walk
        current back before start.                                            */
    b.shorten(1);   row("shorten(1) past empty", b.string(), "");
    rowLen("length after underflow", b.length(), 0);

    /*  A COUNT PAST THE END empties rather than underflowing                  */
    b.reset();
    b.appendString((char *)"abc", 0, 0);
    b.shorten(99);  row("shorten(99) on 3 chars", b.string(), "");
    rowLen("length after over-shorten", b.length(), 0);

    /*  ZERO is a no-op so a loop can call it unguarded                        */
    b.reset();
    b.appendString((char *)"abc", 0, 0);
    b.shorten(0);   row("shorten(0) is a no-op", b.string(), "abc");

    /*  EXACTLY length() empties, and the boundary is inclusive               */
    b.shorten(3);   row("shorten(length) empties", b.string(), "");

    /*  UP AGAIN after shortening: the buffer is still usable, current and the
        terminator are consistent, and nothing was left dangling. "Both
        directions" in the brief is this row.                                  */
    b.reset();
    b.appendString((char *)"abcdef", 0, 0);
    b.shorten(3);   row("shorten(3) of 6", b.string(), "abc");
    b.appendString((char *)"XY", 0, 0);
    row("append after shorten", b.string(), "abcXY");
    rowLen("length after append", b.length(), 5);
    b.shorten(2);   row("shorten again", b.string(), "abc");

    /*  MARK-UNAWARE, and this is the whole reason shorten is not an alias for
        deleteFromBuffer: with a mark armed, deleteFromBuffer deletes AT the
        mark. shorten always takes the tail. A caller that means "give back
        what I just appended" must not have that meaning changed by whether
        some earlier code armed a mark.                                        */
    b.reset();
    b.appendString((char *)"abc", 0, 0);
    b.setMark();
    b.appendString((char *)"def", 0, 0);
    b.shorten(3);   row("shorten with a mark armed takes the TAIL", b.string(), "abc");

    printf("\n");
    if (failures == 0)  printf("SHORTEN POP PASSED -- %d checks\n", checks);
    else                printf("SHORTEN POP FAILED -- %d of %d checks\n", failures, checks);
    return failures;
}
