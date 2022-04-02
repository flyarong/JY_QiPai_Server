//
// 作者: 隆元线
// Date: 2018/10/1
// Time: 14:48
// lua 数据类型导出
//

extern "C"  
{  
    #include "lua.h"  
    #include "lauxlib.h"  
    #include "lualib.h"  
}  

// 取参数开始，设置 起始序号
#define LParamBegin(index) int _stack_index = index;

#define LParamEnd() 

// 取得参数（一定要顺序放置）
#define LGetValue(_var) \
	++ _stack_index; \
	if (!lget_value(L,_stack_index,_var,#_var " value error! ")) \
	{ \
		return luaL_error(L,"get value " #_var " error,it is null !");  \
	}

// 取得 数组 参数（一定要顺序放置）
#define LGetVector(_var) \
	++ _stack_index; \
	if (!lget_vector(L,_stack_index,_var,#_var " vector error! ")) \
	{ \
		return luaL_error(L,"get vector " #_var " error,it is null !");  \
	}

// 取得 map 表参数（一定要顺序放置）
#define LGetMap(_var) \
	++ _stack_index; \
	if (!lget_map(L,_stack_index,_var,#_var " map error! ")) \
	{ \
		return luaL_error(L,"get map " #_var " error,it is null !");  \
	}

// 转换 栈序号为正数
inline void trans_stack(lua_State *L,int &i)
{
	if (i<0)
		i = lua_gettop(L) + i + 1;
}

///////////////////////////////////////////////


template <typename T>
bool lget_vector(lua_State *L, int tIndex, std::vector<T> & param, const char * title = "param");
template <typename K,typename V>
bool lget_map(lua_State *L, int tIndex, std::map<K,V> & param, const char * title = "param");
template <typename T>
bool lget_value(lua_State *L, int i, std::vector<T> & param, const char * title = "param");
template <typename K,typename V>
bool lget_value(lua_State *L, int i, std::map<K,V> & param, const char * title = "param");

// 数据压栈
template <typename T>
void lpush_value(lua_State *L,const T &value) 
{
	lua_pushinteger(L,(lua_Integer)value);
}

void lpush_value(lua_State *L,const char * value) 
{
	lua_pushstring(L,value);
}

void lpush_value(lua_State *L,const std::string &value) 
{
	lua_pushstring(L,value.c_str());
}

template <typename K,typename V>
void lpush_value(lua_State *L,const std::map<K,V> &value) 
{
	lua_newtable(L);
	
	for (auto &pair : value)
	{
		lpush_value(L,pair.first);
		lpush_value(L,pair.second);
		lua_settable(L,-3);
	}
}

void lpush_value(lua_State *L,HuPaiInfo &value) 
{
	lua_newtable(L);

	lua_pushstring(L,"hu_type_info");
	lpush_value(L,value.hu_type_info);
	lua_settable(L,-3);

	lua_pushstring(L,"mul");
	lpush_value(L,value.mul);
	lua_settable(L,-3);

	lua_pushstring(L,"geng_num");
	lpush_value(L,value.geng_num);
	lua_settable(L,-3);

}


// 读取数据
template <typename T>
bool lget_integer(lua_State *L,int i,T &param,const char * title = "param") 
{
	if (!lua_isinteger(L,i))
	{
		luaL_error(L,"'%s' error,expect 'integer' but '%s'!",title,luaL_typename(L,i));
		return false;
	}

	param = (T)luaL_checkinteger(L,i);
	return true;
}

template <typename T>
bool lget_value(lua_State *L,int i,T &param,const char * title = "param") 
{ 
	return lget_integer(L,i,param,title); 
}

bool lget_value(lua_State *L,int i,std::string &param,const char * title = "param") 
{
	if (!lua_isstring(L,i))
	{
		luaL_error(L,"'%s' error,expect 'string' but '%s'!",title,luaL_typename(L,i));
		return false;
	}

	param = luaL_checkstring(L,i);
	return true;
}


bool lget_value(lua_State *L,int i,bool &param,const char * title = "param") 
{
	if (!lua_isboolean(L,i))
	{
		luaL_error(L,"'%s' error,expect 'boolean' but '%s'!",title,luaL_typename(L,i));
		return false;
	}

	if (lua_toboolean(L,i))
		param = true;
	else
		param = false;
	
	return true;
}  

template <typename T>
bool lget_value(lua_State *L, int i, std::vector<T> & param, const char * title /*= "param"*/)
{
	return lget_vector(L,i,param,title);
}

template <typename K,typename V>
bool lget_value(lua_State *L, int i, std::map<K,V> & param, const char * title /*= "param"*/)
{
	return lget_map(L,i,param,title);
}

bool lget_value(lua_State *L, int i, PaiItem &param, const char * title = "param")
{
	if (!lua_istable(L, i))
	{
		luaL_error(L, "'%s' error,expect 'PaiItem table' but '%s'!", title, luaL_typename(L, i));
		return false;
	}
	
	trans_stack(L,i);

	lua_getfield(L, i, "type");
	lget_value(L, -1, param.type);
	lua_pop(L, 1);
	
	lua_getfield(L, i, "pai_type");
	lget_value(L, -1, param.pai_type);
	lua_pop(L, 1);

	return true;
}


bool lget_value(lua_State *L, int i, HuPaiData &param, const char * title = "param")
{
	if (!lua_istable(L, i))
	{
		luaL_error(L, "'%s' error,expect 'HuPaiData table' but '%s'!", title, luaL_typename(L, i));
		return false;
	}
	
	trans_stack(L,i);

	lua_getfield(L, i, "jiang_num");
	lget_value(L, -1, param.jiang_num);
	lua_pop(L, 1);

	lua_getfield(L, i, "list_pos");
	lget_value(L, -1, param.list_pos);
	lua_pop(L, 1);

	lua_getfield(L, i, "list");
	lget_vector(L, -1, param.list);
	lua_pop(L, 1);

	return true;
}

bool lget_value(lua_State *L, int i, PlayerPaiInfo &param, const char * title = "param")
{
	if (!lua_istable(L, i))
	{
		luaL_error(L, "'%s' error,expect 'PlayerPaiInfo table' but '%s'!", title, luaL_typename(L, i));
		return false;
	}

	trans_stack(L,i);

	lua_getfield(L, i, "pai_map");
	lget_map(L, -1, param.pai_map,"PlayerPaiInfo.pai_map");
	lua_pop(L, 1);

	lua_getfield(L, i, "pg_map");
	lget_map(L, -1, param.pg_map,"PlayerPaiInfo.pg_map");
	lua_pop(L, 1);

	lua_getfield(L, i, "ding_que");
	lget_value(L, -1, param.ding_que,"PlayerPaiInfo.ding_que");
	lua_pop(L, 1);

	return true;
}

template <typename T>
bool lget_vector(lua_State *L,int tIndex,std::vector<T> & param,const char * title /*= "param"*/)
{
	if (lua_isnil(L,tIndex))
		return true; // 空值 不认为失败

	if (!lua_istable(L,tIndex))
	{
		luaL_error(L,"'%s' error,expect 'table' but '%s'!",title,luaL_typename(L,tIndex));
		return false;
	}

	int len = luaL_len(L,tIndex);

	int top = lua_gettop(L);

	// 转换 栈 到正数
	trans_stack(L,tIndex);

	char buftitle[500] = {0};

	for (int k=1;k<=len;++k)
	{
		lua_geti(L,tIndex,k);

		sprintf(buftitle,"%s, index %d ",title,k);

		param.push_back(T());
		if (!lget_value(L,-1, param.back(),buftitle))
			return false;

		lua_pop(L,1);
	}

	// 清栈
	lua_settop(L,top);
	return true;
}


template <typename K,typename V>
bool lget_map(lua_State *L, int tIndex, std::map<K,V> & param, const char * title /*= "param"*/)
{
	if (lua_isnil(L, tIndex))
		return true; // 空值 不认为失败

	if (!lua_istable(L, tIndex))
	{
		luaL_error(L, "'%s' error,expect 'table' but '%s'!", title, luaL_typename(L, tIndex));
		return false;
	}

	int top = lua_gettop(L);

	// 转换 栈 到正数
	trans_stack(L,tIndex);

	char buftitle[500] = { 0 };

	lua_pushnil(L);
	while (lua_next(L, tIndex) != 0) 
	{
		sprintf(buftitle, "%s, get key ", title);

		K k;
		lget_value(L, -2, k, buftitle);
		param[k] = V();

		sprintf(buftitle, "%s, get value ", title);
		lget_value(L, -1, param[k], buftitle);

		lua_pop(L, 1);
	}

	// 清栈
	lua_settop(L, top);
	return true;
}

// 得到表成员
template <typename T>
bool lget_table_memb(lua_State *L,int tIndex,std::string &name,T &member,const char * title = "member") 
{
	trans_stack(L,tIndex);

	if (!lua_istable(L,tIndex))
	{
		luaL_error(L,"'%s' error,expect 'table' but '%s'!",title,luaL_typename(L,tIndex));
		return false;
	}

	lua_pushstring(L,name.c_str());
	lua_gettable(L,tIndex);

	char buftitle[500] = {0};
	sprintf(buftitle,"%s, index %d ",title,name.c_str());

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



