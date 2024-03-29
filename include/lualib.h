/*
** $Id: lualib.h,v 1.36.1.1 2007/12/27 13:02:25 roberto Exp $
** Lua standard libraries
** See Copyright Notice in lua.h
*/


#ifndef lualib_h
#define lualib_h

#include "lua.h"


/* Key to file-handle type */
#define LUA_FILEHANDLE		"FILE*"


#define LUA_COLIBNAME	"coroutine"
LUALIB_API int (luaopen_base) (lua_State *L);

#define LUA_TABLIBNAME	"table"
LUALIB_API int (luaopen_table) (lua_State *L);

#define LUA_IOLIBNAME	"io"
LUALIB_API int (luaopen_io) (lua_State *L);

#define LUA_OSLIBNAME	"os"
LUALIB_API int (luaopen_os) (lua_State *L);

#define LUA_STRLIBNAME	"string"
LUALIB_API int (luaopen_string) (lua_State *L);

#define LUA_MATHLIBNAME	"math"
LUALIB_API int (luaopen_math) (lua_State *L);

#define LUA_DBLIBNAME	"debug"
LUALIB_API int (luaopen_debug) (lua_State *L);

#define LUA_LOADLIBNAME	"package"
LUALIB_API int (luaopen_package) (lua_State *L);

#define LUA_HTTPLIBNAME "http"
LUALIB_API int (luaopen_http) (lua_State *L);

#define LUA_JSONLIBNAME "json"
LUALIB_API int (luaopen_cjson) (lua_State *L);

#define LUA_JSONSAFELIBNAME	"json_safe"
LUALIB_API int (luaopen_cjson_safe) (lua_State *L);

#define REX_LIBNAME "pcre"
LUALIB_API int (luaopen_rex_pcre) (lua_State *L);

#define LUA_CSVLIBNAME "csv"
LUALIB_API int (luaopen_csv) (lua_State *L);

#define LUA_IUPLIBNAME "iup"
LUALIB_API int (luaopen_iuplua) (lua_State *L);

#define LUA_GZIOLIBNAME   "gzio"
LUALIB_API  int (luaopen_gzio) (lua_State *L);

#define LUA_LFSLIBNAME   "lfs"
LUALIB_API  int (luaopen_lfs) (lua_State *L);

#define LUA_ZIPLIBNAME	"zip"
LUALIB_API int luaopen_zip (lua_State *L);

/* open all previous libraries */
LUALIB_API void (luaL_openlibs) (lua_State *L); 

#ifndef lua_assert
#define lua_assert(x)	((void)0)
#endif


#endif
