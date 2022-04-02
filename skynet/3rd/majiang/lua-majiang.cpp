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

#include "majiang.h"
#include "lua-majiang-def.hpp"
#include "nor_mj_auto_algorithm_lib.hpp"

int calc_num(std::map<MJ_PAI, int> &pai_map)
{
	int ret = 0;
	for (auto it = pai_map.begin();it!= pai_map.end();++it)
		ret += it->second;

	return ret;
}


extern "C" int ltest(lua_State *L) {


	std::map<MJ_PAI, int> pai_map = {
		{ 23,3 },

		{ 33,1 },
		{ 32,1 },
		{ 31,1 },

		{ 14,1 },
		{ 15,1 },
		{ 16,1 },

		{ 24,1 },
		{ 25,1 },

		{ 26,1 },
		{ 27,1 },
		{ 28,1 },
	};
	MJ_PAI _s = 11;
	int all_num = calc_num(pai_map);
	int jiang_num = 0;
	std::vector<PaiItem> list;
	int list_pos = 0;
	std::vector<HuPaiData> info;

	compute_nor_hupai_info(pai_map,_s,all_num,jiang_num,list,list_pos,info);


	return 0;
}


extern "C" int lget_hupai_info(lua_State *L) 
{
	PAI_MAP pai_map;
	PG_MAP pg_map;
	MJ_PAI must_que;
	KAI_GUAN kaiguan;
	MULTI_TYPES multi_types;
	int maxShouPaiNum;

	LParamBegin(0);

	LGetMap(pai_map);
	LGetMap(pg_map);
	LGetValue(must_que);
	LGetMap(kaiguan);
	LGetMap(multi_types);
	LGetValue(maxShouPaiNum);

	LParamEnd();

	
	HuPaiInfo hupaiInfo;
	if (get_hupai_info(pai_map,pg_map,must_que,kaiguan,multi_types,maxShouPaiNum,hupaiInfo))
	{
		lpush_value(L,hupaiInfo);
	}
	else
	{
		lua_pushnil(L);
	}
	

	return 1;
}

extern "C" int lget_chupai(lua_State *L)
{
	vector<PlayerPaiInfo> players_pai;
	vector<int> pai_pool;
	map<int,int> chu_pai;
	int tuguan_level;

	LParamBegin(0);

	LGetVector(players_pai)
	LGetVector(pai_pool)
	LGetMap(chu_pai)
	LGetValue(tuguan_level)

	int ret = get_chupai(players_pai,pai_pool,chu_pai,tuguan_level);

	lpush_value(L,ret);

	return 1;
}


extern "C" int lcan_peng(lua_State *L) 
{
	std::vector<PlayerPaiInfo> players_pai;
	std::vector<int> pai_pool;
	map<int,int> chu_pai;
	int peng;

	LParamBegin(0);

	LGetValue(players_pai)
	LGetValue(pai_pool)
	LGetValue(chu_pai)
	LGetValue(peng);

	int ret = can_peng(players_pai,pai_pool,chu_pai,peng);

	lpush_value(L,ret);

	return 1;
}

extern "C" int lcan_gang(lua_State *L) 
{
	std::vector<PlayerPaiInfo> players_pai;
	std::vector<int> pai_pool;
	map<int,int> chu_pai;
	int gang;

	LParamBegin(0);

	LGetValue(players_pai)
	LGetValue(pai_pool)
	LGetValue(chu_pai)
	LGetValue(gang);

	int ret = can_gang(players_pai,pai_pool,chu_pai,gang);

	lpush_value(L,ret);

	return 1;
}

extern "C" int lspecial_deal_chupai(lua_State *L)
{
	map<int, int> pai_map;
	int dq_color;
	map<int, int> chu_pai;
	LParamBegin(0);

	LGetValue(pai_map)
	LGetValue(dq_color)
	LGetValue(chu_pai)

	int ret = special_deal_chupai(pai_map,dq_color,chu_pai);		
	
	lpush_value(L,ret);
	
	return 1;
}

extern "C" int luaopen_majiang_core(lua_State *L) 
{

	luaL_checkversion(L);


	luaL_Reg l[] = 
	{
		{ "test", ltest},
		{ "get_hupai_info", lget_hupai_info },
		{ "get_chupai", lget_chupai },
		{ "can_peng", lcan_peng },
		{ "can_gang", lcan_gang },
		{ "special_deal_chupai", lspecial_deal_chupai },
		{ NULL, NULL },
	};


	luaL_newlib(L, l);

  return 1;
}
