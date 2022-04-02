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
#include "CMD_Game.h"
#include "CMD_Control.h"
#include "GameUserItemSink.h"

#include "lua-land-def.hpp"

extern "C" int lcreate_logic(lua_State *L) {

	CGameUserItemSink * gu = new CGameUserItemSink;

	lua_pushlightuserdata(L,gu);

	return 1;
}


extern "C" int ldestroy_logic(lua_State *L) {

	LGetGameObject(gu,gl)

	delete gu;

	return 0;
}

extern "C" int lSetUserCard(lua_State *L) {

	LGetGameObject(gu,gl)

	WORD wChairID;
	std::vector<BYTE> cbCardData;

	LGetValue(wChairID)
	LGetVector(cbCardData)

	gu->SetUserCard(wChairID,&cbCardData[0],(BYTE)cbCardData.size());

	return 0;
}

extern "C" int lSetLastOutCard(lua_State *L) {

	LGetGameObject(gu,gl)

	WORD wOutUser;
	std::vector<BYTE> cbCardData;

	LGetValue(wOutUser)
	LGetVector(cbCardData)

	gu->SetLastOutCard(wOutUser,cbCardData.empty()?nullptr:&cbCardData[0],(BYTE)cbCardData.size());

	return 0;
}

extern "C" int lSetBanker(lua_State *L) {

	LGetGameObject(gu,gl)

	WORD wBanker;

	LGetValue(wBanker)

	gl->SetBanker(wBanker);

	return 0;
}

extern "C" int lSetOutCount(lua_State *L) {

	LGetGameObject(gu,gl)

	std::vector<BYTE> cbOutCounts;

	LGetVector(cbOutCounts)

	BYTE vecOutCounts[GAME_PLAYER] = {0};

	for (int i=0;i<cbOutCounts.size();++i)
		vecOutCounts[i] = cbOutCounts[i];

	gu->SetOutCount(vecOutCounts);

	return 0;
}

// 设置地主牌
extern "C" int lSetLandScoreCardData(lua_State *L) {

	LGetGameObject(gu,gl)

	std::vector<BYTE> cbCardData;

	// 取得参数

	LGetVector(cbCardData)

	gl->SetLandScoreCardData(&cbCardData[0],(BYTE)cbCardData.size());

	return 0;
}

// 设置底牌给 地主
extern "C" int lSetBackCard(lua_State *L) {

	LGetGameObject(gu,gl)

	WORD wChairID;
	std::vector<BYTE> cbCardData;

	// 取得参数

	LGetValue(wChairID)
	LGetVector(cbCardData)

	gu->SetBackCard(wChairID,&cbCardData[0],(BYTE)cbCardData.size());

	return 0;
}

// 分析是否可以叫地主
extern "C" int lAnalyseLandScore(lua_State *L) {

	LGetGameObject(gu,gl)

	LAND_TRY

	std::vector<BYTE> cbCardData;

	// 取得参数

	LGetVector(cbCardData)

	bool ret = gl->AnalyseLandScore(&cbCardData[0],(BYTE)cbCardData.size());

	lua_pushboolean(L,ret ? 1 : 0);

	LAND_CATCH

	return 1;
}

// 计算叫地主分数
extern "C" int lLandScore(lua_State *L) {

	LGetGameObject(gu,gl)

	WORD wMeChairID;
	BYTE cbCurrentLandScore;

	// 取得参数

	LGetValue(wMeChairID)
	LGetValue(cbCurrentLandScore)

	BYTE ret = gl->LandScore(wMeChairID,cbCurrentLandScore);

	lua_pushinteger(L,(lua_Integer)ret);

	return 1;
}

extern "C" int lSetMeChairId(lua_State *L) {
	LGetGameObject(gu,gl)

	WORD wMeChairID;

	// 取得参数

	LGetValue(wMeChairID)

	gu->SetMeChairId(wMeChairID);

	return 0;
}

extern "C" int lOnUserOutCard(lua_State *L) {

	LGetGameObject(gu,gl)

	LAND_TRY

	WORD wOutChairID;
	std::vector<BYTE> cbOutCardData;

	// 取得参数

	LGetValue(wOutChairID)
	LGetVector(cbOutCardData)

	gu->OnUserOutCard(wOutChairID,&cbOutCardData[0],(BYTE)cbOutCardData.size());

	LAND_CATCH

	return 0;
}

extern "C" int lCalcOutCard(lua_State *L) {

	LGetGameObject(gu,gl)

	LAND_TRY

	BYTE isMust;

	// 取得参数

	LGetValue(isMust)

	// 返回值
	tagOutCard outCard;

	int ret = gu->CalcOutCard(isMust,outCard);

	// 不出或出错
	if (ret <= 0)
	{
		lua_pushinteger(L,(lua_Integer)ret);
		return 1;
	}

	// 设置返回表

	lua_newtable(L);

	// outCard.cards
	lua_pushstring(L,"cards");
	lpush_vector(L,outCard.cbCardData,outCard.cbCardCount);
	lua_settable(L,-3);

	// outCard.card_type
	lua_pushstring(L,"card_type");
	lpush_value(L,outCard.cbCardType);
	lua_settable(L,-3);

	// outCard.logic_value
	lua_pushstring(L,"logic_value");
	lpush_value(L,outCard.cbLogicValue);
	lua_settable(L,-3);

	LAND_CATCH

	return 1;
}

extern "C" int lSetppRule(lua_State *L) {

	LGetGameObject(gu,gl)

	DWORD dwRule;

	// 取得参数

	LGetValue(dwRule)

	gl->SetppRule(dwRule);

	return 0;
}

extern "C" int luaopen_land_core(lua_State *L) {
  luaL_checkversion(L);

 //  	CGameLogic gl;
	// gl.load("./gamelogic_debug.dump");

	// BYTE cbHandCard[MAX_COUNT] = { 0x12, 0x2, 0x38, 0x33, 0x23 };
	// BYTE cTurnCard[MAX_COUNT] = {0};
	// tagOutCard stOutCard = { 0 };

	// gl.SearchOutCard(cbHandCard, 5, cTurnCard, 0, INVALID_CHAIR, 2, stOutCard);

  luaL_Reg l[] = {
    {"create", lcreate_logic},
    {"destroy", ldestroy_logic},
    {"SetUserCard", lSetUserCard},
    {"SetLastOutCard", lSetLastOutCard},
    {"SetBanker", lSetBanker},
    {"SetOutCount", lSetOutCount},
    //{"SearchOutCard", lSearchOutCard},
    //{"GetCardType", lGetCardType},
    // {"SortCardList", lSortCardList},
    // {"CompareCard", lCompareCard},
    {"SetLandScoreCardData", lSetLandScoreCardData},
    {"SetBackCard", lSetBackCard},
    {"AnalyseLandScore", lAnalyseLandScore},
    {"LandScore", lLandScore},
    {"SetMeChairId", lSetMeChairId},
    {"OnUserOutCard", lOnUserOutCard},
    {"CalcOutCard", lCalcOutCard},
    {"SetppRule", lSetppRule},

	// 新版代码

    { NULL, NULL },
  };


  luaL_newlib(L, l);

  return 1;
}