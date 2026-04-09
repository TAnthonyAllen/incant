class Segment;
/*******************************************************************************
	This is a revised version of BitMAP that uses a simpler segment structure.
*******************************************************************************/

class BitMAP : public DoubleLinkList
{
public:
int bitCount;
static int emergency;
BitMAP();
BitMAP(int bit);
BitMAP(BitMAP *map);
int add(BitMAP *map);
int add(int bit);
int andEqual(BitMAP *map);
int ands(BitMAP *map);
void clear();
int contains(BitMAP *map);
int dQ();
void dump();
int get(int bit);
Segment *getSegmentContaining(int bit);
int lastBit();
int minus(BitMAP *map);
int minus(int bit);
int next(int bit);
int nth(int bit);
int pop();
int xorEqual(BitMAP *map);
int prior(int bit);
void setCount();
static int subscript(int bit);
};
