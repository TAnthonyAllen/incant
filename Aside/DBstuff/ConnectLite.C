#include <string.h>
#include <stdio.h>
#include "GroupItem.h"
#include "GroupRegistry.h"
#include "BaseHash.h"
#include "sqlite.h"
#include "ConnectLite.h"

ConnectLite::ConnectLite(char *dbName)
{
	callback = 0;
	database = 0;
	debug = 0;
	name = dbName;
	connect();
}

/******************************************************************************
	Close database connection
******************************************************************************/
void ConnectLite::close()
{
	::sqlite3_close(database);
	if ( debug )
		printf("Closing connection\n");
}

/******************************************************************************
	Establish a database connection
******************************************************************************/
int ConnectLite::connect()
{
	if ( ::sqlite3_open(name,&database) )
		{
		fprintf(stderr,"Unable to open database: %s\n",name);
		return 0;
		}
	if ( debug )
		printf("Connected\n");
	return 1;
}

/******************************************************************************
	The exec method runs the select statement passed in, which is assumed to
	not produce results.
******************************************************************************/
int ConnectLite::exec(char *select)
{
char 	*error = 0;
	if ( ::sqlite3_exec(database,select,callback,(void*)0,&error) )
		{
		fprintf(stderr,"exec failed: %s\n",error);
		return 0;
		}
	if ( debug )
		printf("exec succeeded\n");
	return 1;
}

/******************************************************************************
	load atomic elements into registry
******************************************************************************/
void ConnectLite::getData(char *select, GroupRegistry *registry)
{
	query(select,(void*)registry,::itemCallback);
}

/******************************************************************************
	load GroupItem members.
******************************************************************************/
void ConnectLite::getMembers(char *select, GroupItem *group)
{
	query(select,(void*)group,::memberCallback);
}

/******************************************************************************
	The query method runs query, which invokes the callback if supplied
	(passing data as the first parameter to the callback). It returns true
	if it succeeds, false otherwise.
******************************************************************************/
void ConnectLite::query(char *select, void *data, int (*callback)(void *, int , char **, char **))
{
char 	*error = 0;
	if ( ::sqlite3_exec(database,select,callback,data,&error) )
		fprintf(stderr,"Query failed: %s\n",error);
	if ( debug )
		printf("Query succeeded\n");
}
// Ignoring declaration of unused variable item in method: itemCallback(void*,int,char**,char**)

/******************************************************************************
	Callback to load atomic elements into registry.
	THIS NEEDS TO BE MODIFIED TO DEAL W/CONTENTS OF QUERY
******************************************************************************/
int itemCallback(void *n, int columns, char **value, char **label)
{
GroupRegistry 	*registry = (GroupRegistry*)n;
	 ERROR could not find isStored = 1;
	return 0;
}

/******************************************************************************
	Callback to load GroupItem members.
******************************************************************************/
int memberCallback(void *n, int columns, char **value, char **label)
{
GroupRegistry 	*registry = 0;
GroupItem 		*item = (GroupItem*)n;
GroupItem 		*member = 0;
	registry = (GroupRegistry*)GroupRegistry::registries->get(*value);
	if ( !registry )
		{
		fprintf(stderr,"getMembers: could not find registry %s\n",value[0]);
		return 1;
		}
	member = registry->registryItem->getWhatever(value[1]);
	if ( !member )
		{
		fprintf(stderr,"getMembers: could not find %s in registry %s\n",value[1],registry->type);
		return 1;
		}
	item->addGroup(member);
	return 0;
}
