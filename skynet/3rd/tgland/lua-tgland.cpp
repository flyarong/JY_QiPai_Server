//
// 作者: 隆元线
// Date: 2018/10/1
// Time: 14:48
// 导出 CGameLogic 的函数
//

#include <string.h>
#include <stdio.h>
#include <memory.h>
#include <string.h>
#include <errno.h>

#include<execinfo.h>
#include<signal.h>

#include <vector>
#include <string>
#include <map>

#include <algorithm>

#include "ddz_boyi_search.hpp"

#include "lua-tgland-def.hpp"

extern "C" int lget_boyiSearch(lua_State *L) {

	vector<pai_struct> cp_return_list;

	map<int,map<int,int>>pai_map;
	map<int,int> seat_type;
	map<int,int> game_over_info;
	map<int,int> kaiguan;
	map<int,int> cp_count;
	
	int cur_p; // 当前该出牌的人
	int all_seat;
	int cp_p; // 出了牌的人
	pai_struct cp_data; // 出了的牌
	int times_limit;

	LParamBegin()

	LGetValue(pai_map)
	LGetValue(seat_type)
	LGetValue(game_over_info)
	LGetValue(kaiguan)
	LGetValue(cp_count)

	LGetValue(cur_p)
	LGetValue(all_seat)
	LGetValue(cp_p)
	LGetValue(cp_data)
	LGetValue(times_limit)

	get_boyiSearch(
		cp_return_list,
		pai_map,
		seat_type,
		game_over_info,
		kaiguan,
		cp_count,
		
		cur_p,
		all_seat,
		cp_p,
		cp_data.type <= 0 ? nullptr : &cp_data,
		times_limit		
	);

	lpush_vector(L,cp_return_list);

	return 1;
}

extern "C" int lget_boyiSearch_have_pe(lua_State *L) {

	vector<pai_struct> cp_return_list;

	map<int,map<int,int>>pai_map;
	map<int,int> seat_type;
	map<int,int> game_over_info;
	map<int,int> kaiguan;
	map<int,int> cp_count;

	map<int,map<int,vector<pai_struct>>> pai_enum;
	
	int cur_p;
	int all_seat;
	int cp_p;
	pai_struct cp_data;
	int times_limit;

	LParamBegin()

	LGetValue(pai_map)
	LGetValue(seat_type)
	LGetValue(game_over_info)
	LGetValue(kaiguan)
	LGetValue(cp_count)

	LGetValue(pai_enum)

	LGetValue(cur_p)
	LGetValue(all_seat)
	LGetValue(cp_p)
	LGetValue(cp_data)
	LGetValue(times_limit)

	get_boyiSearch_have_pe(
		cp_return_list,
		pai_map,
		seat_type,
		game_over_info,
		kaiguan,
		cp_count,
		
		pai_enum,

		cur_p,
		all_seat,
		cp_p,
		cp_data.type <= 0 ? nullptr : &cp_data,
		times_limit		
	);

	lpush_vector(L,cp_return_list);

	return 1;
}

extern "C" int lfenpai_for_all(lua_State *L) {
	FenpaiData data;
	std::map<int,std::map<int,int>> pais;
	std::map<int,int> sz_min;
	std::map<int,int> sz_max;
	std::map<int,int> kaiguan;
	int my_seat_id;
	int dz_seat_id;
	int seat_count;

	LParamBegin()

	LGetValue(pais)
	LGetValue(sz_min)
	LGetValue(sz_max)
	LGetValue(kaiguan)
	LGetValue(my_seat_id)
	LGetValue(dz_seat_id)
	LGetValue(seat_count)

	fenpai_for_all(&data,pais,sz_min,sz_max,kaiguan,my_seat_id,dz_seat_id,seat_count);

	lua_newtable(L);

	lua_pushstring(L,"query_map");
	lua_pushlightuserdata(L,data.query_map);
	lua_settable(L,-3);

	lua_pushstring(L,"fen_pai");
	lpush_value(L,data.fen_pai);
	lua_settable(L,-3);

	lua_pushstring(L,"xjbest_fenpai");
	lpush_value(L,data.xjbest_fenpai);
	lua_settable(L,-3);

	return 1;
}

extern "C" int lfenpai_for_one(lua_State *L) {
	FenpaiData data;
	std::map<int,std::map<int,int>> pais;
	std::map<int,int> sz_min;
	std::map<int,int> sz_max;
	std::map<int,int> kaiguan;
	int my_seat_id;
	int dz_seat_id;
	int seat_count;

	LParamBegin()

	LGetValue(pais)
	LGetValue(sz_min)
	LGetValue(sz_max)
	LGetValue(kaiguan)
	LGetValue(my_seat_id)
	LGetValue(dz_seat_id)
	LGetValue(seat_count)

	fenpai_for_one(&data,pais,sz_min,sz_max,kaiguan,my_seat_id,dz_seat_id,seat_count);

	lua_newtable(L);

	lua_pushstring(L,"fen_pai");
	lpush_value(L,data.fen_pai);
	lua_settable(L,-3);

	return 1;
}



extern "C" int lquery_map_get_pai_score(lua_State *L) {
	QueryMap* query_map;
	int lseat_id;
	PaiStruct pai;
	bool use_all_unkown;

	LParamBegin()

	LGetLightObject(query_map)
	LGetValue(lseat_id)
	LGetValue(pai)
	LGetValue(use_all_unkown)
	
	auto ret = query_map_get_pai_score(query_map,lseat_id,pai,use_all_unkown);

	lpush_value(L,ret.first);
	lpush_value(L,ret.second);

	return 2;
}

extern "C" int lquery_map_get_pai_is_bigger_in_unkown(lua_State* L)
{
	QueryMap* query_map;
	int lseat_id;
	PaiStruct pai;

	LParamBegin()

	LGetLightObject(query_map)
	LGetValue(lseat_id)
	LGetValue(pai)

	int ret=query_map_get_pai_is_bigger_in_unkown(query_map,lseat_id,pai);
	lpush_value(L,ret);
	return 1;
}

extern "C" int ldestroy_query_map(lua_State *L) {
	QueryMap* query_map;

	LParamBegin()

	LGetLightObject(query_map)

	if (query_map)
		destroy_query_map(query_map);

	return 0;
}




extern "C" int luaopen_tgland_core(lua_State *L) {
  luaL_checkversion(L);

  luaL_Reg l[] = {
    {"get_boyiSearch", lget_boyiSearch},
    {"get_boyiSearch_have_pe", lget_boyiSearch_have_pe},
    {"fenpai_for_all", lfenpai_for_all},
    {"fenpai_for_one", lfenpai_for_one},
	{"query_map_get_pai_score", lquery_map_get_pai_score},
	{"query_map_get_pai_is_bigger_in_unkown",lquery_map_get_pai_is_bigger_in_unkown},
	{"destroy_query_map", ldestroy_query_map},

    { NULL, NULL },
  };


  luaL_newlib(L, l);

  return 1;
}
