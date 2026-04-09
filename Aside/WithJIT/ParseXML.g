include groupIncludes

/*******************************************************************************
    Initializer for GroupItem, a wrapper that the jit can find. first it looks
    thru the parent hierarchy, checking tags and attributes. If not found, it
    looks thru the registry search path.
*******************************************************************************/
extern GroupItem locateGroup(GroupItem item,String text)
{
GroupItem   group;
use item.parser
    if text eq "selection" group = lastSelect;
    else group = item.find(text);
    return group;
}

/*******************************************************************************
    Looks for a group. If there is a currentBlock, it calls locateGroup, otherwise
    it calls locate to look thru the registry search path. If the group is found,
    it gets wrapped in an instance, with the address put in instance.prefix and
    returned.
*******************************************************************************/
extern Instance getGroupInstance(String text)
{
GroupItem   group;
Instance    instance;
ParseXML    parser = externalENV;
    cout "getGroupInstance: searching for",text:;
    if currentBlock group = currentBlock.find(text);
    else group = locate(text);
    if group
        {
        instance    = new(getType("GroupItem"));
        prefix      = (String)group;
        indirection = 1;
        isExternalType  = true;
        }
    return instance;
}

%%
Rules		Attribute CommandText EndTag Epilog GroupCommand Integer LocateRegistry
            Max Modifier Number Parameter Part Reference Tag Text Field Value
			;
Set     alphaSet    [A-Za-z_]
Set     anchorSet   [/%]
Set     bodySet     [^>'"]
Set		commentSet	[!?-]
Set		dateSet		[0-9/:APM ]
Set		delimitSet	[,\n]
Set		fieldSet	[^ +?*:!#/@|$%<>~;=()[.\r\t\n'"]
Set		nameSet		[A-Za-z0-9_]
Set		notSpace	[^ \t\n\r\f]
Set     singleQuote [']
Set		spaces      [ \t\n\r\f]
Set		tagSet		[ =~]
Set		textSet		[^ :%/>|~;.\r\t\n'"]

/*****************************************************************************
	grammar for processing an XML file
*****************************************************************************/
insert(ParseXML.rtn)
include(ParseXML.act)
include(Command.act)
include(Command.g)
include(Delimited.g)

resetSKIP
Number		:   number	= ([-0-9]+)
				part	= ([.0-9]+)?
                alphaSet!&
			;

Comment     :   comment = '/*' <> '*/'
            |   comment = '<!' <> '!>'
            |   comment = '<?' <> '?>'
            |   comment = '<-' <> '->'
            ;

Quoted		:   '"' text = ([^"]+&) '"'
			|   ['] text = ([^']+&) [']
            ;

Text		:   text = Quoted
			|   text	= (textSet+&)
			;

RegexText	:   ['] text = ([^']+&) [']
			|   notSpace+
			;
setSKIP
/*****************************************************************************
	XML rules
*****************************************************************************/
FieldName	:   regex	= '~'
				RegexText
			|   any     = '*'
			|   '"' field = ([^"]+&) '"'
			|   ['] field = ([^']+&) [']
			|   (fieldSet+&)
			;

Field		:   field	= FieldName
			;

Limit       :   '{'
                minimum     = Number
                ','?
                maximum     = Number?
                '}'
            ;

Modifier	:   modifier	= [+?!*]?
                limit       = Limit?
                alternate   = '|'?
			;

ValueText	:   amount	= Number
				percent	= '%'?&
			|
				text	= Text
			;

Value		:   regex	= '=~'
				text	= RegexText
			|   '='
                dollar  = '$'?
				text	= ValueText
			;

Attribute	:   target  = [@%]*&
				name	= Field
				value	= Value?
				modify	= Modifier?
			;

/*****************************************************************************
	Two types of start tags:
        regular xml tags;
        command tags that build or operate on groups
            if the only attribute is path=a path expression if gets processed
            into a path that gets matched against the current search list or
            in case the path starts with a regular expression or * then it is
            matched against the current registry. Any match gets added to the
            group that is created
            
            groupBy creates a group from members of a source based on one or
            more attributes. It takes a source attribute (source=something)
            and a value (groupBy=something) that defines either an attribute
            to be matched or a group containing attributes to be matched
            
            mapWRT maps a group wrt a source
*****************************************************************************/
StartTag	:   '<'
                commentSet!
                command     = [:[]?
				SetTagFlag?
				attributes  = Attribute+
				singleton   = [)/;]?
				'>'
            |   '*'
			;

Epilog		:   epilog = ~$}
			;

Integer		:   count	= ([0-9]+&)
			;

Max			:   ','
				maximum = Integer
			;

TagBody     :   bodySet+
            |   '"' [^"]+ '"'
			|   ['] [^']+ [']
            ;

AnyTag      :   '<' commentSet! TagBody+ '>'
            |   '#' CommandText? ';'
            ;

BodyParts   :    part    = '<![CDATA[' <> ']]>'
            |    part    = Comment
            ;

Body        :   prefix  = BodyParts*
                body    = AnyTag{
            ;

EndTag		:   '</'
				field	= Field?
				'>'
			;

Tag			:   tag	= EndTag
            |   tag	= StartTag
			|   Command
			;

Part		:   body	= Body?&
				head	= Tag
			;

StartXML    :   Part+
				spaces*
				epilog	= Epilog?
			;

/*****************************************************************************
	macros
*****************************************************************************/
resetSKIP
MacroPart   :
                '$'
                text    = Text
            |
                text    = ([^$]+)
            ;

Macro       :
                
                macro   = MacroPart+
            ;

/*****************************************************************************
	Simple direct path called by simplePath() method
*****************************************************************************/
Up          :
                '..'
                more    = '/..'*
                slash   = '/'?
            ;

PathItem    :
                text    = Text
                slash   = '/'?
            ;

Path        :
                up      = Up?
                path    = PathItem*
            ;

