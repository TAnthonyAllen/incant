#import <Cocoa/Cocoa.h>
#import <stdlib.h>
#import <WebKit/WebKit.h>
#import <string.h>
#import <stdio.h>
#import "GroupItem.h"
#import "OCroutines.h"
#import "GroupControl.h"
#import "PLGparse.h"
#import "Details.h"
#import "ParseXML.h"
#import "GroupRegistry.h"
#import "BaseHash.h"
#import "Bwana.h"
#import "junk.h"

/******************************************************************************
	GroupItem aliases have to preceed in order for noRoom setter to register
******************************************************************************/
GroupItem *attributeToGroup(GroupItem *item, char *attribute)
{
GroupItem 	*group = 0;
GroupItem 	*trait = 0;
char 		*name = 0;
	if ( item->registry )
		{
		trait = GroupControl::groupController->itemFactory(attribute);
		group = item->registry->addToRegistry(trait);
		trait = item->getAttribute(attribute);
		if ( trait && trait->data )
			{
			name = trait->getText();
			trait = (GroupItem*)item->registry->registryHash->get(name);
			if ( !trait )
				{
				GroupItem 	*registeredItem = GroupControl::groupController->itemFactory(name);
				trait = item->registry->addToRegistry(registeredItem);
				trait->addString(attribute);
				group->addGroup(trait);
				}
			}
		}
	return trait;
}

/*******************************************************************************
	Return a string representation of a bit index
*******************************************************************************/
char *bitString(unsigned long source)
{
char 			digit = 0;
int 			j = 0;
unsigned long 	mask = 1;
char 			*atText = 0;
char 			*text = (char*)::calloc(65,sizeof(char));
	mask <<= 63;
	atText = text;
	for ( j = 63; j >= 0; j--, atText++ )
		{
		mask >>= 1;
		digit = source & mask ? '1' : '0';
		::sprintf(atText,"%c",digit);
		}
	return text;
}

/*******************************************************************************
	main
*******************************************************************************/
int main(int argc, char **argv)
{
junk 	*crap = [[id alloc] init];
	if ( argc == 2 )
		[crap test:argv[1]];
	else	::fprintf(stderr,"invoke w/file name as argument\n");
}

@implementation junk

- (id)init
{
	parser = new ParseXML();
	parser->doNotExpandMacros = 0;
	registry = new GroupRegistry("Groupify");
	parser->currentRegistry = registry;
	return self;
}

- (void)test:(char*)filename
{
GroupItem 	*source = parser->parseFile(filename);
GroupItem 	*artist = 0;
GroupItem 	*album = 0;
GroupItem 	*item = 0;
	while ( item = source->nextMember(item) )
		{
		artist = ::attributeToGroup(item,"artist");
		album = ::attributeToGroup(item,"album");
		album->addGroup(item);
		if ( !artist->get(album->tag) )
			artist->addGroup(album);
		}
	item = (GroupItem*)registry->registryHash->get("artist");
	item->dumpDetail(0,99);
}
@end
// Ignoring declaration of unused variable parser in method: attributeToGroup(GroupItem*,char*)
