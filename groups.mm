#include <Cocoa/Cocoa.h>
#include <string.h>
#include <stdio.h>
#include "OCroutines.h"
#include "StringRoutines.h"
#include "GroupItem.h"
#include "GroupControl.h"
#include "GroupRules.h"
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
GroupRules 	*ruler = GroupControl::groupController->groupRules;
	if ( name )
		{
		GroupItem 	*boot = crap->bootstrapper();
		ruler->atRuleMark = ::getStringFromFile(name);
		ruler->ruleInputStart = ruler->atRuleMark;
		boot->parse(0);
		}
}

void groups::run()
{
	return;
}
