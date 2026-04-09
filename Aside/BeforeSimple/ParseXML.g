include groupIncludes

%%
Condition   simpleSyntax stopParsing
            ;
Variable    endString subString
            ;
Rules		Attribute CommandText EndTag Epilog Field Integer
            LocateRegistry Locate Max Modifier Number Parameter Part Reference
            Registry SetTagFlag Tag Text TextBody Value
			;
Set     alphaSet    [A-Za-z_]
Set     anchorSet   [/%]
Set     bodySet     [^<>'"]
Set		commentSet	[!?-]
Set		dateSet		[0-9/:APM ]
Set		delimitSet	[,\n]
Set		fieldSet	[^ `,:+?*:!#/@|$%&<>~.;=()[\r\t\n'{}"]
Set		nameSet		[A-Za-z0-9_]
Set		notSpace	[^ \t\n\r\f]
Set     simpleEnd   [!@#$%&*()_]
Set     singleQuote [']
Set		spaces      [ \t\n\r\f]
Set		tagSet		[ =~]
Set	    textFollow  [A-Za-z0-9_]

/*****************************************************************************
	grammar for processing an XML file
*****************************************************************************/
insert(ParseXML.rtn)
include(Command.act)
include(ParseXML.act)
include(Command.g)
include(Delimited.g)

resetSKIP
Number		:   number	= ('-'?[0-9]+)
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

Text		:   text    = Quoted
			|   text	= (fieldSet+)
			;

RegexText	:   ['] text = ([^']+&) [']
			|   notSpace+
			;

EndBrace    :   endBrace = ']'
            ;

StringSet   :   '['
                text	= EndBrace}
            ;

SubString   :   subString}
            ;
setSKIP
/*****************************************************************************
	XML rules
*****************************************************************************/
FieldName	:   regex	= '~'
				RegexText
			|   any     = [*$]
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
resetSKIP
Line        :   line        = '\n'}
            ;

Lines       :   lines       = Line+
            ;
setSKIP
Modifier	:   limit       = Limit?
                modifier	= [+?!*{}%&<]*
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
                text    = StringSet
			|   '='
                dollar  = '$'?
				text	= ValueText
			;

Attribute	:   target  = [@%]*
				name	= Field&
				value	= Value?
				modify	= Modifier?
			;

/*****************************************************************************
	Two types of start tags:
        regular xml tags;
        command tags that build groups from sources
            In a group command, the attributes are sources; the members are
            paths that get matched against the sources. Every match gets
            added to the command groupl
            
            There are two alternate types of group commands:
            
            groupBy creates the command group from sources based on one or
            more attributes. Any attributes aside from the groupBy attribute
            are taken as input sources. The groupBy attribute value points
            to a group whose attributes are used to sort the members of
            the input sources into the command group.
            
            filterBy creates the command group containing only the attributes
            specified in the filter group pointed to in the filterBy attribute
            (the filter must be specified separately and referenced from the search
            path). All attributes except for the filterBy attribute are taken
            to be the input sources to be filtered.
*****************************************************************************/
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

BodyParts   :    part    = '<![CDATA[' <> ']]>'
            |    Comment
            ;

Closing     :   closing = '/'+
            |   closing = ';'
            ;

SetAttributes   :
				SetTagFlag?
				attributes  = Attribute+
            ;

SetSimpleEnd    :
                simpleEnd+
                ;

SimpleEnd   :   ':'
                textBody    = TextBody?
            |   close       = [,;]+
                field       = Field?&
            ;

StartTag	:   '<'
                commentSet!
                traits      = SetAttributes
				singleton   = Closing?
				'>'
            |   simpleSyntax
                traits      = SetAttributes
                end         = SimpleEnd
			;

EndTag		:   '<'
                action  = Closing
				field	= Field?
				'>'
            |   simpleSyntax
                action  = Closing
			;

Tag			:   Command
            |   tag	= StartTag
            |   tag	= EndTag
			;

Part		:   prefix  = BodyParts*
                body    = Tag}
			;

StartXML    :   Part+
				spaces*
				epilog	    = Epilog?
			;

TextBody    :
                SetSimpleEnd
                body        = endString}
                ';'
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

