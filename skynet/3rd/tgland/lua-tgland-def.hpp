//
// 作者: 隆元线
// Date: 2018/10/1
// Time: 14:48
// lua 数据类型导出
//

#include <assert.h>

extern "C"  
{  
    #include "lua.h"  
    #include "lauxlib.h"  
    #include "lualib.h"  
}  

typedef unsigned short WORD;
typedef unsigned int DWORD;
typedef unsigned int UINT;
typedef unsigned long LONG;
typedef char TCHAR;
typedef unsigned char BYTE;

#define PAI_STRUCT_LEN 7

// 捕获所有异常
#ifdef LYX_DEBUG
	#define LAND_TRY

	#define LAND_CATCH
#else

	#define LAND_TRY try {

	#define LAND_CATCH 	} \
		catch(TempExcep &te) \
		{ \
			printf("CalcOutCard game logic error id:%d\n",te.error); \
			lua_pushinteger(L,(lua_Integer)te.error); \
			return 1; \
		} \
		catch(...) \
		{ \
			printf("CalcOutCard game logic error other\n"); \
			assert(false); \
			lua_pushinteger(L,(lua_Integer)-2001); \
			return 1; \
		}

#endif


// 开始取参数
#define LParamBegin() int _stack_index = 0;

// 取得参数（一定要顺序放置）
#define LGetValue(_var) \
	++ _stack_index; \
	if (!lget_value(L,(int)_stack_index,_var,#_var " value error! ")) \
	{ \
		return luaL_error(L,"get value " #_var " error,it is null !");  \
	}

// 取得自定义对象指针
#define LGetLightObject(_var) \
	++ _stack_index; \
	if (!lua_islightuserdata(L,_stack_index))  \
	{  \
		return luaL_error(L,"get object " #_var " error, lua type is not lightuserdata!");  \
	}  \
	convert_userdata_type(_var,lua_touserdata(L,_stack_index)); \
	if (!_var)  \
	{  \
		return luaL_error(L,"get object " #_var " error,it is null !");  \
	}

template <typename T>	
void convert_userdata_type(T &v,void * ud)
{
	v = (T)ud;
}

// 前置声明
bool lget_value(lua_State *L,int tIndex,pai_struct &param,const char * title = "pai_struct");
template <typename T>
bool lget_value(lua_State *L,int tIndex,std::vector<T> & param,const char * title = "vector param");
template <typename K,typename V>
bool lget_value(lua_State *L,int tIndex,std::map<K,V> &param,const char * title = "map param");
template <typename T>
bool lget_table_memb(lua_State *L,int tIndex,const std::string &name,T &member,const char * title = "member");
template <typename T,int len>
bool lget_value(lua_State *L,int tIndex,int param[len],const char * title = "param");
template <typename K,typename V>
void lpush_value(lua_State *L,const std::map<K,V> &value,const char * title = "map");
template <typename T>
void lpush_value(lua_State *L,const std::vector<T> &value,const char * title = "vector");

void regular_stack(lua_State *L, int &i)
{
	// 转换 栈 到正数
	if (i < 0)
		i = lua_gettop(L) + i + 1;	
}

std::string debug_print_v(lua_State *L,int i)
{
	if (lua_isnil(L,i))
		return std::string("nil\n");

	char buftitle[500] = {0};

	sprintf(buftitle,"type:%s,value:%s\n",luaL_typename(L,i),luaL_checkstring(L,i));
	return std::string(buftitle);
}

std::string debug_print(lua_State *L,int i)
{
	if (lua_isnil(L,i))
		return std::string("nil\n");


	if (lua_type(L,i) == LUA_TTABLE)
	{
		std::string ret;

		int top = lua_gettop(L);
		int ik = top + 1;
		int iv = top + 2;

		ret = ret + "table item:\n";

		lua_pushnil(L);
		while (lua_next(L, i) != 0) 
		{
			ret = ret + debug_print_v(L,ik);
			ret = ret + debug_print_v(L,iv);

			lua_pop(L, 1);
		}

		return ret;
	}

	char buftitle[500] = {0};
	sprintf(buftitle,"type:%s,value:%s\n",luaL_typename(L,i),luaL_checkstring(L,i));
	return std::string(buftitle);
}


// 数据压栈

void lpush_value(lua_State *L,const bool &value) 
{
	lua_pushboolean(L,value ? 1 : 0);
}

void lpush_value(lua_State *L,const int &value) 
{
	lua_pushinteger(L,(lua_Integer)value);
}

void lpush_value(lua_State *L,const char * value) 
{
	lua_pushstring(L,value);

}

void lpush_value(lua_State *L,const pai_struct &value) 
{
	lua_newtable(L);

		lua_pushstring(L,"type");
		lpush_value(L,value.type);
		lua_settable(L,-3);


		lua_pushstring(L,"score");
		lpush_value(L,value.score);
		lua_settable(L,-3);

		lua_pushstring(L,"pai");
		lua_newtable(L);
		for (int i=1;i<=PAI_STRUCT_LEN;i++)
		{
			lua_pushinteger(L,i);
			lpush_value(L,value.pai[i-1]);
			lua_settable(L,-3);
		}
		lua_settable(L,-3);
}

void lpush_value(lua_State *L,const PaiTypeMap &value) 
{
	lua_newtable(L);

		lua_pushstring(L,"pai");
		lpush_value(L,value.pai);
		lua_settable(L,-3);


		lua_pushstring(L,"score");
		lpush_value(L,value.score);
		lua_settable(L,-3);

		lua_pushstring(L,"shoushu");
		lpush_value(L,value.shoushu);
		lua_settable(L,-3);

		lua_pushstring(L,"bomb_count");
		lpush_value(L,value.bomb_count);
		lua_settable(L,-3);

		lua_pushstring(L,"xiajiao");
		lpush_value(L,value.xiajiao);
		lua_settable(L,-3);

		lua_pushstring(L,"no_xiajiao_socre");
		lpush_value(L,value.no_xiajiao_score);
		lua_settable(L,-3);
}

// 读取数据

bool lget_value(lua_State *L,int i,int &param,const char * title = "param") 
{
	if (lua_isnil(L,i))
		return false;

	if (!lua_isinteger(L,i))
	{
		luaL_error(L,"'%s' error,expect 'integer' but '%s'!",title,luaL_typename(L,i));
		return false;
	}

	param = luaL_checkinteger(L,i);
	return true;
}

bool lget_value(lua_State *L,int i,bool &param,const char * title = "param") 
{
	param = lua_toboolean(L,i) ? true : false;
	return true;
}

bool lget_value(lua_State *L,int i,std::string &param,const char * title = "param") 
{
	if (lua_isnil(L,i))
		return false;

	if (!lua_isstring(L,i))
	{
		luaL_error(L,"'%s' error,expect 'string' but '%s'!",title,luaL_typename(L,i));
		return false;
	}

	param = luaL_checkstring(L,i);
	return true;
}

template <typename T,int len>
bool lget_value(lua_State *L,int tIndex,int param[len],const char * title)
{
	if (lua_isnil(L,tIndex))
		return false; // 空值 不认为失败

	if (!lua_istable(L,tIndex))
	{
		luaL_error(L,"'%s' error,expect 'table' but '%s'!",title,luaL_typename(L,tIndex));
		return false;
	}

	int top = lua_gettop(L);

	// 转换 栈 到正数
	if (tIndex < 0)
		tIndex = top + tIndex + 1;

	char buftitle[500] = {0};

	for (int k=1;k<=len;++k)
	{
		lua_pushinteger(L,k);
		lua_gettable(L,tIndex);

		sprintf(buftitle,"%s, index %d ",title,k);

		T v;

		if (!lget_value(L,-1,v,buftitle))
			break;

		lua_pop(L,1);
		param[k-1] = v;
	}

	// 清栈
	lua_settop(L,top);
	return true;
}

template <typename T>
bool lget_vector(lua_State *L,int tIndex,std::vector<T> & param,const char * title = "param")
{
	if (lua_isnil(L,tIndex))
		return false; 

	if (!lua_istable(L,tIndex))
	{
		luaL_error(L,"'%s' error,expect 'table' but '%s'!",title,luaL_typename(L,tIndex));
		return false;
	}

	int len = luaL_len(L,tIndex);

	int top = lua_gettop(L);

	// 转换 栈 到正数
	if (tIndex < 0)
		tIndex = top + tIndex + 1;

	char buftitle[500] = {0};

	for (int k=1;k<=len;++k)
	{
		lua_pushinteger(L,k);
		lua_gettable(L,tIndex);

		sprintf(buftitle,"%s, index %d ",title,k);

		T v;

		if (!lget_value(L,-1,v,buftitle))
			return false;

		lua_pop(L,1);
		param.push_back(v);
	}

	// 清栈
	lua_settop(L,top);
	return true;
}

template <typename T>
bool lget_value(lua_State *L,int tIndex,std::vector<T> & param,const char * title)
{
	return lget_vector(L,tIndex,param,title);
}

// 得到表成员
template <typename T>
bool lget_table_memb(lua_State *L,int tIndex,const std::string &name,T &member,const char * title) 
{
	if (!lua_istable(L,tIndex))
	{
		luaL_error(L,"'%s' error,expect 'table' but '%s'!",title,luaL_typename(L,tIndex));
		return false;
	}

	lua_pushstring(L,name.c_str());
	lua_gettable(L,tIndex);

	char buftitle[500] = {0};
	sprintf(buftitle,"%s, index %s ",title,name.c_str());

	if (!lget_value(L,-1,member,buftitle))
		return false;

	lua_pop(L,1);

	return true;
}

// 创建一个新的 lua 数组，放到栈顶，并填充数据
template <typename T>
void lpush_vector(lua_State *L,const T *data,UINT count) 
{
	lua_newtable(L);

	for (UINT i=0;i < count;++i)
	{
		lua_pushinteger(L,(lua_Integer)(i+1)); // lua 表 从 1 开始，所以 +1
		lpush_value(L,data[i]);

		lua_settable(L,-3);
	}
}
template <typename T,unsigned N>
void lpush_vector(lua_State *L,const T data[N]) 
{
	lpush_vector(L,(T*)data,(UINT)N);
}
template <typename T>
void lpush_vector(lua_State *L,const std::vector<T> &data) 
{
	lpush_vector(L,(T*)&data[0],(UINT)data.size());
}

template <typename T>
void lpush_value(lua_State *L,const std::vector<T> &value,const char * title) 
{
	lpush_vector(L,value);
}

template <typename K,typename V>
void lpush_value(lua_State *L,const std::map<K,V> &value,const char * title) 
{
	lua_newtable(L);
	
	for (auto &pair : value)
	{
		lpush_value(L,pair.first);
		lpush_value(L,pair.second);
		lua_settable(L,-3);
	}
}

bool lget_value(lua_State *L,int tIndex,pai_struct &param,const char * title ) 
{
	if (lua_isnil(L,tIndex))
		return false;

	if (!lua_istable(L,tIndex))
	{
		luaL_error(L,"'%s' error,pai_struct expect 'table' but '%s'!",title,luaL_typename(L,tIndex));
		return false;
	}	

	memset(&param,0,sizeof(param));

	int top = lua_gettop(L);

	// 转换 栈 到正数
	if (tIndex < 0)
		tIndex = top + tIndex + 1;

	lget_table_memb(L,tIndex,"type",param.type,"pai_struct.type");
	lget_table_memb(L,tIndex,"score",param.score,"pai_struct.score");

	//lget_table_memb(L,tIndex,"pai",param.pai,"pai_struct.pai");
	lua_pushstring(L,"pai");
	lua_gettable(L,tIndex);
	int tIndexPai = lua_gettop(L);
	if (lua_isnil(L,tIndexPai))
	{
		lua_pop(L,1);
		return true;
	}

	for (int k=1;k<=PAI_STRUCT_LEN;++k)
	{
		lua_pushinteger(L,k);
		lua_gettable(L,tIndexPai);
		int v;
		if (!lget_value(L,-1,v,title))
		{
			lua_pop(L,1);
			break;
		}

		lua_pop(L,1);
		param.pai[k-1] = v;
	}	

	lua_pop(L,1);

	return true;
}

template <typename K,typename V>
bool lget_value(lua_State *L,int tIndex,std::map<K,V> &param,const char * title) 
{ 
	if (lua_isnil(L,tIndex))
		return true; // 空值 不认为失败

	if (!lua_istable(L,tIndex))
	{
		luaL_error(L,"'%s' error,map expect 'table' but '%s'!",title,luaL_typename(L,tIndex));
		return false;
	}

	int top = lua_gettop(L);

	// 转换 栈 到正数
	if (tIndex < 0)
		tIndex = top + tIndex + 1;

	int ik = top + 1;
	int iv = top + 2;

	lua_pushnil(L);
	while (lua_next(L, tIndex) != 0) 
	{
		K key;
		lget_value(L,ik,key,title);
		lget_value(L,iv,param[key],title);

		lua_pop(L, 1);
	}

	return true;
}
