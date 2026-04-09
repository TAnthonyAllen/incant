class GroupRegistry;
class GroupItem;
/******************************************************************************
	ConnectLite provides a connection to a SQLite database and methods for
	accessing it
******************************************************************************/

class ConnectLite
{
public:
char *name;
sqlite3 *database;
int (*callback)(void *, int , char **, char **);
struct 
	{
	unsigned int debug:1;
	};
ConnectLite(char *dbName);
void close();
int connect();
int exec(char *select);
void getData(char *select, GroupRegistry *registry);
void getMembers(char *select, GroupItem *group);
void query(char *select, void *data, int (*callback)(void *, int , char **, char **));
};
int itemCallback(void *n, int columns, char **value, char **label);
int memberCallback(void *n, int columns, char **value, char **label);
