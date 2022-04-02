#include <string.h>
#include <stdio.h>
#include <memory.h>

#include <algorithm>
#include "CMD_Game.h"
#include "CMD_Control.h"
#include "GameUserItemSink.h"

using namespace std;

#define my_max(a,b) (((a) > (b)) ? (a) : (b))
#define my_min(a,b) (((a) < (b)) ? (a) : (b))


CGameUserItemSink::CGameUserItemSink()
{
	m_GameLogic.m_userSink = this;

	//扑克变量
	m_cbTurnCardCount=0;
	ZeroMemory(m_cbTurnCardData,sizeof(m_cbTurnCardData));

	//手上扑克
	ZeroMemory(m_cbHandCardData,sizeof(m_cbHandCardData));
	ZeroMemory(m_cbHandCardCount,sizeof(m_cbHandCardCount));

	m_wMeChairID = INVALID_CHAIR;
	m_wOutChairID = INVALID_CHAIR;
}

CGameUserItemSink::~CGameUserItemSink()
{
	
}

void CGameUserItemSink::SetUserCard(WORD wChairID, BYTE cbCardData[], BYTE cbCardCount)
{
	CHECK_CHAIR(wChairID);

#ifdef LYX_DEBUG
	printf("CGameUserItemSink SetUserCard AAAA :%d,%s;\n",wChairID,cardDataToString(cbCardData,cbCardCount).c_str());
#endif

	m_cbOutCount[wChairID] = 0;
	m_cbHandCardCount[wChairID] = cbCardCount;
	m_GameLogic.SetUserCard(wChairID, cbCardData, NORMAL_COUNT) ;

	m_GameLogic.SetOutCount(m_cbOutCount);

	if(wChairID==m_wMeChairID)
	{
		CopyMemory(m_cbHandCardData,cbCardData,sizeof(BYTE)*NORMAL_COUNT);
		m_GameLogic.SortCardList(m_cbHandCardData,m_cbHandCardCount[m_wMeChairID],ST_ORDER);
	}

}
VOID CGameUserItemSink::SetLastOutCard(WORD wOutUser,BYTE cbCardData[],BYTE cbCardCount)
{
	m_wOutChairID = wOutUser ;
	m_cbTurnCardCount = cbCardCount;
	CopyMemory(m_cbTurnCardData,cbCardData,cbCardCount*sizeof(BYTE));

	m_GameLogic.SetLastOutCard(wOutUser,cbCardData,cbCardCount);
}

VOID CGameUserItemSink::SetOutCount(const BYTE cbOutCount[])
{
    CHECK_MEMCPY(GAME_PLAYER,sizeof(m_cbOutCount));

	CopyMemory(m_cbOutCount,cbOutCount,sizeof(m_cbOutCount));

	m_GameLogic.SetOutCount(cbOutCount);
}

VOID CGameUserItemSink::SetBackCard(WORD wChairID, BYTE cbBackCardData[], BYTE cbCardCount)
{
	ASSERT(m_cbHandCardCount[wChairID] <= NORMAL_COUNT);

	// 是自己，要复制手牌
	if (wChairID == m_wMeChairID)
	{
		CopyMemory(&m_cbHandCardData[m_cbHandCardCount[wChairID]],cbBackCardData,cbCardCount);
		
		m_cbHandCardCount[wChairID] += cbCardCount;	

		m_GameLogic.SortCardList(m_cbHandCardData,m_cbHandCardCount[m_wMeChairID],ST_ORDER);
	}
	else
	{
		m_cbHandCardCount[wChairID] += cbCardCount;	
	}

	m_GameLogic.SetBackCard(wChairID,cbBackCardData,cbCardCount);
}

void CGameUserItemSink::SetMeChairId(WORD wMeChairID)
{
	CHECK_CHAIR(wMeChairID);

	m_wMeChairID = wMeChairID;
}

void CGameUserItemSink::OnUserOutCard(WORD wOutChairID,BYTE cbOutCardData[], BYTE cbOutCardCount)
{
#ifdef LYX_DEBUG	
	printf("0x%08x -> 0x%08x ============= CGameUserItemSink::OnUserOutCard ========\n",this,&m_GameLogic);
	printf("cbOutCardData:%s;\n",cardDataToString(cbOutCardData,cbOutCardCount).c_str());
	printf("m_cbTurnCardData:%s;\n",cardDataToString(m_cbTurnCardData,m_cbTurnCardCount).c_str());
	printf("m_cbHandCardData:%s;\n",cardDataToString(m_cbHandCardData,m_cbHandCardCount[m_wMeChairID]).c_str());
	for (int i=0;i<GAME_PLAYER;++i)
		printf("player  outcount:%d, %d !\n",i,m_cbOutCount[i]);
	for (int i=0;i<GAME_PLAYER;++i)
		printf("player hand count:%d, %d !\n",i,m_cbHandCardCount[i]);
	printf("my chairId,out chairId:%d,%d.\n",m_wMeChairID,wOutChairID);
#endif

	CHECK_CHAIR(wOutChairID);

	m_cbOutCount[wOutChairID]++;

	m_GameLogic.SetLastOutCard(wOutChairID,cbOutCardData,cbOutCardCount);

	//出牌变量
	m_cbTurnCardCount=cbOutCardCount;
	CopyMemory(m_cbTurnCardData,cbOutCardData,cbOutCardCount*sizeof(BYTE));
	m_wOutChairID = wOutChairID ;

	if (m_wMeChairID == wOutChairID)//出牌是自己
		m_GameLogic.RemoveCard(cbOutCardData, cbOutCardCount, m_cbHandCardData, m_cbHandCardCount[m_wMeChairID]);
	
	//设置变量
	m_GameLogic.RemoveUserCardData(wOutChairID, cbOutCardData, cbOutCardCount);

	m_GameLogic.SetOutCount(m_cbOutCount);

	m_cbHandCardCount[wOutChairID] -= cbOutCardCount;

#ifdef LYX_DEBUG
	printf("0x%08x -> 0x%08x ============= CGameUserItemSink::OnUserOutCard --end-- ========\n",this,&m_GameLogic);
	printf("m_cbTurnCardData:%s;\n",cardDataToString(m_cbTurnCardData,m_cbTurnCardCount).c_str());
	printf("m_cbHandCardData:%s;\n",cardDataToString(m_cbHandCardData,m_cbHandCardCount[m_wMeChairID]).c_str());
	for (int i=0;i<GAME_PLAYER;++i)
		printf("player  outcount:%d, %d !\n",i,m_cbOutCount[i]);
	for (int i=0;i<GAME_PLAYER;++i)
		printf("player hand count:%d, %d !\n",i,m_cbHandCardCount[i]);
	printf("my chairId,out chairId:%d,%d.\n",m_wMeChairID,wOutChairID);
#endif

	// by lyx
	CheckGameLogicData(&m_GameLogic,this);
}

int CGameUserItemSink::CalcOutCard(BYTE isMust,tagOutCard &stOutCard)
{
	if (m_wMeChairID >= GAME_PLAYER)
		return -1;

	int nError=0;	//出错标志

#ifdef LYX_DEBUG
	printf("0x%08x -> 0x%08x ============= CGameUserItemSink::CalcOutCard --end-- ========\n",this,&m_GameLogic);
	printf("m_cbTurnCardData:%s;\n",cardDataToString(m_cbTurnCardData,m_cbTurnCardCount).c_str());
	printf("m_cbHandCardData:%s;\n",cardDataToString(m_cbHandCardData,m_cbHandCardCount[m_wMeChairID]).c_str());
	for (int i=0;i<GAME_PLAYER;++i)
		printf("player  outcount:%d, %d !\n",i,m_cbOutCount[i]);
	for (int i=0;i<GAME_PLAYER;++i)
		printf("player hand count:%d, %d !\n",i,m_cbHandCardCount[i]);
	printf("my chairId,out chairId:%d,%d.\n",m_wMeChairID,m_wOutChairID);
#endif

	// 首发出牌，清理桌面上的牌
	if (isMust)
	{
		m_cbTurnCardCount = 0;
		ZeroMemory(m_cbTurnCardData,sizeof(m_cbTurnCardData));

		printf("out card is must,clear turn card count!\n");
	}

	//扑克分析

	ZeroMemory(&stOutCard,sizeof(stOutCard));
	m_GameLogic.SetOutCount(m_cbOutCount);
	if (m_cbTurnCardCount==0||m_wOutChairID==m_wMeChairID)
		m_wOutChairID=INVALID_CHAIR;

#ifdef LYX_DEBUG
	CGameLogic tempgl;
	m_GameLogic.copy(tempgl);
	TRY
	{
#endif

		m_GameLogic.SearchOutCard(m_cbHandCardData, m_cbHandCardCount[m_wMeChairID], 
			m_cbTurnCardData, m_cbTurnCardCount, 
			m_wOutChairID, m_wMeChairID, stOutCard);

		if (stOutCard.cbCardCount > m_cbHandCardCount[m_wMeChairID])
		{
			THROW_ERROR(-1003);
		}

#ifdef LYX_DEBUG
	}

	CATCH(TempExcep &te)
	{


		ASSERT(false);

		for (;true;)
		{
			CGameLogic tempgl2;
			tempgl.copy(tempgl2);
			TRY
			{
				tempgl2.SearchOutCard(m_cbHandCardData, m_cbHandCardCount[m_wMeChairID], 
					m_cbTurnCardData, m_cbTurnCardCount, 
					m_wOutChairID, m_wMeChairID, stOutCard);

			}
			CATCH(...)
			{
				continue;
			}
		}


		tempgl.save("./gamelogic_debug.dump");

		THROW;

	}CATCH(...){

		tempgl.save("./gamelogic_debug.dump");

		ASSERT(false);

		ZeroMemory(&stOutCard,sizeof(tagOutCard));
		THROW;

		//return -2;
	}

#endif

	//牌型合法判断
	if(stOutCard.cbCardCount>0 && CT_ERROR==m_GameLogic.GetCardType(stOutCard.cbCardData,stOutCard.cbCardCount))
	{
		ZeroMemory(&stOutCard, sizeof(tagOutCard));

		return -3;
	}

	// 首发必须出牌
	if(isMust)
	{
		if(stOutCard.cbCardCount==0)
		{
			if (m_cbHandCardCount[m_wMeChairID] == 0) 
				return -4;

			//最小一张
			stOutCard.cbCardCount = 1 ;
			BYTE cbCardData[MAX_COUNT] = { 0 };
			BYTE cbCardCount = my_min(m_cbHandCardCount[m_wMeChairID], MAX_COUNT);

			CopyMemory(cbCardData, m_cbHandCardData, sizeof(BYTE)*cbCardCount);
			m_GameLogic.SortCardList(cbCardData, cbCardCount, ST_ORDER);
			if (cbCardCount  >= 1)
			{
				stOutCard.cbCardType = CT_SINGLE;
				stOutCard.cbCardData[0] = cbCardData[cbCardCount - 1];
			}
			else
			{
				return -5;
			}
		}
	}
	else
	{
		if(!m_GameLogic.CompareCard(m_cbTurnCardData,stOutCard.cbCardData,m_cbTurnCardCount,stOutCard.cbCardCount))
		{
			// 不出牌
			return 0;
		}				
	}

	//结果判断
	if (stOutCard.cbCardCount <= 0)
	{
		// 不出牌
		return 0;
	}

	return 1;
}