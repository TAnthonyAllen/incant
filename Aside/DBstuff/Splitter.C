#include <stdlib.h>
#include <dispatch/dispatch.h>
#include <string.h>
#include <stdio.h>
#include "GroupItem.h"
#include "StringRoutines.h"
#include "PLGparse.h"
#include "Stak.h"
#include "Tape.h"
#include "ParseXML.h"
#include "DoubleLinkList.h"
#include "DoubleLink.h"
#include "DispatchQ.h"
#include "PLGitem.h"
#include "PLGtester.h"
#include "GroupList.h"
#include "Splitter.h"

/***************************************************************************
	Fix the parent of blocks following unmatched end tag
***************************************************************************/
void cleanup(GroupItem *b, GroupItem *match)
{
GroupItem 	*block =  ERROR could not find b;
	if ( ! ERROR could not find b. ERROR could not find parent )
		return;
	while ( block = block->nextBlock() )
		{
		item =  ERROR could not find b. ERROR could not find parent;
		if ( item && item->parent )
			item->parent->remove(item);
		 ERROR could not find match. ERROR could not find parent += block;
		}
}

/***************************************************************************
	Debugging routine to dump out split results
***************************************************************************/
void dump()
{
ParseXML 	**atParser = 0;
ParseXML 	*parser = 0;
GroupItem 	**atEndTags = 0;
	for ( atParser = splits; atParser && *atParser; atParser++ )
		{
		parser = *atParser;
		if ( parser->endTags->length )
			{
			atEndTags = (GroupItem**)parser->endTags->start;
			printf("End tag list\n");
			for ( ; atEndTags && *atEndTags; atEndTags++ )
				{
				block = *atEndTags;
				printf("\t%s\n",block->tag);
				}
			}
		else	printf("No end tags pending\n");
		printf("Block hierarchy\n");
		block = parser->ancestor;
		while ( block )
			{
			printf("\t%s\n",block->tag);
			block = block->parent;
			}
		}
}

/***************************************************************************
	Search parent for matching unclosed blocks
***************************************************************************/
GroupItem *findMatchingBlock(GroupItem *b, char *name)
{
GroupItem 	*entry = 0;
	if ( list->groupTape->name eq  ERROR could not find b. ERROR could not find tag )
		return  ERROR could not find b;
	entry =  ERROR could not find b.get(list->groupTape->name);
	if ( !entry &&  ERROR could not find b. ERROR could not find parent )
		entry = ::findMatchingBlock( ERROR could not find b. ERROR could not find parent,list->groupTape->name);
	return entry;
}

/***************************************************************************
	Figure out where to end a partition and return an item encapsulating the
	partition
***************************************************************************/
PLGitem *getEndItem(char *text, int size)
{
char 		*atText = group->getText() + stack->size;
int 		length = stack->size;
int 		flag = 0;
	while ( *atText != '>' && atText > group->getText() )
		{
		if ( *atText == '<' )
			flag = 1;
		atText--;
		length--;
		}
	if ( atText == group->getText() || !flag )
		length = stack->size;
	else
	if ( length < stack->size )
		length++;
	item = list->itemFactory(group->getText(),length);
	return item;
}

/***************************************************************************
	Handle embedded unmatched end tags
***************************************************************************/
void handleEndTags(GroupItem *block)
{
GroupItem 	*body = block->getAttribute("body");
GroupItem 	*epilog = block->getAttribute("epilog");
	//cout block.tag " has unmatched end tags\n";
	if ( !block->isClosed )
		{
		item = body->getItem();
		matchEndTags(block,item);
		}
	if ( block->getAttribute("epilog") )
		{
		item = epilog->getItem();
		matchEndTags(block,item);
		}
}

/***************************************************************************
	Parse the split input
***************************************************************************/
void parse()
{
ParseXML 	**atParser = 0;
ParseXML 	*parser = 0;
int 		i = 1;
DispatchQ 	*q = new DispatchQ();
	group = ::dispatch_group_create();
	if ( !input )
		{
		fprintf(stderr,"ERROR: Run split first\n");
		return;
		}
	for ( atParser = splits; atParser && *atParser; atParser++ )
		{
		parser = *atParser;
		useLocalLinkTape(GroupItem::groupList);
		void (^block)() = ^
			{
			printf("Starting Q%d\n",i);
			parser->run("StartXML");
			};
		q->run(block);
		i++;
		}
	q->wait(DISPATCH_TIME_FOREVER);
}

/*****************************************************************************
	Run the splitter to produce a GroupItem
*****************************************************************************/
GroupItem *run(char *filename)
{
	split( ERROR could not find filename);
	::parse();
	//dump();
	block = unsplit();
	return block;
}

/***************************************************************************
	Split file into parts and set a parser for each part
***************************************************************************/
int split(char *filename)
{
ParseXML 	**atSplit = splits;
ParseXML 	*parser = new ParseXML();
int 		i = 0;
long 		length = 0;
char 		*text = 0;
	text = ::getStringFromFile( ERROR could not find filename);
	length = ::strlen(text) / count;
	if ( length <= 100 )
		{
		fprintf(stderr,"%stoo small to split\n", ERROR could not find filename);
		return 0;
		}
	for ( i = 1; i < count; i++ )
		{
		item = ::getEndItem(text,length);
		if ( !item )
			{
			fprintf(stderr,"Failed to find end of partition: %d\n",i);
			return 0;
			}
		text += item->parts->length;
		*atSplit = new ParseXML();
		(*(atSplit++))->setInput(item);
		}
	*atSplit = parser;
	parser->setInput(text);
	return 1;
}

Splitter::Splitter(int i)
{
	input = 0;
	count = i;
	splits = (ParseXML**)::calloc(count + 1,sizeof(ParseXML*));
}

/***************************************************************************
	Fix the parent of blocks following unmatched end tag
***************************************************************************/
void Splitter::cleanup(GroupItem *b, GroupItem *match)
{
GroupItem 	*item = 0;
GroupItem 	*block = b;
	if ( !b->parent )
		return;
	while ( block = block->nextBlock() )
		{
		item = b->parent->getAttribute(block->tag);
		if ( item && item->parent )
			item->parent->remove(item);
		match->parent->addGroup(block);
		}
}

/***************************************************************************
	Debugging routine to dump out split results
***************************************************************************/
void Splitter::dump()
{
GroupItem 	*block = 0;
ParseXML 	**atParser = 0;
ParseXML 	*parser = 0;
GroupItem 	**atEndTags = 0;
	for ( atParser = splits; atParser && *atParser; atParser++ )
		{
		parser = *atParser;
		if ( parser->endTags->length )
			{
			atEndTags = (GroupItem**)parser->endTags->start;
			printf("End tag list\n");
			for ( ; atEndTags && *atEndTags; atEndTags++ )
				{
				block = *atEndTags;
				printf("\t%s\n",block->tag);
				}
			}
		else	printf("No end tags pending\n");
		printf("Block hierarchy\n");
		block = parser->ancestor;
		while ( block )
			{
			printf("\t%s\n",block->tag);
			block = block->parent;
			}
		}
}

/***************************************************************************
	Search parent for matching unclosed blocks
***************************************************************************/
GroupItem *Splitter::findMatchingBlock(GroupItem *b, char *name)
{
GroupItem 	*entry = 0;
	if ( ::compare(name,b->tag) == 0 )
		return b;
	entry = b->get(name);
	if ( !entry && b->parent )
		entry = findMatchingBlock(b->parent,name);
	return entry;
}

/***************************************************************************
	Figure out where to end a partition and return an item encapsulating the
	partition
***************************************************************************/
PLGitem *Splitter::getEndItem(char *text, int size)
{
char 		*atText = text + size;
PLGitem 	*item = 0;
int 		length = size;
int 		flag = 0;
	while ( *atText != '>' && atText > text )
		{
		if ( *atText == '<' )
			flag = 1;
		atText--;
		length--;
		}
	if ( atText == text || !flag )
		length = size;
	else
	if ( length < size )
		length++;
	item = item->test->testParser->plgItemFactory(text,length);
	return item;
}

/***************************************************************************
	Handle embedded unmatched end tags
***************************************************************************/
void Splitter::handleEndTags(GroupItem *block)
{
GroupItem 	*body = block->getAttribute("body");
GroupItem 	*epilog = block->getAttribute("epilog");
PLGitem 	*item = 0;
	//cout block.tag " has unmatched end tags\n";
	if ( !block->isClosed )
		{
		item = body->getItem();
		matchEndTags(block,item);
		}
	if ( block->getAttribute("epilog") )
		{
		item = epilog->getItem();
		matchEndTags(block,item);
		}
}
/*
Warning: the following methods were referenced but not declared
	get(char*)
	matchEndTags(GroupItem*,GroupItem*)
	split(null)
	unsplit()
*/
// Ignoring declaration of unused variable item in method: cleanup(GroupItem*,GroupItem*)
// Ignoring declaration of unused variable block in method: dump()
// Ignoring declaration of unused variable item in method: getEndItem(char*,int)
// Ignoring declaration of unused variable item in method: handleEndTags(GroupItem*)
// Ignoring declaration of unused variable block in method: run(char*)
// Ignoring declaration of unused variable item in method: split(char*)
