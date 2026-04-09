#include <Cocoa/Cocoa.h>
#include <string.h>
#include <stdio.h>
#include "OCroutines.h"
#include "GroupItem.h"
#include "DoubleLinkList.h"
#include "PLGitem.h"
#include "PLGset.h"
#include "Stak.h"
#include "Buffer.h"
#include "regex.h"
#include "PLGrgx.h"
#include "BitMAP.h"
#include "GroupList.h"
#include "GroupDraw.h"
#include "GroupBody.h"

/*****************************************************************************
	Constructors uses default constructor
*****************************************************************************/
GroupBody::GroupBody()
{
	groupList = 0;
	registry = 0;
	guardSet = 0;
	gText = 0;
	gPointer = (void*)0;
	gBuffer = 0;
	gCharacter = 0;
	gCharacterSet = 0;
	gCount = 0;
	gGroup = 0;
	gItem = 0;
	gMap = 0;
	gNumber = 0;
	gObject = 0;
	gRegex = 0;
	gStak = 0;
	tag = "dummy";
}

GroupBody::GroupBody(char *s)
{
	groupList = 0;
	registry = 0;
	guardSet = 0;
	gText = 0;
	gPointer = (void*)0;
	gBuffer = 0;
	gCharacter = 0;
	gCharacterSet = 0;
	gCount = 0;
	gGroup = 0;
	gItem = 0;
	gMap = 0;
	gNumber = 0;
	gObject = 0;
	gRegex = 0;
	gStak = 0;
	tag = s;
}
