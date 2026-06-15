#include <Cocoa/Cocoa.h>
#include <string.h>
#include <stdio.h>
#include "OCroutines.h"
#include "GroupItem.h"
#include "GroupRules.h"
#include "RuleStuff.h"
#include "GroupMain.h"
#include "groups.h"

/*******************************************************************************
	main
*******************************************************************************/
int main(int argc, char **argv)
{
GroupMain 	*crap = new GroupMain();
char 		*name = argv[1];
	if ( name )
		{
		GroupItem 	*boot = crap->bootstrapper();
		GroupItem 	*source = new GroupItem(name);
		::loadInputFromFile(source);
		boot->parse(0);
		}
}

void groups::run()
{
	return;
}
