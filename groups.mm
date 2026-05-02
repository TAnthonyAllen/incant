#include <Cocoa/Cocoa.h>
#include <string.h>
#include <stdio.h>
#include "gc/gc.h"
#include "OCroutines.h"
#include "GroupItem.h"
#include "GroupRules.h"
#include "RuleStuff.h"
#include "GroupDraw.h"
#include "GroupMain.h"
#include "groups.h"

/*******************************************************************************
	main
*******************************************************************************/
int main(int argc, char **argv)
{
	GC_INIT();
GroupMain 	*crap = new GroupMain();
char 		*name = argv[1];
	if ( name )
		{
		GroupItem 	*boot = crap->bootstrapper();
		GroupItem 	*source = new GroupItem(name);
		::getFile(source);
		boot->parse(0);
		}
}

void groups::run()
{
	return;
}
// Ignoring declaration of unused variable ruler in method: main(int,char**)
