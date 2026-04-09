/*******************************************************************************
	Contains a segment of a BitMAP
*******************************************************************************/

class Segment
{
public:
int offset;
unsigned long bits;
static int leftMap[];
Segment(int bit);
Segment(Segment *part);
void add(int bit);
void andEqual(Segment *map);
int ands(Segment *map);
int bitCount();
static unsigned long bitMask(int index);
void dump();
int get(int bit);
int minus(Segment *map);
int minus(int bit);
int next(int bit);
int nth(int bit);
void orEqual(Segment *map);
int overlaps(Segment *map);
int prior(int bit);
int rightMost();
void xorEqual(Segment *map);
};
