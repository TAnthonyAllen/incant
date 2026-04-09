#include <string.h>
#include <stdio.h>
#include "StringRoutines.h"
#include "Segment.h"
#include "DoubleLinkList.h"
#include "DoubleLink.h"
#include "BitMAP.h"
int BitMAP::emergency;

/*******************************************************************************
	Consructors
*******************************************************************************/
BitMAP::BitMAP()
{
	bitCount = 0;
}

BitMAP::BitMAP(int bit)
{
	bitCount = 0;
	add(bit);
}

BitMAP::BitMAP(BitMAP *map)
{
DoubleLink 	*item = 0;
Segment 	*part = 0;
Segment 	*newPart = 0;
	for ( item = map->first; item; item = item->next )
		{
		part = (Segment*)item->value;
		newPart = new Segment(part);
		DoubleLinkList::add((void*)newPart);
		}
	bitCount = map->bitCount;
}

/*******************************************************************************
	Logically ORs this map with the map passed in. Returns true if count increased.
*******************************************************************************/
int BitMAP::add(BitMAP *map)
{
DoubleLink 	*item = first;
DoubleLink 	*mapItem = map->first;
Segment 	*part = 0;
Segment 	*mapPart = 0;
int 		increased = 0;
	if ( mapItem )
		{
		mapPart = (Segment*)mapItem->value;
		if ( !item )
			while ( mapItem )
				{
				mapPart = new Segment(mapPart);
				DoubleLinkList::add((void*)mapPart);
				if ( mapItem = mapItem->next )
					mapPart = (Segment*)mapItem->value;
				}
		else
		for ( ; item; item = item->next )
			{
			part = (Segment*)item->value;
			while ( mapItem && part->offset > mapPart->offset )
				{
				mapPart = new Segment(mapPart);
				item->insert((void*)mapPart);
				if ( mapItem = mapItem->next )
					mapPart = (Segment*)mapItem->value;
				else	mapPart = 0;
				increased = 1;
				}
			if ( mapPart && part->offset == mapPart->offset )
				{
				part->bits |= mapPart->bits;
				increased = 1;
				if ( mapItem = mapItem->next )
					mapPart = (Segment*)mapItem->value;
				else	break;
				}
			if ( !mapPart )
				break;
			}
		for ( ; mapItem; mapItem = mapItem->next )
			{
			mapPart = (Segment*)mapItem->value;
			mapPart = new Segment(mapPart);
			DoubleLinkList::add((void*)mapPart);
			increased = 1;
			}
		if ( increased )
			setCount();
		}
	return increased;
}

/*******************************************************************************
	Find the right segment and set the right bit in that segment. Returns true
    if a bit was set (if bit was already set, returns false).
*******************************************************************************/
int BitMAP::add(int bit)
{
DoubleLink 	*item = 0;
Segment 	*part = 0;
int 		bitOffset = BitMAP::subscript(bit);
	if ( get(bit) )
		return 0;
	else
	if ( !length )
		{
		part = new Segment(bit);
		DoubleLinkList::add((void*)part);
		}
	else
	for ( item = first; item; item = item->next )
		{
		part = (Segment*)item->value;
		if ( bitOffset > part->offset )
			if ( item->next )
				continue;
			else {
				part = new Segment(bit);
				item->append((void*)part);
				break;
				}
		if ( bitOffset < part->offset )
			{
			part = new Segment(bit);
			item->insert((void*)part);
			break;
			}
		part->add(bit);
		break;
		}
	bitCount++;
	return 1;
}

/*******************************************************************************
	Logically ANDs the parameter map into this one. Returns the number left
    in this map.
*******************************************************************************/
int BitMAP::andEqual(BitMAP *map)
{
DoubleLink 	*item = first;
DoubleLink 	*mapItem = 0;
DoubleLink 	*last = 0;
Segment 	*part = 0;
Segment 	*mapPart = 0;
	if ( !map )
		clear();
	if ( mapItem = map->first )
		{
		mapPart = (Segment*)mapItem->value;
		while ( last = item )
			{
			part = (Segment*)item->value;
			if ( mapPart )
				{
				if ( part->offset < mapPart->offset )
					{
					item = item->next;
					last->remove();
					continue;
					}
				while ( mapItem && part->offset > mapPart->offset )
					{
					mapItem = mapItem->next;
					if ( mapItem )
						mapPart = (Segment*)mapItem->value;
					else	mapPart = 0;
					}
				if ( mapPart && part->offset == mapPart->offset )
					{
					item = item->next;
					if ( !(part->bits &= mapPart->bits) )
						last->remove();
					continue;
					}
				}
			item = item->next;
			last->remove();
			}
		}
	setCount();
	return bitCount;
}

/*******************************************************************************
	Returns true if this map intersects the map passed in
*******************************************************************************/
int BitMAP::ands(BitMAP *map)
{
DoubleLink 	*item = first;
DoubleLink 	*mapItem = 0;
Segment 	*part = 0;
Segment 	*mapPart = 0;
	if ( !map || !map->first )
		return 0;
	mapItem = map->first;
	mapPart = (Segment*)mapItem->value;
	for ( ; item; item = item->next )
		{
		part = (Segment*)item->value;
		if ( part->offset < mapPart->offset )
			continue;
		while ( mapItem && part->offset > mapPart->offset )
			{
			mapItem = mapItem->next;
			if ( mapItem )
				mapPart = (Segment*)mapItem->value;
			else	mapPart = 0;
			}
		if ( !mapPart )
			break;
		if ( part->bits & mapPart->bits )
			return 1;
		}
	return 0;
}

/*******************************************************************************
	Frees map segments and clears bitCount.
*******************************************************************************/
void BitMAP::clear()
{
Segment 	*segment = 0;
	entry = 0;
	while ( segment = (Segment*)DoubleLinkList::next() )
		delete segment;
	bitCount = 0;
	DoubleLinkList::clear();
}

/*******************************************************************************
	Returns true if this map contains all entries in the map passed in
*******************************************************************************/
int BitMAP::contains(BitMAP *map)
{
DoubleLink 		*item = first;
DoubleLink 		*mapItem = 0;
Segment 		*part = 0;
Segment 		*mapPart = 0;
unsigned long 	wad = 0;
	if ( !map || !map->first )
		return 0;
	mapItem = map->first;
	mapPart = (Segment*)mapItem->value;
	for ( ; item; item = item->next )
		{
		part = (Segment*)item->value;
		if ( part->offset < mapPart->offset )
			continue;
		if ( part->offset == mapPart->offset )
			{
			wad = part->bits & mapPart->bits;
			if ( mapPart->bits != wad )
				return 0;
			}
		mapItem = mapItem->next;
		if ( !mapItem )
			return 1;
		mapPart = (Segment*)mapItem->value;
		}
	return 0;
}

/*******************************************************************************
	Treats BitMAP like a queue and pops off the first bit and returns it
*******************************************************************************/
int BitMAP::dQ()
{
	return minus(next(0));
}

/*******************************************************************************
 dump out the BitMAP
*******************************************************************************/
void BitMAP::dump()
{
DoubleLink 	*item = first;
Segment 	*part = 0;
	printf("Bits set: %d\n",bitCount);
	for ( ; item; item = item->next )
		{
		part = (Segment*)item->value;
		part->dump();
		}
}

/*******************************************************************************
	get a bit
*******************************************************************************/
int BitMAP::get(int bit)
{
DoubleLink 	*item = 0;
Segment 	*part = 0;
int 		bitOffset = BitMAP::subscript(bit);
	for ( item = first; item; item = item->next )
		{
		part = (Segment*)item->value;
		if ( bitOffset < part->offset )
			break;
		if ( bitOffset > part->offset )
			continue;
		return part->get(bit);
		}
	return 0;
}

/*******************************************************************************
	get the segment that contains the bit passed in
*******************************************************************************/
Segment *BitMAP::getSegmentContaining(int bit)
{
DoubleLink 	*item = first;
Segment 	*part = 0;
int 		limit = sizeof(long) * 8;
	for ( ; item; item = item->next )
		{
		part = (Segment*)item->value;
		if ( bit >= part->offset && bit < part->offset + limit )
			return part;
		}
	return (Segment*)0;
}

/*******************************************************************************
	Returns the last bit set
*******************************************************************************/
int BitMAP::lastBit()
{
Segment 	*part = 0;
int 		lastBit = 0;
	if ( last )
		if ( part = (Segment*)last->value )
			lastBit = part->rightMost();
	return lastBit;
}

/*******************************************************************************
	Subtracts the map passed in from this one. Returns true if anything was
    subtracted.
*******************************************************************************/
int BitMAP::minus(BitMAP *map)
{
DoubleLink 	*item = first;
DoubleLink 	*mapItem = map->first;
DoubleLink 	*last = 0;
Segment 	*part = 0;
Segment 	*mapPart = 0;
int 		reduced = 0;
	if ( !mapItem )
		return 0;
	mapPart = (Segment*)mapItem->value;
	while ( last = item )
		{
		part = (Segment*)item->value;
		if ( part->offset < mapPart->offset )
			{
			item = item->next;
			continue;
			}
		while ( mapItem && part->offset > mapPart->offset )
			{
			mapItem = mapItem->next;
			if ( mapItem )
				mapPart = (Segment*)mapItem->value;
			else	mapPart = 0;
			}
		if ( mapPart )
			{
			item = item->next;
			if ( part->minus(mapPart) )
				{
				if ( !part->bits )
					last->remove();
				reduced = 1;
				}
			continue;
			}
		else	break;
		}
	if ( reduced )
		{
		setCount();
		return 1;
		}
	return 0;
}

/*******************************************************************************
	clear a bit and delete segment if it goes empty. Returns the bit if it
    is found and deleted.
*******************************************************************************/
int BitMAP::minus(int bit)
{
DoubleLink 	*item = 0;
Segment 	*part = 0;
int 		bitOffset = 0;
	if ( bit )
		{
		bitOffset = BitMAP::subscript(bit);
		for ( item = first; item; item = item->next )
			{
			part = (Segment*)item->value;
			if ( bitOffset == part->offset )
				{
				if ( part->minus(bit) )
					{
					if ( !part->bits )
						{
						item->remove();
						delete part;
						}
					bitCount--;
					return bit;
					}
				break;
				}
			}
		}
	return 0;
}

/*******************************************************************************
	Return the position of the next bit greater than the bit argument
*******************************************************************************/
int BitMAP::next(int bit)
{
DoubleLink 	*item = 0;
Segment 	*part = 0;
int 		bitOffset = BitMAP::subscript(bit);
int 		result = 0;
	for ( item = first; item; item = item->next )
		{
		part = (Segment*)item->value;
		if ( bitOffset > part->offset )
			continue;
		if ( result = part->next(bit) )
			break;
		}
	return result;
}

/*******************************************************************************
	Return the offset of the nth set bit
*******************************************************************************/
int BitMAP::nth(int bit)
{
DoubleLink 	*item = 0;
Segment 	*part = 0;
int 		count = 0;
	for ( item = first; item; item = item->next )
		{
		part = (Segment*)item->value;
		count = ::bitCount(part->bits);
		if ( count < bit )
			bit -= count;
		else	return part->nth(bit);
		}
	return 0;
}

/*******************************************************************************
	Treats BitMAP like a stack and pops off the last bit and returns it
*******************************************************************************/
int BitMAP::pop()
{
Segment 	*part = 0;
int 		lastBit = 0;
	if ( last )
		if ( part = (Segment*)last->value )
			lastBit = part->rightMost();
	return minus(lastBit);
}

/*******************************************************************************
	Logically XORs the parameter map into this one
*******************************************************************************/
int BitMAP::xorEqual(BitMAP *map)
{
DoubleLink 	*item = first;
DoubleLink 	*mapItem = map->first;
DoubleLink 	*last = 0;
Segment 	*part = 0;
Segment 	*mapPart = 0;
	if ( !mapItem )
		return 0;
	mapPart = (Segment*)mapItem->value;
	for ( ; item; item = item->next )
		{
		part = (Segment*)item->value;
		while ( mapItem && part->offset > mapPart->offset )
			{
			mapPart = new Segment(mapPart);
			item->insert((void*)mapPart);
			if ( mapItem = mapItem->next )
				mapPart = (Segment*)mapItem->value;
			else	mapPart = 0;
			}
		if ( mapPart && part->offset == mapPart->offset )
			{
			part->bits ^= mapPart->bits;
			if ( !part->bits )
				last = item;
			if ( mapItem = mapItem->next )
				mapPart = (Segment*)mapItem->value;
			else	break;
			}
		if ( !mapPart )
			break;
		}
	if ( last )
		last->remove();
	setCount();
	return bitCount;
}

/*******************************************************************************
	Return the position of the bit preceeding the bit argument
*******************************************************************************/
int BitMAP::prior(int bit)
{
DoubleLink 	*item = 0;
Segment 	*part = 0;
int 		bitOffset = BitMAP::subscript(bit);
int 		result = 0;
	if ( !bit )
		item = last;
	else
	for ( item = first; item; item = item->next )
		{
		part = (Segment*)item->value;
		if ( bitOffset <= part->offset )
			break;
		}
	for ( ; item; item = item->prior )
		{
		part = (Segment*)item->value;
		if ( result = part->prior(bit) )
			break;
		}
	return result;
}

/*******************************************************************************
	Sets bitCount (done after any operation that combines or alters map).
*******************************************************************************/
void BitMAP::setCount()
{
DoubleLink 	*item = 0;
Segment 	*part = 0;
	bitCount = 0;
	for ( item = first; item; item = item->next )
		{
		part = (Segment*)item->value;
		bitCount += ::bitCount(part->bits);
		}
}

/*******************************************************************************
	Convert bit to a subscript to an offset.
*******************************************************************************/
int BitMAP::subscript(int bit)
{
int 	i = 0;
	//	The 6 used below corresponds to 64 bits per long
	if ( !bit )
		return 0;
	i = (bit - 1) >> 6;
	return i << 6;
}
