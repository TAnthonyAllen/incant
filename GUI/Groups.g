include GUIincludes

external PLGitem
{
	alias
		isDouble	flag1
		;
}

%%
insert(Groups.rtn)
include(Groups.act)
Set         operateSet  [-+*/]
Set         alphaSet	[A-Za-z]
Set         hexSet		[0-9a-f]
Set         nameSet		[A-Za-z0-9]
Set         notSpace	[^ \t\n\r\f]
Set         pathOpSet   [%~@:!dgIlrRSTu]
Set         curveOpSet  [aco]
Condition   curving
            notBlock
            ;
/*****************************************************************************
	Drawing grammar - short and sweet. Each element of a drawing path has
    three components: an operator, an x offset from the current point and
    optionally, a y offset from the current point. By default, the current
    point is taken to be the frame origin. The operators that can be used are:
    
        %   Length parameters interpreted as % of frame. So an x offset of 50
            is converted to 50% of the frame width.
        ~   The current point is taken to be where we currently at and it changes
            each time a new point is set.
        @   Move to the new point defined by the following x and y values.
        :   Close the current path after it is drawn.
        !   Resets the % and ~ settings to default where offsets are pixel lengths
            and the current point is the frame origin.
        a   Draw an arc (do not think this is implemented yet).
        c   Draw a curve (in addition to the target point, takes two more points as control arguments)
        d   Direction is down (applies to the y offset).
        g   Save graphics state
        I   Invert the current path when drawn.
        l   Direction is left (applies to the x offset).
        o	Draw an oval (not implemented yet).
        r   Direction is right (applies to the x offset).
        R   Rotate current path by the degrees specified in the x offset.
        S   Scale current path by amount specified in offsets. If no y offset
            specified, both x and y are scaled by the x offset amount.
        T   Shift path by amount specified in offsets.
        u   Direction is up (applies to y offset).
        ,	Separates commands that otherwise might be glommed onto the following command.
        ;	Ends a path, if graphics state saved, restores it.
        $   Stroke the current path
        F   Fill the current path

        The numeric arguments to all commands, except for the rotate command R, are scaled if the % operator is in effect. The arguments for @ resolve to a point. All numeric arguments not associated with the R and @ commands are taken to be lengths, as in how far to move, not defining a point to move to but how far away to move

    Drawing curves takes a couple more arguments and the grammar deals with it.
    The following are the curve commands.

        a   Draw an arc.
        c   Draw a bezier curve.
        o   Draw an oval.
*****************************************************************************/
resetSKIP
Name		:
				alphaSet
				nameSet*
			;

Amount		:
				number	= [0-9]+
				part	= [.0-9]*
			;

Number      :
                operator    = operateSet?
                number      = Amount
            |
                operator    = operateSet?
                number      = Name
            ;

Hex			:
				hexed       = hexSet{2}
			;
/*****************************************************************************
    Colors and Borders
*****************************************************************************/
setSKIP
RGBvalue	:
				hex		= Amount{3}
			|
				'#'
                redValue    = Hex
                greenValue  = Hex
                blueValue   = Hex
			;

Color		:
				color	= RGBvalue
				value	= Amount?
			|
				color	= Name
			;

ColorItem   :
                color   = Color
                ','?
            ;

ColorList   :
                list    = ColorItem+
            ;

BorderValue	:
				color	= Color
			|
				name	= Name
			|
				value	= Amount
			;

BorderLine	:
				BorderValue
				','?
			;

Border		:
				BorderLine+
			;

/*****************************************************************************
    Drawing
*****************************************************************************/
DrawColor   :
                '='
                color   = Color
            ;

DrawOperator    :
                SetNotBlock
                operate = Name
            |
                notBlock
                operate = pathOpSet
            |
                notBlock
                operate = curveOpSet
            |
                notBlock
                operate = [F$]
                color   = DrawColor?
            ;

Point   :
                point   = Number
                yOffset = Number?
                ','?
            ;

PointOp     :
                draw    = DrawOperator*
                point   = Point
                curving
                left    = Point
                right   = Point
            ;

DrawingPath :
                path    = PointOp+
                ';'
            ;

PathList    :
                list    = DrawingPath+
            ;

/*******************************************************************************
    Keystroke processing
*******************************************************************************/
resetSKIP
KeyStruck   :
                '/'
                number      = [0-9]+
            |
                character   = [^\n]
            ;

KeyStroke   :
                modifiers   = [acfmns]*
                '-'
                key         = KeyStruck
                ;
