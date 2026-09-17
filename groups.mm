#include <Cocoa/Cocoa.h>
#include <string.h>
#include <stdio.h>
#include "OCroutines.h"
#include "GroupItem.h"
#include "GroupRules.h"
#include "RuleStuff.h"
#include "Stylish.h"
#include "GroupDraw.h"
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
		/*  abandonedRun  THE OUTERMOST BOUNDARY. A refusal still standing here means the
		abandonedRun  rest of the file was never parsed -- say so, because exit 0 will
		abandonedRun  not.   ruleActions.reportRunAbandoned  */
		::reportRunAbandoned(name);
		}
}

void groups::run()
{
	return;
}
