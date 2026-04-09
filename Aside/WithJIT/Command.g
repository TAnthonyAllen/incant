setSKIP
/*****************************************************************************
	commands
*****************************************************************************/
KeyWord     Registering
                asAttributes
                base
                components
                data
                doNotDuplicate
                grouped
                hasMethods
                noMerging
                search
                tagged
                value
                ;
KeyWord     Flag
                debug
                macro
                pause
                noJIT
                noPrint
                stop
                ;
KeyWord     CommandAction
                dump
                list
                load
                print
                run
                save
                ;

AttributeList   :
                '['
                name    = Text+
            ;

Command		:
				'#'
				command	= CommandText? ';'
			;

RegistryFlag    :
                not     ='!'?
                flag    = Registering
            ;

CommandText	:
				'include'
                spaces*
				file    = ';'{
			|
				'registry'
				type    = Text
				value	= RegistryFlag*
			|
				action  = CommandAction
                number  = Number?
				type    = Registry?
				path	= Locate?
                list    = AttributeList?
			|
				flag    = Flag
            |
                'search'
                plus    = '+'?
                names   = Text*
            |
                'merge'
                target  = Text
                names   = Text+
            |
                group   = Locate
			;

Registry:
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
/*****************************************************************************
	grammar for processing group operations
*****************************************************************************/
GroupTarget :
				'('
				group		= Locate
				command		= GroupCommand+
				')'
			|
				group		= Locate
            ;

GroupCommand	:
				operate     = [-+&|^!]?
				target		= GroupTarget
			;

GroupAction :
                target  = GroupTarget
                action  = GroupCommand
            ;
