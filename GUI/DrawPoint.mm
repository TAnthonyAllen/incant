#include <Cocoa/Cocoa.h>
#include <WebKit/WebKit.h>
#include <string.h>
#include <stdio.h>
#include "GroupItem.h"
#include "OCroutines.h"
#include "Control.h"
#include "PLGparse.h"
#include "Details.h"
#include "Bwana.h"
#include "PLGitem.h"
#include "Buffer.h"
#include "Groups.h"
#include "DrawPoint.h"

/*******************************************************************************
	Go thru the paths associated with GroupItem passed in and draw them.
*******************************************************************************/
void drawPath(GroupItem *item)
{
Details 	*detail = ::getDetail(item);
DrawPoint 	**atPath = 0;
DrawPoint 	**drawingPath = 0;
DrawPoint 	**pathSet = 0;
DrawPoint 	**atSet = 0;
DrawPoint 	*dp = 0;
Buffer 		*buffer = 0;
	if ( item && item->parent && (item->parent->data == 2) )
		{
		buffer = item->parent->getBuffer();
		appendStringBuffer(buffer,"\t",0,0);
		appendStringBuffer(buffer,"ctx.save();",0,0);
		appendStringBuffer(buffer,"\n",0,0);
		appendStringBuffer(buffer,"\t",0,0);
		appendStringBuffer(buffer,"ctx.beginPath();",0,0);
		appendStringBuffer(buffer,"\n",0,0);
		appendStringBuffer(buffer,"\t",0,0);
		appendStringBuffer(buffer,"ctx.translate(",0,0);
		appendDoubleBuffer(buffer,detail->frame.origin.x + detail->frame.size.width / 2,0,0);
		appendStringBuffer(buffer,",",0,0);
		appendDoubleBuffer(buffer,detail->frame.origin.y + detail->frame.size.height / 2,0,0);
		appendStringBuffer(buffer,");",0,0);
		appendStringBuffer(buffer,"\n",0,0);
		if ( pathSet = (DrawPoint**)item->getPointer() )
			{
			for ( atSet = pathSet; atSet && *atSet; atSet++ )
				{
				drawingPath = (DrawPoint**)*atSet;
				DrawPoint::priorPoint.x = 0;
				DrawPoint::priorPoint.y = 0;
				DrawPoint::targetPoint.x = 0;
				DrawPoint::targetPoint.y = 0;
				for ( atPath = drawingPath; atPath && *atPath; atPath++ )
					{
					dp = *atPath;
					dp->draw(item->parent->getBuffer());
					}
				// fill and stroke goes here
				}
			}
		else	::fprintf(stderr,"drawPath: invalid pointer passed in from %s\n",item->tag);
		}
	else	::fprintf(stderr,"ERROR drawPath: invalid input\n");
	if ( buffer )
		{
		appendStringBuffer(buffer,"\t",0,0);
		appendStringBuffer(buffer,"ctx.restore();",0,0);
		appendStringBuffer(buffer,"\n",0,0);
		}
}
GroupItem *DrawPoint::drawGroup;
NSPoint DrawPoint::priorPoint;
NSPoint DrawPoint::targetPoint;

DrawPoint::DrawPoint()
{
	xOperator = 0;
	yOperator = 0;
	control1 = 0;
	control2 = 0;
	drawPathBlock = 0;
	fillColor = 0;
	strokeColor = 0;
	closeIt = 0;
	direction = 0;
	fillPath = 0;
	hasOperator = 0;
	middle = 0;
	move = 0;
	percent = 0;
	relative = 0;
	shape = 0;
	strokePath = 0;
	translate = 0;
}

DrawPoint::DrawPoint(PLGitem *x, PLGitem *y)
{
	xOperator = 0;
	yOperator = 0;
	control1 = 0;
	control2 = 0;
	drawPathBlock = 0;
	fillColor = 0;
	strokeColor = 0;
	closeIt = 0;
	direction = 0;
	fillPath = 0;
	hasOperator = 0;
	middle = 0;
	move = 0;
	percent = 0;
	relative = 0;
	shape = 0;
	strokePath = 0;
	translate = 0;
PLGitem *item = 0;
	if ( x )
		{
		point.x = x->amount;
		if ( item = x->get("operator") )
			xOperator = *item->itemStart;
		}
	else	point.x = 0.0;
	if ( y )
		{
		point.y = y->amount;
		if ( item = y->get("operator") )
			yOperator = *item->itemStart;
		}
	else	point.y = 0.0;
	//if x cout x; else cout "no x"; cout ,point.x`; if y cout y; else cout "no Y"; cout ,point.y:;
}

DrawPoint::DrawPoint(NSPoint p)
{
	xOperator = 0;
	yOperator = 0;
	control1 = 0;
	control2 = 0;
	drawPathBlock = 0;
	fillColor = 0;
	strokeColor = 0;
	closeIt = 0;
	direction = 0;
	fillPath = 0;
	hasOperator = 0;
	middle = 0;
	move = 0;
	percent = 0;
	relative = 0;
	shape = 0;
	strokePath = 0;
	translate = 0;
	point = p;
}

/*******************************************************************************
	Perform the drawing associated with this point.
*******************************************************************************/
void DrawPoint::draw(Buffer *buffer)
{
NSPoint 	c1;
NSPoint 	c2;
Details 	*detail = ::getDetail(DrawPoint::drawGroup);
	DrawPoint::priorPoint = DrawPoint::targetPoint;
	if ( drawPathBlock )
		{
		double 	repeat = point.x;
		if ( !drawPathBlock->getAttribute("drawPathSet") )
			Control::bwana->extendParser->buildPath(drawPathBlock);
		while ( repeat-- > 0 )
			drawBlock(drawPathBlock,buffer);
		}
	else {
		if ( translate )
			{
			Control::bwana->extendParser->translated = 1;
			DrawPoint::priorPoint.x = 0;
			DrawPoint::priorPoint.y = 0;
			}
		if ( relative || hasOperator )
			DrawPoint::targetPoint = getPoint(detail->frame,DrawPoint::priorPoint);
		else	DrawPoint::targetPoint = get(detail->frame);
		if ( translate )
			movePath(DrawPoint::targetPoint,buffer);
		else
		if ( (shape == 2) )
			{
			c1 = control1->getPoint(detail->frame,DrawPoint::priorPoint);
			c2 = control2->getPoint(detail->frame,DrawPoint::priorPoint);
			appendStringBuffer(buffer,"\t",0,0);
			appendStringBuffer(buffer,"ctx.bezierCurveTo(",0,0);
			appendStringBuffer(buffer," ",0,0);
			appendStringBuffer(buffer,::toString(c1),0,0);
			appendStringBuffer(buffer," ",0,0);
			appendStringBuffer(buffer,::toString(c2),0,0);
			appendStringBuffer(buffer," ",0,0);
			appendStringBuffer(buffer,::toString(DrawPoint::targetPoint),0,0);
			appendStringBuffer(buffer,");",0,0);
			appendStringBuffer(buffer,"\n",0,0);
			}
		else
		if ( (shape == 1) )
			{
			c1 = control1->getPoint(detail->frame,DrawPoint::priorPoint);
			c2 = control2->getPoint(detail->frame,DrawPoint::priorPoint);
			// Here c2.x contains the radius - not sure this works as intended
			appendStringBuffer(buffer,"\t",0,0);
			appendStringBuffer(buffer,"ctx.arcTo(",0,0);
			appendStringBuffer(buffer,::toString(DrawPoint::targetPoint),0,0);
			appendStringBuffer(buffer," ",0,0);
			appendStringBuffer(buffer,::toString(c1),0,0);
			appendStringBuffer(buffer," ",0,0);
			appendFloatBuffer(buffer,(float)c2.x,0,0);
			appendStringBuffer(buffer,");",0,0);
			appendStringBuffer(buffer,"\n",0,0);
			}
		else {
			if ( move )
				{
				appendStringBuffer(buffer,"\t",0,0);
				appendStringBuffer(buffer,"ctx.moveTo(",0,0);
				appendStringBuffer(buffer,::toString(DrawPoint::targetPoint),0,0);
				appendStringBuffer(buffer,");",0,0);
				appendStringBuffer(buffer,"\n",0,0);
				}
			else 				{
				appendStringBuffer(buffer,"\t",0,0);
				appendStringBuffer(buffer,"ctx.lineTo(",0,0);
				appendStringBuffer(buffer,::toString(DrawPoint::targetPoint),0,0);
				appendStringBuffer(buffer,");",0,0);
				appendStringBuffer(buffer,"\n",0,0);
				}
			}
		if ( fillPath )
			{
			if ( fillColor )
				{
				appendStringBuffer(buffer,"\t",0,0);
				appendStringBuffer(buffer,"ctx.fillStyle = '",0,0);
				appendItemBuffer(buffer,fillColor);
				appendStringBuffer(buffer,"';",0,0);
				appendStringBuffer(buffer,"\n",0,0);
				}
			appendStringBuffer(buffer,"\t",0,0);
			appendStringBuffer(buffer,"ctx.fill();",0,0);
			appendStringBuffer(buffer,"\n",0,0);
			}
		if ( strokePath )
			{
			if ( strokeColor )
				{
				appendStringBuffer(buffer,"\t",0,0);
				appendStringBuffer(buffer,"ctx.strokeStyle = '",0,0);
				appendItemBuffer(buffer,strokeColor);
				appendStringBuffer(buffer,"';",0,0);
				appendStringBuffer(buffer,"\n",0,0);
				}
			appendStringBuffer(buffer,"\t",0,0);
			appendStringBuffer(buffer,"ctx.stroke();",0,0);
			appendStringBuffer(buffer,"\n",0,0);
			}
		if ( closeIt )
			{
			if ( Control::bwana->extendParser->translated )
				{
				appendStringBuffer(buffer,"\t",0,0);
				appendStringBuffer(buffer,"ctx.setTransform(1, 0, 0, 1, 0, 0);",0,0);
				appendStringBuffer(buffer,"\n",0,0);
				}
			appendStringBuffer(buffer,"\t",0,0);
			appendStringBuffer(buffer,"ctx.closePath();",0,0);
			appendStringBuffer(buffer,"\n",0,0);
			}
		}
}

/*******************************************************************************
	Draw the path contained in the GroupItem passed in
*******************************************************************************/
void DrawPoint::drawBlock(GroupItem *item, Buffer *buffer)
{
Details 	*detail = ::getDetail(item);
DrawPoint 	**atPath = 0;
DrawPoint 	**drawingPath = 0;
DrawPoint 	**pathSet = 0;
DrawPoint 	**atSet = 0;
DrawPoint 	*dp = 0;
	appendStringBuffer(buffer,"\t",0,0);
	appendStringBuffer(buffer,"ctx.save();",0,0);
	appendStringBuffer(buffer,"\n",0,0);
	appendStringBuffer(buffer,"\t",0,0);
	appendStringBuffer(buffer,"ctx.beginPath();",0,0);
	appendStringBuffer(buffer,"\n",0,0);
	appendStringBuffer(buffer,"\t",0,0);
	appendStringBuffer(buffer,"ctx.translate(",0,0);
	appendDoubleBuffer(buffer,detail->frame.origin.x + detail->frame.size.width / 2,0,0);
	appendStringBuffer(buffer,",",0,0);
	appendDoubleBuffer(buffer,detail->frame.origin.y + detail->frame.size.height / 2,0,0);
	appendStringBuffer(buffer,");",0,0);
	appendStringBuffer(buffer,"\n",0,0);
	if ( item && item->parent && (item->parent->data == 2) )
		{
		pathSet = (DrawPoint**)item->getPointer();
		for ( atSet = pathSet; atSet && *atSet; atSet++ )
			{
			drawingPath = (DrawPoint**)*atSet;
			for ( atPath = drawingPath; atPath && *atPath; atPath++ )
				{
				dp = *atPath;
				dp->draw(item->parent->getBuffer());
				}
			}
		}
	else	::fprintf(stderr,"ERROR: drawBlock got invalid input\n");
	appendStringBuffer(buffer,"\t",0,0);
	appendStringBuffer(buffer,"ctx.restore();",0,0);
	appendStringBuffer(buffer,"\n",0,0);
}

/*******************************************************************************
	Return point, adjusting if the point is specified in percents
*******************************************************************************/
NSPoint DrawPoint::get(NSRect frame)
{
NSPoint 	rp;
int 		i = 0;
	if ( !drawPathBlock && percent && !(translate == 2) )
		{
		i = frame.size.width * point.x * 0.01 + 0.5;
		rp.x = i;
		i = frame.size.height * point.y * 0.01 + 0.5;
		rp.y = i;
		}
	else	rp = point;
	//cout "DrawPoint get:"`point.x,point.y,rp.x,rp.y:;
	return rp;
}

/*******************************************************************************
	Returns a resolved point derived from this drawPoint taking into account
    that this drawPoint may be specified using relative offsets
*******************************************************************************/
NSPoint DrawPoint::getPoint(NSRect frame, NSPoint pp)
{
NSPoint 	dp = get(frame);
	if ( hasOperator )
		{
		if ( xOperator == '+' )
			dp.x += pp.x;
		else
		if ( xOperator == '-' )
			dp.x = pp.x - dp.x;
		else
		if ( xOperator == '*' )
			dp.x = pp.x * dp.x;
		else
		if ( xOperator == '/' )
			dp.x = pp.x / dp.x;
		else
		if ( relative )
			dp.x += pp.x;
		else	dp.x = pp.x;
		if ( yOperator == '+' )
			dp.y += pp.y;
		else
		if ( yOperator == '-' )
			dp.y = pp.y - dp.y;
		else
		if ( yOperator == '*' )
			dp.y = pp.y * dp.y;
		else
		if ( yOperator == '/' )
			dp.y = pp.y / dp.y;
		else
		if ( relative )
			dp.y += pp.y;
		else	dp.y = pp.y;
		}
	else
	if ( relative && !move && !translate )
		{
		dp.x += pp.x;
		dp.y += pp.y;
		}
	return dp;
}

/*******************************************************************************
	Transform the current path by inverting, rotating, scaling, or shifting.
*******************************************************************************/
void DrawPoint::movePath(NSPoint p, Buffer *buffer)
{
	if ( (translate == 1) )
		::printf("movePath: must invert\n");
	// x gets converted to radians below
	if ( (translate == 2) )
		{
		appendStringBuffer(buffer,"\t",0,0);
		appendStringBuffer(buffer,"ctx.rotate(",0,0);
		appendDoubleBuffer(buffer,p.x * 0.01745,0,0);
		appendStringBuffer(buffer,");",0,0);
		appendStringBuffer(buffer,"\n",0,0);
		}
	else
	if ( (translate == 3) )
		if ( p.y )
			::printf("movePath: scaleBy(p.x,p.y);\n");
		else	::printf("movePath: scaleBy(p.x);\n");
	else 		{
		appendStringBuffer(buffer,"\t",0,0);
		appendStringBuffer(buffer,"ctx.translate(",0,0);
		appendDoubleBuffer(buffer,p.x,0,0);
		appendStringBuffer(buffer,",",0,0);
		appendDoubleBuffer(buffer,p.y,0,0);
		appendStringBuffer(buffer,");",0,0);
		appendStringBuffer(buffer,"\n",0,0);
		}
}

/*******************************************************************************
	Reset path parameters
*******************************************************************************/
void DrawPoint::reset()
{
	Control::bwana->extendParser->asPercentOfFrame = 0;
	Control::bwana->extendParser->itsAllRelative = 0;
}

/*******************************************************************************
	Return a string representation of this point
*******************************************************************************/
char *DrawPoint::toString()
{
	resetBuffer(Control::bwana->bwanaBuffer);
	if ( percent )
		appendStringBuffer(Control::bwana->bwanaBuffer,"%",0,0);
	if ( move )
		appendStringBuffer(Control::bwana->bwanaBuffer,"@",0,0);
	if ( (direction == 1) )
		appendStringBuffer(Control::bwana->bwanaBuffer,"l",0,0);
	if ( (direction == 2) )
		appendStringBuffer(Control::bwana->bwanaBuffer,"r",0,0);
	if ( (direction == 3) )
		appendStringBuffer(Control::bwana->bwanaBuffer,"u",0,0);
	if ( (direction == 4) )
		appendStringBuffer(Control::bwana->bwanaBuffer,"d",0,0);
	if ( (shape == 1) )
		appendStringBuffer(Control::bwana->bwanaBuffer,"a",0,0);
	if ( (shape == 2) )
		appendStringBuffer(Control::bwana->bwanaBuffer,"c",0,0);
	if ( (shape == 3) )
		appendStringBuffer(Control::bwana->bwanaBuffer,"o",0,0);
	if ( relative )
		appendStringBuffer(Control::bwana->bwanaBuffer,"~",0,0);
	if ( (translate == 1) )
		appendStringBuffer(Control::bwana->bwanaBuffer,"i",0,0);
	if ( (translate == 2) )
		appendStringBuffer(Control::bwana->bwanaBuffer,"R",0,0);
	if ( (translate == 3) )
		appendStringBuffer(Control::bwana->bwanaBuffer,"S",0,0);
	if ( (translate == 4) )
		appendStringBuffer(Control::bwana->bwanaBuffer,"T",0,0);
	if ( fillPath )
		appendStringBuffer(Control::bwana->bwanaBuffer,"F",0,0);
	if ( strokePath )
		appendStringBuffer(Control::bwana->bwanaBuffer,"$",0,0);
	if ( drawPathBlock )
		appendStringBuffer(Control::bwana->bwanaBuffer,drawPathBlock->tag,0,0);
	appendStringBuffer(Control::bwana->bwanaBuffer,"\t",0,0);
	appendDoubleBuffer(Control::bwana->bwanaBuffer,point.x,"%5.1f",5);
	if ( xOperator )
		appendCharBuffer(Control::bwana->bwanaBuffer,xOperator,0,0);
	else	appendStringBuffer(Control::bwana->bwanaBuffer," ",0,0);
	appendStringBuffer(Control::bwana->bwanaBuffer,"\t",0,0);
	appendDoubleBuffer(Control::bwana->bwanaBuffer,point.y,"%5.1f",5);
	if ( yOperator )
		appendCharBuffer(Control::bwana->bwanaBuffer,yOperator,0,0);
	else	appendStringBuffer(Control::bwana->bwanaBuffer," ",0,0);
	return toStringBuffer(Control::bwana->bwanaBuffer);
}
