#include <Cocoa/Cocoa.h>
#include <stdlib.h>
#include <WebKit/WebKit.h>
#include <string.h>
#include <stdio.h>
#include "GroupItem.h"
#include "OCroutines.h"
#include "DrawPoint.h"
#include "PLGparse.h"
#include "Details.h"
#include "DoubleLinkList.h"
#include "PLGrule.h"
#include "PLGitem.h"
#include "PLGset.h"
#include "BaseHash.h"
#include "Bwana.h"
#include "PLGtester.h"
#include "Stylish.h"
#include "Groups.h"

/*******************************************************************************
                Rule actions
            *******************************************************************************/
int AmountGroupsNow(PLGitem *iTEM)
{
PLGitem 	*number = iTEM->get("number");
PLGitem 	*part = iTEM->get("part");
	if ( part )
		{
		number->itemLength += part->itemLength;
		part->itemStart++;
		part->itemLength--;
		part->amount = ::atoi(part->string());
		part->unString();
		iTEM->flag1 = 1;
		number->amount = ::atof(number->string());
		}
	else	number->amount = ::atoi(number->string());
	number->unString();
	iTEM->flag1 = 1;
	return 1;
}

int DrawOperator3GroupsNow(PLGitem *iTEM)
{
Groups 		*p = (Groups*)iTEM->test->testParser;
	p->curving = 1;
	return 1;
}

int DrawOperator4GroupsNow(PLGitem *iTEM)
{
PLGitem 	*operate = iTEM->get("operate");
PLGitem 	*color = iTEM->get("color");
Groups 		*p = (Groups*)iTEM->test->testParser;
	if ( *operate->itemStart == 'F' )
		p->fillColor = color;
	else	p->strokeColor = color;
	return 1;
}

int DrawOperatorGroupsNow(PLGitem *iTEM)
{
PLGitem 	*operate = iTEM->get("operate");
Groups 		*p = (Groups*)iTEM->test->testParser;
GroupItem 	*group = p->drawingBlock->find(operate->string());
	operate->unString();
	if ( !group )
		return 0;
	p->notBlock = 0;
	//cout "Saw operator group",group.tag:;
	if ( (group->data == 3) || (group->data == 4) )
		return 0;
	operate->value = (void*)group;
	return 1;
}

int HexGroupsNow(PLGitem *iTEM)
{
PLGitem 		*hexed = iTEM->get("hexed");
unsigned int 	ui = 0;
	::sscanf(hexed->string(),"%x",&ui);
	hexed->amount = (double)ui;
	hexed->unString();
	return 1;
}

int KeyStrokeGroupsNow(PLGitem *iTEM)
{
PLGitem 	*modifiers = iTEM->get("modifiers");
PLGitem 	*key = iTEM->get("key");
Groups 		*p = (Groups*)iTEM->test->testParser;
PLGitem 	*modify = 0;
	// The following modifiers are aliased in Group.g
	for ( modify = modifiers; modify; modify = modify->next )
		if ( *modify->itemStart == 'a' )
			p->trait->modified = 1;
		else
		if ( *modify->itemStart == 'c' )
			p->trait->indexed = 1;
		else
		if ( *modify->itemStart == 'f' )
			p->trait->expanded = 1;
		else
		if ( *modify->itemStart == 'm' )
			p->trait->mustIndent = 1;
		else
		if ( *modify->itemStart == 'n' )
			p->trait->dotdot = 1;
		else
		if ( *modify->itemStart == 's' )
			p->trait->noAnchor = 1;
	key->itemLength = 1;
	p->trait->setItem(key);
	return 1;
}

int KeyStruck2GroupsNow(PLGitem *iTEM)
{
PLGitem 	*character = iTEM->get("character");
Groups 		*p = (Groups*)iTEM->test->testParser;
	if ( *character->itemStart >= 'A' && *character->itemStart <= 'Z' )
		p->trait->noAnchor = 1;
	return 1;
}

int KeyStruckGroupsNow(PLGitem *iTEM)
{
PLGitem 	*number = iTEM->get("number");
char 		c = ::atoi(number->string());
	number->unString();
	*iTEM->itemStart = c;
	return 1;
}

int Number2GroupsNow(PLGitem *iTEM)
{
PLGitem 	*number = iTEM->get("number");
Groups 		*p = (Groups*)iTEM->test->testParser;
GroupItem 	*group = 0;
	if ( number->itemLength == 1 && p->pathOpSet->contains(*number->itemStart) )
		return 0;
	if ( p->drawingBlock )
		group = p->drawingBlock->find(number->string());
	number->unString();
	if ( group && ((group->data == 3) || (group->data == 4)) )
		if ( (group->data == 3) )
			iTEM->amount = group->getCount();
		else	iTEM->amount = group->getNumber();
	else	return 0;
	return 1;
}

int NumberGroupsNow(PLGitem *iTEM)
{
PLGitem 	*number = iTEM->get("number");
	iTEM->amount = number->amount;
	return 1;
}

int PathListGroupsNow(PLGitem *iTEM)
{
Groups 		*p = (Groups*)iTEM->test->testParser;
	p->currentDP = 0;
	return 1;
}

int PointGroupsNow(PLGitem *iTEM)
{
PLGitem 	*point = iTEM->get("point");
PLGitem 	*yOffset = iTEM->get("yOffset");
Groups 		*p = (Groups*)iTEM->test->testParser;
	p->currentDP = new DrawPoint(point,yOffset);
	point->value = (void*)p->currentDP;
	return 1;
}

int PointOpGroupsNow(PLGitem *iTEM)
{
PLGitem 	*draw = iTEM->get("draw");
PLGitem 	*point = iTEM->get("point");
PLGitem 	*left = iTEM->get("left");
PLGitem 	*right = iTEM->get("right");
Groups 		*p = (Groups*)iTEM->test->testParser;
GroupItem 	*block = 0;
DrawPoint 	*dp = (DrawPoint*)point->value;
char 		*atOP = 0;
	for ( ; draw; draw = draw->next )
		{
		PLGitem 	*operate = draw->get("operate");
		if ( operate )
			if ( block = (GroupItem*)operate->value )
				dp->drawPathBlock = block;
			else {
				for ( atOP = operate->string(); *atOP; atOP++ )
					switch (*atOP)
						{
						case ':':
							dp->closeIt = 1;
							dp->direction = 0;
							dp->shape = 0;
							dp->translate = 0;
							break;
						case 'd':
							dp->direction = 4;
							break;
						case 'g':
							p->saveGraphicState = 1;
							break;
						case 'I':
							dp->translate = 1;
							break;
						case 'l':
							dp->direction = 1;
							break;
						case '@':
							dp->move = 1;
							break;
						case '!':
							dp->reset();
							break;
						case 'r':
							dp->direction = 2;
							break;
						case 'R':
							dp->translate = 2;
							break;
						case 'S':
							dp->translate = 3;
							break;
						case 'T':
							dp->translate = 4;
							break;
						case 'u':
							dp->direction = 3;
							break;
						case '~':
							p->itsAllRelative = 1;
							break;
						case '%':
							p->asPercentOfFrame = 1;
							break;
						case 'a':
							dp->shape = 1;
							break;
						case 'c':
							dp->shape = 2;
							break;
						case 'o':
							dp->shape = 3;
							break;
						case 'F':
							dp->fillPath = 1;
							break;
						case '$':
							dp->strokePath = 1;
						}
				operate->unString();
				}
		}
	dp->percent = p->asPercentOfFrame;
	if ( p->itsAllRelative )
		dp->relative = 1;
	if ( (dp->direction == 3) || (dp->direction == 4) )
		{
		dp->point.y = dp->point.x;
		dp->point.x = 0;
		}
	if ( (dp->direction == 1) )
		dp->xOperator = '-';
	if ( (dp->direction == 4) )
		dp->yOperator = '-';
	if ( dp->xOperator || dp->yOperator )
		dp->hasOperator = 1;
	if ( p->curving )
		{
		p->curving = 0;
		dp->control1 = (DrawPoint*)left->get("point")->value;
		dp->control2 = (DrawPoint*)right->get("point")->value;
		dp->control1->relative = dp->control2->relative = dp->relative;
		dp->control1->percent = dp->control2->percent = dp->percent;
		}
	if ( p->fillColor )
		{
		dp->fillColor = p->fillColor;
		p->fillColor = 0;
		}
	if ( p->strokeColor )
		{
		dp->strokeColor = p->strokeColor;
		p->strokeColor = 0;
		}
	::printf("PointOp: %s\n",dp->toString());
	return 1;
}

int RGBvalue2GroupsNow(PLGitem *iTEM)
{
PLGitem 	*redValue = iTEM->get("redValue");
PLGitem 	*greenValue = iTEM->get("greenValue");
PLGitem 	*blueValue = iTEM->get("blueValue");
PLGitem 	*hexed = redValue->get("hexed");
	redValue->amount = hexed->amount / 255;
	hexed = greenValue->get("hexed");
	greenValue->amount = hexed->amount / 255;
	hexed = blueValue->get("hexed");
	blueValue->amount = hexed->amount / 255;
	return 1;
}

int RGBvalueGroupsNow(PLGitem *iTEM)
{
	::printf("Saw hex amounts %s\n",iTEM->toString());
	return 1;
}

int SetNotBlockGroupsNow(PLGitem *iTEM)
{
Groups 	*p = (Groups*)iTEM->test->testParser;
	p->notBlock = 1;
	return 1;
}

/***************************************************************************
	Drawing data
***************************************************************************/
Groups::Groups()
{
	operateSet = 0;
	alphaSet = 0;
	hexSet = 0;
	nameSet = 0;
	notSpace = 0;
	pathOpSet = 0;
	curveOpSet = 0;
	curving = 0;
	style = 0;
	currentColor = 0;
	drawingBlock = 0;
	trait = 0;
	currentDP = 0;
	fillColor = 0;
	strokeColor = 0;
	asPercentOfFrame = 0;
	closeOut = 0;
	gotoPoint = 0;
	itsAllRelative = 0;
	nested = 0;
	saveGraphicState = 0;
	translated = 0;
	notBlock = 0;
	parserName = "Groups Style Parser";
	mainParser = (void*)this;
}

/***************************************************************************
	Parse the path defined in the text of the GroupItem passed in. It returns
    a pathSet, a list of paths each of which is a list of DrawPoints.
***************************************************************************/
DrawPoint ***Groups::buildPath(GroupItem *item)
{
PLGitem 	*entry = 0;
PLGitem 	*list = 0;
PLGitem 	*path = 0;
int 		size = 0;
DrawPoint 	**drawingPath = 0;
DrawPoint 	**atPath = 0;
DrawPoint 	***pathSet = 0;
DrawPoint 	***atSet = 0;
char 		*text = item->getText();
	//debug = true;
	DrawPoint::drawGroup = 0;
	if ( text )
		if ( path = run("PathList",item) )
			{
			list = path->get("list");
			for ( entry = list; entry; entry = entry->next )
				size++;
			atSet = pathSet = (DrawPoint***)::calloc(size + 1,sizeof(DrawPoint*));
			for ( entry = list; entry; entry = entry->next )
				{
				size = 0;
				for ( path = entry->get("path"); path; path = path->next )
					size++;
				atPath = drawingPath = (DrawPoint**)::calloc(size + 1,sizeof(DrawPoint*));
				for ( path = entry->get("path"); path; path = path->next )
					{
					PLGitem 	*point = path->get("point");
					DrawPoint 	*dp = (DrawPoint*)point->value;
					*atPath++ = dp;
					}
				*atSet++ = drawingPath;
				}
			item->addAttrValue("drawPathSet",(void*)pathSet);
			item->setPointer((void*)pathSet);
			DrawPoint::drawGroup = item;
			}
		else	::fprintf(stderr,"\tERROR %s: Failed parse of drawing commands\n",item->tag);
	else	::fprintf(stderr,"\tERROR %s: No drawing commands found\n",item->tag);
	return pathSet;
}

/***************************************************************************
    Process a keystroke specification used to match a key action.
***************************************************************************/
int Groups::processKeySpec(GroupItem *keyTrait)
{
PLGitem 	*item = 0;
	trait = keyTrait;
	if ( trait && trait->data )
		{
		if ( item = divertInput(trait->getText(),getRule("KeyStroke")) )
			{
			trait->keyAction = 1;
			return 1;
			}
		else	::fprintf(stderr,"processKeySpec: failed\n");
		}
	return 0;
}

PLGitem *Groups::run(char *name)
{
	if ( !rules->hashList->length )
		{
		setRules();
		initialize();
		}
	return parse(name);
}

PLGitem *Groups::run(char *rule, GroupItem *item)
{
	trait = item;
	setInput(item->getText());
	return run(rule);
}

void Groups::setRules()
{
	setSkip();
	operateSet = getSet("operateSet","-+*/");
	alphaSet = getSet("alphaSet","A-Za-z");
	hexSet = getSet("hexSet","0-9a-f");
	nameSet = getSet("nameSet","A-Za-z0-9");
	notSpace = getSet("notSpace","^ \t\n\r\f");
	pathOpSet = getSet("pathOpSet","%~@:!dgIlrRSTu");
	curveOpSet = getSet("curveOpSet","aco");
	//
	currentRule = getRule("Amount");
	currentRule->immediate = ::AmountGroupsNow;
	currentSet = getSet("0-9");
	addTest(6,(void*)currentSet,"number",1,268435455,(char*)0);
	currentSet = getSet(".0-9");
	addTest(6,(void*)currentSet,"part",0,268435455,(char*)0);
	//
	currentRule = getRule("DrawOperator");
	currentRule->immediate = ::DrawOperatorGroupsNow;
	addTest(5,(void*)getRule("SetNotBlock"),(char*)0,1,1,"defaultSKIP");
	addTest(5,(void*)getRule("Name"),"operate",1,1,"defaultSKIP");
	currentRule->next = getRule("DrawOperator2");
	//
	currentRule = getRule("DrawOperator3");
	currentRule->immediate = ::DrawOperator3GroupsNow;
	addTest(8,(void*)&notBlock,(char*)0,1,1,"defaultSKIP");
	currentTest->type = 8;
	currentSet = curveOpSet;
	addTest(6,(void*)currentSet,"operate",1,1,"defaultSKIP");
	currentRule->next = getRule("DrawOperator4");
	//
	currentRule = getRule("DrawOperator4");
	currentRule->immediate = ::DrawOperator4GroupsNow;
	addTest(8,(void*)&notBlock,(char*)0,1,1,"defaultSKIP");
	currentTest->type = 8;
	currentSet = getSet("F$");
	addTest(6,(void*)currentSet,"operate",1,1,"defaultSKIP");
	addTest(5,(void*)getRule("DrawColor"),"color",0,1,"defaultSKIP");
	//
	currentRule = getRule("ColorList");
	addTest(5,(void*)getRule("ColorItem"),"list",1,268435455,"defaultSKIP");
	//
	currentRule = getRule("Hex");
	currentRule->immediate = ::HexGroupsNow;
	currentSet = hexSet;
	addTest(6,(void*)currentSet,"hexed",2,2,(char*)0);
	//
	currentRule = getRule("KeyStruck");
	currentRule->immediate = ::KeyStruckGroupsNow;
	addTest(7,(void*)"/",(char*)0,1,1,(char*)0);
	currentSet = getSet("0-9");
	addTest(6,(void*)currentSet,"number",1,268435455,(char*)0);
	currentRule->next = getRule("KeyStruck2");
	//
	currentRule = getRule("KeyStruck2");
	currentRule->immediate = ::KeyStruck2GroupsNow;
	currentSet = getSet("^\n");
	addTest(6,(void*)currentSet,"character",1,1,(char*)0);
	//
	currentRule = getRule("KeyStroke");
	currentRule->immediate = ::KeyStrokeGroupsNow;
	currentSet = getSet("acfmns");
	addTest(6,(void*)currentSet,"modifiers",0,268435455,(char*)0);
	addTest(7,(void*)"-",(char*)0,1,1,(char*)0);
	addTest(5,(void*)getRule("KeyStruck"),"key",1,1,(char*)0);
	//
	currentRule = getRule("Number");
	currentRule->immediate = ::NumberGroupsNow;
	currentSet = operateSet;
	addTest(6,(void*)currentSet,"operator",0,1,(char*)0);
	addTest(5,(void*)getRule("Amount"),"number",1,1,(char*)0);
	currentRule->next = getRule("Number2");
	//
	currentRule = getRule("Number2");
	currentRule->immediate = ::Number2GroupsNow;
	currentSet = operateSet;
	addTest(6,(void*)currentSet,"operator",0,1,(char*)0);
	addTest(5,(void*)getRule("Name"),"number",1,1,(char*)0);
	//
	currentRule = getRule("PathList");
	currentRule->immediate = ::PathListGroupsNow;
	addTest(5,(void*)getRule("DrawingPath"),"list",1,268435455,"defaultSKIP");
	//
	currentRule = getRule("Point");
	currentRule->immediate = ::PointGroupsNow;
	addTest(5,(void*)getRule("Number"),"point",1,1,"defaultSKIP");
	addTest(5,(void*)getRule("Number"),"yOffset",0,1,"defaultSKIP");
	addTest(7,(void*)",",(char*)0,0,1,"defaultSKIP");
	//
	currentRule = getRule("PointOp");
	currentRule->immediate = ::PointOpGroupsNow;
	addTest(5,(void*)getRule("DrawOperator"),"draw",0,268435455,"defaultSKIP");
	addTest(5,(void*)getRule("Point"),"point",1,1,"defaultSKIP");
	addTest(8,(void*)&curving,(char*)0,1,1,"defaultSKIP");
	currentTest->type = 8;
	addTest(5,(void*)getRule("Point"),"left",1,1,"defaultSKIP");
	addTest(5,(void*)getRule("Point"),"right",1,1,"defaultSKIP");
	//
	currentRule = getRule("RGBvalue");
	currentRule->immediate = ::RGBvalueGroupsNow;
	addTest(5,(void*)getRule("Amount"),"hex",3,3,"defaultSKIP");
	currentRule->next = getRule("RGBvalue2");
	//
	currentRule = getRule("RGBvalue2");
	currentRule->immediate = ::RGBvalue2GroupsNow;
	addTest(7,(void*)"#",(char*)0,1,1,"defaultSKIP");
	addTest(5,(void*)getRule("Hex"),"redValue",1,1,"defaultSKIP");
	addTest(5,(void*)getRule("Hex"),"greenValue",1,1,"defaultSKIP");
	addTest(5,(void*)getRule("Hex"),"blueValue",1,1,"defaultSKIP");
	//
	currentRule = getRule("SetNotBlock");
	currentRule->immediate = ::SetNotBlockGroupsNow;
	//
	currentRule = getRule("Name");
	currentSet = alphaSet;
	addTest(6,(void*)currentSet,(char*)0,1,1,(char*)0);
	currentSet = nameSet;
	addTest(6,(void*)currentSet,(char*)0,0,268435455,(char*)0);
	//
	currentRule = getRule("Color");
	addTest(5,(void*)getRule("RGBvalue"),"color",1,1,"defaultSKIP");
	addTest(5,(void*)getRule("Amount"),"value",0,1,"defaultSKIP");
	currentRule->next = getRule("Color2");
	//
	currentRule = getRule("Color2");
	addTest(5,(void*)getRule("Name"),"color",1,1,"defaultSKIP");
	//
	currentRule = getRule("ColorItem");
	addTest(5,(void*)getRule("Color"),"color",1,1,"defaultSKIP");
	addTest(7,(void*)",",(char*)0,0,1,"defaultSKIP");
	//
	currentRule = getRule("BorderValue");
	addTest(5,(void*)getRule("Color"),"color",1,1,"defaultSKIP");
	currentRule->next = getRule("BorderValue2");
	//
	currentRule = getRule("BorderValue2");
	addTest(5,(void*)getRule("Name"),"name",1,1,"defaultSKIP");
	currentRule->next = getRule("BorderValue3");
	//
	currentRule = getRule("BorderValue3");
	addTest(5,(void*)getRule("Amount"),"value",1,1,"defaultSKIP");
	//
	currentRule = getRule("BorderLine");
	addTest(5,(void*)getRule("BorderValue"),(char*)0,1,1,"defaultSKIP");
	addTest(7,(void*)",",(char*)0,0,1,"defaultSKIP");
	//
	currentRule = getRule("Border");
	addTest(5,(void*)getRule("BorderLine"),(char*)0,1,268435455,"defaultSKIP");
	//
	currentRule = getRule("DrawColor");
	addTest(7,(void*)"=",(char*)0,1,1,"defaultSKIP");
	addTest(5,(void*)getRule("Color"),"color",1,1,"defaultSKIP");
	//
	currentRule = getRule("DrawOperator2");
	addTest(8,(void*)&notBlock,(char*)0,1,1,"defaultSKIP");
	currentTest->type = 8;
	currentSet = pathOpSet;
	addTest(6,(void*)currentSet,"operate",1,1,"defaultSKIP");
	currentRule->next = getRule("DrawOperator3");
	//
	currentRule = getRule("DrawingPath");
	addTest(5,(void*)getRule("PointOp"),"path",1,268435455,"defaultSKIP");
	addTest(7,(void*)";",(char*)0,1,1,"defaultSKIP");
}
// Ignoring declaration of unused variable p in method: AmountGroupsNow(PLGitem*)
// Ignoring declaration of unused variable operate in method: DrawOperator3GroupsNow(PLGitem*)
// Ignoring declaration of unused variable p in method: HexGroupsNow(PLGitem*)
// Ignoring declaration of unused variable p in method: KeyStruckGroupsNow(PLGitem*)
// Ignoring declaration of unused variable operator in method: Number2GroupsNow(PLGitem*)
// Ignoring declaration of unused variable operator in method: NumberGroupsNow(PLGitem*)
// Ignoring declaration of unused variable p in method: NumberGroupsNow(PLGitem*)
// Ignoring declaration of unused variable list in method: PathListGroupsNow(PLGitem*)
// Ignoring declaration of unused variable p in method: RGBvalue2GroupsNow(PLGitem*)
// Ignoring declaration of unused variable hex in method: RGBvalueGroupsNow(PLGitem*)
// Ignoring declaration of unused variable p in method: RGBvalueGroupsNow(PLGitem*)
