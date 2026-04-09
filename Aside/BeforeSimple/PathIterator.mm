#include <Cocoa/Cocoa.h>
#include <string.h>
#include <stdio.h>
#include "GroupItem.h"
#include "OCroutines.h"
#include "Stak.h"
#include "GroupBody.h"
#include "PathIterator.h"

PathIterator::PathIterator(GroupItem *p, GroupItem *s)
{
	setInitialPath(p);
	setInitialBlock(s);
	target = 0;
	iterateStack = new Stak();
}

/*****************************************************************************
    Returns true if the attributes of the iterateBlock match the attributes
    of iteratePath.
*****************************************************************************/
int PathIterator::attributesMatch()
{
GroupItem 	*currentBlock = 0;
GroupItem 	*pathAttribute = 0;
int 		alternateFlag = 0;
	while ( pathAttribute = iteratePath->nextAttribute(pathAttribute) )
		{
		if ( pathAttribute->groupBody->isOption || pathAttribute->groupBody->noPrint )
			continue;
		if ( alternateFlag )
			{
			alternateFlag = pathAttribute->groupBody->isAlternate;
			continue;
			}
		if ( !iterateBlock->groupBody->hasAttributes )
			{
			pathError = 2;
			goto failedMatch;
			}
		/*****************************************************************
		if pathAttribute is not a regular expression, can do a simple
		search for a matching attribute based on tag.
		*****************************************************************/
		if ( !isRegexGRP(pathAttribute->groupBody->data) )
			{
			if ( currentBlock = iterateBlock->getAttribute(pathAttribute->groupBody->tag) )
				{
				if ( debugPath )
					::printf("\tpath attribute: %s=%s %s\n",pathAttribute->groupBody->tag,pathAttribute->getText(),currentBlock->groupBody->tag);
				if ( currentBlock->matches(pathAttribute) )
					goto checkAlternate;
				}
			if ( !pathAttribute->groupBody->isAlternate )
				goto failedMatch;
			continue;
			}
		/*****************************************************************
		pathAttribute is a regular expression so loop thru attributes
		to see if any match the expression.
		*****************************************************************/
		currentBlock = 0;
		while ( currentBlock = iterateBlock->nextAttribute(currentBlock) )
			if ( currentBlock->matches(pathAttribute) )
				goto checkAlternate;
		if ( !pathAttribute->groupBody->isAlternate )
			break;
		continue;
checkAlternate:
		if ( pathAttribute->isTarget )
			target = currentBlock;
		/*****************************************************************
		The alternateFlag is set when the attribute matches and
		the pathAttribute is an alternate (that is, any following
		alternate pathAttribute can be skipped).
		*****************************************************************/
		alternateFlag = pathAttribute->groupBody->isAlternate;
		}
	if ( debugPath )
		::printf("\t\tattributesMatch succeeded\n");
	return 1;
failedMatch:
	if ( !pathError )
		pathError = 4;
	target = 0;
	if ( debugPath )
		::printf("\t\tattributesMatch failed\n");
	return 0;
}

/*****************************************************************************
    Walk the path, checking for actions. Also checks to see if we need to
    descend any attributes. Note: an attribute cannot have both. That is if
    it has a method, we do not descend it.
*****************************************************************************/
void PathIterator::checkForActions(GroupItem *path)
{
GroupItem 	*group = 0;
GroupItem 	*pathAttribute = 0;
	while ( group = path->walk(group) )
		{
		while ( pathAttribute = group->nextAttribute(pathAttribute) )
			{
			//  modified overloaded to indicate path has attribute descend
			if ( pathAttribute->groupBody->gMethod )
				{
				if ( pathAttribute->groupBody->getFromList("onFailure") )
					pathAttribute->onFailure = 1;
				}
			else
			if ( !path->groupBody->modified && !path->groupBody->hasMembers && pathAttribute->groupBody->hasMembers )
				{
				path->groupBody->modified = 1;
				checkForActions(pathAttribute);
				}
			}
		}
}

/*****************************************************************************
    Error messages
*****************************************************************************/
void PathIterator::displayError()
{
	::fprintf(stderr,"\t\t\tFailed: ");
	if ( noAttributes(pathError) )
		::fprintf(stderr,"Expected attributes from ");
	else
	if ( notDeepEnough(pathError) )
		::fprintf(stderr,"Expected members from ");
	else
	if ( noMatch(pathError) )
		::fprintf(stderr,"No match for ");
	::fprintf(stderr,"%s comparing to %s\n",iterateBlock->getTagXML(),iteratePath->getTagXML());
}

/*****************************************************************************
    Returns the next block that matches the path.
*****************************************************************************/
GroupItem *PathIterator::next()
{
GroupItem 	*pathAttribute = 0;
	target = 0;
	hitBottom = 0;
	if ( !endPath )
		{
		if ( !iterateBlock )
			iterateBlock = initialBlock->nextMember(0);
		while ( iterateBlock )
			{
			if ( iterateBlock->groupBody->getFromList("debug") )
				debugPath = 1;
			if ( debugPath )
				::printf("Walked to %s\n",iterateBlock->getTagXML());
			pathError = 0;
			if ( !(iterateBlock->matches(iteratePath)) )
				pathError = 1;
			else
			if ( !(iteratePath->groupBody->hasAttributes && attributesMatch()) )
				pathError = 1;
			else
			if ( iteratePath->isTarget )
				{
				target = iterateBlock;
				if ( debugPath )
					::printf("\t\t\tfound target %s\n",iterateBlock->groupBody->tag);
				}
			/*****************************************************************
			Process any path methods.
			*****************************************************************/
			while ( pathAttribute = iteratePath->nextAttribute(pathAttribute) )
				if ( pathAttribute->groupBody->gMethod )
					{
					if ( !pathError && !pathAttribute->onFailure )
						pathAttribute->groupBody->gMethod(iterateBlock);
					else
					if ( pathError && pathAttribute->onFailure )
						pathAttribute->groupBody->gMethod(iterateBlock);
					}
			if ( pathError && debugPath )
				displayError();
			else
			if ( debugPath )
				::printf("\t\t\tsucceeded\n");
			iterateBlock = walkPath();
			if ( hitBottom )
				{
				if ( debugBlock(debugPath) )
					debugPath = 0;
				break;
				}
			}
		}
	return target;
}

/*****************************************************************************
    Initialize the initial block.
*****************************************************************************/
void PathIterator::setInitialBlock(GroupItem *source)
{
	initialBlock = source;
	if ( initialBlock->groupBody->getFromList("debug") )
		debugPath = 2;
	iterateBlock = 0;
}

/*****************************************************************************
    Initialize the path.
*****************************************************************************/
void PathIterator::setInitialPath(GroupItem *path)
{
	initialPath = path;
	iteratePath = path;
	checkForActions(path);
}

/*******************************************************************************
    Walks blocks keeping path in sync
*******************************************************************************/
GroupItem *PathIterator::walkPath()
{
GroupItem 	*group = 0;
GroupItem 	*path = 0;
	if ( !iterateBlock->groupBody->hasMembers )
		{
		if ( iteratePath->groupBody->hasMembers )
			pathError = 3;
		else
		if ( target )
			hitBottom = 1;
		}
	else
	if ( iteratePath->noAnchor || iteratePath->groupBody->hasMembers )
		{
		if ( iteratePath->noAnchor || (path = iteratePath->nextMember(0)) )
			{
			path->groupBody->pushToList(iteratePath);
			if ( debugPath )
				::printf("\tpushing %s\n",iteratePath->getTagXML());
			if ( path )
				iteratePath = path;
			iterateBlock = iterateBlock->nextMember(0);
			return iterateBlock;
			}
		}
	while ( group = iterateBlock->parent )
		{
		if ( iterateBlock = group->nextMember(0) )
			break;
		if ( group == initialBlock )
			{
			iterateBlock = 0;
			endPath = 1;
			break;
			}
		if ( !iterateBlock && group->parent )
			{
			iterateBlock = group;
			if ( iterateBlock == target )
				hitBottom = 1;
			// reset path up because we are about to ascend
			if ( iteratePath = (GroupItem*)iterateStack->pop() )
				if ( debugPath )
					::printf("\tpopping %s %s\n",iteratePath->getTagXML(),iterateBlock->groupBody->tag);
			}
		}
	return iterateBlock;
}
