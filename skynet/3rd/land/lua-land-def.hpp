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
			ASSERT(false); \
			lua_pushinteger(L,(lua_Integer)-2001); \
			return 1; \
		}

#endif


// 取得对象指针
#define LGetLightObject(_t,_var) \
	int _stack_index = 1; \
	if (!lua_islightuserdata(L,_stack_index))  \
	{  \
		return luaL_error(L,"get object " #_t " error, lua type is not lightuserdata!");  \
	}  \
	_t * _var = (_t *)lua_touserdata(L,_stack_index);  \
	if (!_var)  \
	{  \
		return luaL_error(L,"get object " #_t " error,it is null !");  \
	}

// 取得参数（一定要顺序放置）
#define LGetValue(_var) \
	++ _stack_index; \
	if (!lget_value(L,_stack_index,_var,#_var " value error! ")) \
	{ \
		return luaL_error(L,"get value " #_var " error,it is null !");  \
	}

// 取得 数组 参数（一定要顺序放置）
#define LGetVector(_var,...) \
	++ _stack_index; \
	if (!lget_vector(L,_stack_index,_var,##__VA_ARGS__,#_var " vector error! ")) \
	{ \
		return luaL_error(L,"get vector " #_var " error,it is null !");  \
	}

// 取得对象的简化定义
#define LGetGameObject(guName,glName) \
	LGetLightObject(CGameUserItemSink,guName) \
	CGameLogic * glName = &(guName)->m_GameLogic; 



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


template <typename T>
bool lget_vector(lua_State *L,int tIndex,std::vector<T> & param,const char * title = "param")
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

// 得到表成员
template <typename T>
bool lget_table_memb(lua_State *L,int tIndex,std::string &name,T &member,const char * title = "member") 
{
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



