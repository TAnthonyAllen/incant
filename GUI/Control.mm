#include <Cocoa/Cocoa.h>
#include <stdlib.h>
#include <Foundation/Foundation.h>
#include <WebKit/WebKit.h>
#include <string.h>
#include <stdio.h>
#include "GroupItem.h"
#include "OCroutines.h"
#include "StringRoutines.h"
#include "GroupList.h"
#include "GroupLink.h"
#include "GroupControl.h"
#include "PLGparse.h"
#include "Control.h"
#include "Details.h"
#include "Bwana.h"
#include "Delegate.h"
#include "Tape.h"
#include "ParseXML.h"
#include "DoubleLinkList.h"
#include "PLGitem.h"
#include "BaseHash.h"
#include "Buffer.h"
#include "Source.h"
#include "Layout.h"

/*******************************************************************************
	Generate the code to draw the block passed in
*******************************************************************************/
void jsDraw(GroupItem *block, Buffer *buffer)
{
Details 	*detail = ::getDetail(block);
GroupItem 	*rounded = block->getAttribute("rounded");
GroupItem 	*border = block->getAttribute("border");
GroupItem 	*stroke = block->getAttribute("stroke");
GroupItem 	*fill = block->getAttribute("fill");
GroupItem 	*group = 0;
int 		fillIt = 0;
int 		radius = 0;
int 		strokeIt = 0;
char 		*filler = 0;
char 		*stroker = 0;
	if ( rounded || border || fill )
		{
		if ( fill )
			{
			fillIt = 1;
			if ( filler = fill->getText() )
				if ( group = Control::colorRegistry->get(filler) )
					if ( group->data )
						filler = ::concat(3,"'",group->getText(),"'");
			if ( !filler )
				filler = "0";
			}
		if ( stroke )
			stroker = stroke->getText();
		strokeIt = 1;
		if ( rounded )
			{
			radius = rounded->getCount();
			if ( !radius )
				radius = 5;
			}
		if ( border && border->data )
			stroker = border->getText();
		if ( stroker )
			if ( group = Control::colorRegistry->get(stroker) )
				if ( group->data )
					stroker = ::concat(3,"'",group->getText(),"'");
		if ( !stroker )
			stroker = "0";
		appendStringBuffer(buffer,"//",0,0);
		appendStringBuffer(buffer," ",0,0);
		appendStringBuffer(buffer,block->tag,0,0);
		appendStringBuffer(buffer,"\n",0,0);
		appendStringBuffer(buffer,"\t",0,0);
		appendStringBuffer(buffer,"\t",0,0);
		appendStringBuffer(buffer,"drawBox(",0,0);
		appendDoubleBuffer(buffer,detail->frame.origin.x,"%4.1f",4);
		appendStringBuffer(buffer,",",0,0);
		appendDoubleBuffer(buffer,detail->frame.origin.y,"%4.1f",4);
		appendStringBuffer(buffer,",",0,0);
		appendDoubleBuffer(buffer,detail->frame.size.width,"%4.1f",4);
		appendStringBuffer(buffer,",",0,0);
		appendDoubleBuffer(buffer,detail->frame.size.height,"%4.1f",4);
		appendStringBuffer(buffer,",",0,0);
		appendIntBuffer(buffer,radius,0,0);
		appendStringBuffer(buffer,",",0,0);
		appendIntBuffer(buffer,fillIt,0,0);
		appendStringBuffer(buffer,",",0,0);
		appendStringBuffer(buffer,filler,0,0);
		appendStringBuffer(buffer,",",0,0);
		appendIntBuffer(buffer,strokeIt,0,0);
		appendStringBuffer(buffer,",",0,0);
		appendStringBuffer(buffer,stroker,0,0);
		appendStringBuffer(buffer,");",0,0);
		appendStringBuffer(buffer,"\n",0,0);
		}
	/***************************************************************************
	If this draws a path, the starting point gets first set to be the middle
	of the enclosing block (by translation, so the middle gets set to be the
	point at 0,0).
	***************************************************************************/
	if ( (detail->content == 4) )
		{
		appendStringBuffer(buffer,"//",0,0);
		appendStringBuffer(buffer," ",0,0);
		appendStringBuffer(buffer,block->tag,0,0);
		appendStringBuffer(buffer,"\n",0,0);
		appendStringBuffer(buffer,stringBuffer(block->getBuffer()),0,0);
		appendStringBuffer(buffer,"\n",0,0);
		}
	if ( (detail->content == 5) )
		{
		NSTextView 	*editor = detail->object;
		if ( editor )
			{
			char 				*imageName = ::concat(2,"Base64Image",block->tag);
			NSBitmapImageRep 	*BMrep = [editor bitmapImageRepForCachingDisplayInRect:[editor visibleRect]];
			NSData 				*data = [BMrep representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.5] forKey:NSImageCompressionFactor]];
			NSData 				*encoded = [data base64EncodedDataWithOptions:NSDataBase64Encoding64CharacterLineLength];
			char 				*text = (char*)[encoded bytes];
			appendStringBuffer(buffer,"var",0,0);
			appendStringBuffer(buffer," ",0,0);
			appendStringBuffer(buffer,imageName,0,0);
			appendStringBuffer(buffer," ",0,0);
			appendStringBuffer(buffer,"= new Image();",0,0);
			appendStringBuffer(buffer,"\n",0,0);
			appendStringBuffer(buffer,imageName,0,0);
			appendStringBuffer(buffer,".src = \"data:image/jpeg;base64,",0,0);
			appendStringBuffer(buffer,text,0,0);
			appendStringBuffer(buffer,"\";",0,0);
			appendStringBuffer(buffer,"\n",0,0);
			appendStringBuffer(buffer,"ctx.drawImage(",0,0);
			appendStringBuffer(buffer,imageName,0,0);
			appendStringBuffer(buffer,",",0,0);
			appendStringBuffer(buffer,::toString([editor frame]),0,0);
			appendStringBuffer(buffer,");",0,0);
			appendStringBuffer(buffer,"\n",0,0);
			}
		}
}

/*******************************************************************************
    Returns the next visible item using a depth first walk that skips over
	blocks that have no room
*******************************************************************************/
GroupItem *walkVisible(GroupItem *base, GroupItem *item)
{
GroupItem 	*group = 0;
	if ( !item )
		return base;
	if ( item->isTarget )
		while ( group = item->parent )
			{
			do	item = group->nextMember(item);
			while ( item && item->isTarget );
			if ( !item && group->parent )
				{
				if ( group == base )
					return 0;
				item = group;
				}
			else	return item;
			}
	if ( item->hasMembers )
		{
		item->reset();
		do	group = item->nextMember();
		while ( group && group->isTarget );
		if ( group )
			return group;
		}
	if ( item != base )
		while ( group = item->parent )
			{
			do	item = group->nextMember(item);
			while ( item && item->isTarget );
			if ( !item && group->parent )
				{
				if ( group == base )
					return 0;
				item = group;
				}
			else	return item;
			}
	return 0;
}
Bwana *Control::bwana;
GroupItem *Control::fontRegistry;
GroupItem *Control::colorRegistry;

Control::Control()
{
	baseURL = 0;
	loadedItem = 0;
	root = 0;
	activeView = 0;
	flexLayoutStash = 0;
	attributeDetail = 0;
	buffer = 0;
	convertWindowToPanel = 0;
	showWarnings = 0;
	timer = [NSDate date];
	detailTape = new Tape("Details details",1000,sizeof(Details));
	GroupControl::groupController = new GroupControl(10000);
	GroupControl::registries->addString("doNotCopy");
	GroupControl::groupController->setBaseRegistries();
	GroupControl::groupController->groupParser->doNotExpandMacros = 0;
	Control::bwana = new Bwana(this);
	classList = GroupControl::groupController->itemFactory("classes");
	delegator = [[Delegate alloc] init];
	controlBuffer = GroupControl::groupController->groupParser->scratch;
	setup();
}

/*******************************************************************************
	This takes the chain of PLGitems in the calling parent block that ParseXML
    creates when it is parsing text and converts it into <p> html blocks that
    get added to the parent block
*******************************************************************************/
GroupItem *Control::addPara(GroupItem *block, char *s)
{
GroupItem 	*group = GroupControl::groupController->itemFactory("p");
	group->setText(s);
	group->isClosed = 1;
	if ( block->firstMember() )
		{
		group->groupLink = block->parts->entry->insert(group->tag,group);
		group->affiliation = 3;
		group->parent = block;
		block->hasMembers = 1;
		}
	else	block->addGroup(group);
	block->setItem((PLGitem*)0);
	group->registry = GroupControl::groupController->htmlRegister;
	return group;
}

/******************************************************************************
	Debugging dump of frame
******************************************************************************/
void Control::dump(GroupItem *group)
{
Details 	*detail = ::getDetail(group);
GroupItem 	*item = 0;
	if ( detail )
		detail->dump();
	group->reset();
	if ( group->hasMembers )
		while ( item = group->nextMember() )
			if ( !item->isComment )
				dump(item);
}

/*******************************************************************************
	Populate the width, and height attributes. The x and y attributes are left
    out and get ignored, letting html deal w/positioning
*******************************************************************************/
void Control::fillFrame(GroupItem *item)
{
Details 	*detail = ::getDetail(item);
GroupItem 	*group = 0;
	if ( detail )
		{
		if ( group = item->get("width") )
			group->setNumber(detail->frame.size.width);
		else	group = item->addAttrDouble("width",detail->frame.size.width);
		if ( group = item->get("height") )
			group->setNumber(detail->frame.size.height);
		else	group = item->addAttrDouble("height",detail->frame.size.height);
		}
}

/*******************************************************************************
	Set the size of this based on the size of the components. Triggered by
    the fit attribute. If the fit attribute has no value, the fit follows the
    direction of the current item's layout orientation. The fit values are:
        height          vertical fit
        width           horizontal fit
        both            both horizontal and vertical
        none            horizontal, if orientation is across
                        vertical, if orientation is down
*******************************************************************************/
void Control::fitSize(GroupItem *item)
{
Details 	*detail = ::getDetail(item);
GroupItem 	*group = 0;
GroupItem 	*fit = item->getAttribute("fit");
char 		*fitting = fit->getText();
int 		noFitAcross = 0;
int 		noFitDown = 0;
	//cout `"Fitting: " item.tag:;
	if ( (detail->sizeToFit == 2) )
		if (::compare(fitting,"width") != 0)
			detail->frame.size.height = 0;
		else {
			noFitDown = 1;
			detail->frame.size.width = 0;
			}
	else
	if ( (detail->sizeToFit == 1) )
		if (::compare(fitting,"height") != 0)
			detail->frame.size.width = 0;
		else {
			noFitAcross = 1;
			detail->frame.size.height = 0;
			}
	else
	if ( (detail->sizeToFit == 3) )
		detail->frame.size.width = detail->frame.size.height = 0;
	while ( group = item->nextMember(group) )
		{
		GroupItem 	*groupFit = group->get("fit");
		int 		groupHeight = 0;
		int 		groupWidth = 0;
		if ( groupFit )
			{
			fitSize(group);
			groupHeight = detail->frame.size.height;
			groupWidth = detail->frame.size.width;
			}
		else {
			if ( groupFit = group->getAttribute("height") )
				groupHeight = groupFit->getNumber();
			if ( groupFit = group->getAttribute("width") )
				groupWidth = groupFit->getNumber();
			}
		if ( !noFitDown && ((detail->sizeToFit == 2) || (detail->sizeToFit == 3)) )
			{
			if ( (detail->orient == 1) )
				detail->frame.size.height += groupHeight;
			else
			if ( (detail->orient == 2) && groupHeight > detail->frame.size.height )
				detail->frame.size.height = groupHeight;
			}
		if ( !noFitAcross && ((detail->sizeToFit == 1) || (detail->sizeToFit == 3)) )
			if ( (detail->orient == 2) )
				detail->frame.size.width += groupWidth;
			else
			if ( (detail->orient == 1) && groupWidth > detail->frame.size.width )
				detail->frame.size.width = groupWidth;
		}
}

/*******************************************************************************
	Set layout of flexible contents.
*******************************************************************************/
void Control::flexLayout(GroupItem *group)
{
GroupItem 	*first = 0;
GroupItem 	*item = 0;
Details 	*itemDetail = 0;
Details 	*detail = 0;
double 		added = 0;
double 		extent = 0;
double 		roomLeft = 0;
	// indexed turned off so new flex content added as a source listener in nEXT()
	group->indexed = 0;
	detail = ::setDetail(group);
	if ( detail->view->resized )
		detail->high = 0;
	if ( (detail->orient == 2) )
		{
		if ( detail->high && detail->high >= detail->frame.size.width )
			return;
		if ( !detail->high )
			roomLeft = detail->frame.size.width;
		else	roomLeft = detail->frame.size.width - detail->high;
		}
	else {
		if ( detail->high && detail->high >= detail->frame.size.height )
			return;
		if ( !detail->high )
			roomLeft = detail->frame.size.height;
		else	roomLeft = detail->frame.size.height - detail->high;
		}
	detail->offset = 0;
	group->reset();
	while ( item = group->nextMember() )
		{
		itemDetail = ::setDetail(item);
		if ( (detail->orient == 2) )
			{
			extent = itemDetail->frame.size.width;
			if ( !extent )
				::fprintf(stderr,"variable content members of %s must specify width\n",group->tag);
			}
		else {
			extent = itemDetail->frame.size.height;
			if ( !extent )
				::fprintf(stderr,"variable content members of %s must specify height\n",group->tag);
			}
		if ( !extent )
			::exit(0);
		detail->offset += (int)extent;
		}
	roomLeft -= detail->offset;
	//cout "flexLayout:",group.tag,extent,offset,roomLeft:;
	while ( detail->offset <= roomLeft )
		{
		roomLeft -= detail->offset;
		detail->high += detail->offset;
		item = setFlexDetails(group);
		if ( !first )
			first = item;
		added++;
		}
	//cout `"added",added:;
	/***************************************************************************
	Would like to just call layout on group but that would get us into a
	loop since layout would send us back here. Here we need to setDetails
	and layout everything added (starting with first).
	***************************************************************************/
	if ( added )
		if ( item = first )
			{
			do	detail = setDetails(item);
			while ( item = group->walk(item) );
			item = first;
			do	{
				detail = ::getDetail(item);
				detail->setFrame();
				detail->checkStretch();
				//dumpDetails();
				}
			while ( item = group->walk(item) );
			}
}

/*******************************************************************************
	Reset the layout
*******************************************************************************/
void Control::layout(GroupItem *base)
{
GroupItem 	*show = 0;
GroupItem 	*group = 0;
GroupItem 	*item = 0;
Details 	*ancestor = 0;
Details 	*detail = 0;
Source 		*source = 0;
	//cout "Control: layout":;
	if ( Control::bwana->sourceList )
		while ( source = (Source*)Control::bwana->sourceList->next() )
			if ( activeView->resized && source->resetOnResize )
				{
				// The following is necessary in case of nested variable content
				if ( source->listeners )
					source->listeners->clear();
				source->reset();
				}
	while ( item = base->walk(item) )
		{
		detail = setDetails(item);
		if ( item->noAnchor && activeView && activeView->resized && activeView->hasVariableContent )
			resetVariableContent(item);
		}
	while ( item = base->walk(item) )
		{
		detail = ::getDetail(item);
		if ( detail->sizeToFit )
			fitSize(item);
		}
	while ( item = base->walk(item) )
		{
		detail = ::getDetail(item);
		detail->setFrame();
		detail->checkStretch();
		if ( !detail->view )
			{
			if ( item->parent )
				{
				ancestor = ::getDetail(item->parent);
				if ( detail->view = ancestor->view )
					goto hasView;
				}
			else
			if ( (detail->pane == 6) || (detail->pane == 3) )
				{
				detail->view = [[Layout alloc] init:detail->frame];
				detail->view->base = detail->wig;
				activeView = detail->view;
				//cout "Layout frame:",view.frame :;
				[detail->view setNeedsDisplay:1];
				}
			else
			if ( !activeView )
				::fprintf(stderr,"Control layout: no active view for %s\n",detail->wig->tag);
			else	detail->view = activeView;
			}
hasView:
		if ( !detail->view )
			::fprintf(stderr,"Control layout: could not set view for %s\n",item->tag);
		if ( item->noAnchor )
			{
			if ( activeView )
				activeView->hasVariableContent = 1;
			flexLayout(item);
			}
		}
	/***************************************************************************
	This goes thru everything once again to run any layout methods. It also
	checks for show.
	***************************************************************************/
	show = GroupControl::groupController->properties->getMember("show");
	while ( item = base->walk(item) )
		{
		detail = ::getDetail(item);
		if ( group = item->get("show") )
			if ( !show->getMember(item->tag) )
				show->addGroup(item);
		if ( !detail->attributed || detail->hasReactions )
			detail->processAttributes();
		}
	/***************************************************************************
	One more walk thru to make padding adjustments, check selectability
	and debugging attributes.
	This goes thru everything to make sure there is room to
	display it in the current view, taking into account that flexible
	content may have changed during layout.
	***************************************************************************/
	while ( item = base->walk(item) )
		{
		detail = ::getDetail(item);
		if ( item->isTarget )
			continue;
		detail->checkFit();
		if ( item->getAttribute("dEBUG") )
			detail->view->debug = 1;
		if ( item->getAttribute("pRINT") )
			::printf("%s\n",item->toString());
		if ( item->getAttribute("dUMP") )
			dump(item);
		if ( group = item->getAttribute("hTML") )
			{
			char 	*filename = group->getText();
			group = item->copy();
			GroupControl::groupController->groupParser->isRigorous = 1;
			if ( filename )
				{
				group = makeCanvas(group);
				group->toFile(filename);
				}
			else	::printf("%s",makeCanvas(group)->toString());
			GroupControl::groupController->groupParser->isRigorous = 0;
			}
		// if an item is not selectable, neither are its descendents
		// here dotdot is used as a temporary flag to avoid descending multiple times
		if ( !detail->selectable )
			if ( !item->dotdot )
				{
				group = item;
				while ( group = item->walk(group) )
					{
					if ( group->registry && !group->registry->getAttribute("isGUIregistry") )
						continue;
					if ( detail = ::setDetail(group) )
						{
						detail->selectable = 0;
						if ( !item->isTarget )
							item->dotdot = 1;
						}
					}
				}
			else	item->dotdot = 0;
		}
	::setModified(base);
	activeView->laidout = 1;
	[activeView display];
	//cout base:;
	//dump(base);
}

/*******************************************************************************
	Load an xml file specifying a layout
*******************************************************************************/
void Control::load(char *name)
{
	GroupControl::groupController->groupParser->reset();
	GroupControl::groupController->groupParser->doNotExpandMacros = 1;
	if ( !(loadedItem = GroupControl::groupController->groupParser->parseFile(name)) )
		::fprintf(stderr,"Load: failed for %s\n",name);
	GroupControl::groupController->groupParser->doNotExpandMacros = 0;
	::printf("Loaded %s\n",name);
	//timer = timeEnd(timer);
}

void Control::load(GroupItem *item)
{
GroupItem 	*file = item->get("file");
	if ( file )
		{
		GroupItem 	*directory = item->findAttribute("directory");
		char 		*fileName = 0;
		if ( directory )
			fileName = ::concat(3,directory->getText(),"/",file->getText());
		else	fileName = file->getText();
		if ( fileName )
			load(fileName);
		if ( loadedItem->isShell )
			{
			GroupItem 	*group = 0;
			while ( group = loadedItem->nextMember() )
				if ( group->get("window") || group->get("panel") )
					layout(group);
			}
		else
		if ( loadedItem->get("window") || loadedItem->get("panel") )
			layout(loadedItem);
		}
}

/*******************************************************************************
	Convert a block into a css style statement and return it in a PLGitem
*******************************************************************************/
PLGitem *Control::makeCSSline(GroupItem *block)
{
GroupItem 	*group = 0;
PLGitem 	*item = 0;
char 		*lineText = 0;
	resetBuffer(controlBuffer);
	if ( ::compare(block->tag,"class") == 0 )
		{
		appendStringBuffer(controlBuffer,".",0,0);
		appendStringBuffer(controlBuffer,block->getText(),0,0);
		appendStringBuffer(controlBuffer," {",0,0);
		}
	else
	if ( block->registry != GroupControl::groupController->htmlRegister )
		{
		appendStringBuffer(controlBuffer,"#",0,0);
		appendStringBuffer(controlBuffer,block->tag,0,0);
		appendStringBuffer(controlBuffer," {",0,0);
		}
	else {
		appendStringBuffer(controlBuffer,block->tag,0,0);
		appendStringBuffer(controlBuffer," {",0,0);
		}
	block->reset();
	while ( group = block->nextAttribute() )
		if ( !group->noPrint )
			toCSS(group);
	appendStringBuffer(controlBuffer," }",0,0);
	lineText = toStringBuffer(controlBuffer);
	item = GroupControl::groupController->groupParser->plgItemFactory(lineText);
	return item;
}

/*******************************************************************************
    This is based on makeHTML. It builds a web page based on a canvas.
*******************************************************************************/
GroupItem *Control::makeCanvas(GroupItem *group)
{
GroupItem 	*head = GroupControl::groupController->groupParser->locate("head");
GroupItem 	*title = 0;
GroupItem 	*body = 0;
GroupItem 	*canvas = 0;
GroupItem 	*script = 0;
GroupItem 	*block = 0;
	GroupControl::groupController->groupParser->noCDATA = 1;
	GroupControl::groupController->groupParser->ignoreNoRoom = 1;
	classList->clear();
	if ( !head )
		{
		group = GroupControl::groupController->itemFactory("makeCanvas: could not find head block");
		return group;
		}
	else	group->groupLink->insert(head);
	body = group->getMember("body");
	if ( !body )
		{
		group = GroupControl::groupController->itemFactory("makeCanvas: could not find body block");
		return group;
		}
	canvas = body->getMember("canvas");
	if ( !canvas )
		{
		group = GroupControl::groupController->itemFactory("makeCanvas: could not find canvas block");
		return group;
		}
	else {
		fillFrame(canvas);
		canvas->reset();
		while ( block = canvas->nextMember() )
			block->noPrint = 1;
		}
	group->tag = "html";
	// remember, when you add a group you get a copy so here head is set to its copy
	// otherwise references to head, and title will point to the wrong stuff
	head = group->addGroup(head);
	head->affiliation = 3;
	if ( title = head->getMember("title") )
		{
		if ( block = group->findAttribute("title") )
			title->setText(block->getText());
		if ( !title->data )
			{
			group = GroupControl::groupController->itemFactory("makeCanvas: could not find title text");
			return group;
			}
		title->isSingleton = 0;
		}
	else {
		group = GroupControl::groupController->itemFactory("makeCanvas: could not find title block");
		return group;
		}
	/***************************************************************************
	Generate draw function
	***************************************************************************/
	if ( block = canvas->get("id") )
		{
		script = head->get("script");
		buffer = script->getBuffer();
		unMarkBuffer(buffer);
		setMarkBuffer(buffer);
		appendStringBuffer(buffer,"\n",0,0);
		appendStringBuffer(buffer,"function draw()",0,0);
		appendStringBuffer(buffer,"\n",0,0);
		appendStringBuffer(buffer,"\t",0,0);
		appendStringBuffer(buffer,"{",0,0);
		appendStringBuffer(buffer,"\n",0,0);
		appendStringBuffer(buffer,"\t",0,0);
		appendStringBuffer(buffer,"var canvas = document.getElementById('",0,0);
		appendStringBuffer(buffer,block->getText(),0,0);
		appendStringBuffer(buffer,"');",0,0);
		appendStringBuffer(buffer,"\n",0,0);
		appendStringBuffer(buffer,"\t",0,0);
		appendStringBuffer(buffer,"if (canvas.getContext)",0,0);
		appendStringBuffer(buffer,"\n",0,0);
		appendStringBuffer(buffer,"\t",0,0);
		appendStringBuffer(buffer,"\t",0,0);
		appendStringBuffer(buffer,"{ ctx = canvas.getContext('2d');",0,0);
		appendStringBuffer(buffer,"\n",0,0);
		block = 0;
		while ( block = ::walkVisible(body,block) )
			if ( !block->isComment && !block->isTarget && block->hasAttributes && block->registry != GroupControl::groupController->htmlRegister )
				::jsDraw(block,buffer);
		appendStringBuffer(buffer,"\t",0,0);
		appendStringBuffer(buffer,"}}",0,0);
		}
	else	::fprintf(stderr,"makeCanvas: could not find canvas id\n");
	return group;
}

/*******************************************************************************
	Make block passed in a div block and convert attributes to css
*******************************************************************************/
PLGitem *Control::makeDiv(GroupItem *block)
{
GroupItem 	*classy = 0;
GroupItem 	*labeled = 0;
GroupItem 	*styling = 0;
GroupItem 	*group = 0;
GroupLink 	*link = 0;
PLGitem 	*item = 0;
int 		hasStyle = 0;
char 		*text = 0;
Details 	*detail = ::getDetail(block);
	//cout "makeDiv: processing",block.tag:;
	resetBuffer(controlBuffer);
	styling = block->extract("style");
	labeled = block->extract("label");
	fillFrame(block);
	classy = block->get("class");
	if ( classy && !classy->data )
		{
		classy->setText(block->tag);
		group = classList->get(block->tag);
		if ( !group )
			{
			appendStringBuffer(controlBuffer,".",0,0);
			appendStringBuffer(controlBuffer,block->tag,0,0);
			appendStringBuffer(controlBuffer," {",0,0);
			classy = classList->addString(block->tag);
			while ( group = block->nextAttribute(group) )
				if ( group->registry != GroupControl::groupController->htmlRegister )
					classy->addGroup(group);
			}
		else	classy = group;
		}
	else
	if ( !styling )
		{
		if ( block->registry != GroupControl::groupController->htmlRegister )
			{
			appendStringBuffer(controlBuffer,"#",0,0);
			appendStringBuffer(controlBuffer,block->tag,0,0);
			appendStringBuffer(controlBuffer," {",0,0);
			}
		else {
			appendStringBuffer(controlBuffer,block->tag,0,0);
			appendStringBuffer(controlBuffer," {",0,0);
			}
		}
	if ( (block->data == 5) && block->get("next") )
		block->fLAG = 1;
	if ( block->hasAttributes )
		{
		block->parts->resetIterator();
		block->hasAttributes = 0;
		while ( link = block->parts->nextLink() )
			{
			group = link->value;
			if ( !(group->affiliation == 1) || group->registry == GroupControl::groupController->htmlRegister )
				continue;
			if ( !group->noPrint )
				{
				if ( !classy || !classy->get(group->tag) )
					if ( toCSS(group) )
						hasStyle = 1;
				if ( ::compare(group->tag,"image") == 0 )
					text = group->getText();
				group->release();
				link->remove();
				}
			else	block->hasAttributes = 1;
			}
		}
	if ( block->registry != GroupControl::groupController->htmlRegister )
		{
		char 		*label = block->getText();
		GroupItem 	*idAttribute = 0;
		if ( !classy && !styling )
			{
			idAttribute = GroupControl::groupController->itemFactory("id");
			idAttribute->affiliation = 1;
			idAttribute->setText(block->tag);
			block->addGroup(idAttribute);
			}
		if ( GroupControl::groupController->htmlRegister->get(label) )
			{
			block->tag = label;
			block->setText((char*)0);
			}
		else {
			char 	*oldTag = block->tag;
			block->tag = "div";
			if ( text )
				{
				group = GroupControl::groupController->itemFactory("img");
				block->addGroup(group);
				group->addAttrString("alt",oldTag);
				group->addAttrString("src",text);
				group->addAttrString("width","100%");
				group->addAttrString("height","100%");
				}
			else
			if ( !block->fLAG && !block->isComment )
				if ( detail && detail->showBlank )
					addPara(block," ");
				else
				if ( (block->data == 6) )
					{
					item = block->getItem();
					do	addPara(block,item->toString());
					while ( item = item->next );
					}
				else
				if ( labeled )
					addPara(block,oldTag);
				else
				if ( block->data && (text = ::getCellText(block)) )
					addPara(block,text);
			block->isSingleton = 0;
			}
		}
	if ( styling && hasStyle )
		{
		styling->setText(toStringBuffer(controlBuffer));
		block->addGroup(styling);
		}
	else
	if ( hasStyle )
		{
		appendStringBuffer(controlBuffer," }",0,0);
		item = GroupControl::groupController->groupParser->plgItemFactory(toStringBuffer(controlBuffer));
		}
	return item;
}

/*******************************************************************************
	Convert the block passed in to HTML.
        Set title text from block text
        Change block tag to "html"
   Walk block so for each block:
        if not an html block, convert it to div (merge w/div, generate id).
        Get style. If hasAttributes create an id style block w/all css attributes
        Add id block to style.
        Convert style to html/css syntax (print each memeber as css).
    The group passed in should be copied first to not muck up the original
*******************************************************************************/
GroupItem *Control::makeHTML(GroupItem *group)
{
GroupItem 	*head = GroupControl::groupController->groupParser->locate("head");
GroupItem 	*style = 0;
GroupItem 	*title = 0;
GroupItem 	*body = 0;
GroupItem 	*block = 0;
GroupLink 	*link = 0;
PLGitem 	*styleItem = 0;
PLGitem 	*item = 0;
	GroupControl::groupController->groupParser->noCDATA = 1;
	GroupControl::groupController->groupParser->ignoreNoRoom = 1;
	classList->clear();
	if ( !head )
		{
		group = GroupControl::groupController->itemFactory("makeHTML: could not find head block");
		return group;
		}
	else	head->affiliation = 1;
	body = group->getMember("body");
	if ( !body )
		{
		group = GroupControl::groupController->itemFactory("makeHTML: could not find body block");
		return group;
		}
	group->tag = "html";
	// remember, when you add a group you get a copy so here head is set to its copy
	// otherwise references to head, style and title will point to the wrong stuff
	head = group->addGroup(head);
	head->affiliation = 3;
	style = head->getMember("style");
	if ( !style )
		{
		group = GroupControl::groupController->itemFactory("makeHTML: could not find style block");
		return group;
		}
	if ( title = head->getMember("title") )
		{
		if ( block = group->findAttribute("title") )
			title->setText(block->getText());
		if ( !title->data )
			{
			group = GroupControl::groupController->itemFactory("makeHTML: could not find title text");
			return group;
			}
		title->isSingleton = 0;
		}
	else {
		group = GroupControl::groupController->itemFactory("makeHTML: could not find title block");
		return group;
		}
	//cout group:;
	/***************************************************************************
	Add style block
	***************************************************************************/
	if ( style->hasMembers )
		while ( link = style->parts->nextLink() )
			{
			block = link->value;
			if ( !(block->affiliation == 3) )
				continue;
			if ( item = makeCSSline(block) )
				if ( !styleItem )
					styleItem = item;
				else	styleItem->append(item);
			block->release();
			link->remove();
			}
	block = 0;
	while ( block = ::walkVisible(body,block) )
		if ( !block->isComment && !block->isTarget && block->hasAttributes && ::compare(block->tag,"img") != 0 )
			if ( item = makeDiv(block) )
				if ( !styleItem )
					styleItem = item;
				else	styleItem->append(item);
	/***************************************************************************
	Add class styles
	***************************************************************************/
	while ( block = classList->nextAttribute() )
		{
		block->setText(block->tag);
		block->tag = "class";
		if ( item = makeCSSline(block) )
			if ( !styleItem )
				styleItem = item;
			else	styleItem->append(item);
		}
	block = GroupControl::groupController->itemFactory("boDY");
	block->setItem(styleItem);
	block->noTag = 1;
	block->isComment = 1;
	block->isClosed = 1;
	style->addGroup(block);
	return group;
}

/*******************************************************************************
	Runs a tracked action on all its members. The tracked members are the blocks
    enclosing the attribute being tracked. In some cases, the tracked attribute
    may have a value, in which case you have to use the local copy of the attribute
    stored in the block (when there is no value, the registered copy of the
    attribute is sufficient).
*******************************************************************************/
void Control::processActionTrack(GroupItem *action)
{
GroupItem 	*attribute = 0;
GroupItem 	*group = 0;
	action->reset();
	while ( group = action->nextMember() )
		{
		// deferred usually applies to actions, here it is used on the action parent
		// to indicate that the tracked action was run (do not want to run it again);
		if ( (group->methodType == 1) )
			continue;
		group->methodType = 1;
		if ( attribute = group->get(action->tag) )
			{
			// attribute parent set because wont be right in case of flex layout
			attribute->parent = group;
			action->gMethod(attribute);
			}
		else	::fprintf(stderr,"processAction: could not find attribute %s in %s\n\t%s\n",action->tag,group->tag,group->getTagXML());
		}
}

/*******************************************************************************
	This resets the variable content group passed in to its initial state
    before any flex layout happens.
*******************************************************************************/
void Control::resetVariableContent(GroupItem *group)
{
GroupItem 	*item = 0;
GroupItem 	*content = group->getAttribute("vCONTENt");
	if ( !content || !content->hasMembers )
		return;
	::printf("Resetting variable content for %s\n",group->tag);
	group->clearMembers();
	content->reset();
	while ( item = content->nextMember() )
		group->addGroup(item);
	//cout "After reset",group:;
}

/*******************************************************************************
	Set layout details for the GroupItem passed in and its members.
    Called from layout() flexLayout() and recursively
*******************************************************************************/
Details *Control::setDetails(GroupItem *item)
{
Details 	*ancestor = 0;
Details 	*detail = 0;
GroupItem 	*stuff = 0;
GroupItem 	*group = 0;
GroupItem 	*record = 0;
GroupItem 	*member = 0;
int 		repeat = 0;
	item->reset();
	detail = ::setDetail(item);
	if ( ancestor = ::getAncestor(item) )
		detail->level = ancestor->level + 1;
	detail->frame.origin.x = detail->frame.origin.y = detail->frame.size.height = detail->frame.size.width = 0;
	detail->length = 0;
	repeat = detail->initialize(item);
	if ( item->noAnchor )
		{
		record = item->getAttribute("vCONTENt");
		if ( !record && item->hasMembers )
			{
			record = item->addString("vCONTENt");
			detail->deferDraw = 1;
			item->reset();
			while ( member = item->nextMember() )
				{
				group = record->addGroup(member);
				record->hasMembers = 1;
				if ( stuff = group->get("down") )
					{
					if ( stuff->gText && *stuff->gText == '*' )
						group->noAnchor = 1;
					}
				else
				if ( stuff = group->get("across") )
					if ( stuff->gText && *stuff->gText == '*' )
						group->noAnchor = 1;
				}
			// do not think we need deferDraw (defers draw on resizing???)
			}
		}
	return detail;
}

/*******************************************************************************
	Add a record of flexible content for the GroupItem passed in
*******************************************************************************/
GroupItem *Control::setFlexDetails(GroupItem *group)
{
GroupItem 	*first = 0;
GroupItem 	*block = 0;
GroupItem 	*item = 0;
GroupItem 	*record = group->get("vCONTENt");
	if ( !record )
		{
		::fprintf(stderr,"setFlexDetails: could not find record for %s\n",group->tag);
		::exit(0);
		}
	record->reset();
	while ( item = record->nextMember() )
		{
		block = group->addGroup(item);
		if ( !first )
			first = block;
		}
	return first;
}

/*******************************************************************************
	Set the layout for item and descendents
*******************************************************************************/
void Control::setLayout(GroupItem *item, Layout *lay)
{
GroupItem 	*group = 0;
Details 	*detail = 0;
	while ( group = item->walk(group) )
		if ( detail = ::getDetail(group) )
			detail->view = lay;
}

/*****************************************************************************
	Set up the attributes and types registries
*****************************************************************************/
void Control::setup()
{
GroupItem 	*item = 0;
GroupItem 	*type = 0;
	Control::bwana->registerMethods();
	Control::fontRegistry = GroupControl::groupController->getRegistry("fONTs");
	Control::colorRegistry = GroupControl::groupController->getRegistry("cOLOr");
	GroupControl::groupController->properties->reset();
	while ( item = GroupControl::groupController->properties->parts->next() )
		{
		type = item->get("type");
		if ( type && !type->data )
			{
			type = Control::bwana->types->addString(item->tag);
			if ( item->get("register") )
				type->setPointer((void*)GroupControl::groupController->getRegistry(type->tag));
			}
		}
}

/******************************************************************************
	Start the display
******************************************************************************/
void Control::start(NSWindow *window)
{
GroupItem 	*item = 0;
GroupItem 	*group = 0;
	Control::bwana->window = window;
	[window setDelegate:(id)delegator];
	//if window.delegate cout "has window delegate":; else cout "no window delegate":;
	baseURL = GroupControl::groupController->groupParser->locate("baseURL");
	if ( !baseURL )
		{
		::fprintf(stderr,"Control start: could not set base URL, bailing\n");
		return;
		}
	if ( loadedItem->isShell )
		{
		loadedItem->reset();
		while ( group = loadedItem->nextMember() )
			if ( group->get("window") || group->get("panel") )
				layout(group);
		}
	else
	if ( loadedItem->get("window") || loadedItem->get("panel") )
		layout(loadedItem);
	if ( !Control::bwana->windows->hashList->length )
		{
		item = GroupControl::groupController->itemFactory("<error window closable text>No window block found</error>");
		layout(item);
		}
	timer = ::timeEnd(timer);
	//laidout = false;
	/***************************************************************************
	Fixes problem w/text blocks scrolling to bottom. Not sure why it happens.
	May also fix problem with window showing up blank sometimes (No!).
	***************************************************************************/
	[window makeKeyAndOrderFront:window];
	[window display];
	::printf("Done starting\n");
}

/*******************************************************************************
	Print a group as a style statement attribute to the scratch buffer. Gets
    called by makeDiv(). cssRegister and properties referenced are registries
    defined in GroupMain and globally accessible from the static driver. The
    buffer buffer is accessible from the parser also defined in GroupMain
*******************************************************************************/
int Control::toCSS(GroupItem *group)
{
GroupItem 	*cssGroup = GroupControl::groupController->cssRegister->get(group->tag);
GroupItem 	*property = 0;
char 		*content = 0;
char 		*groupText = group->getText();
	if ( group->isPercent )
		group->isPercent = 0;
	if ( !cssGroup )
		{
		property = GroupControl::groupController->properties->get(group->tag);
		if ( property )
			if ( (property->data == 5) )
				cssGroup = property->getGroup();
			else {
				if ( content = property->getText() )
					if ( cssGroup = GroupControl::groupController->cssRegister->get(content) )
						property->setGroup(cssGroup);
				}
		}
	if ( cssGroup )
		{
		if ( groupText )
			content = groupText;
		else	content = cssGroup->getText();
		if ( content )
			{
			appendStringBuffer(controlBuffer," ",0,0);
			appendStringBuffer(controlBuffer,cssGroup->tag,0,0);
			appendStringBuffer(controlBuffer,":",0,0);
			appendStringBuffer(controlBuffer,content,0,0);
			if ( cssGroup->get("needsUnit") )
				appendStringBuffer(controlBuffer,"px;",0,0);
			else	appendStringBuffer(controlBuffer,";",0,0);
			}
		}
	else	return 0;
	return 1;
}
