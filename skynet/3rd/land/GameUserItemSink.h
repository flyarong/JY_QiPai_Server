#ifndef GAME_USER_ITEM_SINK_HEAD_FILE
#define GAME_USER_ITEM_SINK_HEAD_FILE

#include "GameLogic.h"

class CGameUserItemSink
{
public:

	CGameLogic m_GameLogic;

	WORD m_wMeChairID; // 自己的椅子号

	WORD m_wOutChairID; // 出牌人 id

	BYTE							m_cbOutCount[GAME_PLAYER];			//出牌次数
	BYTE							m_cbTurnCardCount;					//出牌数目
	BYTE							m_cbTurnCardData[MAX_COUNT];		//出牌列表
	BYTE							m_cbHandCardData[MAX_COUNT];		//手上扑克
	BYTE							m_cbHandCardCount[GAME_PLAYER];		//扑克数目

	CGameUserItemSink();
	~CGameUserItemSink();

	//设置玩家手上的扑克
	void SetUserCard(WORD wChairID, BYTE cbCardData[], BYTE cbCardCount);

	//自己 座位号
	void SetMeChairId(WORD nId);

	// 用户出牌：已经出完牌的 通知
	void OnUserOutCard(WORD wOutChairID,BYTE cbOutCardData[], BYTE cbOutCardCount);

	//设置出牌
	VOID SetLastOutCard(WORD wOutUser,BYTE cbCardData[],BYTE cbCardCount);

	//出牌次数
	VOID SetOutCount(const BYTE cbOutCount[]);
	
	//设置底牌
	VOID SetBackCard(WORD wChairID, BYTE cbBackCardData[], BYTE cbCardCount) ;

	// 计算自己出牌
	//  isMust ： 是否必须出，即本轮 首发人
	// 返回：  0 放弃出牌; 1 出牌; 小于 0 ，出错
	int CalcOutCard(BYTE isMust,tagOutCard &stOutCard);
};

#endif