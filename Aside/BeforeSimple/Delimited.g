
include(Delimited.act)
/*****************************************************************************
	grammar for converting a comma separated file into GroupItems
*****************************************************************************/
Rules       JSONblock JSONrepeat
            ;
resetSKIP
DelimitDate		:
				['"]?
                date	= (dateSet+)
				['"]?
				delimit	= delimitSet
			;

DelimitNumber		:
				['"]?
				number	= Number
				['"]?
				delimit	= delimitSet
			;

DelimitText		:
                '"'
				text	= '"'}
				delimit	= delimitSet
            |
				singleQuote
				text	= singleQuote}
				delimit	= delimitSet
            |
				text	= delimitSet{
				delimit	= delimitSet
			;

DelimitEmpty    :
                #doNotGuard
                ['"]*
				delimit	= delimitSet
                ;

DelimitField	:
                item    = DelimitDate
            |   item    = DelimitNumber
            |   item    = DelimitText
            |   item    = DelimitEmpty
			;

DelimitFieldName	:
				name	= DelimitText
			;

Heading		:
				DelimitFieldName+
			;

Skipping    :
                skip = SkipGuard
                data = delimitSet}
            ;

FieldItem   :
                skips   = Skipping*
                item    = DelimitField
            ;

List		:
				FieldItem+
			;
/*****************************************************************************
    grammar for converting a json file into GroupItems
*****************************************************************************/
setSKIP
JSONtext        :
                    quote   = '"'
                    name    = '"'}
                |
                    name    = [^,:{}[ \]\t\n\r]+
                ;

JSONdata        :
                    name    = JSONtext
                |
                    block   = JSONblock
                |
                    repeat  = JSONrepeat
                ;

JSONpair        :
                    name    = JSONtext
                    ':'
                    data    = JSONdata
                    ','?
                ;

JSONblock       :
                    '{'
                    pair    = JSONpair+
                    '}'
                ;

JSONrepeatEntry :
                    data    = JSONdata
                    ','?
                ;

JSONrepeat      :
                    '['
                    entry  = JSONrepeatEntry+
                    ']'?
                ;

JSONlistEntry   :
                    entry   = JSONblock
                ;

JSONlist        :
                    blocks  = JSONlistEntry+
                ;
