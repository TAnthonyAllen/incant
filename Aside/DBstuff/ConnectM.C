#include <string.h>
#include <stdio.h>
#include "GroupItem.h"
#include "mysql.h"
#include "mysql.h"
#include "GroupRegistry.h"
#include "BaseHash.h"
#include "ConnectM.h"

/******************************************************************************
	Close database connection
******************************************************************************/
void close()
{
	::mysql_close(mysql);
	if ( debug )
		printf("Closing connection\n");
}

/******************************************************************************
	Establish a database connection
******************************************************************************/
int connect()
{
	mysql = ::mysql_init(0);
	if ( !::mysql_real_connect(mysql,host,user,password,DB,port,socket,0) )
		{
		fprintf(stderr,"Could not connect: %s\n",::mysql_error(mysql));
		return 0;
		}
	if ( debug )
		printf("Connected\n");
	return 1;
}

ConnectM::ConnectM()
{
	socket = 0;
	debug = 0;
	row = 0;
	columns = 0;
	rows = 0;
	host = "TonyG5.local";
	user = "root";
	password = "alix";
	DB = "test";
	port = 3306;
	fields = new BaseHash();
	connect();
}

/******************************************************************************
	Close database connection
******************************************************************************/
void ConnectM::close()
{
	::mysql_close(mysql);
	if ( debug )
		printf("Closing connection\n");
}

/******************************************************************************
	Establish a database connection
******************************************************************************/
int ConnectM::connect()
{
	mysql = ::mysql_init(0);
	if ( !::mysql_real_connect(mysql,host,user,password,DB,port,socket,0) )
		{
		fprintf(stderr,"Could not connect: %s\n",::mysql_error(mysql));
		return 0;
		}
	if ( debug )
		printf("Connected\n");
	return 1;
}
