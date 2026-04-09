setSKIP
/*****************************************************************************
	commands
*****************************************************************************/
KeyWord     Registering
                asAttributes
                base
                components
                data
                descending
                display
                grouped
                layout
                noPrint
                rules
                search
                sort
                track
                value
                ;
KeyWord     Flag
                debug
                easy
                macro
                pause
                noJIT
                noPrint
                stop
                ;
KeyWord     CommandAction
                dump
                list
                print
                save
                test
                ;

AttributeList   :
                '['
                name    = Text+
            ;

Command		:
				'#'
				command	= CommandText?
                ';'
			;

CommandArgument :
                '(' argument = Locate? ')'
            ;

CommandText	:
				'include'                   textFollow!
				file    = ';'{
			|
				'registry'                  textFollow!&
				type    = Text
				flag	= Registering*
			|
				action  = CommandAction     textFollow!&
				type    = Registry?
				path	= Locate?
                list    = AttributeList?
                number  = Number?
			|
				flag    = Flag              textFollow!&
            |
                'search'                    textFollow!&
                plus    = '+'?
                names   = Text*
            |
                'load'                      textFollow!&
				path	= Locate
            |
                group       = Locate
                argument    = CommandArgument?
			;

Registry    :
                type    = Text
            ;

Locate      :
                type    = Registry?
                field   = Text
            ;

URLhead		:
				'ftp:'
			|   'file:'
			|   'http' 's'? ':'
            |   'data:'
			;
