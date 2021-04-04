# makefile for building LuaX in Linux
# prepare other libs: apt install libreadline-dev libcurl4-openssl-dev libpcre3-dev libz-dev

# == CHANGE THE SETTINGS BELOW TO SUIT YOUR ENVIRONMENT =======================

# Your platform. See PLATS for possible values.
PLAT= none

CC= gcc
CFLAGS= -O2 -Wall -DLUA_USE_LINUX -Iinclude
AR= ar -r
RANLIB= ranlib
RM= rm -f
LIBS= -lm -lz -Wl,-E -ldl -lreadline -lhistory -lncurses -lcurl -lpcre

BSTRINGSRCDIR= ext-library/bstring/
LIBLUASRCDIR= lua-library-src/liblua/
MYLIBSDIR= lib/
MYBINDIR= bin/
MYOBJDIR= builds/

# == END OF USER SETTINGS. NO NEED TO CHANGE ANYTHING BELOW THIS LINE =========

all: $(MYBINDIR)lua

$(MYBINDIR)lua: $(MYOBJDIR)lua.o $(MYLIBSDIR)liblua.a $(MYLIBSDIR)bstring.a
	$(CC) -o $(MYBINDIR)lua $(MYOBJDIR)lua.o $(MYLIBSDIR)liblua.a $(MYLIBSDIR)bstring.a $(LIBS)

BSTRING_SRCS = $(wildcard $(BSTRINGSRCDIR)*.c)
BSTRING_OBJS = $(BSTRING_SRCS:.c=.o)
$(MYLIBSDIR)bstring.a: $(BSTRING_OBJS)
	$(AR) $@ $(BSTRING_OBJS)
	$(RANLIB) $@

LIBLUA_SRCS = $(wildcard $(LIBLUASRCDIR)*.c)
LIBLUA_OBJS = $(LIBLUA_SRCS:.c=.o)
$(MYLIBSDIR)liblua.a: $(LIBLUA_OBJS) $(MYOBJDIR)lcsvlib.o $(MYOBJDIR)lgziolib.o $(MYOBJDIR)lfs.o $(MYOBJDIR)lhttplib.o $(MYOBJDIR)lua_cjson.o $(MYOBJDIR)lpcre.o $(MYOBJDIR)lpcre_f.o $(MYOBJDIR)common.o
	$(AR) $@ $(LIBLUA_OBJS) $(MYOBJDIR)lcsvlib.o $(MYOBJDIR)lgziolib.o $(MYOBJDIR)lfs.o $(MYOBJDIR)lhttplib.o $(MYOBJDIR)lua_cjson.o $(MYOBJDIR)lpcre.o $(MYOBJDIR)lpcre_f.o $(MYOBJDIR)common.o
	$(RANLIB) $@

$(MYOBJDIR)lpcre.o: lua-library-src/luapcre/lpcre.c lua-library-src/luapcre/common.h lua-library-src/luapcre/algo.h
	$(CC) -O2 -Wall -c -o $@ lua-library-src/luapcre/lpcre.c -Iinclude
	
$(MYOBJDIR)lpcre_f.o: lua-library-src/luapcre/lpcre_f.c lua-library-src/luapcre/common.h lua-library-src/luapcre/algo.h
	$(CC) -O2 -Wall -c -o $@ lua-library-src/luapcre/lpcre_f.c -Iinclude
	
$(MYOBJDIR)common.o: lua-library-src/luapcre/common.c lua-library-src/luapcre/common.h lua-library-src/luapcre/algo.h	
	$(CC) -O2 -Wall -c -o $@ lua-library-src/luapcre/common.c -Iinclude

$(MYOBJDIR)lhttplib.o: lua-library-src/luahttp/lhttplib.c
	$(CC) -O2 -Wall -c -DLUA_USE_LINUX -o $@ $< -Iinclude

$(MYOBJDIR)lcsvlib.o: lua-library-src/luacsv/lcsvlib.c
	$(CC) -O2 -Wall -c -o $@ $< -Iinclude

$(MYOBJDIR)lua_cjson.o: lua-library-src/luajson/lua_cjson.c
	$(CC) -O2 -Wall -c -o $@ $< -Iinclude

$(MYOBJDIR)lgziolib.o: lua-library-src/luagzio/lgziolib.c
	$(CC) -O2 -Wall -c -o $@ $< -Iinclude

$(MYOBJDIR)lfs.o: lua-library-src/luafilesystem/lfs.c
	$(CC) -O2 -Wall -fPIC -W -Waggregate-return -Wcast-align -Wmissing-prototypes -Wnested-externs -Wshadow -Wwrite-strings -pedantic -c -o $@ $< -Iinclude

$(MYOBJDIR)lua.o: lua-interpreter-src/lua.c
	$(CC) -O2 -Wall -c -DLUA_USE_LINUX -o $@ $< -Iinclude

clean:
	$(RM) $(BSTRINGSRCDIR)*.o
	$(RM) $(LIBLUASRCDIR)*.o
	$(RM) $(MYLIBSDIR)*.a
	$(RM) $(MYOBJDIR)*.o
	$(RM) $(MYBINDIR)lua

# (end of Makefile)

