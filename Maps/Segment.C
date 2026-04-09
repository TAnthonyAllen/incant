#include <string.h>
#include <stdio.h>
#include "StringRoutines.h"
#include "DoubleLinkList.h"
#include "BitMAP.h"
#include "Segment.h"
int Segment::leftMap[] = {0, 8, 7, 7, 6, 6, 6, 6, 5, 5, 5, 5, 5, 5, 5, 5, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1};

/***************************************************************************
	Constructors
***************************************************************************/
Segment::Segment(int bit)
{
	offset = 0;
	bits = 0;
	if ( bit )
		add(bit);
}

Segment::Segment(Segment *part)
{
	offset = part->offset;
	bits = part->bits;
}

/*******************************************************************************
	Sets bit in the map
*******************************************************************************/
void Segment::add(int bit)
{
int 	i = 0;
	if ( !bits )
		offset = BitMAP::subscript(bit);
	i = bit - offset;
	if ( i > 0 && i <= 64 )
		bits |= Segment::bitMask(i);
	else	::fprintf(stderr,"Invalid bit offset into bit map\n");
}

/*******************************************************************************
	If the offsets match, ands the parameter map into this one.
*******************************************************************************/
void Segment::andEqual(Segment *map)
{
	if ( offset == map->offset )
		bits &= map->bits;
}

/*******************************************************************************
	Returns true if this shares any set bits with the map passed in
*******************************************************************************/
int Segment::ands(Segment *map)
{
	if ( offset == map->offset && bits & map->bits )
		return 1;
	return 0;
}

/*******************************************************************************
	Returns a 64 bit mask w/index bit turned on
*******************************************************************************/
unsigned long Segment::bitMask(int index)
{
int 			i = index % 64;
unsigned long 	masked = 0;
	if ( i )
		masked = 1LL << 64 - i;
	else
	if ( index )
		masked = 1LL;
	return masked;
}

/*******************************************************************************
 dump out the Segment
*******************************************************************************/
void Segment::dump()
{
int 	i = 0;
int 	limit = sizeof(long) * 8;
	::printf(" offset: %d bits set: %d\t[",offset,::bitCount(bits));
	for ( i = 1; i <= limit; i++ )
		{
		if ( bits & Segment::bitMask(i) )
			::printf("1");
		else	::printf("0");
		if ( !(i % 10) )
			::printf(" ");
		}
	::printf("]\n");
}

/*******************************************************************************
	Returns true if the bit passed in is set
*******************************************************************************/
int Segment::get(int bit)
{
unsigned long 	flag = 0;
int 			i = bit - offset;
	if ( i > 0 && i <= 64 )
		flag = bits & Segment::bitMask(i);
	return flag != 0;
}

/*******************************************************************************
	Subtracts the segment passed in from this one, assuming the offets match.
	This can zero out the segment. Dealing with a zeroed out segment is left
	to whoever calls this.
*******************************************************************************/
int Segment::minus(Segment *map)
{
unsigned long 	mask = 0;
	if ( offset == map->offset )
		if ( mask = bits & map->bits )
			{
			bits ^= mask;
			return 1;
			}
	return 0;
}

/*******************************************************************************
	Turns off bit in the map. This can zero out the segment. Dealing with a
	zeroed out segment is left to whoever calls this. Returns true if a bit
    was turned off, false otherwise.
*******************************************************************************/
int Segment::minus(int bit)
{
int 	i = bit - offset;
long 	mask = Segment::bitMask(i);
	if ( i > 0 && i <= 64 && bits & mask )
		{
		bits &= ~mask;
		return 1;
		}
	return 0;
}

/***************************************************************************
	Returns the offset to the next bit set following the bit argument. 	
***************************************************************************/
int Segment::next(int bit)
{
unsigned long 	word = bits;
int 			bite = 0;
int 			i = 7;
int 			j = 0;
int 			k = 0;
int 			bitOffset = 0;
	if ( bit > offset )
		{
		bitOffset = bit - offset;
		word <<= bitOffset;
		k = bitOffset >> 3;
		}
	if ( word )
		for ( ; i >= k; i--, j += 8 )
			{
			bite = (int)(word >> (i << 3)) & 0xff;
			if ( bite )
				return bitOffset + Segment::leftMap[bite] + j + offset;
			}
	return 0;
}

/*******************************************************************************
	Return the offset of the nth set bit
*******************************************************************************/
int Segment::nth(int bit)
{
unsigned char 	byte = 0;
unsigned char 	*atByte = 0;
int 			count = bit;
int 			position = 0;
int 			shift = 0;
int 			shifted = 0;
	if ( bit )
		{
		atByte = (unsigned char*)&bits + 7;
		while ( atByte >= (unsigned char*)&bits )
			{
			byte = *atByte;
			while ( byte )
				{
				shift = Segment::leftMap[byte];
				shifted += shift;
				if ( --count == 0 )
					return shifted + position + offset;
				byte <<= shift;
				}
			atByte--;
			position += 8;
			shifted = 0;
			}
		}
	return 0;
}

/*******************************************************************************
	If offsets match, logically ORs the parameter Segment into this one
*******************************************************************************/
void Segment::orEqual(Segment *map)
{
	if ( offset == map->offset )
		bits |= map->bits;
}

/***************************************************************************
	Returns offset to the set bit preceeding the bit argument. 	
***************************************************************************/
int Segment::prior(int bit)
{
unsigned long 	word = bits;
unsigned int 	i = 0;
unsigned int 	j = 1;
unsigned int 	bitOffset = bit - offset;
	if ( bitOffset == 1 )
		return 0;
	if ( bit && bitOffset > 0 && bitOffset <= 64 )
		{
		bitOffset = 65 - bitOffset;
		word >>= bitOffset;
		word <<= bitOffset;
		}
	bitOffset = 0;
	if ( word )
		{
		i = word & 0xffffffff;
		if ( !i )
			{
			bitOffset += 32;
			i = word >> 32;
			}
		if ((i & 0x0000ffff) == 0)
			{
			j += 16;
			i >>= 16;
			}
		if ((i & 0x000000ff) == 0)
			{
			j += 8;
			i >>= 8;
			}
		if ((i & 0x0000000f) == 0)
			{
			j += 4;
			i >>= 4;
			}
		if ((i & 0x00000003) == 0)
			{
			j += 2;
			i >>= 2;
			}
		i = offset + 64 - (bitOffset + j - (i & 1));
		}
	return i;
}

/*******************************************************************************
	Returns the right most bit
*******************************************************************************/
int Segment::rightMost()
{
unsigned long 	word = bits & -bits;
int 			bite = 0;
int 			i = 7;
int 			j = 0;
int 			k = 0;
	if ( word )
		for ( ; i >= k; i--, j += 8 )
			{
			bite = (int)(word >> (i << 3)) & 0xff;
			if ( bite )
				return Segment::leftMap[bite] + j + offset;
			}
	return 0;
}

/*******************************************************************************
	If offsets match, XORs the parameter map into this one
*******************************************************************************/
void Segment::xorEqual(Segment *map)
{
	if ( offset == map->offset )
		bits ^= map->bits;
}
