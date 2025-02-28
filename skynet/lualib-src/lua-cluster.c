#define LUA_LIB

#include <lua.h>
#include <lauxlib.h>
#include <string.h>
#include <assert.h>

#include "skynet.h"
#define REQUEST_S_MAX (INT32_MAX/2-2)
#define RESPONSE_S_MAX (INT32_MAX-2)
#define SET_HIGH_BIT_INT32(a) (a|(1<<31))
#define KICK_HIGH_BIT_INT32(a) (a&((1<<31)-1))
#define CHECK_HIGH_BIT_INT32(a) (a&(1<<31))
/*
	uint32_t/string addr 
	uint32_t/session session
	lightuserdata msg
	uint32_t sz

	return 
		string request
		uint32_t next_session
 */

#define TEMP_LENGTH 0x8200
#define MULTI_PART 0x8000

static void
fill_uint32(uint8_t * buf, uint32_t n) {
	buf[0] = n & 0xff;
	buf[1] = (n >> 8) & 0xff;
	buf[2] = (n >> 16) & 0xff;
	buf[3] = (n >> 24) & 0xff;
}

static void
fill_header(lua_State *L, uint8_t *buf, int sz) {
	assert(sz < 0x10000);
	buf[0] = (sz >> 8) & 0xff;
	buf[1] = sz & 0xff;
}

/*
	The request package : 
		first WORD is size of the package with big-endian
		DWORD in content is small-endian
	size <= 0x8000 (32K) and address is id
		WORD sz+9
		BYTE 0
		DWORD addr
		DWORD session
		PADDING msg(sz)
	size > 0x8000 and address is id
		WORD 13
		BYTE 1	; multireq	, 0x41: multi push
		DWORD addr
		DWORD session
		DWORD sz

	size <= 0x8000 (32K) and address is string
		WORD sz+6+namelen
		BYTE 0x80
		BYTE namelen
		STRING name
		DWORD session
		PADDING msg(sz)
	size > 0x8000 and address is string
		WORD 10 + namelen
		BYTE 0x81	; 0xc1 : multi push
		BYTE namelen
		STRING name
		DWORD session
		DWORD sz

	multi req
		WORD sz + 5
		BYTE 2/3 ; 2:multipart, 3:multipart end
		DWORD SESSION
		PADDING msgpart(sz)
 */
static int
packreq_number(lua_State *L, int session, void * msg, uint32_t sz, int is_push) {
	uint32_t addr = (uint32_t)lua_tointeger(L,1);
	uint8_t buf[TEMP_LENGTH];
	if (sz < MULTI_PART) {
		fill_header(L, buf, sz+9);
		buf[2] = 0;
		fill_uint32(buf+3, addr);
		fill_uint32(buf+7,  (uint32_t)session);
		memcpy(buf+11,msg,sz);

		lua_pushlstring(L, (const char *)buf, sz+11);
		return 0;
	} else {
		int part = (sz - 1) / MULTI_PART + 1;
		fill_header(L, buf, 13);
		buf[2] = is_push ? 0x41 : 1;	// multi push or request
		fill_uint32(buf+3, addr);
		fill_uint32(buf+7, (uint32_t)session);
		fill_uint32(buf+11, sz);
		lua_pushlstring(L, (const char *)buf, 15);
		return part;
	}
}

static int
packreq_string(lua_State *L, int session, void * msg, uint32_t sz, int is_push) {
	size_t namelen = 0;
	const char *name = lua_tolstring(L, 1, &namelen);
	if (name == NULL || namelen < 1 || namelen > 255) {
		skynet_free(msg);
		luaL_error(L, "name is too long %s", name);
	}

	uint8_t buf[TEMP_LENGTH];
	if (sz < MULTI_PART) {
		fill_header(L, buf, sz+6+namelen);
		buf[2] = 0x80;
		buf[3] = (uint8_t)namelen;
		memcpy(buf+4, name, namelen);
		fill_uint32(buf+4+namelen, (uint32_t)session);
		memcpy(buf+8+namelen,msg,sz);

		lua_pushlstring(L, (const char *)buf, sz+8+namelen);
		return 0;
	} else {
		int part = (sz - 1) / MULTI_PART + 1;
		fill_header(L, buf, 10+namelen);
		buf[2] = is_push ? 0xc1 : 0x81;	// multi push or request
		buf[3] = (uint8_t)namelen;
		memcpy(buf+4, name, namelen);
		fill_uint32(buf+4+namelen, (uint32_t)session);
		fill_uint32(buf+8+namelen, sz);

		lua_pushlstring(L, (const char *)buf, 12+namelen);
		return part;
	}
}

static void
packreq_multi(lua_State *L, int session, void * msg, uint32_t sz) {
	uint8_t buf[TEMP_LENGTH];
	int part = (sz - 1) / MULTI_PART + 1;
	int i;
	char *ptr = msg;
	for (i=0;i<part;i++) {
		uint32_t s;
		if (sz > MULTI_PART) {
			s = MULTI_PART;
			buf[2] = 2;
		} else {
			s = sz;
			buf[2] = 3;	// the last multi part
		}
		fill_header(L, buf, s+5);
		fill_uint32(buf+3, (uint32_t)session);
		memcpy(buf+7, ptr, s);
		lua_pushlstring(L, (const char *)buf, s+7);
		lua_rawseti(L, -2, i+1);
		sz -= s;
		ptr += s;
	}
}

static int
packrequest(lua_State *L, int is_push) {
	void *msg = lua_touserdata(L,3);
	if (msg == NULL) {
		return luaL_error(L, "Invalid request message");
	}
	uint32_t sz = (uint32_t)luaL_checkinteger(L,4);
	int session = luaL_checkinteger(L,2);
	int session_copy=session;
	if (session <= 0) {
		skynet_free(msg);
		return luaL_error(L, "Invalid request session %d", session);
	}
	if(is_push) 
	{
		session_copy=SET_HIGH_BIT_INT32(session);
	}
	int addr_type = lua_type(L,1);
	int multipak;
	if (addr_type == LUA_TNUMBER) {
		multipak = packreq_number(L, session_copy, msg, sz, is_push);
	} else {
		multipak = packreq_string(L, session_copy, msg, sz, is_push);
	}
	uint32_t new_session = (uint32_t)session + 1;
	if (new_session > REQUEST_S_MAX) {
		new_session = 50;
	}
	lua_pushinteger(L, new_session);
	if (multipak) {
		lua_createtable(L, multipak, 0);
		packreq_multi(L, session_copy, msg, sz);
		skynet_free(msg);
		return 3;
	} else {
		skynet_free(msg);
		return 2;
	}
}

static int
lpackrequest(lua_State *L) {
	return packrequest(L, 0);
}

static int
lpackpush(lua_State *L) {
	return packrequest(L, 1);
}

/*
	string packed message
	return 	
		uint32_t or string addr
		int session
		string msg
		boolean padding
 */

static inline uint32_t
unpack_uint32(const uint8_t * buf) {
	return buf[0] | buf[1]<<8 | buf[2]<<16 | buf[3]<<24;
}

static int
unpackreq_number(lua_State *L, const uint8_t * buf, int sz) {
	if (sz < 9) {
		return luaL_error(L, "Invalid cluster message (size=%d)", sz);
	}
	
	uint32_t address = unpack_uint32(buf+1);
	uint32_t session = unpack_uint32(buf+5);

	lua_pushinteger(L, address);
	lua_pushinteger(L, KICK_HIGH_BIT_INT32(session));
	lua_pushlstring(L, (const char *)buf+9, sz-9);
	if (CHECK_HIGH_BIT_INT32(session)!=0) {
		lua_pushnil(L);
		lua_pushboolean(L,1);	// is_push, no reponse
		return 5;
	}

	return 3;
}

static int
unpackmreq_number(lua_State *L, const uint8_t * buf, int sz, int is_push) {
	if (sz != 13) {
		return luaL_error(L, "Invalid cluster message size %d (multi req must be 13)", sz);
	}
	uint32_t address = unpack_uint32(buf+1);
	uint32_t session = unpack_uint32(buf+5);
	uint32_t size = unpack_uint32(buf+9);
	lua_pushinteger(L, address);
	lua_pushinteger(L, KICK_HIGH_BIT_INT32(session));
	lua_pushinteger(L, size);
	lua_pushboolean(L, 1);	// padding multi part
	lua_pushboolean(L, is_push);

	return 5;
}

static int
unpackmreq_part(lua_State *L, const uint8_t * buf, int sz) {
	if (sz < 5) {
		return luaL_error(L, "Invalid cluster multi part message");
	}

	int padding = (buf[0] == 2);
	//表示是 multi part end
	if(padding==0)
	{
        padding=2;
	} 
	uint32_t session = unpack_uint32(buf+1);

	lua_pushboolean(L, 0);	// no address
	lua_pushinteger(L, KICK_HIGH_BIT_INT32(session));
	lua_pushlstring(L, (const char *)buf+5, sz-5);
	lua_pushinteger(L, (lua_Integer)padding);

	return 4;
}

static int
unpackreq_string(lua_State *L, const uint8_t * buf, int sz) {
	if (sz < 2) {
		return luaL_error(L, "Invalid cluster message (size=%d)", sz);
	}
	size_t namesz = buf[1];
	if (sz < namesz + 6) {
		return luaL_error(L, "Invalid cluster message (size=%d)", sz);
	}
	lua_pushlstring(L, (const char *)buf+2, namesz);
	uint32_t session = unpack_uint32(buf + namesz + 2);
	lua_pushinteger(L, (uint32_t)KICK_HIGH_BIT_INT32(session));
	lua_pushlstring(L, (const char *)buf+2+namesz+4, sz - namesz - 6);
	if (CHECK_HIGH_BIT_INT32(session)) {
		lua_pushnil(L);
		lua_pushboolean(L,1);	// is_push, no reponse
		return 5;
	}

	return 3;
}

static int
unpackmreq_string(lua_State *L, const uint8_t * buf, int sz, int is_push) {
	if (sz < 2) {
		return luaL_error(L, "Invalid cluster message (size=%d)", sz);
	}
	size_t namesz = buf[1];
	if (sz < namesz + 10) {
		return luaL_error(L, "Invalid cluster message (size=%d)", sz);
	}
	lua_pushlstring(L, (const char *)buf+2, namesz);
	uint32_t session = unpack_uint32(buf + namesz + 2);
	uint32_t size = unpack_uint32(buf + namesz + 6);
	lua_pushinteger(L, KICK_HIGH_BIT_INT32(session));
	lua_pushinteger(L, size);
	lua_pushboolean(L, 1);	// padding multipart
	lua_pushboolean(L, is_push);

	return 5;
}

static int
lunpackrequest(lua_State *L) {
	size_t ssz;
	const char *msg = luaL_checklstring(L,1,&ssz);
	int sz = (int)ssz;
	switch (msg[0]) {
	case 0:
		return unpackreq_number(L, (const uint8_t *)msg, sz);
	case 1:
		return unpackmreq_number(L, (const uint8_t *)msg, sz, 0);	// request
	case '\x41':
		return unpackmreq_number(L, (const uint8_t *)msg, sz, 1);	// push
	case 2:
	case 3:
		return unpackmreq_part(L, (const uint8_t *)msg, sz);
	case '\x80':
		return unpackreq_string(L, (const uint8_t *)msg, sz);
	case '\x81':
		return unpackmreq_string(L, (const uint8_t *)msg, sz, 0 );	// request
	case '\xc1':
		return unpackmreq_string(L, (const uint8_t *)msg, sz, 1 );	// push
	default:
		return luaL_error(L, "Invalid req package type %d", msg[0]);
	}
}

/*
	The response package :
	WORD size (big endian)
	DWORD session
	BYTE type
		0: error
		1: ok
		2: multi begin
		3: multi part
		4: multi end
	PADDING msg
		type = 0, error msg
		type = 1, msg
		type = 2, DWORD size
		type = 3/4, msg
 */
/*
	int session
	boolean ok
	lightuserdata msg
	int sz
	return string response
 */
static int
lpackresponse(lua_State *L) {
	uint32_t session = (uint32_t)luaL_checkinteger(L,1);
	uint32_t my_session = (uint32_t)luaL_checkinteger(L,2);
	uint32_t new_session=my_session+1;
	if(new_session>RESPONSE_S_MAX)
	{
		new_session=50;
	} 
	// clusterd.lua:command.socket call lpackresponse,
	// and the msg/sz is return by skynet.rawcall , so don't free(msg)
	int ok = lua_toboolean(L,3);
	void * msg;
	size_t sz;
	
	if (lua_type(L,4) == LUA_TSTRING) {
		msg = (void *)lua_tolstring(L, 4, &sz);
	} else {
		msg = lua_touserdata(L,4);
		sz = (size_t)luaL_checkinteger(L, 5);
	}

	if (!ok) {
		if (sz > MULTI_PART) {
			// truncate the error msg if too long
			sz = MULTI_PART;
		}
	} else {
		if (sz > MULTI_PART) {
			// return 
			int part = (sz - 1) / MULTI_PART + 1;
			lua_createtable(L, part+1, 0);
			uint8_t buf[TEMP_LENGTH];

			// multi part begin
			fill_header(L, buf, 13);
			fill_uint32(buf+2, session);
			fill_uint32(buf+6, my_session);
			buf[10] = 2;
			fill_uint32(buf+11, (uint32_t)sz);
			lua_pushlstring(L, (const char *)buf, 15);
			lua_rawseti(L, -2, 1);

			char * ptr = msg;
			int i;
			for (i=0;i<part;i++) {
				int s;
				if (sz > MULTI_PART) {
					s = MULTI_PART;
					buf[10] = 3;
				} else {
					s = sz;
					buf[10] = 4;
				}
				fill_header(L, buf, s+9);
				fill_uint32(buf+2, session);
				fill_uint32(buf+6, my_session);
				memcpy(buf+11,ptr,s);
				lua_pushlstring(L, (const char *)buf, s+11);
				lua_rawseti(L, -2, i+2);
				sz -= s;
				ptr += s;
			}
			lua_pushinteger(L, new_session);
			return 2;
		}
	}

	uint8_t buf[TEMP_LENGTH];
	fill_header(L, buf, sz+9);
	fill_uint32(buf+2, session);
	fill_uint32(buf+6, my_session);
	buf[10] = ok;
	memcpy(buf+11,msg,sz);

	lua_pushlstring(L, (const char *)buf, sz+11);
	lua_pushinteger(L, new_session);
	return 2;
}

/*
	string packed response
	return integer session
		boolean ok
		string msg
		boolean padding
 */
static int
lunpackresponse(lua_State *L) {
	size_t sz;
	const char * buf = luaL_checklstring(L, 1, &sz);
	if (sz < 9) {
		return 0;
	}
	uint32_t session = unpack_uint32((const uint8_t *)buf);
	uint32_t my_session = unpack_uint32((const uint8_t *)buf+4);
	lua_pushinteger(L, (lua_Integer)session);
	switch(buf[8]) {
	case 0:	// error
		lua_pushboolean(L, 0);
		lua_pushlstring(L, buf+9, sz-9);
		//by HW
		lua_pushinteger(L, (lua_Integer)my_session);
		return 4;
		//by HW
	case 1:	// ok
		lua_pushboolean(L, 1);
		lua_pushlstring(L, buf+9, sz-9);
		//by HW
		lua_pushinteger(L, (lua_Integer)my_session);
		return 4;
	case 4:	// multi end
		lua_pushboolean(L, 1);
		lua_pushlstring(L, buf+9, sz-9);
		//by HW
		lua_pushinteger(L, (lua_Integer)my_session);
		//by HW 2为multi end结束标志
		lua_pushinteger(L, (lua_Integer)2);
		return 5;
		//by HW
	case 2:	// multi begin
		if (sz != 13) {
			return 0;
		}
		sz = unpack_uint32((const uint8_t *)buf+9);
		lua_pushboolean(L, 1);
		lua_pushinteger(L, sz);
		//by HW
		lua_pushinteger(L, (lua_Integer)my_session);
		lua_pushinteger(L, (lua_Integer)1);
		return 5;
		//by HW
	case 3:	// multi part
		lua_pushboolean(L, 1);
		lua_pushlstring(L, buf+9, sz-9);
		//by HW
		lua_pushinteger(L, (lua_Integer)my_session);
		lua_pushinteger(L, (lua_Integer)1);
		return 5;
		//by HW
	default:
		return 0;
	}
}

static int
lconcat(lua_State *L) {
	if (!lua_istable(L,1))
		return 0;
	if (lua_geti(L,1,1) != LUA_TNUMBER)
		return 0;
	int sz = lua_tointeger(L,-1);
	lua_pop(L,1);
	char * buff = skynet_malloc(sz);
	int idx = 2;
	int offset = 0;
	while(lua_geti(L,1,idx) == LUA_TSTRING) {
		size_t s;
		const char * str = lua_tolstring(L, -1, &s);
		if (s+offset > sz) {
			skynet_free(buff);
			return 0;
		}
		memcpy(buff+offset, str, s);
		lua_pop(L,1);
		offset += s;
		++idx;
	}
	if (offset != sz) {
		skynet_free(buff);
		return 0;
	}
	// buff/sz will send to other service, See clusterd.lua
	lua_pushlightuserdata(L, buff);
	lua_pushinteger(L, sz);
	return 2;
}

LUAMOD_API int
luaopen_skynet_cluster_core(lua_State *L) {
	luaL_Reg l[] = {
		{ "packrequest", lpackrequest },
		{ "packpush", lpackpush },
		{ "unpackrequest", lunpackrequest },
		{ "packresponse", lpackresponse },
		{ "unpackresponse", lunpackresponse },
		{ "concat", lconcat },
		{ NULL, NULL },
	};
	luaL_checkversion(L);
	luaL_newlib(L,l);

	return 1;
}
