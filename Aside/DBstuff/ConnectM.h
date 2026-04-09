class BaseHash;
class GroupRegistry;
class GroupItem;
/******************************************************************************
	ConnectM provides a connection to a mysql database and methods for
	accessing a database to load GroupItems
******************************************************************************/

class ConnectM
{
public:
char *host;
char *user;
char *password;
char *DB;
char *socket;
int port;
struct 
	{
	unsigned int debug:1;
	};
MYSQL mysql;
BaseHash *fields;
MYSQL_RES result;
char **row;
int columns;
long rows;
ConnectM();
void close();
int connect();
void getData(char *select, GroupRegistry *registry);
void getMembers(char *s, GroupItem *g);
int query(char *s);
};
MYSQL mysql;
BaseHash *fields;
MYSQL_RES result;
char **row;
char *host;
char *user;
char *password;
char *DB;
char *socket;
int port;
int columns;
long rows;
struct 
	{
	unsigned int debug:1;
	};
GroupItem *item;
int *lengths;
void close();
int connect();
void getData(char *select, GroupRegistry *registry);
struct FieldMap
	{
	int row;
	MYSQL_FIELD dbField;
	};
